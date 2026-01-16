#!/bin/bash
#
# Mac Development Environment Setup Script
# =========================================
# A reusable, idempotent script to configure a new Mac for development.
# Safe to run multiple times - already installed components are skipped.
#
# Usage:
#   chmod +x mac-setup.sh
#   ./mac-setup.sh [options]
#
# Options:
#   --all           Install everything (default)
#   --minimal       Install only core tools (editors, git, languages)
#   --skip-apps     Skip GUI applications (VS Code, Docker, etc.)
#   --skip-mobile   Skip mobile development tools
#   --skip-infra    Skip infrastructure tools
#   --dry-run       Show what would be installed without installing
#   --non-interactive  Skip all prompts, use defaults
#   --git-name "Name"  Set git user name (for non-interactive mode)
#   --git-email "Email" Set git user email (for non-interactive mode)
#   --help          Show this help message
#
# Examples:
#   ./mac-setup.sh                                    # Full interactive setup
#   ./mac-setup.sh --dry-run                          # Preview what will be installed
#   ./mac-setup.sh --minimal --non-interactive        # Quick minimal setup
#   ./mac-setup.sh --git-name "John" --git-email "john@example.com"  # Pre-set git config
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration flags
INSTALL_APPS=true
INSTALL_MOBILE=true
INSTALL_INFRA=true
DRY_RUN=false
INTERACTIVE=true
GIT_NAME=""
GIT_EMAIL=""

# Help function
show_help() {
  sed -n '2,/^$/p' "$0" | sed 's/^# //' | sed 's/^#//'
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --minimal)
      INSTALL_APPS=false
      INSTALL_MOBILE=false
      INSTALL_INFRA=false
      shift
      ;;
    --skip-apps)
      INSTALL_APPS=false
      shift
      ;;
    --skip-mobile)
      INSTALL_MOBILE=false
      shift
      ;;
    --skip-infra)
      INSTALL_INFRA=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --git-name)
      GIT_NAME="$2"
      shift 2
      ;;
    --git-email)
      GIT_EMAIL="$2"
      shift 2
      ;;
    --all)
      INSTALL_APPS=true
      INSTALL_MOBILE=true
      INSTALL_INFRA=true
      shift
      ;;
    --help|-h)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Helper to ask yes/no questions (respects non-interactive mode)
ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"  # default to yes

  if [ "$INTERACTIVE" = false ]; then
    [[ "$default" =~ ^[Yy] ]] && return 0 || return 1
  fi

  local yn
  if [[ "$default" =~ ^[Yy] ]]; then
    echo -n "$prompt [Y/n]: "
  else
    echo -n "$prompt [y/N]: "
  fi
  read -r yn

  if [ -z "$yn" ]; then
    [[ "$default" =~ ^[Yy] ]] && return 0 || return 1
  fi

  [[ "$yn" =~ ^[Yy] ]] && return 0 || return 1
}

# Helper to prompt for input (respects non-interactive mode)
ask_input() {
  local prompt="$1"
  local default="$2"
  local var_name="$3"

  if [ "$INTERACTIVE" = false ]; then
    eval "$var_name=\"$default\""
    return
  fi

  if [ -n "$default" ]; then
    echo -n "$prompt [$default]: "
  else
    echo -n "$prompt: "
  fi
  read -r input
  if [ -z "$input" ]; then
    eval "$var_name=\"$default\""
  else
    eval "$var_name=\"\$input\""
  fi
}

# Helper functions
print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
  echo -e "${GREEN}▸${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN]${NC} $*"
  else
    "$@"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

