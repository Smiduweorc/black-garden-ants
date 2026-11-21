#!/usr/bin/env sh
#
# Checks the package as a consumer gets it: packs the tarball, installs it into
# a throwaway project outside the repo, and imports it under Bun and Node.
# Catches broken "exports", "types" or "files" that in-repo tests cannot see.
#
# Expects dist/ to be built already. Usage: scripts/pack-check.sh

set -eu

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v bun >/dev/null 2>&1 || die "bun not found"
[ -d dist ] || die "dist/ is missing; build first"

name="$(bun -e 'console.log(require("./package.json").name)')"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

say "Packing $name"
tarball="$(bun pm pack --destination "$work" --quiet --ignore-scripts)"
# Older Bun prints a bare filename, newer an absolute path.
case "$tarball" in /*) ;; *) tarball="$work/$(basename "$tarball")" ;; esac

mkdir "$work/consumer"
cd "$work/consumer"
printf '{ "name": "consumer", "private": true, "type": "module" }\n' > package.json
bun add "$tarball" >/dev/null

# Importing the bare name exercises the "exports" map, not a file path.
script="const m = await import(\"$name\"); if (Object.keys(m).length === 0) throw new Error(\"no exports\");"

say "Importing under Bun"
bun -e "$script"

if command -v node >/dev/null 2>&1; then
	say "Importing under Node"
	node --input-type=module -e "$script"
elif [ -n "${CI:-}" ]; then
	die "node not found; CI must check both runtimes"
else
	say "node not found; skipping the Node import"
fi

say "Package imports cleanly"
