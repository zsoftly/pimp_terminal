#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(unset CDPATH; cd -- "$(dirname -- "$0")/.." && pwd)

zsh -n "$ROOT_DIR/config/zshrc"
zsh -n "$ROOT_DIR/config/p10k.zsh"
zsh -n "$ROOT_DIR/config/zshenv"
bash -n "$ROOT_DIR/scripts/install-linux.sh"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -s bash "$ROOT_DIR/scripts/install-linux.sh" "$ROOT_DIR/tests/verify.sh"
fi

TEST_HOME=$(mktemp -d)
BAD_HOME=$(mktemp -d)
DIR_HOME=$(mktemp -d)
MOCK_BIN=$(mktemp -d)
BODY_TMPDIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_HOME" "$BAD_HOME" "$DIR_HOME" "$MOCK_BIN" "$BODY_TMPDIR"' EXIT
unset XDG_CONFIG_HOME XDG_STATE_HOME ZDOTDIR

file_mtime() {
  if stat -c %Y "$1" >/dev/null 2>&1; then
    stat -c %Y "$1"
  else
    stat -f %m "$1"
  fi
}

file_mode() {
  if stat -c %a "$1" >/dev/null 2>&1; then
    stat -c %a "$1"
  else
    stat -f %Lp "$1"
  fi
}

printf 'not a directory\n' >"$DIR_HOME/.config"
if directory_output=$(HOME="$DIR_HOME" "$ROOT_DIR/scripts/install-linux.sh" 2>&1); then
  printf 'regular-file directory test unexpectedly succeeded\n' >&2
  exit 1
fi
printf '%s\n' "$directory_output" | grep -Fqx "pimp-terminal: expected directory: $DIR_HOME/.config"

printf 'export PIMP_PROFILE_TEST=preserved\n' >"$TEST_HOME/.profile"
printf 'private history line\n' >"$TEST_HOME/.bash_history"
HOME="$TEST_HOME" "$ROOT_DIR/scripts/install-linux.sh" --bash-handoff
before=$(cksum "$TEST_HOME/.zshrc" "$TEST_HOME/.zshenv" "$TEST_HOME/.bashrc" "$TEST_HOME/.profile")
zshrc_mtime=$(file_mtime "$TEST_HOME/.zshrc")
zshenv_mtime=$(file_mtime "$TEST_HOME/.zshenv")
bashrc_mtime=$(file_mtime "$TEST_HOME/.bashrc")
profile_mtime=$(file_mtime "$TEST_HOME/.profile")
private_tmp="$TEST_HOME/.local/state/pimp-terminal/tmp"
[ -d "$private_tmp" ]
[ ! -L "$private_tmp" ]
[ "$(file_mode "$private_tmp")" = 700 ]
HOME="$TEST_HOME" TMPDIR=/tmp zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
HOME="$TEST_HOME" TMPDIR=/tmp/ zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
HOME="$TEST_HOME" TMPDIR="$TEST_HOME/not-a-directory" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
(
  cd "$TEST_HOME"
  HOME="$TEST_HOME" XDG_STATE_HOME=relative-state "$ROOT_DIR/scripts/install-linux.sh"
)
[ ! -e "$TEST_HOME/relative-state" ]
(
  cd "$BAD_HOME"
  HOME="$TEST_HOME" TMPDIR=/tmp XDG_STATE_HOME=relative-state zsh -c 'print -r -- "$TMPDIR"'
) | grep -Fqx "$private_tmp"
[ ! -e "$BAD_HOME/relative-state" ]
absolute_state="$TEST_HOME/absolute-state"
HOME="$TEST_HOME" XDG_STATE_HOME="$absolute_state" "$ROOT_DIR/scripts/install-linux.sh"
HOME="$TEST_HOME" TMPDIR=/tmp XDG_STATE_HOME="$absolute_state" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$absolute_state/pimp-terminal/tmp"
custom_tmp="$TEST_HOME/custom-tmp"
mkdir -m 700 "$custom_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_tmp" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$custom_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_tmp///" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$custom_tmp"
custom_link_target="$TEST_HOME/custom-link-target"
custom_link="$TEST_HOME/custom-link"
mkdir -m 700 "$custom_link_target"
ln -s "$custom_link_target" "$custom_link"
HOME="$TEST_HOME" TMPDIR="$custom_link/" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_link///" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_link/." zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
chmod 200 "$custom_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_tmp" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
chmod 777 "$custom_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_tmp" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$private_tmp"
chmod 700 "$custom_tmp"
HOME="$TEST_HOME" TMPDIR="$custom_tmp" zsh -c 'print -r -- "$TMPDIR"' | grep -Fqx "$custom_tmp"
quiet_output=$(HOME="$TEST_HOME" TMPDIR=/tmp zsh -c ':')
[ -z "$quiet_output" ]
# shellcheck disable=SC2016
unset_tmpdir=$(env -u TMPDIR HOME="$TEST_HOME" zsh -uc 'print -r -- "$TMPDIR"')
[ "$unset_tmpdir" = "$private_tmp" ]
printf 'typeset -g PIMP_LOCAL_TEST=preserved\n' >"$TEST_HOME/.config/pimp-terminal/local.zsh"
printf 'typeset -g PIMP_P10K_TEST=preserved\n' >"$TEST_HOME/.p10k.zsh"
printf 'stale managed default\n' >"$TEST_HOME/.config/pimp-terminal/p10k.zsh"
printf 'stale managed default\n' >"$TEST_HOME/.config/pimp-terminal/zshrc"
sleep 1
HOME="$TEST_HOME" "$ROOT_DIR/scripts/install-linux.sh" --bash-handoff
after=$(cksum "$TEST_HOME/.zshrc" "$TEST_HOME/.zshenv" "$TEST_HOME/.bashrc" "$TEST_HOME/.profile")
cmp "$ROOT_DIR/config/p10k.zsh" "$TEST_HOME/.config/pimp-terminal/p10k.zsh"
cmp "$ROOT_DIR/config/zshrc" "$TEST_HOME/.config/pimp-terminal/zshrc"
grep -Fqx 'typeset -g PIMP_LOCAL_TEST=preserved' "$TEST_HOME/.config/pimp-terminal/local.zsh"
grep -Fqx 'typeset -g PIMP_P10K_TEST=preserved' "$TEST_HOME/.p10k.zsh"
grep -Fqx 'export PIMP_PROFILE_TEST=preserved' "$TEST_HOME/.profile"
grep -Fqx 'private history line' "$TEST_HOME/.bash_history"
[ "$before" = "$after" ]
[ "$zshrc_mtime" = "$(file_mtime "$TEST_HOME/.zshrc")" ]
[ "$zshenv_mtime" = "$(file_mtime "$TEST_HOME/.zshenv")" ]
[ "$bashrc_mtime" = "$(file_mtime "$TEST_HOME/.bashrc")" ]
[ "$profile_mtime" = "$(file_mtime "$TEST_HOME/.profile")" ]

