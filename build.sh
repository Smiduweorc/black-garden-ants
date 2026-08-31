#!/usr/bin/env bash
#
# Generates templates/ from src/.
#
# Every template is assembled from the same pieces:
#
#   src/core/           files identical in all templates (release.sh, cliff.toml,
#                       lefthook.yml, the commit-msg checker, issue templates)
#   src/flavor/<f>/     the language: its scripts/tasks.body.sh, starter sources,
#                       .gitignore, dependabot config, toolchain pins
#   src/stack/<s>/      the task runner, plus the CI bootstrap it implies
#
# scripts/tasks.sh is concatenated from core head + flavor body + core tail, so
# the task dispatcher and help text cannot drift between languages.
#
# Run ./build.sh after editing anything under src/. templates/ is committed so
# that degit works; CI checks it is in sync.

set -euo pipefail

cd "$(dirname "$0")"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# flavor:stack pairs to generate.
COMBOS=(
	bare:make
	bare:just
	go:make
	go:just
	ts:make
	ts:just
	ts:npm
)

# Adding a stack means adding a case to both of these. They fail rather than
# yield an empty string, which would otherwise be substituted straight into the
# help text and README.
runner_name() {
	case "$1" in
		make) echo "make" ;;
		just) echo "just" ;;
		npm) echo "npm run" ;;
		*) die "no runner name for stack '$1'" ;;
	esac
}

release_example() {
	case "$1" in
		make) echo "make release V=v1.2.3" ;;
		just) echo "just release v1.2.3" ;;
		npm) echo "npm run release -- v1.2.3" ;;
		*) die "no release example for stack '$1'" ;;
	esac
}

rm -rf templates
mkdir -p templates

for combo in "${COMBOS[@]}"; do
	flavor="${combo%%:*}"
	stack="${combo##*:}"
	out="templates/${flavor}-${stack}"

	mkdir -p "$out"

	cp -a src/core/. "$out/"
	rm -f "$out/scripts/tasks.head.sh" "$out/scripts/tasks.tail.sh"

	cp -a "src/flavor/$flavor/." "$out/"
	rm -f "$out/tasks.body.sh"

	# The npm stack installs its tools from devDependencies, so it has no
	# mise.toml and brings its own CI workflow.
	if [ "$stack" = npm ]; then
		rm -f "$out/mise.toml"
	else
		cp -a src/stack/_mise/. "$out/"
	fi

	cp -a "src/stack/$stack/." "$out/"

	# The dispatcher and help text live in the shared head and tail, so they
	# cannot drift between languages.
	cat \
		src/core/scripts/tasks.head.sh \
		"src/flavor/$flavor/tasks.body.sh" \
		src/core/scripts/tasks.tail.sh \
		> "$out/scripts/tasks.sh"

	runner="$(runner_name "$stack")"
	example="$(release_example "$stack")"

	# lefthook and git-cliff come from devDependencies here, and npm's own
	# prepare lifecycle installs the hooks.
	if [ "$stack" = npm ]; then
		python3 - "$out/package.json" <<-'PY'
			import json, sys, collections
			p = sys.argv[1]
			with open(p) as f:
			    pkg = json.load(f, object_pairs_hook=collections.OrderedDict)
			pkg["devDependencies"]["git-cliff"] = "^2.13.1"
			pkg["devDependencies"]["lefthook"] = "^2.1.10"
			pkg["devDependencies"] = collections.OrderedDict(
			    sorted(pkg["devDependencies"].items())
			)
			scripts = collections.OrderedDict()
			scripts["prepare"] = "scripts/tasks.sh hooks"
			scripts.update(pkg["scripts"])
			pkg["scripts"] = scripts
			with open(p, "w") as f:
			    json.dump(pkg, f, indent="\t")
			    f.write("\n")
		PY
		# No mise.toml here, so .nvmrc carries the same Node version the
		# other stacks pin in mise.toml.
		node_version="$(sed -n 's/^node = "\([^"]*\)"$/\1/p' "src/flavor/$flavor/mise.toml")"
		[ -n "$node_version" ] || die "no node pin in src/flavor/$flavor/mise.toml"
		echo "$node_version" > "$out/.nvmrc"
	fi

	sed -e "s|@@FLAVOR@@|$flavor|g" \
		-e "s|@@STACK@@|$stack|g" \
		-e "s|@@RUNNER@@|$runner|g" \
		-e "s|@@RELEASE@@|$example|g" \
		src/README.template.md > "$out/README.md"

	sed -i -e "s|<RUNNER>|$runner|g" -e "s|<RELEASE_EXAMPLE>|$example|g" \
		"$out/scripts/tasks.sh"

	chmod +x "$out/release.sh" "$out/scripts/tasks.sh" "$out/scripts/commit-msg.sh"
	find "$out" -name '*.sh' -path '*/tests/*' -exec chmod +x {} +

	printf '  %-12s %s\n' "$flavor-$stack" "$(find "$out" -type f | wc -l) files"
done

echo "Generated ${#COMBOS[@]} templates."
