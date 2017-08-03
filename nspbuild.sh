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

  if [ -f "${nspcontainer}/etc/locale.gen" ]; then
    sudo sed -i -e "/^#\s*${nsplang%.*}.*/s/^#\s*//" "${nspcontainer}/etc/locale.gen"
    sudo arch-chroot ${nspcontainer} locale-gen
  fi

  echo -e "# machinectl\npts/0" | sudo tee -a "${nspcontainer}/etc/securetty"

  sudo rm -f "${nspcontainer}/etc/resolv.conf"
  sudo arch-chroot ${nspcontainer} ln -sf "/run/systemd/resolve/resolv.conf" "/etc/resolv.conf"
  sudo arch-chroot ${nspcontainer} systemctl enable "systemd-networkd" "systemd-resolved"
}

# Build and configure rootfs for Arch Linux.
rootfs_archlinux() {
  local base=$(pacman -Sqg base | sed -e "/^linux$/d" | tr "\n" " ")

  sudo pacstrap -M -c -d -i ${nspcontainer} ${base} --noconfirm

  sudo sed -i -e "\$ p" "${nspcontainer}/etc/securetty"

  rootfs_common

  sudo sed -i -e "/^#.*rackspace.*/s/^#//" "${nspcontainer}/etc/pacman.d/mirrorlist"
}

# Build and configure rootfs for Debian.
rootfs_debian() {
  local release=${nspcontainer#*-}

  sudo debootstrap --include="console-setup,dbus,locales" ${release} ${nspcontainer}

  rootfs_common

  sudo sed -i -e "\$p" -e "s/${release}/${release}-updates/" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "\$p" -e "s/deb\.\(.*\)debian\(.*\)-/security.\1\2\//" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "/.*/s/$/ contrib non-free/" "${nspcontainer}/etc/apt/sources.list"

  sudo arch-chroot ${nspcontainer} apt-get -y update
  sudo arch-chroot ${nspcontainer} env DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade
}

# Build and configure rootfs for Fedora.
rootfs_fedora() {
  local release=${nspcontainer#*-}

  curl -L -O -f "http://download.fedoraproject.org/pub/fedora/linux/releases/${release}/Everything/x86_64/os/Packages/f/fedora-repos-${release}-1.noarch.rpm"
  sudo bsdtar Jxf "fedora-repos-${release}-1.noarch.rpm" -C ${nspcontainer}
  rm -f "fedora-repos-${release}-1.noarch.rpm"

  sudo ln -sf "$(pwd)/${nspcontainer}/etc/pki" "/etc/pki"
  sudo dnf -x "NetworkManager" -y --installroot="$(pwd)/${nspcontainer}" --releasever=${release} install @core
  sudo rm -f "/etc/pki"

  rootfs_common
}

# Build and configure rootfs for Ubuntu.
rootfs_ubuntu() {
  local release=${nspcontainer#*-}

  sudo debootstrap --components="main,universe" ${release} ${nspcontainer}

  rootfs_common

  sudo sed -i -e "\$p" -e "s/${release}/${release}-updates/" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "\$p" -e "s/updates/security/" "${nspcontainer}/etc/apt/sources.list"
  sudo sed -i -e "/.*/s/$/ restricted universe/" "${nspcontainer}/etc/apt/sources.list"

  sudo arch-chroot ${nspcontainer} apt-get -y update
  sudo arch-chroot ${nspcontainer} env DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade
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
    "fedora")
      rootfs_fedora
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
for nsptraball in *".tar.xz"; do
  sha256sum ${nsptraball} >> "${nsptraball}.sha256"
done
cd ".."

{ set +ex; } 2>/dev/null