brew_install() {
  local pkg_name="$1"

  # Check if already installed via brew
  if brew list "$pkg_name" &>/dev/null; then
    print_success "$pkg_name already installed (via brew)"
    return 0
  fi

  # Map package names to their binary names for fallback check
  local bin_name=""
  case "$pkg_name" in
    ripgrep)    bin_name="rg" ;;
    fd)         bin_name="fd" ;;
    neovim)     bin_name="nvim" ;;
    golang)     bin_name="go" ;;
    python@*)   bin_name="python3" ;;
    *)          bin_name="$pkg_name" ;;
  esac

  # Check if binary exists (installed via other means)
  if command_exists "$bin_name"; then
    print_success "$pkg_name already available ($bin_name in PATH)"
    return 0
  fi

  # Not found, install it
  print_step "Installing $pkg_name..."
  run_cmd brew install "$pkg_name"
}

brew_cask_install() {
  local cask_name="$1"

  # Check if already installed via brew
  if brew list --cask "$cask_name" &>/dev/null; then
    print_success "$cask_name already installed (via brew)"
    return 0
  fi

  # Map cask names to their app names in /Applications
  local app_name=""
  case "$cask_name" in
    iterm2)                 app_name="iTerm.app" ;;
    visual-studio-code)     app_name="Visual Studio Code.app" ;;
    zed)                    app_name="Zed.app" ;;
    docker)                 app_name="Docker.app" ;;
    android-studio)         app_name="Android Studio.app" ;;
    google-cloud-sdk)       app_name="Google Cloud SDK" ;;  # This is in ~/
    temurin)                app_name="" ;;  # JDK, no .app
    *)                      app_name="" ;;
  esac

  # Check if app exists in /Applications - adopt it into brew
  if [ -n "$app_name" ] && [ -d "/Applications/$app_name" ]; then
    print_step "Adopting existing $app_name into Homebrew..."
    if run_cmd brew install --cask --adopt "$cask_name" 2>/dev/null; then
      print_success "$cask_name adopted into Homebrew"
    else
      print_success "$cask_name already installed (/Applications/$app_name)"
    fi
    return 0
  fi

  # Check for JDKs (temurin)
  if [ "$cask_name" = "temurin" ]; then
    if /usr/libexec/java_home &>/dev/null; then
      print_success "$cask_name already installed (Java found)"
      return 0
    fi
  fi

  # Not found, install it
  print_step "Installing $cask_name..."
  run_cmd brew install --cask "$cask_name"
}

# ============================================================================
# XCODE COMMAND LINE TOOLS
# ============================================================================
install_xcode_cli() {
  print_header "Xcode Command Line Tools"

  if xcode-select -p &>/dev/null; then
    print_success "Xcode CLI tools already installed"
  else
    print_step "Installing Xcode Command Line Tools..."
    run_cmd xcode-select --install
    echo "Please complete the Xcode CLI installation and re-run this script."
    exit 0
  fi
}

