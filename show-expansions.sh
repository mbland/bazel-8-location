#!/usr/bin/env bash

BUILD_EXPANSIONS_OUTPUT_FILE="$1"
shift

printf 'From `bazel build //:build-expansions`:\n'

while IFS='' read -r line; do
    printf '  %s\n' "$line"
done <"$BUILD_EXPANSIONS_OUTPUT_FILE"

printf '\nFrom `bazel run //:run-expansions`:\n'
printf '  %s\n' "$@"
