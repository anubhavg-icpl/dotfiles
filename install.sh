#!/bin/bash

# Colors for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ] && [ ! -f /etc/endeavouros-release ]; then
    print_msg "This script is designed for Arch Linux and Arch-based distributions." $RED
    exit 1
fi

# Welcome message
clear
print_msg "========================================================" $BLUE
print_msg "                Dotfiles Installation Script            " $BLUE
print_msg "========================================================" $BLUE
print_msg "\nThis script will install dotfiles to your home directory.\n" $YELLOW
print_msg "It will backup your existing configurations before replacing them.\n" $YELLOW
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_msg "Installation aborted." $RED
    exit 1
fi

# Install required packages
print_msg "\nChecking and installing dependencies..." $BLUE
dependencies=(i3-wm i3blocks i3lock rofi dunst feh kitty acpi brightnessctl maim pactl scrot xbacklight zenity)

missing_deps=()
for dep in "${dependencies[@]}"; do
    if ! pacman -Qq $dep &>/dev/null; then
        missing_deps+=($dep)
    fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
    print_msg "Installing missing dependencies: ${missing_deps[*]}" $YELLOW
    sudo pacman -S --needed --noconfirm ${missing_deps[@]} || {
        print_msg "Failed to install dependencies. Please install them manually." $RED
        exit 1
    }
else
    print_msg "All dependencies are already installed." $GREEN
fi

# Create backup directory
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_dir="$HOME/.dotfiles_backup_$timestamp"
mkdir -p "$backup_dir"
print_msg "\nBackup directory created at $backup_dir" $GREEN

# Function to backup and copy files
backup_and_copy() {
    source="$1"
    dest="$2"

    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Backup if exists
    if [ -e "$dest" ]; then
        backup_path="$backup_dir$(dirname "$dest")"
        mkdir -p "$backup_path"
        mv "$dest" "$backup_path/" && print_msg "Backed up: $dest" $YELLOW
    fi

    # Copy new file
    cp -r "$source" "$dest" && print_msg "Installed: $dest" $GREEN
}

# Dotfiles location
dotfiles_dir="$(pwd)"

print_msg "\nInstalling dotfiles..." $BLUE

# Install .config files
config_dirs=("i3" "rofi")
for dir in "${config_dirs[@]}"; do
    if [ -d "$dotfiles_dir/.config/$dir" ]; then
        backup_and_copy "$dotfiles_dir/.config/$dir" "$HOME/.config/$dir"
    fi
done

# Install home directory files
home_files=(".bashrc" ".dircolors")
for file in "${home_files[@]}"; do
    if [ -f "$dotfiles_dir/$file" ]; then
        backup_and_copy "$dotfiles_dir/$file" "$HOME/$file"
    fi
done

# Make scripts executable
scripts_dirs=("$HOME/.config/i3/scripts" "$HOME/.config/i3/scripts/miei")
for dir in "${scripts_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_msg "Setting execute permissions for scripts in $dir" $BLUE
        chmod +x $dir/*.sh $dir/volume $dir/powermenu $dir/blur-lock 2>/dev/null
    fi
done

# Create wallpapers directory if needed
mkdir -p "$HOME/wallpapers"
if [ -d "$dotfiles_dir/wallpapers" ]; then
    cp -r "$dotfiles_dir/wallpapers/"* "$HOME/wallpapers/"
    print_msg "Installed wallpapers to $HOME/wallpapers/" $GREEN
else
    print_msg "No wallpapers found in dotfiles directory. Please add your own." $YELLOW
fi

# Final steps
print_msg "\nSetting i3 to start on login (if using display manager)..." $BLUE
if [ -d "/usr/share/xsessions" ]; then
    if ! grep -q "i3" ~/.xinitrc 2>/dev/null; then
        echo "exec i3" >> ~/.xinitrc && print_msg "Added 'exec i3' to ~/.xinitrc" $GREEN
    fi
else
    print_msg "Could not set up i3 autostart. Please set up manually." $YELLOW
fi

print_msg "\n========================================================" $BLUE
print_msg "                Installation Complete!                  " $GREEN
print_msg "========================================================" $BLUE
print_msg "\nYour previous configurations were backed up to: $backup_dir" $YELLOW
print_msg "\nTo start using i3, log out and select i3 at the login screen," $YELLOW
print_msg "or run 'startx' if you're not using a display manager." $YELLOW
print_msg "\nYou may need to customize some settings to match your system:" $YELLOW
print_msg "- Check monitor settings in ~/.config/i3/config" $YELLOW
print_msg "- Configure keyboard shortcuts as needed" $YELLOW
print_msg "- Adjust paths in scripts if necessary" $YELLOW
print_msg "\nEnjoy your new dotfiles setup!" $GREEN

exit 0
