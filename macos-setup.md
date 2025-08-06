# iTerm2 and Powerlevel10k Setup Guide for macOS

This guide will walk you through the process of setting up iTerm2 with Powerlevel10k, Meslo Nerd Font, configuring VS Code, and setting up Git aliases on a new Mac.

## Table of Contents
1. [Install Homebrew](#1-install-homebrew)
2. [Install iTerm2](#2-install-iterm2)
3. [Install Zsh](#3-install-zsh)
4. [Install Oh My Zsh](#4-install-oh-my-zsh)
5. [Install Powerlevel10k](#5-install-powerlevel10k)
6. [Install Meslo Nerd Font](#6-install-meslo-nerd-font)
7. [Configure iTerm2](#7-configure-iterm2)
8. [Configure Powerlevel10k](#8-configure-powerlevel10k)
9. [Enable Git Integration and Auto-suggestions](#9-enable-git-integration-and-auto-suggestions)
10. [Set iTerm2 as Default Terminal](#10-set-iterm2-as-default-terminal)
11. [Configure VS Code](#11-configure-vs-code)
12. [Set Up Git Aliases](#12-set-up-git-aliases)

## 1. Install Homebrew

Open Terminal and run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the prompts to complete the installation.

## 2. Install iTerm2

In Terminal, run:

```bash
brew install --cask iterm2
```

## 3. Install Zsh

Zsh comes pre-installed on macOS Catalina and later. If you're using an older version, install it with:

```bash
brew install zsh
```

## 4. Install Oh My Zsh

Run:

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## 5. Install Powerlevel10k

Run:

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Then, edit your `~/.zshrc` file:

```bash
nano ~/.zshrc
```

Find the `ZSH_THEME` line and change it to:

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

Save and exit (Ctrl+X, then Y, then Enter).

## 6. Install Meslo Nerd Font

Run:

```bash
brew install --cask font-meslo-lg-nerd-font
```

If this doesn't work, try manual installation:

```bash
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip -o Meslo.zip
unzip Meslo.zip -d MesloFont
mkdir -p ~/Library/Fonts
mv MesloFont/*.ttf ~/Library/Fonts/
rm -rf MesloFont Meslo.zip
```

## 7. Configure iTerm2

1. Open iTerm2
2. Go to iTerm2 > Preferences > Profiles > Text
3. In the Font section, change the font to "MesloLGS Nerd Font Mono"

## 8. Configure Powerlevel10k

Close and reopen iTerm2, or run:

```bash
source ~/.zshrc
```

The Powerlevel10k configuration wizard should start automatically. If it doesn't, run:

```bash
p10k configure
```

Follow the prompts to set up Powerlevel10k according to your preferences.

## 9. Enable Git Integration and Auto-suggestions

Git integration should be enabled by default. To enable auto-suggestions:

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Edit your `~/.zshrc` file:

```bash
nano ~/.zshrc
```

Find the `plugins` line and add `zsh-autosuggestions`:

```bash
plugins=(git zsh-autosuggestions)
```

Save and exit, then apply changes:

```bash
source ~/.zshrc
```

## 10. Set iTerm2 as Default Terminal

1. Open iTerm2
2. Go to iTerm2 > Make iTerm2 Default Term in the menu bar
3. Click "Yes" in the prompt

## 11. Configure VS Code

1. Open VS Code
2. Open Settings (Cmd + ,)
3. Search for "font"
4. Click "Edit in settings.json" under "Editor: Font Family"
5. Add or modify these lines:

```json
{
  "editor.fontFamily": "'MesloLGS Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace",
  "terminal.integrated.fontFamily": "MesloLGS Nerd Font Mono"
}
```

6. Save the file and restart VS Code

## 12. Set Up Git Aliases

To make your Git workflow more efficient, you can set up aliases for commonly used Git commands. These aliases will work globally, regardless of which shell you're using.

Run the following commands in your terminal:

```bash
git config --global alias.st status
git config --global alias.br branch
git config --global alias.co commit
git config --global alias.ch checkout
```

These commands create the following aliases:
- `git st` for `git status`
- `git br` for `git branch`
- `git co` for `git commit`
- `git ch` for `git checkout`

### Optional Git Aliases

You can set up additional aliases for even more convenience:

```bash
git config --global alias.pu pull
git config --global alias.ph push
```

These commands create the following additional aliases:
- `git pu` for `git pull`
- `git ph` for `git push`

After setting these aliases, you can use them in any terminal or Git-enabled application. For example, typing `git st` will execute `git status`.

To view all your current Git aliases, run:

```bash
git config --get-regexp alias
```

To remove an alias you no longer want, use the `--unset` option. For example:

```bash
git config --global --unset alias.ci
```

This command would remove the `ci` alias if you had it set previously.

Note: These aliases are different from shell-specific aliases (like those you might set in `.zshrc`). These Git aliases work with the `git` command itself and are available in any shell or Git-enabled application.

## Conclusion

You now have a fully configured development environment with iTerm2, Powerlevel10k, Meslo Nerd Font, and useful Git aliases. This setup includes Git integration and auto-suggestions in your terminal, the font is configured in both iTerm2 and VS Code, and you have efficient Git shortcuts at your disposal.

Remember, you can always modify these configurations to suit your preferences. Enjoy your new, efficient setup!
