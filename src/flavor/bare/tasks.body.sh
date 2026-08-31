
# Flavor: bare. No language toolchain, just the release machinery. Useful for
# shell utilities, packaging repos and documentation.

flavor_setup() { :; }

task_fmt() {
	have shfmt || { say "shfmt not installed; skipping fmt"; return 0; }
	say "Formatting shell sources"
	if [ "$#" -eq 0 ]; then
		shfmt -w .
		return 0
	fi
	# The hook hands us every staged file; keep only the shell scripts. Append
	# the matches to the positional parameters and drop the originals, so paths
	# containing spaces survive.
	staged_count=$#
	for f in "$@"; do
		case "$f" in *.sh) set -- "$@" "$f" ;; esac
	done
	shift "$staged_count"
	[ "$#" -gt 0 ] || return 0
	shfmt -w -- "$@"
}

task_lint() {
	have shellcheck || { say "shellcheck not installed; skipping lint"; return 0; }
	say "Linting shell sources"
	# -exec ... + runs nothing at all when nothing matches, and reports a
	# non-zero shellcheck as find's own exit status.
	find . -name '*.sh' -not -path './.git/*' -exec shellcheck -- {} +
}

task_test() {
	if [ ! -d tests ]; then
		say "No tests/ directory; nothing to run"
		return 0
	fi
	say "Running tests"
	found=0
	for t in tests/*.sh; do
		[ -f "$t" ] || continue
		found=1
		printf '  %s\n' "$t"
		sh "$t"
	done
	[ "$found" = 1 ] || say "No tests/*.sh found"
}

task_build() { say "Nothing to build"; }

task_clean() { :; }

# The tag is the only version this flavor has.
task_bump_version() { :; }
