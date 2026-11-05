#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(unset CDPATH; cd -- "$(dirname -- "$0")/.." && pwd)

zsh -n "$ROOT_DIR/config/zshrc"
zsh -n "$ROOT_DIR/config/p10k.zsh"
bash -n "$ROOT_DIR/scripts/install-linux.sh"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -s bash "$ROOT_DIR/scripts/install-linux.sh" "$ROOT_DIR/tests/verify.sh"
fi

TEST_HOME=$(mktemp -d)
BAD_HOME=$(mktemp -d)
trap 'rm -rf -- "$TEST_HOME" "$BAD_HOME"' EXIT
unset XDG_CONFIG_HOME XDG_STATE_HOME ZDOTDIR
printf 'export PIMP_PROFILE_TEST=preserved\n' >"$TEST_HOME/.profile"
printf 'private history line\n' >"$TEST_HOME/.bash_history"
HOME="$TEST_HOME" "$ROOT_DIR/scripts/install-linux.sh" --bash-handoff
before=$(cksum "$TEST_HOME/.zshrc" "$TEST_HOME/.bashrc" "$TEST_HOME/.profile")
printf 'typeset -g PIMP_LOCAL_TEST=preserved\n' >"$TEST_HOME/.config/pimp-terminal/local.zsh"
printf 'typeset -g PIMP_P10K_TEST=preserved\n' >"$TEST_HOME/.p10k.zsh"
printf 'stale managed default\n' >"$TEST_HOME/.config/pimp-terminal/p10k.zsh"
printf 'stale managed default\n' >"$TEST_HOME/.config/pimp-terminal/zshrc"
HOME="$TEST_HOME" "$ROOT_DIR/scripts/install-linux.sh" --bash-handoff
after=$(cksum "$TEST_HOME/.zshrc" "$TEST_HOME/.bashrc" "$TEST_HOME/.profile")
cmp "$ROOT_DIR/config/p10k.zsh" "$TEST_HOME/.config/pimp-terminal/p10k.zsh"
cmp "$ROOT_DIR/config/zshrc" "$TEST_HOME/.config/pimp-terminal/zshrc"
grep -Fqx 'typeset -g PIMP_LOCAL_TEST=preserved' "$TEST_HOME/.config/pimp-terminal/local.zsh"
grep -Fqx 'typeset -g PIMP_P10K_TEST=preserved' "$TEST_HOME/.p10k.zsh"
grep -Fqx 'export PIMP_PROFILE_TEST=preserved' "$TEST_HOME/.profile"
grep -Fqx 'private history line' "$TEST_HOME/.bash_history"
[ "$before" = "$after" ]

zsh_probe="print -r -- \${ZSH_VERSION:-missing}"$'\nexit'
printf '%s\n' "$zsh_probe" | HOME="$TEST_HOME" bash --noprofile --norc -ic 'source "$HOME/.bashrc"' 2>/dev/null | grep -E '^5\.'
printf '%s\n' "$zsh_probe" | HOME="$TEST_HOME" bash -ilc ':' 2>/dev/null | grep -E '^5\.'
HOME="$TEST_HOME" bash -lc 'test -n "$BASH_VERSION" && test -z "${ZSH_VERSION:-}"'
HOME="$TEST_HOME" zsh -ic 'test "$PIMP_LOCAL_TEST" = preserved && test "$PIMP_P10K_TEST" = preserved' >/dev/null 2>&1

cat >"$BAD_HOME/.zshrc" <<'EOF'
# >>> pimp-terminal zsh >>>
# >>> pimp-terminal local >>>
keep this user content
# <<< pimp-terminal local <<<
# <<< pimp-terminal zsh <<<
EOF
cp "$BAD_HOME/.zshrc" "$BAD_HOME/zshrc.before"
if HOME="$BAD_HOME" "$ROOT_DIR/scripts/install-linux.sh" >/dev/null 2>&1; then
  printf 'nested marker test unexpectedly succeeded\n' >&2
  exit 1
fi
cmp "$BAD_HOME/zshrc.before" "$BAD_HOME/.zshrc"

printf 'Linux terminal setup checks passed.\n'
