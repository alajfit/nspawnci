#!/bin/bash

set -ex

# Variables declaration.
declare -r pkgslug="${1}"
declare -r pkgtag="${2}"
declare -r pkgrepo="${1#*/}"

# Add repository aurutilsci and incude ${pkgrepo}.
sudo tee -a "/etc/pacman.conf" << EOF

[${pkgrepo}]
SigLevel = Optional TrustAll
Server = https://github.com/${pkgslug}/releases/download/${pkgtag}
EOF

# Sync repositories.
sudo pacman -Sy --noconfirm

# Install packages for create Arch Linux container image.
sudo pacman -S --needed --noconfirm arch-install-scripts

# Install packages for create Debian and Ubuntu containers images.
sudo pacman -S --noconfirm debian-archive-keyring debootstrap ubuntu-keyring

{ set +ex; } 2>/dev/null
