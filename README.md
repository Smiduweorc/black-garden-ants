# black-garden-ants

Project templates for Go, TypeScript and repos with no compiler, driven by
make, just or npm. All seven share the same commit hook, changelog config and
release script; only the language and the runner differ.

Pull one down with [degit][dg]:

```sh
npx degit Smiduweorc/black-garden-ants/templates/go-just my-project
cd my-project && git init && just setup
```

[dg]: https://github.com/Rich-Harris/degit

## Templates

|  | `make` | `just` | `npm` |
| --- | --- | --- | --- |
| bare | [`bare-make`](templates/bare-make) | [`bare-just`](templates/bare-just) | n/a |
| go | [`go-make`](templates/go-make) | [`go-just`](templates/go-just) | n/a |
| ts | [`ts-make`](templates/ts-make) | [`ts-just`](templates/ts-just) | [`ts-npm`](templates/ts-npm) |

`bare` is for repos with no compiler (shell utilities, packaging,
documentation) that still want changelogs and tagged releases.

The column decides whether the dev tooling comes from npm. With `make` or
`just`, [mise][ms] installs the pinned toolchain plus [lefthook][lh] and
[git-cliff][gc] as single binaries, so `bare` and `go` have no Node, no
`package.json` and no npm entry in Dependabot. `ts-make` and `ts-just` use npm
for the project's own dependencies only. `make` needs nothing extra installed;
`just` has the nicer syntax. `npm` installs the same tools from
`devDependencies` and only exists for `ts`, where Node is already there.

CI smoke-tests `go-make`, `go-just`, `ts-make`, `ts-npm` and `bare-make`.
`ts-just` and `bare-just` are only checked for consistency.

[ms]: https://mise.jdx.dev
[lh]: https://lefthook.dev
[gc]: https://git-cliff.org

## Tasks and hooks

Every template has the same tasks (`setup`, `lint`, `test`, `release` and so
on; `help` lists them). Each is defined once, in `scripts/tasks.sh`, and the
Makefile, justfile or npm scripts, the git hooks and CI all call that script.
To change what `lint` does, edit it there.

`setup` installs the hooks: pre-commit runs `fmt` on the staged files and then
`lint`, pre-push runs `test`, and commit-msg runs `scripts/commit-msg.sh`.

`release.sh`, `cliff.toml`, `lefthook.yml`, `scripts/commit-msg.sh` and
`.editorconfig` are byte-identical in all seven templates, and CI fails if
they are not.

## Commits

Commit messages must follow [Conventional Commits][cc], because git-cliff
builds `CHANGELOG.md` from them. `scripts/commit-msg.sh` checks the message
with a regex, unless one of these is set up:

- [commitlint][cl]: a `commitlint.config.*`, `.commitlintrc.json` or
  `.commitlintrc.js` plus `node_modules/.bin/commitlint`. `ts-npm` ships it.
  Add it to `ts-make` or `ts-just` and the script picks it up without edits.
- [commitlint-rs][clrs]: a `.commitlintrc.json`, `.commitlintrc.yaml` or
  `.commitlintrc.yml` plus commitlint-rs on `PATH`. No template here ships it;
  [rustCrateTemplate][rct] does. The script adds the
  `@commitlint/config-conventional` checks commitlint-rs lacks: 100-character
  lines, no whitespace around the subject, and a warning when the body does
  not follow a blank line. commitlint-rs 0.2 cannot parse a bare
  `.commitlintrc`, so use one of the other names.

[cc]: https://www.conventionalcommits.org
[cl]: https://commitlint.js.org
[clrs]: https://github.com/KeisukeYamashita/commitlint-rs
[rct]: https://github.com/Smiduweorc/rustCrateTemplate

## Releasing

```sh
just release v1.2.3      # or patch | minor | major
```

The runners spell it `make release V=v1.2.3` and `npm run release -- v1.2.3`.

`release.sh` refuses a dirty tree, an existing tag, or any branch other than
`master` (set `RELEASE_BRANCH` to change it). It runs `preflight` (lint and
test), bumps `package.json` for TypeScript, regenerates `CHANGELOG.md`,
commits `chore(release): prepare for <tag>` and creates an annotated tag whose
message is that release's changelog. Go has nothing to bump: the tag is
injected at build time with `-ldflags`. Nothing is pushed unless you set
`PUSH=1`.

## Working on the templates

`templates/` is generated and committed so degit works. Edit `src/` and run
`./build.sh` (needs bash and python3). `src/core/` goes into every template,
`src/flavor/<f>/` holds one language and `src/stack/<s>/` one runner;
`scripts/tasks.sh` is concatenated from the core head, the flavor body and the
core tail. To add a combination, add it to `COMBOS` in `build.sh`. CI runs
`./check.sh`, which rebuilds and fails if the output differs from what is
committed.
