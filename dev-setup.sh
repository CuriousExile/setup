#!/usr/bin/env bash
set -e

###############################################################################
# Detect OS / Package Manager
###############################################################################
if command -v apt-get &>/dev/null; then
    PM="apt"
elif command -v pacman &>/dev/null; then
    PM="pacman"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PM="brew"
else
    echo "Unsupported OS."
    exit 1
fi

echo "Using package manager: $PM"

###############################################################################
# Install common packages using the appropriate package manager
###############################################################################
if [ "$PM" = "apt" ]; then
    echo "[apt] Enabling universe repository (if not already enabled)..."
    sudo add-apt-repository -y universe
    echo "[apt] Updating package lists..."
    sudo apt-get update
    # Optional: upgrade your system packages (uncomment the next line if desired)
    # sudo apt-get upgrade -y
    echo "[apt] Installing packages..."
    # Note: We removed awscli from the apt install list since it’s not available.
    sudo apt-get install -y \
         git \
         neovim \
         luarocks \
         golang \
         build-essential \
         tmux \
         fzf \
         xclip \
         stow \
         zsh \
         bat \
         jq \
         ripgrep \
         default-jdk \
         docker.io \
         zoxide \
         eva

    # Install AWS CLI v2 via the official installer if it's not already installed.
    if ! command -v aws &>/dev/null; then
        echo "[apt] Installing AWS CLI v2 via official installer..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf awscliv2.zip aws
    else
        echo "[apt] AWS CLI is already installed."
    fi

elif [ "$PM" = "pacman" ]; then
    echo "[pacman] Updating and installing packages..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm \
         git \
         neovim \
         luarocks \
         go \
         base-devel \
         tmux \
         aws-cli \
         fzf \
         xclip \
         stow \
         zsh \
         bat \
         jq \
         ripgrep \
         docker \
         zoxide \
         eva
elif [ "$PM" = "brew" ]; then
    echo "[brew] Updating Homebrew..."
    brew update
    echo "[brew] Installing packages..."
    brew install \
         git \
         neovim \
         luarocks \
         go \
         tmux \
         awscli \
         fzf \
         stow \
         zsh \
         bat \
         jq \
         ripgrep \
         zoxide \
         eva
    echo "[brew] Installing Docker (via cask)..."
    brew install --cask docker

    # For build tools on macOS, ensure Xcode Command Line Tools are installed.
    if ! xcode-select -p &>/dev/null; then
        echo "Xcode Command Line Tools not found. Installing…"
        xcode-select --install
    fi
fi

###############################################################################
# Install Nerd Font (FiraCode Nerd Font)
###############################################################################
install_nerdfont() {
    echo "Installing Nerd Font (FiraCode Nerd Font)..."
    if [ "$PM" = "apt" ] || [ "$PM" = "pacman" ]; then
         FONT_DIR="$HOME/.local/share/fonts"
         mkdir -p "$FONT_DIR"
         TMP_ZIP=$(mktemp /tmp/firacode.zip.XXXXXX)
         # Download FiraCode Nerd Font (version v2.3.3 – update as needed)
         curl -L -o "$TMP_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/FiraCode.zip
         unzip -o "$TMP_ZIP" -d "$FONT_DIR"
         rm "$TMP_ZIP"
         # Refresh the font cache (Linux)
         if command -v fc-cache &>/dev/null; then
             fc-cache -fv
         fi
    elif [ "$PM" = "brew" ]; then
         brew tap homebrew/cask-fonts
         brew install --cask font-fira-code-nerd-font
    fi
}
install_nerdfont

###############################################################################
# Install nvm (Node Version Manager)
###############################################################################
install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo "nvm is already installed."
    else
        echo "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        # Load nvm into the current shell session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
}
install_nvm

# Ensure nvm is loaded (for non-interactive shells)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

###############################################################################
# Install latest Node.js and global npm packages (@angular/cli and yarn)
###############################################################################
echo "Installing latest Node.js via nvm…"
nvm install node

echo "Installing global npm packages: @angular/cli and yarn…"
npm install -g @angular/cli yarn

###############################################################################
# Install eza (a modern replacement for ls)
###############################################################################
install_eza() {
    if [ "$PM" = "apt" ]; then
        # eza is not in the standard Debian repos – install via cargo.
        if ! command -v cargo &>/dev/null; then
            echo "Rust/Cargo not found. Installing Rust toolchain…"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            export PATH="$HOME/.cargo/bin:$PATH"
        fi
        echo "Installing eza via cargo…"
        cargo install eza
    elif [ "$PM" = "pacman" ]; then
        sudo pacman -S --noconfirm eza
    elif [ "$PM" = "brew" ]; then
        brew install eza
    fi
}
install_eza

###############################################################################
# Install lazygit
###############################################################################
install_lazygit() {
    if [ "$PM" = "apt" ]; then
        echo "Installing lazygit via go…"
        go install github.com/jesseduffield/lazygit@latest
    elif [ "$PM" = "pacman" ]; then
        sudo pacman -S --noconfirm lazygit
    elif [ "$PM" = "brew" ]; then
        brew install lazygit
    fi
}
install_lazygit

###############################################################################
# Install lazydocker
###############################################################################
install_lazydocker() {
    if [ "$PM" = "apt" ]; then
        echo "Installing lazydocker via go…"
        go install github.com/jesseduffield/lazydocker@latest
    elif [ "$PM" = "pacman" ]; then
        sudo pacman -S --noconfirm lazydocker
    elif [ "$PM" = "brew" ]; then
        brew install lazydocker
    fi
}
install_lazydocker

###############################################################################
# Final message
###############################################################################
echo "============================================="
echo "Development environment setup complete!"
echo ""
echo "Reminder: If you installed tools via Go or Cargo (such as lazygit, lazydocker, or eza),"
echo "you may need to add the following directories to your PATH:"
echo "    \$HOME/go/bin"
echo "    \$HOME/.cargo/bin"
echo "============================================="
