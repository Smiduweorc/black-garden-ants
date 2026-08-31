
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
  <RUNNER> test
  <RELEASE_EXAMPLE>
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
