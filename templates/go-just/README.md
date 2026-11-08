# go-just

A project from the [black-garden-ants][bga] `go-just` template.
Replace this README with your own once the project runs.

## Getting started

```sh
just setup
```

That installs the toolchain, the dependencies and the git hooks.
`just help` lists the other tasks. They are all defined in
`scripts/tasks.sh`; edit that file to change what a task does.

Commit messages must follow [Conventional Commits][cc]; the commit-msg hook
rejects anything else. To cut a release from `master`:

```sh
just release v1.2.3      # or patch | minor | major
```

Nothing is pushed unless you set `PUSH=1`. The [black-garden-ants
README][bga] explains the hooks, commitlint and the release flow.

[bga]: https://github.com/Smiduweorc/black-garden-ants#readme
[cc]: https://www.conventionalcommits.org
