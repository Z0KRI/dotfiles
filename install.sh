#!/bin/bash

set -e  # Exit on any error

# Get the directory where this script is located (the dotfiles repo root)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  
  echo -e "${BLUE}Installing $desc...${NC}"
  
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

echo -e "${BLUE}📁 Creating ~/.config directory if it doesn't exist...${NC}"
mkdir -p "$HOME/.config"

# Check if omarchy configuration exists
OMARCHY_EXISTS=false
if [[ -d "$HOME/.local/share/omarchy" ]]; then
  OMARCHY_EXISTS=true
  echo -e "${YELLOW}⚠️  Omarchy configuration detected - skipping ghostty, hyprland, rofi, waybar, btop, and cursor${NC}"
fi

# Hyprland (Linux only)
if [[ "$OMARCHY_EXISTS" == false && "$OS" == "linux" && -d "$DOTFILES_DIR/hypr" ]]; then
  create_symlink "$DOTFILES_DIR/hypr" "$HOME/.config/hypr" "Hyprland window manager config"
fi

echo -e "${BLUE} Installing dependencies... ${NC}"
sudo pacman -S cmake cpio pkgconf git gcc base-devel hyprland-headers rofi waybar --noconfirm

echo -e "${BLUE} Allowing the execution of scripts... ${NC}"
chmod +x "$DOTFILES_DIR/hypr/themes/mac/scripts/*sh"