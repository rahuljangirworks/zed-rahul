#!/usr/bin/env bash
#
# bootstrap.sh — one-command fresh-machine setup for the Zed config in this repo.
#
# What it does (idempotent, safe to re-run):
#   1. Runs ./install  -> symlinks settings/keymap/tasks into ~/.config/zed
#                         and installs the X11 wake-up workaround launcher.
#   2. Symlinks save-img-hugo into ~/.local/bin (./install only globs *.json,
#      so this helper must be linked separately).
#   3. Installs the Maple Mono NF + JetBrainsMono Nerd Font Mono fonts into
#      ~/.local/share/fonts (these are NOT tracked by git, so they must be
#      fetched on every new machine for Zed to render with the intended font).
#
# What it CANNOT do (needs sudo / an external service — it only reminds you):
#   - Install system packages:  xdotool  (X11 wake-up) and  libwebp-tools (cwebp,
#     needed by save-img-hugo). Run the printed dnf/apt command yourself.
#   - Start the local CLIProxyAPI agent proxy at 127.0.0.1:8317 — that lives
#     outside this repo; the settings already point at it.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
LOCAL_BIN_DIR="$HOME/.local/bin"
MAPLE_VER="v7.9"
NERD_VER="v3.5.1"

echo "==> [1/3] Installing Zed config (./install)"
"$SCRIPT_DIR/install"

echo
echo "==> [2/3] Linking save-img-hugo into $LOCAL_BIN_DIR"
mkdir -p "$LOCAL_BIN_DIR"
ln -sfn "$SCRIPT_DIR/save-img-hugo" "$LOCAL_BIN_DIR/save-img-hugo"
echo "Linked $LOCAL_BIN_DIR/save-img-hugo -> $SCRIPT_DIR/save-img-hugo"

echo
echo "==> [3/3] Installing fonts (Maple Mono NF + JetBrainsMono Nerd Font Mono)"
mkdir -p "$FONT_DIR"
tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

# Maple Mono NF — official build (nerd-fonts does not ship Maple Mono).
maple_url="https://github.com/subframe7536/maple-font/releases/download/${MAPLE_VER}/MapleMono-NF.zip"
if fc-list 2>/dev/null | grep -qi "Maple Mono NF"; then
  echo "Maple Mono NF already installed; skipping download."
else
  echo "Downloading Maple Mono NF ($maple_url)"
  curl -fL --retry 3 -o "$tmp/MapleMono-NF.zip" "$maple_url"
  rm -rf "$FONT_DIR/MapleMono-NF"
  mkdir -p "$FONT_DIR/MapleMono-NF"
  unzip -o -q "$tmp/MapleMono-NF.zip" -d "$FONT_DIR/MapleMono-NF"
  echo "Installed Maple Mono NF."
fi

# JetBrainsMono Nerd Font Mono — from ryanoasis/nerd-fonts.
jb_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VER}/JetBrainsMono.zip"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font Mono"; then
  echo "JetBrainsMono Nerd Font Mono already installed; skipping download."
else
  echo "Downloading JetBrainsMono Nerd Font Mono ($jb_url)"
  curl -fL --retry 3 -o "$tmp/JetBrainsMono-NF.zip" "$jb_url"
  rm -rf "$FONT_DIR/JetBrainsMono-NF"
  mkdir -p "$FONT_DIR/JetBrainsMono-NF"
  unzip -o -q "$tmp/JetBrainsMono-NF.zip" -d "$FONT_DIR/JetBrainsMono-NF"
  echo "Installed JetBrainsMono Nerd Font Mono."
fi

fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true

echo
echo "==> Done. Remaining manual steps (need sudo / external service):"
echo "  sudo dnf install -y xdotool libwebp-tools   # Fedora (x11 wake-up + cwebp)"
echo "  # or: sudo apt install -y xdotool webp      # Debian/Ubuntu"
echo "  Start your local CLIProxyAPI agent proxy (settings expect http://127.0.0.1:8317/v1)."
echo "  Then (re)start Zed to pick up the new config + fonts."
