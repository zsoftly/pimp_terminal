#!/usr/bin/env bash
# Install the user-scoped Linux terminal profile. It never invokes sudo.
set -euo pipefail

SCRIPT_DIR=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(unset CDPATH; cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck source=../config/linux-versions.env
# shellcheck disable=SC1091
. "$REPO_DIR/config/linux-versions.env"

HANDOFF=false
BODY_FILES=()

cleanup() {
  local body_file
  for body_file in "${BODY_FILES[@]}"; do
    [ -z "$body_file" ] || rm -f -- "$body_file"
  done
}

trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: scripts/install-linux.sh [--bash-handoff]

Install Powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting for the
current user. Required commands: zsh and git. The script does not use
sudo and does not change the login shell.

--bash-handoff  Start zsh only from interactive Bash terminals. This is useful
                for browser terminals whose configured shell remains Bash.
EOF
}

fail() { printf 'pimp-terminal: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"; }

assert_regular_or_missing() {
  [ ! -L "$1" ] || fail "refusing symbolic link: $1"
  [ ! -e "$1" ] || [ -f "$1" ] || fail "refusing non-regular file: $1"
}

assert_directory_not_symlink() {
  [ ! -L "$1" ] || fail "refusing symbolic link directory: $1"
  [ ! -e "$1" ] || [ -d "$1" ] || fail "expected directory: $1"
  [ -d "$1" ] || mkdir -p -- "$1"
  [ -d "$1" ] || fail "expected directory: $1"
}

refresh_managed_file() {
  local source_path=$1 destination_path=$2
  local temporary_path
  assert_regular_or_missing "$destination_path"
  temporary_path=$(mktemp "${destination_path}.pimp-terminal.XXXXXX")
  install -m 0644 "$source_path" "$temporary_path"
  if ! cmp -s "$source_path" "$destination_path" 2>/dev/null; then
    [ ! -e "$destination_path" ] || backup_if_needed "$destination_path"
    mv "$temporary_path" "$destination_path"
    temporary_path=''
  fi
  [ -z "$temporary_path" ] || rm -f -- "$temporary_path"
}

backup_if_needed() {
  local source_path=$1
  [ -f "$source_path" ] || return 0
  local backup_path
  backup_path="${source_path}.pimp-terminal-backup.$(date +%Y%m%d%H%M%S)"
  cp -p -- "$source_path" "$backup_path"
  printf 'Backed up %s to %s\n' "$source_path" "$backup_path"
}

replace_managed_block() {
  local source_path=$1 block_name=$2 body_file=$3
  local begin="# >>> pimp-terminal ${block_name} >>>"
  local end="# <<< pimp-terminal ${block_name} <<<"
  local begin_count end_count begin_line end_line temporary_path existed=false

  assert_regular_or_missing "$source_path"
  if [ -f "$source_path" ]; then
    existed=true
  else
    : >"$source_path"
  fi
  begin_count=$(grep -Fxc "$begin" "$source_path" || true)
  end_count=$(grep -Fxc "$end" "$source_path" || true)
  [ "$begin_count" -le 1 ] && [ "$end_count" -le 1 ] || fail "duplicate managed markers in $source_path"
  [ "$begin_count" = "$end_count" ] || fail "unmatched managed markers in $source_path"
  if [ "$begin_count" = 1 ]; then
    begin_line=$(grep -Fn "$begin" "$source_path" | cut -d: -f1)
    end_line=$(grep -Fn "$end" "$source_path" | cut -d: -f1)
    [ "$begin_line" -lt "$end_line" ] || fail "managed markers are out of order in $source_path"
    if ! awk -v begin="$begin" -v end="$end" '
      $0 == begin { inside = 1; next }
      $0 == end && inside { exit 0 }
      inside && $0 ~ /^# (>>>|<<<) pimp-terminal .+ (>>>|<<<)$/ { exit 1 }
    ' "$source_path"; then
      fail "nested pimp-terminal marker in $source_path"
    fi
  fi

  temporary_path=$(mktemp "${source_path}.pimp-terminal.XXXXXX")
  if [ "$begin_count" = 1 ]; then
    awk -v begin="$begin" -v end="$end" -v body="$body_file" '
      $0 == begin {
        print begin
        while ((getline line < body) > 0) print line
        close(body)
        inside = 1
        next
      }
      $0 == end && inside { print end; inside = 0; next }
      !inside { print }
    ' "$source_path" >"$temporary_path"
  else
    cat "$source_path" >"$temporary_path"
    [ -s "$temporary_path" ] && printf '\n' >>"$temporary_path"
    {
      printf '%s\n' "$begin"
      cat "$body_file"
      printf '%s\n' "$end"
    } >>"$temporary_path"
  fi
  if ! cmp -s "$source_path" "$temporary_path"; then
    [ "$existed" = true ] && backup_if_needed "$source_path"
    mv "$temporary_path" "$source_path"
    temporary_path=''
  fi
  [ -z "$temporary_path" ] || rm -f -- "$temporary_path"
}

install_pinned_repo() {
  local name=$1 url=$2 revision=$3 destination
  destination="$VENDOR_DIR/$name"
  if [ -e "$destination" ]; then
    [ ! -L "$destination" ] || fail "refusing symbolic link: $destination"
    git -C "$destination" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "existing vendor directory is not a Git checkout: $destination"
    [ "$(git -C "$destination" remote get-url origin)" = "$url" ] || fail "unexpected origin for $destination"
    [ -z "$(git -C "$destination" status --porcelain)" ] || fail "vendor checkout has local changes: $destination"
  else
    git init -q "$destination"
    git -C "$destination" remote add origin "$url"
  fi
  if [ "$(git -C "$destination" rev-parse --verify HEAD 2>/dev/null || true)" != "$revision" ]; then
    git -C "$destination" fetch -q --depth 1 origin "$revision"
    git -C "$destination" checkout -q --detach FETCH_HEAD
  fi
  [ "$(git -C "$destination" rev-parse HEAD)" = "$revision" ] || fail "could not verify pinned revision for $name"
}

while [ "$#" -gt 0 ]; do
  case $1 in
    --bash-handoff) HANDOFF=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown option: $1" ;;
  esac
  shift
