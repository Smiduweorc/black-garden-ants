# go-make

A project template: **go** sources, driven by **make**.

Replace this README with your own once you have the project running.

## Getting started

```sh
make setup
```

That installs the toolchain, the dependencies and the git hooks.

## Tasks

| Task | What it does |
| --- | --- |
| `make setup` | Install the toolchain, dependencies and git hooks |
| `make fmt` | Format sources in place |
| `make lint` | Static checks; fails on a problem, changes nothing |
| `make test` | Run the test suite |
| `make build` | Produce the build artifacts |
| `make changelog` | Regenerate `CHANGELOG.md` from the commit history |
| `make release V=v1.2.3` | Cut a release |
| `make preflight` | `lint` + `test`, as run before a release |
| `make hooks` | (Re)install the git hooks |
| `make clean` | Remove build artifacts |
| `make help` | List the tasks |

Every one of these is a thin wrapper around `scripts/tasks.sh <task>`. That
file is the single definition of what each task means; the runner, the git
hooks and CI all call into it, so they cannot drift apart. If you need to
change what `lint` does, change it there and all three follow.

## Releasing

```sh
make release V=v1.2.3          # or: patch | minor | major
```

`release.sh` will:

1. refuse to run on the wrong branch or a dirty tree,
2. run `preflight` (lint + test),
3. bump any version-bearing manifest,
4. regenerate `CHANGELOG.md` with git-cliff,
5. commit as `chore(release): prepare for <tag>`,
6. create an annotated tag whose message is that release's changelog.

Nothing is pushed unless you ask:

```sh
PUSH=1 make release V=v1.2.3
```

## Commits

Commit messages must follow [Conventional Commits][cc]. `scripts/commit-msg.sh`
enforces this through a git hook, and git-cliff builds `CHANGELOG.md` from it.

```
feat: add the widget
fix(parser): handle an empty input
refactor!: drop the legacy entry point
```

[cc]: https://www.conventionalcommits.org

## Layout

| Path | Purpose |
| --- | --- |
| `scripts/tasks.sh` | What every task means. Edit this to change behaviour. |
| `scripts/commit-msg.sh` | Conventional Commits check, run by the git hook |
| `release.sh` | The release flow. Identical in every template. |
| `cliff.toml` | Changelog generation rules |
| `lefthook.yml` | Which hooks run which tasks |
