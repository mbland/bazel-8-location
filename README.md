# Bazel 8 `$(location)` and `--legacy_external_runfiles` example

This reproduces the changing behavior of [the `$(location)` predefined
source/output path variable][predefpath] in [Bazel 8.0.0][] and [Bazel 8.0.1][].
Corresponds to [bazelbuild/bazel#25198][].

## Summary

Under Bazel 8, `bazel build` expansions of `$(location)` for targets in external
repositories match `$(execpath)` instead of `$(rootpath)`, which breaks some
existing `BUILD` targets.

Under `bazel run`, expansions of `$(location)` match `$(rootpath)` instead.

There are two workarounds:

- Update all affected `$(location)` expansions to use `$(rootpath)` instead.
    This is backwards compatible to Bazel 6.5.0.

- Apply the [`--legacy_external_runfiles`][] flag to restore the previous
    behavior, whereby expansions of `$(rootpath)`, `$(execpath)`, and
    `$(location)` are identical.

## Running the reproduction

Run the [`run-reproduction.sh`][] script, which uses [bazelisk][] and
[.bazelversion](./.bazelversion) to configure the Bazel version for each run.
I distilled the repository rule in [repository.bzl](./repository.bzl) from the
rule that instantiates the `@org_apache_commons_commons_lang_3_5_without_file`
repo seen in [bazelbuild/rules_scala#1678][]. (Specifically, from
[`jvm_import_external` in `scala/scala_maven_import_external.bzl`][jvm_ext].)

The output will contain the following (edited out from all of the Bazel
messages):

```txt
$ ./run-reproduction.sh

-----------
Bazel 7.5.0
-----------

From `bazel build //:build-expansions`:
  execpath: external/_main~_repo_rules~org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  rootpath: external/_main~_repo_rules~org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  location: external/_main~_repo_rules~org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar

From `bazel run //:run-expansions`:
  execpath: external/_main~_repo_rules~org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  rootpath: external/_main~_repo_rules~org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  location: external/_main~_repo_rules~org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar

-----------
Bazel 8.0.1
-----------

From `bazel build //:build-expansions`:
  execpath: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  rootpath: ../+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  location: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar

From `bazel run //:run-expansions`:
  execpath: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  rootpath: ../+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  location: ../+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar

-------------------------------------------
Bazel 8.0.1 with --legacy_external_runfiles
-------------------------------------------

From `bazel build //:build-expansions`:
  execpath: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  rootpath: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  location: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar

From `bazel run //:run-expansions`:
  execpath: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  rootpath: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
  location: external/+_repo_rules+org_apache_commons_commons_lang3_3_5/commons-lang3-3.5.jar
```

## Analysis

All of the expansions in question are for targets in external repositories.

The reproduction shows that prior to Bazel 8, expansions of `$(location)`,
`$(rootpath)`, and `$(execpath)` are identical. All of them begin with
`external/`, whether running `bazel build` or `bazel run`.

Under Bazel 8, by default, expansions of `$(rootpath)` now begin with `../`, and
expansions of `$(execpath)` begin with `external/`. However, expansions of
`$(location)` depend on the Bazel command:

| Command | `$(location)` expands to | which starts with |
| :-: | :-: | :-: |
| `bazel build` | `$(execpath)` | `external/` |
| `bazel run` | `$(rootpath)` | `../` |

Setting the `--legacy_external_runfiles` flag to `true` will restore the
behavior whereby all expansions are identical and begin with `external/`.

## Conclusion

Arguably, users should always use `$(rootpath)` to expand targets in external
repositories (unless they're using `$(rlocationpath)` with a [runfiles
library][]). The [predefined source/output path variable
documentation][predefpath] even mentions:

> The `rootpath` of a file in an external repository `repo` will start with
> `../repo/`, followed by the repository-relative path.

At the same time, `bazel build` should probably expand `$(location)` to match
`$(rootpath)`, just as `bazel run` already does.

## Background

I'd first noticed the broken `$(location)` phenomenon when working on
[bazelbuild/rules_scala#1652][], and committed the `$(rootpath)` fix in
[bazelbuild/rules_scala#1678][]. The message for
[bazelbuild/rules_scala@08ab275][] contains notes on my investigation at the
time.

Then [@shs96c][] mentioned that he'd encountered the same problem in [a #general
thread in the Bazel Slack workspace on 2025-02-03][slack]. [@fmeum] mentioned
the connection to `--legacy_external_runfiles` in the same thread.

[predefpath]: https://bazel.build/reference/be/make-variables#predefined_label_variables
[Bazel 8.0.0]: https://github.com/bazelbuild/bazel/releases/tag/8.0.0
[Bazel 8.0.1]: https://github.com/bazelbuild/bazel/releases/tag/8.0.1
[bazelbuild/bazel#25198]: https://github.com/bazelbuild/bazel/issues/25198
[`--legacy_external_runfiles`]: https://bazel.build/reference/command-line-reference#flag--legacy_external_runfiles
[`run-reproduction.sh`]: ./run-reproduction.sh
[bazelisk]: https://github.com/bazelbuild/bazelisk
[bazelbuild/rules_scala#1678]: https://github.com/bazelbuild/rules_scala/pull/1678
[jvm_ext]: https://github.com/bazelbuild/rules_scala/blob/bfb9b9e87a4365b6b1417a05e01409384bd37bf9/scala/scala_maven_import_external.bzl#L66-L266
[runfiles library]: https://blog.engflow.com/2024/08/09/migrating-to-bazel-modules-aka-bzlmod---repo-names-and-runfiles/
[bazelbuild/rules_scala#1652]: https://github.com/bazelbuild/rules_scala/issues/1652
[bazelbuild/rules_scala@08ab275]: https://github.com/bazelbuild/rules_scala/commit/08ab275bd5f1e97f497ea74e55a084ebf3fda9a6
[@shs96c]: https://github.com/shs96c
[slack]: https://bazelbuild.slack.com/archives/CA31HN1T3/p1738598104277129
[@fmeum]: https://github.com/fmeum
