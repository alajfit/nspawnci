# nspawnci [![Build Status](https://travis-ci.org/localnet/nspawnci.svg?branch=master)](https://travis-ci.org/localnet/nspawnci)                                                                                                                                               
                                                                                                                                                                                                                                                                               
Use [Travis CI](https://travis-ci.org/localnet/nspawnci) for building a few [systemd-nspawn](https://www.freedesktop.org/software/systemd/man/systemd-nspawn.html) container images and deploy them to [GitHub Releases](https://github.com/localnet/nspawnci/releases) so it can be downloaded and used easily with machinectl.

## Use container

To use with [machinectl](https://www.freedesktop.org/software/systemd/man/machinectl.html) on the command line:

```
machinectl pull-tar --verify=checksum https://github.com/localnet/nspawnci/releases/download/container/{image}.tar.xz
machinectl start {image}                  # Starts the container.
machinectl shell root@{image} /bin/bash   # Get a root bash shell.
passwd                                    # Set root password.
logout                                    # Log out root bash shell.
machinectl login {image}                  # Log in the container.
```

**NOTE:** Default configuration to local time and locale of all containers is Spanish.

## Use repository

To use as custom repository in [Arch Linux](https://www.archlinux.org), add to file `/etc/pacman.conf`:

```
[nspawnci]
SigLevel = Optional TrustAll
Server = https://github.com/localnet/nspawnci/releases/download/repository
```

Then on the command line:

```
pacman -Sy            # Refresh package database.
pacman -Sl nspawnci   # Show packages in repository.
pacman -S {package}   # Install a package.
```

**NOTE:** List of currently maintained packages can change at any moment.