real_git=$(command -v git)
cat >"$MOCK_BIN/git" <<'EOF'
#!/usr/bin/env bash
for argument in "$@"; do
  if [ "$argument" = fetch ]; then
    printf 'unexpected git fetch on pinned rerun\n' >&2
    exit 99
  fi
done
exec "$REAL_GIT" "$@"
EOF
chmod +x "$MOCK_BIN/git"
PATH="$MOCK_BIN:$PATH" REAL_GIT="$real_git" HOME="$TEST_HOME" "$ROOT_DIR/scripts/install-linux.sh" --bash-handoff

zsh_probe="print -r -- \${ZSH_VERSION:-missing}"$'\nexit'
zsh_version=$(zsh -fc 'print -r -- "$ZSH_VERSION"')
printf '%s\n' "$zsh_probe" | HOME="$TEST_HOME" bash --noprofile --norc -ic 'source "$HOME/.bashrc"' 2>/dev/null | grep -Fqx "$zsh_version"
printf '%s\n' "$zsh_probe" | HOME="$TEST_HOME" bash -ilc ':' 2>/dev/null | grep -Fqx "$zsh_version"
HOME="$TEST_HOME" bash -lc 'test -n "$BASH_VERSION" && test -z "${ZSH_VERSION:-}"'
HOME="$TEST_HOME" zsh -ic 'test "$PIMP_LOCAL_TEST" = preserved && test "$PIMP_P10K_TEST" = preserved' >/dev/null 2>&1

fallback_target="$TEST_HOME/fallback-target"
mkdir -m 755 "$fallback_target"
rmdir "$private_tmp"
ln -s "$fallback_target" "$private_tmp"
HOME="$TEST_HOME" TMPDIR=/tmp zsh -c ':'
[ "$(file_mode "$fallback_target")" = 755 ]

cat >"$BAD_HOME/.zshrc" <<'EOF'
# >>> pimp-terminal zsh >>>
# >>> pimp-terminal local >>>
keep this user content
# <<< pimp-terminal local <<<
# <<< pimp-terminal zsh <<<
EOF
cp "$BAD_HOME/.zshrc" "$BAD_HOME/zshrc.before"
if nested_output=$(TMPDIR="$BODY_TMPDIR" HOME="$BAD_HOME" "$ROOT_DIR/scripts/install-linux.sh" 2>&1); then
  printf 'nested marker test unexpectedly succeeded\n' >&2
  exit 1
fi
printf '%s\n' "$nested_output" | grep -Fqx "pimp-terminal: nested pimp-terminal marker in $BAD_HOME/.zshrc"
cmp "$BAD_HOME/zshrc.before" "$BAD_HOME/.zshrc"
[ -z "$(find "$BODY_TMPDIR" -mindepth 1 -type f -print -quit)" ]

printf 'Linux terminal setup checks passed.\n'
