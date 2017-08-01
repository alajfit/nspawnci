#!/bin/bash

set -ex

# Variables declaration.
declare -a nsplist=()
declare -l nspcontainer=""
declare -r nsplocaltime=${1}
declare -r nspkeymap=${2}
declare -r nsplang=${3}

# Common configuration for all rootfs.
rootfs_common() {
  sudo arch-chroot ${nspcontainer} ln -sf "/usr/share/zoneinfo/${nsplocaltime}" "/etc/localtime"

  sudo tee -a "${nspcontainer}/etc/vconsole.conf" <<< "KEYMAP=${nspkeymap}"
  sudo tee -a "${nspcontainer}/etc/locale.conf" <<< "LANG=${nsplang}"
  sudo sed -i -e "/^#\s*${nsplang%.*}.*/s/^#\s*//" "${nspcontainer}/etc/locale.gen"
  sudo arch-chroot ${nspcontainer} locale-gen

  sudo rm "${nspcontainer}/etc/resolv.conf"
  sudo arch-chroot ${nspcontainer} ln -sf "/run/systemd/resolve/resolv.conf" "/etc/resolv.conf"
  sudo arch-chroot ${nspcontainer} systemctl enable "systemd-networkd" "systemd-resolved"
}

# Build and configure rootfs for Arch Linux.
rootfs_archlinux() {
  sudo pacstrap -M -c -d -i ${nspcontainer} "base" --noconfirm
  sudo arch-chroot ${nspcontainer} pacman -Rscn --noconfirm "linux"

  sudo sed -i -e "/^#.*rackspace.*/s/^#//" "${nspcontainer}/etc/pacman.d/mirrorlist"

  sudo sed -i -e "\$ipts/0\n" "${nspcontainer}/etc/securetty"

  rootfs_common
}

# Build and configure rootfs for Debian.
rootfs_debian() {
  local release=${nspcontainer#*-}

  sudo debootstrap --include="console-setup,dbus,locales" ${release} ${nspcontainer}

  sudo sed -i -e "\$p" -e "s/${release}/${release}-updates/" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "\$p" -e "s/deb\.\(.*\)debian\(.*\)-/security.\1\2\//" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "/.*/s/$/ contrib non-free/" "${nspcontainer}/etc/apt/sources.list"

  sudo sed -i -e "\$a\\\n# machinectl\npts/0" "${nspcontainer}/etc/securetty"

  rootfs_common
}

# Build and configure rootfs for Ubuntu.
rootfs_ubuntu() {
  local release=${nspcontainer#*-}

  sudo debootstrap ${release} ${nspcontainer}

  sudo sed -i -e "\$p" -e "s/${release}/${release}-updates/" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "\$p" -e "s/updates/security/" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "/.*/s/$/ restricted universe/" "${nspcontainer}/etc/apt/sources.list"

  sudo sed -i -e "\$a\\\n# machinectl\npts/0" "${nspcontainer}/etc/securetty"

  rootfs_common
}

# Remove comments or blank lines.
sed -i -e "/\s*#.*/s/\s*#.*//" -e "/^\s*$/d" "nsplist"

# Load files.
mapfile nsplist < "nsplist"

# Generate rootfs and tarball.
cd "rootfs"
for nspcontainer in ${nsplist[@]}; do
  mkdir -p ${nspcontainer}
  case ${nspcontainer%-*} in
    "archlinux")
      rootfs_archlinux
      ;;
    "debian")
      rootfs_debian
      ;;
    "ubuntu")
      rootfs_ubuntu
      ;;
  esac
  cd ${nspcontainer}
  sudo bsdtar Jcf "../../tarball/${nspcontainer}.tar.xz" "."
  cd ".."
done
cd ".."

# Generate tarball sha256sum.
cd "tarball"
sha256sum *".tar.xz" > "SHA256SUMS"
cd ".."

{ set +ex; } 2>/dev/null
