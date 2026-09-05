#!/bin/sh
# The installer lives with the skill, so that a skill directory copied into
# ~/.claude/skills on its own is complete. This is here for anyone who cloned
# the repository and expects an install script at the root.
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec sh "$here/plugins/no-attribution/skills/no-attribution/install.sh" "$@"
