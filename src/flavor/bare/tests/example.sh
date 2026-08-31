#!/usr/bin/env sh
# Tests are plain shell scripts, run from the project root: a non-zero exit is
# a failure. Replace this placeholder with the first real test.
set -eu

scripts/tasks.sh help >/dev/null