done

require_command zsh
require_command git

if [ -n "${ZDOTDIR:-}" ] && [ "$ZDOTDIR" != "$HOME" ]; then
  fail 'ZDOTDIR is set outside HOME; unset it or configure that directory before running this installer'
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pimp-terminal"
VENDOR_DIR="$CONFIG_DIR/vendor"
assert_directory_not_symlink "${XDG_CONFIG_HOME:-$HOME/.config}"
assert_directory_not_symlink "$CONFIG_DIR"
assert_directory_not_symlink "$VENDOR_DIR"
refresh_managed_file "$REPO_DIR/config/p10k.zsh" "$CONFIG_DIR/p10k.zsh"
refresh_managed_file "$REPO_DIR/config/zshrc" "$CONFIG_DIR/zshrc"
refresh_managed_file "$REPO_DIR/config/zshenv" "$CONFIG_DIR/zshenv"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
case "$STATE_HOME" in
  /*) ;;
  *) STATE_HOME="$HOME/.local/state" ;;
esac
STATE_DIR="$STATE_HOME/pimp-terminal"
TMP_DIR="$STATE_DIR/tmp"
assert_directory_not_symlink "$STATE_HOME"
assert_directory_not_symlink "$STATE_DIR"
assert_directory_not_symlink "$TMP_DIR"
chmod 700 "$TMP_DIR"

install_pinned_repo powerlevel10k https://github.com/romkatv/powerlevel10k.git "$POWERLEVEL10K_REV"
install_pinned_repo zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_AUTOSUGGESTIONS_REV"
install_pinned_repo zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_REV"

zsh_body=$(mktemp)
BODY_FILES+=("$zsh_body")
cat >"$zsh_body" <<'EOF'
if [[ -z ${PIMP_TERMINAL_DISABLE:-} ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/pimp-terminal/zshrc"
fi
EOF
replace_managed_block "$HOME/.zshrc" zsh "$zsh_body"

zshenv_body=$(mktemp)
BODY_FILES+=("$zshenv_body")
cat >"$zshenv_body" <<'EOF'
if [[ -z ${PIMP_TERMINAL_DISABLE:-} ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/pimp-terminal/zshenv"
fi
EOF
replace_managed_block "$HOME/.zshenv" zshenv "$zshenv_body"

if [ "$HANDOFF" = true ]; then
  bash_body=$(mktemp)
  BODY_FILES+=("$bash_body")
  cat >"$bash_body" <<'EOF'
if [[ $- == *i* ]] && [[ -z ${PIMP_TERMINAL_DISABLE:-} ]] && [[ -z ${PIMP_TERMINAL_IN_ZSH:-} ]]; then
  export PIMP_TERMINAL_IN_ZSH=1
  exec zsh -l
fi
EOF
  replace_managed_block "$HOME/.bashrc" bash-handoff "$bash_body"
  login_path="$HOME/.profile"
  for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    if [ -e "$candidate" ] || [ -L "$candidate" ]; then
      login_path=$candidate
      break
    fi
  done
  replace_managed_block "$login_path" bash-login-handoff "$bash_body"
fi

zsh -n "$CONFIG_DIR/zshrc"
zsh -n "$CONFIG_DIR/p10k.zsh"
zsh -n "$CONFIG_DIR/zshenv"
zsh -n "$HOME/.zshrc"
zsh -n "$HOME/.zshenv"
printf 'Installed Linux terminal profile for %s. Open a new terminal.\n' "${USER:-user}"
