#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a new machine from zero to fully configured.
# Works on macOS (Apple Silicon) and Linux (x86_64).
#
# Usage:
#   git clone https://github.com/mmcguffi/dotfiles.git ~/dotfiles
#   cd ~/dotfiles
#   ./bootstrap.sh

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Detecting platform..."
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS-$ARCH" in
  Darwin-arm64)  SYSTEM="aarch64-darwin" ;;
  Linux-x86_64)  SYSTEM="x86_64-linux" ;;
  *) echo "ERROR: Unsupported platform $OS-$ARCH"; exit 1 ;;
esac

echo "    Platform: $OS $ARCH ($SYSTEM)"
echo

# --- User config ---
USER_NIX="$DOTFILES_DIR/user.nix"
if [[ ! -f "$USER_NIX" ]] || grep -q 'username = "your-username"' "$USER_NIX" 2>/dev/null; then
  echo "==> First-time setup: configuring identity"
  echo

  default_username="$(whoami)"
  read -rp "    Username [$default_username]: " input_username
  USERNAME="${input_username:-$default_username}"

  read -rp "    Full name (for git): " FULL_NAME
  read -rp "    Email (for git): " EMAIL

  cat > "$USER_NIX" <<EOF
{
  username = "$USERNAME";
  fullName = "$FULL_NAME";
  email = "$EMAIL";
}
EOF
  echo
  echo "    Wrote $USER_NIX"
  echo
else
  echo "==> Using existing user.nix:"
  echo "    $(grep 'username' "$USER_NIX" | sed 's/.*= "//;s/".*//')"
  echo "    $(grep 'email' "$USER_NIX" | sed 's/.*= "//;s/".*//')"
  echo "    Edit $USER_NIX to change identity"
  echo
fi

# Read username from user.nix for flake target
USERNAME=$(grep 'username' "$USER_NIX" | sed 's/.*= "//;s/".*//')

case "$SYSTEM" in
  aarch64-darwin) FLAKE_TARGET="$USERNAME" ;;
  x86_64-linux)   FLAKE_TARGET="$USERNAME@linux" ;;
esac

echo "    Flake target: $FLAKE_TARGET"
echo

# --- Install Nix ---
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo
  echo "    Nix installed. You may need to restart your shell or run:"
  echo "    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  echo
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi
else
  echo "==> Nix already installed: $(nix --version)"
fi

# --- Enable flakes ---
mkdir -p ~/.config/nix
if ! grep -q "experimental-features.*flakes" ~/.config/nix/nix.conf 2>/dev/null; then
  echo "==> Enabling Nix flakes..."
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# --- Run home-manager ---
echo "==> Applying home-manager configuration..."
echo "    (this may take a few minutes on first run as packages are fetched)"
echo

nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/home-manager -- switch --flake "$DOTFILES_DIR#$FLAKE_TARGET"

# --- macOS: Homebrew for casks and tap-only tools ---
if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  echo "==> Installing macOS casks and tap tools via Homebrew..."
  brew bundle --file="$DOTFILES_DIR/configs/Brewfile"
fi

echo
echo "==> Done! Your environment is configured."
echo
echo "    Next steps:"
echo "    1. Copy configs/env.local.example to ~/.env.local and fill in secrets"
echo "    2. Restart your shell (or run: exec zsh)"
echo
echo "    To update after changing configs:"
echo "      home-manager switch --flake $DOTFILES_DIR"
