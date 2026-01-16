# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains a single bash script (`mac-setup.sh`) that configures a new Mac for software development. The script is idempotent - safe to run multiple times.

## Testing the Script

```bash
# Preview what would be installed (no changes made)
./mac-setup.sh --dry-run

# Run with minimal output for testing
./mac-setup.sh --minimal --non-interactive --dry-run
```

## Script Architecture

The script is organized into modular installation functions that follow a consistent pattern:

1. **Helper functions** (lines 51-223): `print_*` for output, `run_cmd` for dry-run support, `brew_install`/`brew_cask_install` for idempotent package installation
2. **Installation sections** (lines 274-1188): Each component has its own `install_*` function (xcode_cli, homebrew, ohmyzsh, iterm2, editors, languages, mobile, infrastructure, cli_tools)
3. **Configuration sections** (lines 691-1150): `configure_git`, `configure_global_gitignore`, `configure_zshrc`
4. **Main entry point** (lines 1231-1289): Parses flags, shows mode info, calls installation functions in order

Key patterns:
- All package installations check if already installed before attempting install
- GUI apps use `brew_cask_install` which can adopt existing `/Applications/*.app` into Homebrew
- The `run_cmd` wrapper enables `--dry-run` mode throughout
- Interactive prompts respect `--non-interactive` flag via `ask_yes_no` and `ask_input` helpers
