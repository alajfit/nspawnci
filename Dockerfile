FROM archimg/base-devel

# Update packages.
RUN pacman -Syu --noconfirm

# Clear cache.
RUN pacman -Scc --noconfirm

# Create an unprivileged user.
RUN useradd -m -G wheel -s /bin/bash nspuser

# Grant group wheel sudo rights without password.
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

# https://wiki.archlinux.org/index.php/Install_from_existing_Linux#.2Fdev.2Fshm
RUN mkdir -p /run/shm

# Set user.
USER nspuser

# Set working dir.
WORKDIR /home/nspuser

# Create dirs.
RUN mkdir rootfs tarball
