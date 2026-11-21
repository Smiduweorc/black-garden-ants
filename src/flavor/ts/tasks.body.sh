
# Flavor: ts
#
# Bun first: it installs the dependencies and is the main runtime. Node is a
# supported runtime too, so the tests run under both.

flavor_setup() { :; }

task_fmt() {
	say "Formatting"
	if [ "$#" -eq 0 ]; then
		bunx eslint --fix .
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
	bunx eslint --fix --no-warn-ignored -- "$@"
}

task_lint() {
	say "Linting"
	bunx eslint .
	say "Typechecking"
	bunx tsc --noEmit
	# The tests are outside the build tsconfig's rootDir, so they get their own.
	if [ -f tests/tsconfig.json ]; then
		bunx tsc --noEmit -p tests/tsconfig.json
	fi
}

# The tests use node:test and node:assert, which both runtimes run unchanged.
# Without Node on PATH the Node run is skipped locally, but fails in CI.
task_test() {
	say "Running tests under Bun"
	bun test
	if have node; then
		say "Running tests under Node"
		node --import tsx --test "tests/**/*.test.ts"
	elif [ -n "${CI:-}" ]; then
		die "node not found; CI must test both runtimes"
	else
		say "node not found; skipping the Node test run"
	fi
}

task_build() {
	say "Building"
	bunx tsc
}

task_clean() {
	say "Removing build artifacts"
	rm -rf dist .eslintcache
}

# bun owns the version in package.json; print what it touched so release.sh
# can stage it.
task_bump_version() {
	[ "$#" -ge 1 ] || die "usage: scripts/tasks.sh bump-version <X.Y.Z>"
	bun pm version "$1" --no-git-tag-version --allow-same-version >/dev/null
	echo "package.json"
	if [ -f bun.lock ]; then
		echo "bun.lock"
	fi
}
