---

## WSL Ubuntu Customization Guide

This guide will walk you through setting up Powerlevel10k, Meslo Nerd Font, configuring VS Code, and setting up Git aliases on a new WSL Ubuntu installation.

### Table of Contents
1. [Install Zsh](#1-install-zsh)
2. [Install Oh My Zsh](#2-install-oh-my-zsh)
3. [Install Powerlevel10k](#3-install-powerlevel10k)
4. [Install Meslo Nerd Font](#4-install-meslo-nerd-font)
5. [Configure Powerlevel10k](#5-configure-powerlevel10k)
6. [Enable Git Integration and Auto-suggestions](#6-enable-git-integration-and-auto-suggestions)
7. [Configure VS Code](#7-configure-vs-code)
8. [Set Up Git Aliases](#8-set-up-git-aliases)

---

### 1. Install Zsh

Install Zsh on WSL:

```bash
sudo apt update && sudo apt install zsh -y
```

After installation, make Zsh your default shell by running:

```bash
chsh -s $(which zsh)
```

You may need to restart your terminal for the change to take effect.

### 2. Install Oh My Zsh

Run the following command to install Oh My Zsh:

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 3. Install Powerlevel10k

Clone the Powerlevel10k theme repository:

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Edit your `~/.zshrc` file:

```bash
nano ~/.zshrc
```

Find the `ZSH_THEME` line and change it to:

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

Save and exit (`Ctrl+X`, then `Y`, then `Enter`).

### 4. Install Meslo Nerd Font

For proper font rendering, install Meslo Nerd Font on your Windows host machine and set it in your WSL terminal.

1. Download the Meslo Nerd Font [here](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip).
2. Unzip the file and install the `.ttf` files.
3. Set MesloLGS Nerd Font Mono as your font in your WSL terminal settings (if using Windows Terminal, go to Settings > Appearance > Font face).

### 5. Configure Powerlevel10k

After setting the Meslo font, restart your terminal and run the following to reload your `.zshrc`:

```bash
source ~/.zshrc
```

The Powerlevel10k configuration wizard should start automatically. If it doesn’t, run:

```bash
p10k configure
```

Follow the prompts to configure your terminal appearance.

### 6. Enable Git Integration and Auto-suggestions

To enable auto-suggestions, run the following:

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Next, edit your `~/.zshrc`:

```bash
nano ~/.zshrc
```

Find the `plugins` line and add `zsh-autosuggestions`:

```bash
plugins=(git zsh-autosuggestions)
```

Save and exit, then apply the changes:

```bash
source ~/.zshrc
```

### 7. Configure VS Code

If you're using VS Code in WSL, configure it to use Meslo Nerd Font.

1. Open VS Code.
2. Open the settings (`Ctrl + ,`).
3. Search for "Font Family."
4. Edit the `settings.json` file and add the following lines:

```json
{
  "editor.fontFamily": "'MesloLGS Nerd Font Mono', Consolas, 'Courier New', monospace",
  "terminal.integrated.fontFamily": "MesloLGS Nerd Font Mono"
}
```

Save the file and restart VS Code.

### 8. Set Up Git Aliases

Set up convenient Git aliases with the following commands:

```bash
git config --global alias.st status
git config --global alias.br branch
git config --global alias.co commit
git config --global alias.ch checkout
```

Optional aliases:

```bash
git config --global alias.pu pull
git config --global alias.ph push
git config --global core.pager cat                # Disables paging by sending all output directly to the terminal
git config --global advice.statusHints true       # Enables hints in `git status` to provide helpful suggestions
git config --global advice.commitBeforeMerge true # Provides a reminder to commit any changes before merging
git config --global alias.br "branch -vv"         # Creates an alias `git br` that lists branches with verbose output
git config --global color.ui auto                 # Enables automatic color-coding in Git output for easier readability
git config --global init.defaultBranch main  # Sets 'main' as the default branch name for all new repositories
git config --global pull.rebase false
git config --global cola.spellcheck false
git config --global push.autoSetupRemote true
git config --global push.default current
```

To view all current Git aliases, run:

```bash
git config --get-regexp alias
```

---
