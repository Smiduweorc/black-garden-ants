#!/usr/bin/env sh
#
# The single definition of what this project's tasks mean.
#
# The task runner (make / just / npm), the git hooks and CI all shell out to
# this file, so there is exactly one place where "lint" is defined and the
# three entry points cannot drift apart.
#
# Usage: scripts/tasks.sh <task> [args...]
#        scripts/tasks.sh help

set -eu

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# git-cliff may come from PATH (mise) or node_modules (npm stack).
cliff() {
	if have git-cliff; then
		git-cliff "$@"
	elif [ -x node_modules/.bin/git-cliff ]; then
		node_modules/.bin/git-cliff "$@"
	else
		die "git-cliff not found. Run: scripts/tasks.sh setup"
	fi
}

# lefthook, likewise.
lefthook() {
	if have lefthook; then
		command lefthook "$@"
	elif [ -x node_modules/.bin/lefthook ]; then
		node_modules/.bin/lefthook "$@"
	else
		die "lefthook not found. Run: scripts/tasks.sh setup"
	fi
}
