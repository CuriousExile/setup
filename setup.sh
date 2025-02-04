#!/usr/bin/env bash
set -euo pipefail

# ================================
# Utility Functions
# ================================

# Log messages with a simple prefix.
log() {
  echo "[INFO] $1"
}

error() {
  echo "[ERROR] $1" >&2
  exit 1
}

# ================================
# OS Detection and Package Installation
# ================================

install_mac() {
  log "Detected macOS."

  # Check if Homebrew is installed; install it if not.
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  log "Updating Homebrew..."
  brew update

  # List of packages to install on macOS.
  # Added 'stow' along with neovim and fzf.
  packages=(neovim fzf stow)
  # You can easily add more packages to the 'packages' array.

  for pkg in "${packages[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
      log "$pkg is already installed."
    else
      log "Installing $pkg..."
      brew install "$pkg"
    fi
  done
}

install_ubuntu() {
  log "Detected Ubuntu/Debian."

  # Update apt repository.
  log "Updating apt repository..."
  sudo apt-get update

  # List of packages to install on Ubuntu/Debian.
  # Added 'stow' along with neovim and fzf.
  packages=(neovim fzf stow)
  # Extend this array to include more packages as needed.

  for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      log "$pkg is already installed."
    else
      log "Installing $pkg..."
      sudo apt-get install -y "$pkg"
    fi
  done
}

detect_and_install() {
  if [[ "$(uname)" == "Darwin" ]]; then
    install_mac
  elif [[ -f /etc/os-release ]]; then
    # Source /etc/os-release to get distribution info.
    . /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *debian* ]]; then
      install_ubuntu
    else
      error "Your Linux distribution ($ID) is not supported by this script."
    fi
  else
    error "Unsupported operating system."
  fi
}

# ================================
# Dotfiles Setup Using GNU Stow
# ================================

setup_dotfiles() {
  # Determine the directory of the current script.
  local DOTFILES_DIR
  DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

  # Assume your dotfiles are stored in a subdirectory named "dotfiles"
  # inside your repository, with each subdirectory representing a package.
  local SRC_DIR="$DOTFILES_DIR/dotfiles"

  if [[ ! -d "$SRC_DIR" ]]; then
    log "No dotfiles directory found at $SRC_DIR. Skipping dotfiles setup."
    return
  fi

  # Check that stow is installed.
  if ! command -v stow >/dev/null 2>&1; then
    error "GNU Stow is not installed. Please re-run the script after installation."
  fi

  log "Setting up dotfiles using GNU Stow..."

  # Change into the dotfiles directory.
  cd "$SRC_DIR"

  # Loop over each subdirectory in the dotfiles directory.
  # Each subdirectory should contain the configuration files for an application.
  for d in *; do
    if [[ -d "$d" ]]; then
      log "Stowing $d..."
      # The -t option tells stow to create symlinks in the target directory ($HOME).
      stow -v -t "$HOME" "$d"
    fi
  done

  # Return to the original directory.
  cd "$DOTFILES_DIR"
}

# ================================
# Main Execution
# ================================

main() {
  log "Starting environment setup..."

  # Install the necessary packages.
  detect_and_install

  # Set up dotfiles using GNU Stow.
  setup_dotfiles

  log "Environment setup complete!"
}

main
