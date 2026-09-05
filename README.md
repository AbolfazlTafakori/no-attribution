# no-attribution

Keeps AI assistant attribution out of your git history.

Claude Code adds a trailer to every commit it helps with:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

and a line to every pull request body it writes. Whether that belongs in your
repository is your decision. Plenty of people have a reason for saying no — a
company policy about what appears in a public repo, a contributor list that is
meant to be people, a client paying for work rather than for a tool credit, or
simply not wanting it there. This turns it off and keeps it off.

It is not about hiding that an assistant was used. Say so in a pull request, a
README, or a conversation whenever it is useful. What this removes is
machine-generated credit in metadata, which is a different thing.

## Install

**As a skill.** Copy the skill directory into your Claude Code skills folder:

```bash
git clone https://github.com/AbolfazlTafakori/no-attribution
cp -r no-attribution/plugins/no-attribution/skills/no-attribution ~/.claude/skills/
```

**As a plugin,** if you use a marketplace: add this repository as a source and
install `no-attribution` from it.

Either way, the skill only carries the rule. The hook is what enforces it:

```bash
cd no-attribution
sh install.sh              # this repository only
sh install.sh --global     # every repository on this machine
sh install.sh --claude-md  # also add the rule to ~/.claude/CLAUDE.md
sh install.sh --check      # report what is installed, change nothing
sh install.sh --uninstall  # put everything back
```

On Windows use Git Bash — git runs hooks through `sh` there too.

## Two layers, because one is not enough

**The rule** lives in the skill, and in `~/.claude/CLAUDE.md` if you pass
`--claude-md`. It covers everything an assistant writes: commits, pull request
bodies, issues, changelogs, contributor files. It is an instruction, so it holds
as long as the instruction is read.

**The hook** covers commits only, and covers them absolutely. It rewrites the
message after it is written and before the commit exists, so a trailer added by
habit, by a default, or by an instruction you never wrote does not land.

You want both. The hook cannot see a pull request body; the rule cannot survive
a tool that ignores it.

## What it does and does not touch

Removed:

- `Co-Authored-By:` trailers naming Claude, Anthropic, an `@anthropic.com`
  address, Copilot, Cursor, Aider or Devin
- `🤖 Generated with [Claude Code]` footers
- the blank line a stripped trailer leaves behind

Left alone:

- co-authors who are people
- a sentence in your commit body that happens to mention Claude — that is you
  writing about your work
- everything else in the message, byte for byte

## Honest limitations

- **A pull request body is not git.** It is written by `gh` or a browser and
  never passes through a commit hook. Only the rule covers those.
- **`git clone` does not copy hooks.** A per-repository install is gone in a
  fresh clone. Re-run the installer, or use `--global`.
- **`--global` loses to a repository's own `core.hooksPath`.** husky and
  lefthook both set it. Run the per-repository install inside those.
- **`git commit --no-verify` skips it,** as it skips every hook.
- **It never blocks a commit.** The trailer is removed and the commit is made. A
  hook that fails in the middle of someone's work is a worse trade than one that
  quietly does its job.

## Hooks you already have

The installer does not replace another tool's hook. It moves an existing
`commit-msg` to `commit-msg.local` and calls it, so a ticket-number rule,
commitlint, or a DCO sign-off keeps working. `--uninstall` puts it back.

Installed globally, the same applies to every repository's own
`.git/hooks/commit-msg`.

## History that already has the trailer

Rewriting history changes every commit hash from the first one you touch, so do
not do it to a branch other people have pulled without telling them.

```bash
git switch -c strip-attribution
git filter-branch -f --msg-filter \
  'grep -v -i -e "^Co-Authored-By:.*claude" -e "^Co-Authored-By:.*anthropic"' \
  HEAD~50..HEAD
git log --format=%B | head -40    # look before you push
```

`git-filter-repo` is the better tool where you have it. A forge builds its
contributor list from commit metadata, so it updates when the history does —
though caches lag, and a fork someone else made keeps the old commits.

## License

MIT.
