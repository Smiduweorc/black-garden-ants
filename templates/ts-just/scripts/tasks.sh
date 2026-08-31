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

# Flavor: ts

flavor_setup() { :; }

task_fmt() {
	say "Formatting"
	if [ "$#" -eq 0 ]; then
		npx eslint --fix .
		return 0
	fi
	# The hook hands us every staged file; keep only the ones eslint handles.
	# Append the matches to the positional parameters and drop the originals, so
	# paths containing spaces survive.
	staged_count=$#
	for f in "$@"; do
		case "$f" in *.ts | *.tsx | *.js | *.mjs | *.cjs) set -- "$@" "$f" ;; esac
	done
	shift "$staged_count"
	[ "$#" -gt 0 ] || return 0
	npx eslint --fix --no-warn-ignored -- "$@"
}

task_lint() {
	say "Linting"
	npx eslint .
	say "Typechecking"
	npx tsc --noEmit
	# The tests are outside the build tsconfig's rootDir, so they get their own.
	if [ -f tests/tsconfig.json ]; then
		npx tsc --noEmit -p tests/tsconfig.json
	fi
}

task_test() {
	say "Running tests"
	node --import tsx --test "tests/**/*.test.ts"
}

task_build() {
	say "Building"
	npx tsc
}

task_clean() {
	say "Removing build artifacts"
	rm -rf dist .eslintcache
}

# npm owns the version in package.json; print what it touched so release.sh
# can stage it.
task_bump_version() {
	[ "$#" -ge 1 ] || die "usage: scripts/tasks.sh bump-version <X.Y.Z>"
	npm version "$1" --no-git-tag-version --allow-same-version >/dev/null
	echo "package.json"
	if [ -f package-lock.json ]; then
		echo "package-lock.json"
	fi
}

# Everything below is shared by every flavor.

# Bootstrap reacts to which files the template has, so the mise-based and
# npm-based stacks share one code path.
task_setup() {
	if [ -f mise.toml ]; then
		have mise || die "mise not found. Install it: https://mise.jdx.dev"
		say "Installing pinned tools"
		mise install
	fi
	if [ -f package.json ]; then
		say "Installing npm dependencies"
		if [ -f package-lock.json ]; then npm ci; else npm install; fi
	fi
	flavor_setup
	task_hooks
	say "Ready."
}

# Everything release.sh runs before it will cut a tag.
task_preflight() {
	task_lint
	task_test
}

task_changelog() {
	say "Regenerating CHANGELOG.md"
	cliff --config cliff.toml --output CHANGELOG.md
}

task_release() {
	[ "$#" -ge 1 ] || die "usage: scripts/tasks.sh release <vX.Y.Z|major|minor|patch>"
	./release.sh "$@"
}

task_hooks() {
	# setup runs before `git init` often enough to be worth handling: lefthook
	# exits non-zero with no git directory, which would fail the whole install.
	# .git is a file rather than a directory in worktrees and submodules.
	if [ ! -e .git ]; then
		say "Not a git repository yet; skipping hooks. After 'git init', run: scripts/tasks.sh hooks"
		return 0
	fi
	say "Installing git hooks"
	lefthook install
}

task_help() {
	cat <<'USAGE'
Tasks:
  setup        install the toolchain, dependencies and git hooks
  fmt          format sources in place
  lint         static checks; fails on a problem, changes nothing
  test         run the test suite
  build        produce the build artifacts
  changelog    regenerate CHANGELOG.md from the commit history
  release      cut a release (vX.Y.Z | major | minor | patch)
  preflight    lint + test, as run before a release
  hooks        (re)install the git hooks
  clean        remove build artifacts
  help         this list

Through this project's task runner:
  just test
  just release v1.2.3
USAGE
}

task="${1:-help}"
[ "$#" -gt 0 ] && shift

case "$task" in
	setup) task_setup "$@" ;;
	fmt) task_fmt "$@" ;;
	lint) task_lint "$@" ;;
	test) task_test "$@" ;;
	build) task_build "$@" ;;
	changelog) task_changelog "$@" ;;
	release) task_release "$@" ;;
	preflight) task_preflight "$@" ;;
	bump-version) task_bump_version "$@" ;;
	hooks) task_hooks "$@" ;;
	clean) task_clean "$@" ;;
	help | -h | --help) task_help ;;
	*) die "unknown task '$task'. Try: scripts/tasks.sh help" ;;
esac
