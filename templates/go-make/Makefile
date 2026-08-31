# Thin dispatcher over scripts/tasks.sh, which is where the tasks are actually
# defined. Keeping the logic there means `make test` and the git hooks and CI
# all run the identical command.

.DEFAULT_GOAL := help

TASKS := setup fmt lint test build changelog preflight hooks clean help

.PHONY: $(TASKS) release

$(TASKS):
	@scripts/tasks.sh $@

# make release V=v1.2.3   (or V=patch | minor | major)
release:
	@test -n "$(V)" || { echo "usage: make release V=<vX.Y.Z|major|minor|patch>" >&2; exit 1; }
	@scripts/tasks.sh release $(V)