# ============================================================================
# HOMEBREW
# ============================================================================
install_homebrew() {
  print_header "Homebrew"

  if command_exists brew; then
    print_success "Homebrew already installed"
    print_step "Updating Homebrew..."
    run_cmd brew update
  else
    print_step "Installing Homebrew..."
    run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Ensure brew is in PATH for this session
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# ============================================================================
# OH-MY-ZSH
# ============================================================================
install_ohmyzsh() {
  print_header "Oh My Zsh"

  if [ -d "$HOME/.oh-my-zsh" ]; then
    print_success "Oh My Zsh already installed"
  else
    print_step "Installing Oh My Zsh..."
    run_cmd sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  # Install plugins
  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_success "zsh-autosuggestions already installed"
  else
    print_step "Installing zsh-autosuggestions..."
    run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  fi

  if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_success "zsh-syntax-highlighting already installed"
  else
    print_step "Installing zsh-syntax-highlighting..."
    run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  fi

  if [ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    print_success "zsh-completions already installed"
  else
    print_step "Installing zsh-completions..."
    run_cmd git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
  fi
}

# ============================================================================
# TERMINAL (iTerm2)
# ============================================================================
install_iterm2() {
  print_header "Terminal (iTerm2)"

  if [ "$INSTALL_APPS" = true ]; then
    brew_cask_install iterm2
    configure_iterm2_dark_theme
  fi
}

configure_iterm2_dark_theme() {
  local profile_path="$HOME/Library/Application Support/iTerm2/DynamicProfiles/dark-profile.json"

  # Check if already configured
  if [ -f "$profile_path" ]; then
    print_success "iTerm2 dark theme already configured"
    return 0
  fi

  print_step "Configuring iTerm2 dark theme..."

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN]${NC} Would configure iTerm2 dark theme"
    return
  fi

  # Create iTerm2 dynamic profiles directory
  mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"

  # Create a dark theme profile
  cat > "$profile_path" << 'EOF'
{
  "Profiles": [
    {
      "Name": "Dark Developer",
      "Guid": "dark-developer-profile",
      "Dynamic Profile Parent Name": "Default",
      "Custom Directory": "Recycle",
      "Working Directory": "~",
      "Normal Font": "MesloLGS-NF-Regular 14",
      "Non Ascii Font": "MesloLGS-NF-Regular 14",
      "Use Non-ASCII Font": false,
      "Cursor Type": 2,
      "Cursor Color": {
        "Red Component": 0.8,
        "Green Component": 0.8,
        "Blue Component": 0.8
      },
      "Foreground Color": {
        "Red Component": 0.85,
        "Green Component": 0.85,
        "Blue Component": 0.85
      },
      "Background Color": {
        "Red Component": 0.1,
        "Green Component": 0.1,
        "Blue Component": 0.12
      },
      "Bold Color": {
        "Red Component": 1,
        "Green Component": 1,
        "Blue Component": 1
      },
      "Selection Color": {
        "Red Component": 0.3,
        "Green Component": 0.35,
        "Blue Component": 0.45
      },
      "Selected Text Color": {
        "Red Component": 1,
        "Green Component": 1,
        "Blue Component": 1
      },
      "Ansi 0 Color": {
        "Red Component": 0.15,
        "Green Component": 0.15,
        "Blue Component": 0.17
      },
      "Ansi 1 Color": {
        "Red Component": 0.9,
        "Green Component": 0.35,
        "Blue Component": 0.35
      },
      "Ansi 2 Color": {
        "Red Component": 0.35,
        "Green Component": 0.85,
        "Blue Component": 0.45
      },
      "Ansi 3 Color": {
        "Red Component": 0.95,
        "Green Component": 0.75,
        "Blue Component": 0.35
      },
      "Ansi 4 Color": {
        "Red Component": 0.4,
        "Green Component": 0.55,
        "Blue Component": 0.95
      },
      "Ansi 5 Color": {
        "Red Component": 0.85,
        "Green Component": 0.45,
        "Blue Component": 0.85
      },
      "Ansi 6 Color": {
        "Red Component": 0.35,
        "Green Component": 0.85,
        "Blue Component": 0.85
      },
      "Ansi 7 Color": {
        "Red Component": 0.85,
        "Green Component": 0.85,
        "Blue Component": 0.85
      },
      "Ansi 8 Color": {
        "Red Component": 0.45,
        "Green Component": 0.45,
        "Blue Component": 0.5
      },
      "Ansi 9 Color": {
        "Red Component": 1,
        "Green Component": 0.45,
        "Blue Component": 0.45
      },
      "Ansi 10 Color": {
        "Red Component": 0.45,
        "Green Component": 0.95,
        "Blue Component": 0.55
      },
      "Ansi 11 Color": {
        "Red Component": 1,
        "Green Component": 0.85,
        "Blue Component": 0.45
      },
      "Ansi 12 Color": {
        "Red Component": 0.5,
        "Green Component": 0.65,
        "Blue Component": 1
      },
      "Ansi 13 Color": {
        "Red Component": 0.95,
        "Green Component": 0.55,
        "Blue Component": 0.95
      },
      "Ansi 14 Color": {
        "Red Component": 0.45,
        "Green Component": 0.95,
        "Blue Component": 0.95
      },
      "Ansi 15 Color": {
        "Red Component": 1,
        "Green Component": 1,
        "Blue Component": 1
      },
      "Transparency": 0.05,
      "Blur": true,
      "Blur Radius": 10,
      "Use Bold Font": true,
      "Use Bright Bold": true,
      "Minimum Contrast": 0.1,
      "Scrollback Lines": 10000,
      "Unlimited Scrollback": false,
      "Terminal Type": "xterm-256color"
    }
  ]
}
EOF

  # Set iTerm2 preferences for dark appearance
  # Use dark tab style
  defaults write com.googlecode.iterm2 TabStyleWithAutomaticOption -int 1

  # Minimal theme
  defaults write com.googlecode.iterm2 TabStyle -int 1

  # Hide scrollbar
  defaults write com.googlecode.iterm2 HideScrollbar -bool true

  # Set the default profile to our dark profile on first launch
  defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "dark-developer-profile"

  # Disable prompt on quit
  defaults write com.googlecode.iterm2 PromptOnQuit -bool false

  # Enable status bar
  defaults write com.googlecode.iterm2 ShowFullScreenTabBar -bool false

  # Use system window restoration
  defaults write com.googlecode.iterm2 NSQuitAlwaysKeepsWindows -bool false

  print_success "iTerm2 dark theme configured"
  print_warning "Open iTerm2 and select 'Dark Developer' profile in Preferences > Profiles"
}

# ============================================================================
# EDITORS
# ============================================================================
install_editors() {
  print_header "Code Editors"

  if [ "$INSTALL_APPS" = true ]; then
    brew_cask_install visual-studio-code
    brew_cask_install zed
  fi

  brew_install neovim
}

# ============================================================================
# PROGRAMMING LANGUAGES
# ============================================================================
install_languages() {
  print_header "Programming Languages"

  # Node.js via nvm
  print_step "Setting up Node.js (via nvm)..."
  brew_install nvm
  mkdir -p ~/.nvm

  # Python via pyenv
  print_step "Setting up Python (via pyenv)..."
  brew_install pyenv
  brew_install pyenv-virtualenv

  # Go
  print_step "Setting up Go..."
  brew_install go

  # Rust (optional but useful)
  if ! command_exists rustc; then
    print_step "Installing Rust..."
    if [ "$DRY_RUN" = false ]; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    else
      echo -e "${YELLOW}[DRY RUN]${NC} curl ... | sh (rust installer)"
    fi
  else
    print_success "Rust already installed"
  fi
}

# ============================================================================
# MOBILE DEVELOPMENT
# ============================================================================
install_mobile() {
  print_header "Mobile Development (React Native)"

  brew_install watchman
  brew_install cocoapods

  if [ "$INSTALL_APPS" = true ]; then
    brew_cask_install temurin  # Java for Android
    brew_cask_install android-studio
  fi

  print_warning "After installation, open Android Studio to complete SDK setup"
  print_warning "Install Xcode from the App Store for iOS development"
}

# ============================================================================
# INFRASTRUCTURE & DEVOPS
# ============================================================================
install_infrastructure() {
  print_header "Infrastructure & DevOps Tools"

  # Docker
  if [ "$INSTALL_APPS" = true ]; then
    brew_cask_install docker
  fi

  # Kubernetes
  brew_install kubectl
  brew_install kubectx
  brew_install helm
  brew_install k9s

  # Terraform
  brew_install terraform
  brew_install terragrunt

  # Cloud CLIs
  brew_install awscli
  if [ "$INSTALL_APPS" = true ]; then
    brew_cask_install google-cloud-sdk
  fi
  brew_install azure-cli
}

# ============================================================================
# CLI UTILITIES
# ============================================================================
install_cli_tools() {
  print_header "CLI Utilities"

  # Version control
  brew_install git
  brew_install gh
  brew_install lazygit

  # Search and navigation
  brew_install fzf
  brew_install ripgrep
  brew_install fd
  brew_install zoxide
  brew_install tree

  # File viewing and processing
  brew_install bat
  brew_install eza
  brew_install jq
  brew_install yq

  # Networking
  brew_install httpie
  brew_install curl
  brew_install wget

  # System monitoring
  brew_install htop
  brew_install btop

  # Terminal multiplexer
  brew_install tmux

  # Docker TUI
  brew_install lazydocker

  # Documentation
  brew_install tldr

  # Prompt
  brew_install starship

  # Misc
  brew_install coreutils
  brew_install gnu-sed
  brew_install direnv
}

# ============================================================================
# GIT CONFIGURATION
# ============================================================================
configure_git() {
  print_header "Git Configuration"

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN]${NC} Would configure git"
    return
  fi

  # --- User Identity ---
  print_step "Configuring Git identity..."

  local current_name=$(git config --global user.name 2>/dev/null || echo "")
  local current_email=$(git config --global user.email 2>/dev/null || echo "")

  # Use command line args if provided
  if [ -n "$GIT_NAME" ]; then
    git config --global user.name "$GIT_NAME"
    print_success "Git user.name set to: $GIT_NAME"
  elif [ -z "$current_name" ]; then
    ask_input "Enter your full name for Git commits" "" git_name_input
    if [ -n "$git_name_input" ]; then
      git config --global user.name "$git_name_input"
      print_success "Git user.name set to: $git_name_input"
    else
      print_warning "Git user.name not set - configure later with: git config --global user.name \"Your Name\""
    fi
  else
    print_success "Git user.name: $current_name"
    if [ "$INTERACTIVE" = true ]; then
      if ! ask_yes_no "Keep this name?" "y"; then
        ask_input "Enter new name" "" git_name_input
        git config --global user.name "$git_name_input"
        print_success "Git user.name updated to: $git_name_input"
      fi
    fi
  fi

  # Use command line args if provided
  if [ -n "$GIT_EMAIL" ]; then
    git config --global user.email "$GIT_EMAIL"
    print_success "Git user.email set to: $GIT_EMAIL"
  elif [ -z "$current_email" ]; then
    ask_input "Enter your email for Git commits" "" git_email_input
    if [ -n "$git_email_input" ]; then
      git config --global user.email "$git_email_input"
      print_success "Git user.email set to: $git_email_input"
    else
      print_warning "Git user.email not set - configure later with: git config --global user.email \"you@example.com\""
    fi
  else
    print_success "Git user.email: $current_email"
    if [ "$INTERACTIVE" = true ]; then
      if ! ask_yes_no "Keep this email?" "y"; then
        ask_input "Enter new email" "" git_email_input
        git config --global user.email "$git_email_input"
        print_success "Git user.email updated to: $git_email_input"
      fi
    fi
  fi

  # --- Core Settings ---
  print_step "Configuring Git defaults..."

  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global push.autoSetupRemote true
  git config --global core.editor "nvim"
  git config --global core.autocrlf input
  git config --global core.ignorecase false

  # Better diff
  git config --global diff.algorithm histogram
  git config --global diff.colorMoved default

  # Merge settings
  git config --global merge.conflictstyle diff3
  git config --global merge.ff false

  # Rebase settings
  git config --global rebase.autoStash true
  git config --global rebase.autoSquash true

  # Fetch/Pull settings
  git config --global fetch.prune true
  git config --global fetch.pruneTags true

  # Better log
  git config --global log.abbrevCommit true
  git config --global log.follow true

  # Misc
  git config --global rerere.enabled true
  git config --global help.autocorrect 10
  git config --global credential.helper osxkeychain

  print_success "Git defaults configured"

  # --- Git Aliases ---
  print_step "Setting up Git aliases..."

  git config --global alias.s "status -sb"
  git config --global alias.co "checkout"
  git config --global alias.cb "checkout -b"
  git config --global alias.br "branch"
  git config --global alias.ci "commit"
  git config --global alias.cm "commit -m"
  git config --global alias.ca "commit --amend"
  git config --global alias.can "commit --amend --no-edit"
  git config --global alias.unstage "reset HEAD --"
  git config --global alias.undo "reset --soft HEAD~1"
  git config --global alias.last "log -1 HEAD --stat"
  git config --global alias.lg "log --oneline --graph --decorate -20"
  git config --global alias.lga "log --oneline --graph --decorate --all"
  git config --global alias.ll "log --pretty=format:'%C(yellow)%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' -20"
  git config --global alias.df "diff"
  git config --global alias.dfs "diff --staged"
  git config --global alias.wip "!git add -A && git commit -m 'WIP'"
  git config --global alias.unwip "reset HEAD~1"
  git config --global alias.branches "branch -a --sort=-committerdate"
  git config --global alias.tags "tag -l --sort=-version:refname"
  git config --global alias.stashes "stash list"
  git config --global alias.remotes "remote -v"
  git config --global alias.contributors "shortlog -sn --no-merges"
  git config --global alias.clean-branches "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"

  print_success "Git aliases configured"

  # --- SSH Key Setup ---
  setup_git_ssh
}

