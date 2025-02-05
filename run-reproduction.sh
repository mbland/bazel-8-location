#!/usr/bin/env bash

banner() {
    local heading="$1"
    local dashes="$(echo "$heading" | sed 's/./-/g')"

    printf '\n%s\n%s\n%s\n\n' "$dashes" "$heading" "$dashes"
}

bazelversion='7.5.0'
banner "Bazel ${bazelversion}"
USE_BAZEL_VERSION="$bazelversion" bazel run //:run-expansions

bazelversion="$(< .bazelversion)"
banner "Bazel ${bazelversion}"
bazel run //:run-expansions

banner "Bazel ${bazelversion} with --legacy_external_runfiles"
bazel run --legacy_external_runfiles //:run-expansions
