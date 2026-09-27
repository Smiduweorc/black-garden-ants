# bare-just

A project template: **bare** sources, driven by **just**.

Replace this README with your own once you have the project running.

## Getting started

```sh
just setup
```

That installs the toolchain, the dependencies and the git hooks.

## Tasks

| Task | What it does |
| --- | --- |
| `just setup` | Install the toolchain, dependencies and git hooks |
| `just fmt` | Format sources in place |
| `just lint` | Static checks; fails on a problem, changes nothing |
| `just test` | Run the test suite |
| `just build` | Produce the build artifacts |
| `just changelog` | Regenerate `CHANGELOG.md` from the commit history |
| `just release v1.2.3` | Cut a release |
| `just preflight` | `lint` + `test`, as run before a release |
| `just hooks` | (Re)install the git hooks |
| `just clean` | Remove build artifacts |
| `just help` | List the tasks |

Every one of these is a thin wrapper around `scripts/tasks.sh <task>`. That
file is the single definition of what each task means; the runner, the git
hooks and CI all call into it, so they cannot drift apart. If you need to
change what `lint` does, change it there and all three follow.

## Releasing

```sh
just release v1.2.3          # or: patch | minor | major
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
PUSH=1 just release v1.2.3
```

## Commits

Commit messages must follow [Conventional Commits][cc]. `scripts/commit-msg.sh`
enforces this through a git hook, and git-cliff builds `CHANGELOG.md` from it.

```
feat: add the widget
fix(parser): handle an empty input
refactor!: drop the legacy entry point
```

If [commitlint][cl] is set up (a `commitlint.config.*` is present and its
binary is installed), `scripts/commit-msg.sh` delegates to it instead of its
own regex, so you get commitlint's real parser and config resolution. The same
goes for [commitlint-rs][clrs]: a `.commitlintrc`, `.commitlintrc.json`,
`.commitlintrc.yaml` or `.commitlintrc.yml` plus a commitlint-rs binary on
`PATH`, with the script checking the `@commitlint/config-conventional` rules
commitlint-rs lacks (line lengths, whitespace around the header). This happens
automatically; nothing needs editing to turn it on or off.

[cc]: https://www.conventionalcommits.org
[cl]: https://commitlint.js.org
[clrs]: https://github.com/KeisukeYamashita/commitlint-rs

## Layout

| Path | Purpose |
| --- | --- |
| `scripts/tasks.sh` | What every task means. Edit this to change behaviour. |
| `scripts/commit-msg.sh` | Conventional Commits check, run by the git hook (delegates to commitlint if it's set up) |
| `release.sh` | The release flow. Identical in every template. |
| `cliff.toml` | Changelog generation rules |
| `lefthook.yml` | Which hooks run which tasks |