setup_git_ssh() {
  print_step "Checking SSH key for Git..."

  local ssh_key="$HOME/.ssh/id_ed25519"
  local ssh_pub="$HOME/.ssh/id_ed25519.pub"

  # Check if SSH key exists
  if [ -f "$ssh_key" ]; then
    print_success "SSH key already exists: $ssh_pub"
  else
    if ask_yes_no "Generate a new SSH key for GitHub/GitLab?" "y"; then
      local email=$(git config --global user.email)
      if [ -z "$email" ]; then
        ask_input "Enter email for SSH key" "" email
      fi

      if [ -n "$email" ]; then
        print_step "Generating SSH key..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        ssh-keygen -t ed25519 -C "$email" -f "$ssh_key" -N ""
        print_success "SSH key generated: $ssh_pub"
      else
        print_warning "Skipping SSH key generation (no email provided)"
        return
      fi
    else
      print_warning "Skipping SSH key generation"
      return
    fi
  fi

  # Start ssh-agent and add key
  if [ -f "$ssh_key" ]; then
    print_step "Configuring SSH agent..."

    # Create SSH config if it doesn't exist
    if [ ! -f "$HOME/.ssh/config" ]; then
      cat > "$HOME/.ssh/config" << 'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519
EOF
      chmod 600 "$HOME/.ssh/config"
      print_success "SSH config created"
    else
      print_success "SSH config already exists"
    fi

    # Add to keychain
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add --apple-use-keychain "$ssh_key" 2>/dev/null || ssh-add "$ssh_key" 2>/dev/null
    print_success "SSH key added to agent"

    # Show public key (only in interactive mode)
    if [ "$INTERACTIVE" = true ]; then
      echo ""
      echo -e "${BLUE}Your SSH public key:${NC}"
      echo "────────────────────────────────────────"
      cat "$ssh_pub"
      echo "────────────────────────────────────────"
      echo ""
    fi

    # Check if gh is available and authenticated
    if command_exists gh; then
      if gh auth status >/dev/null 2>&1; then
        # Check if key is already added
        local key_fingerprint=$(ssh-keygen -lf "$ssh_pub" 2>/dev/null | awk '{print $2}')
        if gh ssh-key list 2>/dev/null | grep -q "$key_fingerprint"; then
          print_success "SSH key already added to GitHub"
        elif ask_yes_no "Add this SSH key to your GitHub account?" "y"; then
          local key_title="$(hostname) - $(date +%Y-%m-%d)"
          if gh ssh-key add "$ssh_pub" --title "$key_title" 2>/dev/null; then
            print_success "SSH key added to GitHub"
          else
            print_warning "Could not add key to GitHub (may already exist)"
          fi
        fi
      elif [ "$INTERACTIVE" = true ]; then
        if ask_yes_no "Login to GitHub CLI to add SSH key automatically?" "y"; then
          gh auth login
          if gh auth status >/dev/null 2>&1; then
            local key_title="$(hostname) - $(date +%Y-%m-%d)"
            gh ssh-key add "$ssh_pub" --title "$key_title" 2>/dev/null && \
              print_success "SSH key added to GitHub"
          fi
        fi
      else
        print_warning "Run 'gh auth login' to authenticate with GitHub"
      fi
    else
      if [ "$INTERACTIVE" = true ]; then
        print_warning "Install 'gh' CLI and run 'gh auth login' to auto-add SSH key to GitHub"
        echo "Or manually add the key above to: https://github.com/settings/keys"
      fi
    fi
  fi
}

