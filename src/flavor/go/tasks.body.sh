
# Flavor: go

BINARY="${BINARY:-app}"
PKG="${PKG:-./cmd/$BINARY}"

flavor_setup() {
	say "Downloading Go modules"
	go mod download
}

task_fmt() {
	say "Formatting Go sources"
	if [ "$#" -eq 0 ]; then
		gofmt -w .
		return 0
	fi
	# The hook hands us every staged file; keep only the ones gofmt understands.
	# Append the matches to the positional parameters and drop the originals, so
	# paths containing spaces survive.
	staged_count=$#
	for f in "$@"; do
		case "$f" in *.go) set -- "$@" "$f" ;; esac
	done
	shift "$staged_count"
	[ "$#" -gt 0 ] || return 0
	gofmt -w -- "$@"
}

task_lint() {
	say "Vetting"
	go vet ./...
	unformatted="$(gofmt -l .)"
	[ -z "$unformatted" ] || die "unformatted files:
$unformatted"
	if have golangci-lint; then
		say "golangci-lint"
		golangci-lint run
	fi
	say "Checking go.mod is tidy"
	# -diff reports what tidying would change and exits non-zero, rather than
	# rewriting go.mod during a task that is supposed to change nothing.
	go mod tidy -diff || die "go.mod/go.sum are not tidy; run 'go mod tidy'"
}

task_test() {
	say "Running tests"
	go test -race ./...
}

task_build() {
	version="$(git describe --tags --always --dirty 2>/dev/null || echo dev)"
	say "Building $BINARY ($version)"
	CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=$version" -o "$BINARY" "$PKG"
}

task_clean() {
	say "Removing build artifacts"
	rm -rf "$BINARY" dist coverage.out
}

# Go has no version-bearing manifest: the git tag is the version, injected at
# build time via -ldflags. Nothing to bump, so nothing to stage.
task_bump_version() { :; }
