#!/usr/bin/env bash
#
# Asserts the properties this repo exists to provide. Run it after ./build.sh;
# CI runs it on every push.
#
#   1. templates/ is in sync with src/
#   2. the files that must be identical everywhere really are
#   3. every flavor defines the functions the shared dispatcher calls
#   4. every template exposes the same task list
#   5. every generated shell script parses
#
# No `set -e`: every check runs, and the exit status is the verdict.

set -uo pipefail

cd "$(dirname "$0")" || exit 1

fail=0
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; fail=1; }

# Content plus the executable bit, which build.sh sets and the runners rely on.
snapshot() {
	find templates -type f -exec md5sum {} + | sort
	find templates -type f -perm -u+x -print | sort
}

echo "1. templates/ is in sync with src/"
before="$(snapshot)"
./build.sh >/dev/null
after="$(snapshot)"
if [ "$before" = "$after" ]; then
	ok "committed output matches a fresh build"
else
	bad "templates/ is stale: run ./build.sh and commit the result"
fi

# Globbed after the rebuild, so this is never a stale or literal pattern.
templates=(templates/*/)

echo
echo "2. shared files are byte-identical across all templates"
for f in release.sh cliff.toml lefthook.yml scripts/commit-msg.sh .editorconfig; do
	# A file missing from one template hashes to nothing, which would otherwise
	# leave the remaining templates agreeing with each other and passing.
	hashes="$(for d in "${templates[@]}"; do
		if [ -f "$d$f" ]; then md5sum "$d$f" | cut -d' ' -f1; else echo missing; fi
	done | sort -u)"
	if [ "$hashes" = missing ]; then
		bad "$f is missing from every template"
	elif [ "$(printf '%s\n' "$hashes" | wc -l)" = 1 ]; then
		ok "$f"
	else
		bad "$f differs or is missing in some templates"
	fi
done

echo
echo "3. every flavor implements every task the dispatcher calls"
# The dispatcher lives in the shared tail, so comparing help text would compare
# a file against itself. What can actually go wrong is a flavor body that fails
# to define one of the functions the dispatcher dispatches to.
required=(flavor_setup task_fmt task_lint task_test task_build task_clean task_bump_version)
for d in "${templates[@]}"; do
	missing=""
	for fn in "${required[@]}"; do
		grep -qE "^$fn\(\)" "$d/scripts/tasks.sh" || missing="$missing $fn"
	done
	if [ -z "$missing" ]; then ok "$(basename "$d")"; else bad "$(basename "$d") is missing:$missing"; fi
done

echo
echo "4. every template offers the same task list"
expected=""
for d in "${templates[@]}"; do
	got="$(sh "$d/scripts/tasks.sh" help 2>/dev/null | sed -n '/^Tasks:/,/^$/p' | grep -oE '^  [a-z-]+' | tr -d ' ' | sort | tr '\n' ' ')"
	[ -n "$expected" ] || expected="$got"
	if [ "$got" = "$expected" ]; then ok "$(basename "$d")"; else bad "$(basename "$d") task list differs: $got"; fi
done

echo
echo "5. generated scripts parse"
for d in "${templates[@]}"; do
	broken=""
	sh -n "$d/scripts/tasks.sh"      || broken="$broken scripts/tasks.sh"
	sh -n "$d/scripts/commit-msg.sh" || broken="$broken scripts/commit-msg.sh"
	bash -n "$d/release.sh"          || broken="$broken release.sh"
	if [ -z "$broken" ]; then ok "$(basename "$d")"; else bad "$(basename "$d"):$broken"; fi
done

echo
if [ "$fail" = 0 ]; then
	echo "All checks passed."
else
	echo "Checks failed." >&2
fi
exit "$fail"
