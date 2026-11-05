# Linux terminal setup

This setup provides a compact Zsh terminal with Powerlevel10k, history suggestions, syntax highlighting, completion, optional fuzzy history search, and Git context. It supports browser terminals, SSH sessions, native Linux terminals, and WSL.

It does not install iTerm2. iTerm2 is a macOS client application. For a remote Linux terminal, choose the font in the client browser or terminal application.

## What it installs

- An ASCII-first two-line Powerlevel10k prompt showing user and host, current directory, Git branch and state, last failure, and slow command duration.
- Zsh autosuggestions from history and completion, plus syntax highlighting.
- Shared history, history de-duplication, and ignored space-prefixed commands. Prefix a sensitive command with a space so it is not kept in shell history.
- Convenience aliases: `ll`, `la`, `gst`, and `gl`.

The installer uses pinned upstream Git revisions in [config/linux-versions.env](config/linux-versions.env). It does not use `sudo`, change the login shell, or download anything during shell startup.

It refreshes its managed defaults under `~/.config/pimp-terminal` on each run. Personal files stay separate: use `~/.p10k.zsh` for the Powerlevel10k wizard output and `~/.config/pimp-terminal/local.zsh` for other Zsh additions. Neither file is overwritten.

## Administrator prerequisites

On Ubuntu or Debian, an administrator installs the system dependencies once:

```bash
sudo apt-get update
sudo apt-get install -y zsh git ca-certificates fzf ripgrep
```

`fzf` and `ripgrep` are useful terminal tools but are not required by the profile.

## Install for the current user

Clone this repository, then run:

```bash
./scripts/install-linux.sh
```

The installer creates user-owned files under `~/.config/pimp-terminal` and adds one marked source block to `~/.zshrc`. It makes timestamped backups before it refreshes an existing managed default or changes an existing dotfile.

It refuses symbolic links, duplicate markers, nested markers, incomplete markers, and an unexpected `ZDOTDIR` instead of guessing where configuration belongs.

To make a browser terminal that launches interactive Bash move into Zsh, run once:

```bash
./scripts/install-linux.sh --bash-handoff
```

This adds guarded blocks to `~/.bashrc` and the effective Bash login file: `~/.bash_profile`, `~/.bash_login`, or `~/.profile`.

Interactive login and non-login Bash sessions enter Zsh. Scripts, CI commands, and `bash -lc 'command'` remain Bash because the handoff only runs in interactive shells.

Open a new terminal after installation. Verify it with:

```bash
echo "$0"
zsh --version
git status -sb
```

## Client font and optional icons

The included prompt uses ASCII symbols, so no font installation is required. If you prefer Powerlevel10k's icon-based prompt, install a Nerd Font in the client you use to reach Linux, then run:

```bash
p10k configure
```

For an Orca browser terminal, this choice belongs in the browser or Orca client font settings. For iTerm2, install and select the font on the Mac that runs iTerm2.

The installer does not overwrite a `~/.p10k.zsh` created by the wizard. It prevents plugin downloads during shell startup.

## Temporarily bypass the profile

For a plain Bash session:

```bash
PIMP_TERMINAL_DISABLE=1 bash --norc
```

For a plain Zsh session:

```bash
PIMP_TERMINAL_DISABLE=1 zsh -f
```

## Update the pinned tools

Review the three upstream repositories and update the commit values in `config/linux-versions.env`. Then rerun the installer. Do not use an unreviewed branch name as a replacement for a pin.

## Verify this repository

```bash
./tests/verify.sh
```
