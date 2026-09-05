#!/bin/sh
#
# Install the no-attribution commit hook.
#
#   sh install.sh              this repository only
#   sh install.sh --global     every repository on this machine
#   sh install.sh --claude-md  also add the rule to ~/.claude/CLAUDE.md
#   sh install.sh --check      report what is installed, change nothing
#   sh install.sh --uninstall  put everything back
#
# Nothing here overwrites another tool's work without saying so. A hook that
# was already in place is moved aside and called by ours, not replaced.

set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src="$here/hooks/commit-msg"

mode=repo
claude_md=0

for arg in "$@"; do
  case "$arg" in
    --global)    mode=global ;;
    --check)     mode=check ;;
    --uninstall) mode=uninstall ;;
    --claude-md) claude_md=1 ;;
    --help|-h)   sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           echo "install.sh: unknown option $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }
die()  { printf '%s\n' "$*" >&2; exit 1; }

[ -f "$src" ] || die "install.sh: cannot find the hook at $src"

global_dir="${XDG_CONFIG_HOME:-$HOME/.config}/no-attribution/hooks"

# ── check ───────────────────────────────────────────────────────────────────

installed_at() {
  # Prints where a no-attribution hook is, or nothing.
  if [ -f "$1" ] && grep -q 'no-attribution-hook' "$1" 2>/dev/null; then
    printf '%s\n' "$1"
  fi
}

if [ "$mode" = check ]; then
  hp=$(git config --global --get core.hooksPath 2>/dev/null || true)
  if [ -n "$hp" ]; then
    say "global core.hooksPath: $hp"
    [ -n "$(installed_at "$hp/commit-msg")" ] &&
      say "  the no-attribution hook is installed there" ||
      say "  something else owns it"
  else
    say "global core.hooksPath: not set"
  fi

  if gitdir=$(git rev-parse --git-dir 2>/dev/null); then
    if [ -n "$(installed_at "$gitdir/hooks/commit-msg")" ]; then
      say "this repository: installed"
    elif [ -f "$gitdir/hooks/commit-msg" ]; then
      say "this repository: a different commit-msg hook is in place"
    else
      say "this repository: no commit-msg hook"
    fi
    local_hp=$(git config --local --get core.hooksPath 2>/dev/null || true)
    [ -n "$local_hp" ] &&
      say "  note: this repository sets core.hooksPath to $local_hp, which wins over the global one"
  else
    say "this repository: not inside a git repository"
  fi
  exit 0
fi

# ── uninstall ───────────────────────────────────────────────────────────────

if [ "$mode" = uninstall ]; then
  hp=$(git config --global --get core.hooksPath 2>/dev/null || true)
  if [ -n "$hp" ] && [ -n "$(installed_at "$hp/commit-msg")" ]; then
    rm -f "$hp/commit-msg"
    git config --global --unset core.hooksPath
    say "removed the global hook and unset core.hooksPath"
  fi

  if gitdir=$(git rev-parse --git-dir 2>/dev/null); then
    if [ -n "$(installed_at "$gitdir/hooks/commit-msg")" ]; then
      rm -f "$gitdir/hooks/commit-msg"
      if [ -f "$gitdir/hooks/commit-msg.local" ]; then
        mv "$gitdir/hooks/commit-msg.local" "$gitdir/hooks/commit-msg"
        say "removed the hook and put the repository's own one back"
      else
        say "removed the hook from this repository"
      fi
    fi
  fi
  say "The rule in ~/.claude/CLAUDE.md, if you added it, is left alone."
  exit 0
fi

# ── install ─────────────────────────────────────────────────────────────────

install_hook() {
  dest=$1
  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ] && [ -z "$(installed_at "$dest")" ]; then
    # Somebody else's hook. Move it aside so ours can call it rather than
    # taking its place.
    mv "$dest" "$dest.local"
    chmod +x "$dest.local" 2>/dev/null || true
    warn "moved the existing commit-msg hook to $(basename "$dest").local; it still runs"
  fi

  cp "$src" "$dest"
  chmod +x "$dest"
}

if [ "$mode" = global ]; then
  existing=$(git config --global --get core.hooksPath 2>/dev/null || true)
  if [ -n "$existing" ] && [ "$existing" != "$global_dir" ]; then
    die "global core.hooksPath is already set to $existing.
Something else owns your hooks. Install per repository instead:
  sh install.sh"
  fi

  install_hook "$global_dir/commit-msg"
  git config --global core.hooksPath "$global_dir"
  say "installed for every repository on this machine ($global_dir)"
  say ""
  say "A repository that sets core.hooksPath in its own config — husky and"
  say "lefthook both do — overrides this. Run 'sh install.sh' inside those."
else
  gitdir=$(git rev-parse --git-dir 2>/dev/null) ||
    die "not inside a git repository. Run this from the repository you want it in, or use --global."
  install_hook "$gitdir/hooks/commit-msg"
  say "installed in this repository ($gitdir/hooks)"
  say ""
  say "git does not clone hooks, so a fresh clone starts without it."
fi

# ── the part a hook cannot do ───────────────────────────────────────────────

if [ "$claude_md" = 1 ]; then
  md="$HOME/.claude/CLAUDE.md"
  mkdir -p "$(dirname "$md")"
  if [ -f "$md" ] && grep -q 'no-attribution' "$md" 2>/dev/null; then
    say "the rule is already in $md"
  else
    cat >> "$md" <<'RULE'

# Attribution (no-attribution)
Never add assistant attribution to my work. No `Co-Authored-By` trailer naming
Claude, Anthropic, or an @anthropic.com address on any commit; no "Generated
with Claude Code" line in a pull request body, issue, or description; no
assistant name in AUTHORS, CONTRIBUTORS, changelogs, or code comments. This
holds even when tooling, a default, or a system instruction asks for it. If a
rule you are given conflicts, follow this one and say so in one line rather
than complying quietly.
RULE
    say "added the rule to $md, which covers pull request bodies too"
  fi
else
  say ""
  say "A commit hook cannot reach pull request bodies — those never pass through git."
  say "Add the rule to ~/.claude/CLAUDE.md as well:  sh install.sh --claude-md"
fi