# ============================================================================
# GLOBAL GITIGNORE
# ============================================================================
configure_global_gitignore() {
  print_step "Setting up global gitignore..."

  local gitignore="$HOME/.gitignore_global"

  if [ -f "$gitignore" ]; then
    print_success "Global gitignore already exists"
    return
  fi

  cat > "$gitignore" << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes

# IDEs and Editors
.idea/
.vscode/
*.swp
*.swo
*~
.project
.classpath
.settings/
*.sublime-workspace
*.sublime-project

# Build outputs
*.o
*.so
*.dylib
*.exe
*.out
*.app
*.dSYM/

# Dependencies
node_modules/
vendor/
.bundle/

# Environment files
.env
.env.local
.env.*.local
*.local

# Logs
*.log
logs/

# Temp files
tmp/
temp/
*.tmp
*.temp

# Coverage
coverage/
.nyc_output/
htmlcov/

# Python
__pycache__/
*.py[cod]
*.egg-info/
.eggs/
*.egg
.mypy_cache/
.pytest_cache/
.tox/
venv/
.venv/

# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars

# Kubernetes
kubeconfig
EOF

  git config --global core.excludesfile "$gitignore"
  print_success "Global gitignore configured"
}

# ============================================================================
# ZSHRC CONFIGURATION
# ============================================================================
configure_zshrc() {
  print_header "Shell Configuration"

  local ZSHRC="$HOME/.zshrc"
  local MARKER="# === MAC-SETUP-SCRIPT ==="

  # Check if our config is already added
  if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    print_success "Shell configuration already added to .zshrc"
    return
  fi

  print_step "Adding configuration to .zshrc..."

  if [ "$DRY_RUN" = false ]; then
    cat >> "$ZSHRC" << 'ZSHRC_CONFIG'

# === MAC-SETUP-SCRIPT ===
# Configuration added by mac-setup.sh

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Android SDK (after Android Studio installation)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# Zoxide (better cd)
eval "$(zoxide init zsh)"

# Starship prompt
eval "$(starship init zsh)"

# Direnv
eval "$(direnv hook zsh)"

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Aliases
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

alias ls="eza"
alias ll="eza -la"
alias la="eza -la"
alias lt="eza --tree --level=2"

alias cat="bat"

alias g="git"
alias gs="git status"
alias gd="git diff"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias glog="git log --oneline --graph --decorate -20"

alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"

alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"

alias lg="lazygit"
alias ld="lazydocker"

alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"

# Quick navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Useful functions
mkcd() { mkdir -p "$1" && cd "$1"; }
ports() { lsof -i -P -n | grep LISTEN; }
weather() { curl "wttr.in/${1:-}"; }

# Oh My Zsh plugins (update your plugins line)
# plugins=(git docker kubectl terraform aws node npm python golang zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

# === END MAC-SETUP-SCRIPT ===
ZSHRC_CONFIG
  fi

  print_success "Shell configuration added"
  print_warning "Update the 'plugins' line in .zshrc to include the new plugins"
}

