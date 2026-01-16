# Mac Development Environment Setup

A reusable, idempotent bash script to configure a new Mac for software development. Safe to run multiple times - already installed components are skipped.

## What's Included

### Core Tools
- **Homebrew** - Package manager
- **Oh My Zsh** - Shell framework with plugins (autosuggestions, syntax highlighting, completions)
- **iTerm2** - Terminal emulator with dark theme configuration

### Editors
- Visual Studio Code
- Zed
- Neovim

### Programming Languages
- **Node.js** via nvm
- **Python** via pyenv
- **Go**
- **Rust**

### Mobile Development
- Watchman
- CocoaPods
- Temurin (Java)
- Android Studio

### Infrastructure & DevOps
- Docker
- Kubernetes tools (kubectl, kubectx, helm, k9s)
- Terraform & Terragrunt
- Cloud CLIs (AWS, GCP, Azure)

### CLI Utilities
- Git, gh, lazygit
- fzf, ripgrep, fd, zoxide
- bat, eza, jq, yq
- httpie, curl, wget
- htop, btop, tmux
- starship prompt
- And more...

## Usage

```bash
chmod +x mac-setup.sh
./mac-setup.sh [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--all` | Install everything (default) |
| `--minimal` | Install only core tools (editors, git, languages) |
| `--skip-apps` | Skip GUI applications (VS Code, Docker, etc.) |
| `--skip-mobile` | Skip mobile development tools |
| `--skip-infra` | Skip infrastructure tools |
| `--dry-run` | Show what would be installed without installing |
| `--non-interactive` | Skip all prompts, use defaults |
| `--git-name "Name"` | Set git user name (for non-interactive mode) |
| `--git-email "Email"` | Set git user email (for non-interactive mode) |
| `--help` | Show help message |

### Examples

```bash
# Full interactive setup
./mac-setup.sh

# Preview what will be installed
./mac-setup.sh --dry-run

# Quick minimal setup
./mac-setup.sh --minimal --non-interactive

# Pre-set git config
./mac-setup.sh --git-name "John Doe" --git-email "john@example.com"
```

## Post-Installation

After running the script:

1. Restart your terminal or run `source ~/.zshrc`
2. Open iTerm2 and select "Dark Developer" profile in Preferences > Profiles
3. Install Xcode from the App Store (for iOS development)
4. Open Docker Desktop and complete setup
5. Open Android Studio and install SDKs

## License

MIT
