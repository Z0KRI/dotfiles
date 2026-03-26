#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located (the dotfiles repo root)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$DOTFILES_DIR/hypr/themes/mac/scripts"

DEPENDENCIES=(cmake cpio pkgconf git gcc base-devel rofi waybar font-manager ttf-jetbrains-mono-nerd)

# Detect OS
OS="unknown"
case "$OSTYPE" in
  darwin*)  OS="mac" ;;
  linux*)   OS="linux" ;;
  *)        echo -e "${RED}Unsupported OS: $OSTYPE${NC}"; exit 1 ;;
esac

# Function to create backup
backup_file() {
  local file="$1"
  if [[ -e "$file" && ! -L "$file" ]]; then
    local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$file" "$backup_dir/"
    echo -e "${YELLOW}  Backed up existing file to: $backup_dir/$(basename "$file")${NC}"
  fi
}

# Function to create symbolic link
create_symlink() {
  local src="$1"
  local dest="$2"
  local desc="$3"
  
  echo -e "${BLUE} Installing $desc...${NC}"
  
  # Create parent directory if it doesn't exist
  mkdir -p "$(dirname "$dest")"
  
  # Backup existing file/directory if it exists and is not a symlink
  backup_file "$dest"
  
  # Remove existing symlink or file
  rm -rf "$dest"
  
  # Create the symlink
  ln -sf "$src" "$dest"
  echo -e "${GREEN}  ✓ $desc installed${NC}"
}

echo -e "${BLUE} 🔍 Checking dependencies...${NC}"
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    # pacman -Qi devuelve 0 si el paquete está instalado, 1 si no
    if ! pacman -Qi "$dep" > /dev/null 2>&1; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW} 📦 Installing missing dependencies: ${MISSING_DEPS[*]}${NC}"
    sudo pacman -S "${MISSING_DEPS[@]}" --noconfirm
else
    echo -e "${GREEN} ✓ All the units have already been installed${NC}"
fi

echo -e "${BLUE} 📁 Creating ~/.config directory if it doesn't exist...${NC}"
mkdir -p "$HOME/.config"

# Check if omarchy configuration exists
OMARCHY_EXISTS=false
if [[ -d "$HOME/.local/share/omarchy" ]]; then
  OMARCHY_EXISTS=true
  echo -e "${YELLOW} ⚠️  Omarchy configuration detected - skipping ghostty, hyprland, rofi, waybar, btop, and cursor${NC}"
fi

# Hyprland (Linux only)
if [[ "$OMARCHY_EXISTS" == false && "$OS" == "linux" && -d "$DOTFILES_DIR/hypr" ]]; then
  create_symlink "$DOTFILES_DIR/hypr" "$HOME/.config/hypr" "Hyprland window manager config"
fi

# Waybar (Linux only)
if [[ "$OMARCHY_EXISTS" == false && "$OS" == "linux" && -d "$DOTFILES_DIR/waybar" ]]; then
  create_symlink "$DOTFILES_DIR/waybar" "$HOME/.config/waybar" "Waybar config"
fi

echo -e "${BLUE} Allowing the execution of scripts... ${NC}"

if [ -d "$SCRIPT_PATH" ]; then
    # Usamos find para evitar errores si no hay archivos .sh
    find "$SCRIPT_PATH" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    echo -e "${GREEN}  ✓ Scripts permissions updated${NC}"
else
    echo -e "${YELLOW}  ⚠️  Warning: Scripts directory not found at $SCRIPT_PATH${NC}"
fi