# ============================================================================
# POST-INSTALL STEPS
# ============================================================================
post_install() {
  print_header "Post-Installation Steps"

  # Install fzf keybindings
  if [ -f /opt/homebrew/opt/fzf/install ]; then
    print_step "Installing fzf keybindings..."
    run_cmd /opt/homebrew/opt/fzf/install --all --no-bash --no-fish
  fi

  # Install latest Node.js via nvm
  if command_exists nvm || [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    print_step "Installing latest Node.js LTS..."
    if [ "$DRY_RUN" = false ]; then
      export NVM_DIR="$HOME/.nvm"
      [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
      nvm install --lts
      nvm use --lts
      nvm alias default 'lts/*'
    fi
  fi

  # Install latest Python via pyenv
  if command_exists pyenv; then
    print_step "Installing latest Python..."
    if [ "$DRY_RUN" = false ]; then
      eval "$(pyenv init -)"
      LATEST_PYTHON=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
      pyenv install -s "$LATEST_PYTHON"
      pyenv global "$LATEST_PYTHON"
    fi
  fi

  print_success "Post-installation complete"
}

# ============================================================================
# SUMMARY
# ============================================================================
print_summary() {
  print_header "Setup Complete!"

  echo ""
  echo "Installed components:"
  echo "  - Xcode Command Line Tools"
  echo "  - Homebrew"
  echo "  - Oh My Zsh + plugins"
  echo "  - iTerm2 (with dark theme)"
  echo "  - Editors: VS Code, Zed, Neovim"
  echo "  - Languages: Node.js (nvm), Python (pyenv), Go, Rust"

  if [ "$INSTALL_MOBILE" = true ]; then
    echo "  - Mobile: React Native, Android Studio, CocoaPods"
  fi

  if [ "$INSTALL_INFRA" = true ]; then
    echo "  - Infra: Docker, Kubernetes, Terraform, Cloud CLIs"
  fi

  echo "  - CLI tools: fzf, ripgrep, bat, eza, lazygit, etc."
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Open iTerm2 and select 'Dark Developer' profile in Preferences > Profiles"
  echo "  3. Install Xcode from the App Store (for iOS development)"
  echo "  4. Open Docker Desktop and complete setup"
  echo "  5. Open Android Studio and install SDKs"
  echo "  6. Configure git credentials:"
  echo "     git config --global user.name \"Your Name\""
  echo "     git config --global user.email \"you@example.com\""
  echo ""
  echo -e "${GREEN}Happy building!${NC}"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║         Mac Development Environment Setup                ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Show current mode
  local mode_info=""
  if [ "$DRY_RUN" = true ]; then
    mode_info="${YELLOW}DRY RUN${NC}"
  elif [ "$INTERACTIVE" = false ]; then
    mode_info="${CYAN}NON-INTERACTIVE${NC}"
  else
    mode_info="${GREEN}INTERACTIVE${NC}"
  fi

  echo -e "Mode: $mode_info"
  echo -e "Apps: $([ "$INSTALL_APPS" = true ] && echo "${GREEN}Yes${NC}" || echo "${YELLOW}Skip${NC}")"
  echo -e "Mobile: $([ "$INSTALL_MOBILE" = true ] && echo "${GREEN}Yes${NC}" || echo "${YELLOW}Skip${NC}")"
  echo -e "Infra: $([ "$INSTALL_INFRA" = true ] && echo "${GREEN}Yes${NC}" || echo "${YELLOW}Skip${NC}")"
  echo ""

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}No changes will be made in dry-run mode${NC}"
    echo ""
  fi

  # Confirm before proceeding in interactive mode
  if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
    if ! ask_yes_no "Proceed with installation?" "y"; then
      echo "Setup cancelled."
      exit 0
    fi
    echo ""
  fi

  install_xcode_cli
  install_homebrew
  install_ohmyzsh
  install_iterm2
  install_editors
  install_languages

  if [ "$INSTALL_MOBILE" = true ]; then
    install_mobile
  fi

  if [ "$INSTALL_INFRA" = true ]; then
    install_infrastructure
  fi

  install_cli_tools
  configure_git
  configure_global_gitignore
  configure_zshrc
  post_install
  print_summary
}

main "$@"
