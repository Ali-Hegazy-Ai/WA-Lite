#!/usr/bin/env bash
#
# build.sh - Quick build script for WhatsAppLite (Linux)
#
# Automates: installing system dependencies, Node.js, pnpm, Rust, and the
# Pake CLI, then runs the final `pake` build command to produce an
# AppImage (and .deb/.rpm where applicable) for WhatsAppLite.
#
# Usage:
#   ./build.sh
#   ./build.sh --name "WhatsAppLite" --icon ./icon.png --width 1200 --height 800
#
set -euo pipefail

APP_NAME="WhatsAppLite"
ICON_PATH=""
WIDTH=1200
HEIGHT=800
URL="https://web.whatsapp.com"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) APP_NAME="$2"; shift 2 ;;
    --icon) ICON_PATH="$2"; shift 2 ;;
    --width) WIDTH="$2"; shift 2 ;;
    --height) HEIGHT="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m✔ %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m! %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. System dependencies
# ---------------------------------------------------------------------------
log "Checking system dependencies"

install_apt() {
  sudo apt update
  sudo apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file \
    libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev pkg-config \
    || sudo apt install -y libwebkit2gtk-4.0-dev build-essential curl wget file \
    libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev pkg-config
}

install_dnf() {
  sudo dnf check-update || true
  sudo dnf install -y webkit2gtk4.1-devel openssl-devel curl wget file \
    libappindicator-gtk3-devel librsvg2-devel libxdo-devel
  sudo dnf group install -y "c-development" || sudo dnf install -y gcc gcc-c++ make
}

install_pacman() {
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm webkit2gtk-4.1 base-devel curl wget file \
    openssl appmenu-gtk-module libappindicator-gtk3 librsvg xdotool
}

if command -v apt >/dev/null 2>&1; then
  install_apt
elif command -v dnf >/dev/null 2>&1; then
  install_dnf
elif command -v pacman >/dev/null 2>&1; then
  install_pacman
else
  warn "Could not detect apt, dnf, or pacman."
  warn "Install the equivalent of: webkit2gtk(-4.1)-dev, build-essential/gcc/make,"
  warn "libayatana-appindicator3-dev, librsvg2-dev, libssl-dev, libxdo-dev, pkg-config"
  warn "for your distro, then re-run this script."
fi
ok "System dependencies satisfied"

# ---------------------------------------------------------------------------
# 2. Node.js
# ---------------------------------------------------------------------------
log "Checking Node.js"
if command -v node >/dev/null 2>&1; then
  ok "Node.js already installed ($(node -v))"
else
  log "Installing Node.js 22.x via NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null \
    && sudo apt install -y nodejs \
    || warn "NodeSource install failed — install Node.js 18+ manually from https://nodejs.org, or via nvm/your package manager, then re-run."
fi

# ---------------------------------------------------------------------------
# 3. pnpm
# ---------------------------------------------------------------------------
log "Checking pnpm"

# Make sure npm's global install location is one we actually own. On many
# distro-packaged Node installs (apt, NodeSource, etc.) the global prefix is
# /usr/local, which is root-owned — so `npm install -g` fails with EACCES for
# a normal user. Rather than reflexively reaching for sudo (which then leaves
# root-owned files for npm to fight with later), point npm at a
# user-owned prefix once, persist it, and proceed without sudo.
ensure_npm_user_prefix() {
  local npm_prefix
  npm_prefix="$(npm config get prefix 2>/dev/null || echo /usr/local)"

  if [[ -w "$npm_prefix/lib/node_modules" ]] || mkdir -p "$npm_prefix/lib/node_modules" 2>/dev/null; then
    return 0
  fi

  warn "npm's global install path ($npm_prefix) isn't writable by your user."
  log "Switching npm's global prefix to ~/.npm-global (no sudo required)"
  mkdir -p "$HOME/.npm-global"
  npm config set prefix "$HOME/.npm-global"
  export PATH="$HOME/.npm-global/bin:$PATH"

  if ! grep -q '.npm-global/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    warn "Added ~/.npm-global/bin to PATH in ~/.bashrc — open a new terminal later for this to persist."
  fi
}

if command -v pnpm >/dev/null 2>&1; then
  ok "pnpm already installed ($(pnpm -v))"
else
  ensure_npm_user_prefix
  if ! npm install -g pnpm; then
    warn "Global install still failed — falling back to sudo for this one command."
    sudo npm install -g pnpm
  fi
fi

# ---------------------------------------------------------------------------
# 4. Rust
# ---------------------------------------------------------------------------
log "Checking Rust"
# Source cargo's env first (if it exists from a prior install) so the check
# below actually sees `cargo` on PATH in this fresh, non-interactive shell.
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env" || true

if command -v cargo >/dev/null 2>&1; then
  ok "Rust already installed ($(cargo --version))"
else
  log "Installing Rust via rustup"
  curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

# ---------------------------------------------------------------------------
# 5. Pake CLI
# ---------------------------------------------------------------------------
log "Checking Pake CLI"

# pnpm refuses to do a global install until its global bin dir is on PATH.
# pnpm's official convention (what `pnpm setup` itself configures) is:
#   PNPM_HOME=~/.local/share/pnpm
#   PATH=$PNPM_HOME/bin:$PATH
# Querying pnpm for this via `pnpm config get global-bin-dir` is unreliable
# across versions, so just set it the same way pnpm setup does, directly.
PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
mkdir -p "$PNPM_HOME/bin"
export PNPM_HOME
export PATH="$PNPM_HOME/bin:$PATH"

if ! grep -q "PNPM_HOME" "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ''
    echo '# pnpm global bin dir'
    echo "export PNPM_HOME=\"$PNPM_HOME\""
    echo 'export PATH="$PNPM_HOME/bin:$PATH"'
  } >> "$HOME/.bashrc"
  warn "Added PNPM_HOME to ~/.bashrc — open a new terminal later for this to persist."
fi

if command -v pake >/dev/null 2>&1; then
  ok "Pake CLI already installed ($(pake --version))"
else
  pnpm install -g pake-cli
  # Make sure pnpm's global bin is on PATH for the rest of this script
  export PATH="$PNPM_HOME/bin:$PATH"
fi

if ! command -v pake >/dev/null 2>&1; then
  warn "pake not found on PATH yet. Try: pnpm setup && source ~/.bashrc (or restart your terminal), then re-run this script."
  exit 1
fi

# ---------------------------------------------------------------------------
# 6. Build
# ---------------------------------------------------------------------------
log "Building $APP_NAME"

BUILD_ARGS=(--name "$APP_NAME" --width "$WIDTH" --height "$HEIGHT")
if [[ -n "$ICON_PATH" ]]; then
  BUILD_ARGS+=(--icon "$ICON_PATH")
fi

pake "$URL" "${BUILD_ARGS[@]}"

ok "Build complete — look for the .AppImage / .deb / .rpm in this folder."
