# black-garden-ants

Project templates that all behave the same way, so the choice of language and
task runner stops being a decision you have to relitigate every time.

Each template ships the same release machinery ([lefthook][lh] hooks,
[git-cliff][gc] changelogs, Conventional Commits enforcement and a `release.sh`
that cuts an annotated tag) and differs only in the language it builds and the
command you type to drive it.

Pick one and pull it down with [degit][dg]:

```sh
npx degit Smiduweorc/black-garden-ants/templates/go-just my-project
cd my-project && git init && just setup
```

[lh]: https://lefthook.dev
[gc]: https://git-cliff.org
[dg]: https://github.com/Rich-Harris/degit

## The matrix

|  | `make` | `just` | `npm` |
| --- | --- | --- | --- |
| **bare**, no language toolchain | [`bare-make`](templates/bare-make) | [`bare-just`](templates/bare-just) | n/a |
| **go** | [`go-make`](templates/go-make) | [`go-just`](templates/go-just) | n/a |
| **ts** | [`ts-make`](templates/ts-make) | [`ts-just`](templates/ts-just) | [`ts-npm`](templates/ts-npm) |

**Choosing a row.** `bare` is for repos with no compiler (shell utilities,
packaging repos, documentation) that still want changelogs and tagged releases.

**Choosing a column.** This is really the question of whether Node is allowed
on the machine:

- **`make` / `just`** keep the dev tooling off npm. [mise][ms] installs the
  pinned toolchain plus lefthook and git-cliff as single binaries. For `bare`
  and `go` that means no Node anywhere: no `package.json`, no `node_modules`,
  and no npm entry in Dependabot. `ts-make` and `ts-just` still use npm for the
  project's own dependencies, since Node is the runtime, but not for the
  release tooling. Pick `just` for nicer syntax, `make` to install nothing extra.
- **`npm`** installs the same tooling from `devDependencies` and uses npm
  scripts as the runner. It exists only for `ts`, where Node is already the
  runtime. For a Go project Node would buy you nothing, which is why those
  cells are empty.

[ms]: https://mise.jdx.dev

## What is guaranteed to be the same

These files are **byte-identical in all seven templates**:

| File | What it does |
| --- | --- |
| `release.sh` | The whole release flow |
| `cliff.toml` | Changelog generation rules |
| `lefthook.yml` | Which hooks run which tasks |
| `scripts/commit-msg.sh` | Conventional Commits enforcement |
| `.editorconfig` | Indentation and whitespace |

`scripts/commit-msg.sh` itself decides how to enforce that: a bash regex by
default, or a delegation to [commitlint][cl] if a `commitlint.config.*` and its
binary are present. Only `ts-npm` ships that by default: it already pulls
lefthook and git-cliff through `devDependencies`, so commitlint fits the same
path. `ts-make` and `ts-just` deliberately don't, per the Node-off-npm
principle above, but adding commitlint to either turns the same script's
behavior on without editing it.

[cl]: https://commitlint.js.org

Every template exposes the same tasks, and they mean the same thing:

| Task | |
| --- | --- |
| `setup` | Install the toolchain, dependencies and git hooks |
| `fmt` | Format sources in place |
| `lint` | Static checks; fails on a problem, changes nothing |
| `test` | Run the test suite |
| `build` | Produce the build artifacts |
| `changelog` | Regenerate `CHANGELOG.md` |
| `release` | Cut a release |
| `preflight` | `lint` + `test`, as run before a release |
| `hooks` | (Re)install the git hooks |
| `clean` | Remove build artifacts |

Only the invocation differs (`make test`, `just test`, `npm run test`), along
with the release argument, which each runner spells its own way:

```sh
make release V=v1.2.3
just release v1.2.3
npm run release -- v1.2.3
```

### How that guarantee is enforced

Every task is defined once, in `scripts/tasks.sh`. The runner, the git hooks
and CI are all thin wrappers that shell out to it:

```text
make test  --+
just test  --+
npm test   --+--> scripts/tasks.sh test --> go test -race ./...
lefthook   --+
CI         --+
```

So `make lint` and the pre-commit hook cannot disagree about what linting is:
they execute the same function. Changing what a task means is a one-line edit
in one file, and everything follows.

## Releasing

```sh
just release v1.2.3      # or: patch | minor | major
```

`release.sh` refuses to run on the wrong branch or a dirty tree, runs
`preflight`, bumps any version-bearing manifest, regenerates `CHANGELOG.md`,
commits as `chore(release): prepare for <tag>`, and creates an annotated tag
whose message is that release's changelog. Nothing is pushed unless you pass
`PUSH=1`.

Go has no version to bump: the tag is the version, injected at build time via
`-ldflags`. TypeScript bumps `package.json`. `release.sh` is identical either
way; the difference lives in each flavor's `bump-version` task.

## Working on the templates

`templates/` is **generated**. Edit `src/`, then run `./build.sh`. It needs
bash and python3; python3 merges the extra devDependencies into the `ts-npm`
`package.json` rather than keeping a second copy of that file in `src/`.

```text
src/core/          identical in every template
                     release.sh, cliff.toml, lefthook.yml, commit-msg.sh,
                     issue templates, and tasks.head.sh / tasks.tail.sh
src/flavor/<f>/    one language: tasks.body.sh, starter sources, .gitignore,
                     dependabot config, mise.toml pins
src/stack/<s>/     one runner: Makefile / justfile, and the CI bootstrap
```

`scripts/tasks.sh` is concatenated from `tasks.head.sh` + the flavor's
`tasks.body.sh` + `tasks.tail.sh`, so the dispatcher and the help text cannot
drift between languages. Adding a task means editing the tail once, not seven
times.

To add a combination, add it to `COMBOS` in `build.sh`.

CI regenerates the templates and fails if the committed output differs, so
`templates/` can never fall behind `src/`.
