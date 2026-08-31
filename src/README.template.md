# @@FLAVOR@@-@@STACK@@

A project template: **@@FLAVOR@@** sources, driven by **@@STACK@@**.

Replace this README with your own once you have the project running.

## Getting started

```sh
@@RUNNER@@ setup
```

That installs the toolchain, the dependencies and the git hooks.

## Tasks

| Task | What it does |
| --- | --- |
| `@@RUNNER@@ setup` | Install the toolchain, dependencies and git hooks |
| `@@RUNNER@@ fmt` | Format sources in place |
| `@@RUNNER@@ lint` | Static checks; fails on a problem, changes nothing |
| `@@RUNNER@@ test` | Run the test suite |
| `@@RUNNER@@ build` | Produce the build artifacts |
| `@@RUNNER@@ changelog` | Regenerate `CHANGELOG.md` from the commit history |
| `@@RELEASE@@` | Cut a release |
| `@@RUNNER@@ preflight` | `lint` + `test`, as run before a release |
| `@@RUNNER@@ hooks` | (Re)install the git hooks |
| `@@RUNNER@@ clean` | Remove build artifacts |
| `@@RUNNER@@ help` | List the tasks |

Every one of these is a thin wrapper around `scripts/tasks.sh <task>`. That
file is the single definition of what each task means; the runner, the git
hooks and CI all call into it, so they cannot drift apart. If you need to
change what `lint` does, change it there and all three follow.

## Releasing

```sh
@@RELEASE@@          # or: patch | minor | major
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
PUSH=1 @@RELEASE@@
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
