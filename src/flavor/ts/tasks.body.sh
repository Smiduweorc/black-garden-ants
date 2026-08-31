
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
