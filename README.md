# nspawnci [![Build Status](https://travis-ci.org/localnet/nspawnci.svg?branch=master)](https://travis-ci.org/localnet/nspawnci)                                                                                                                                               
                                                                                                                                                                                                                                                                               
Use [Travis CI](https://travis-ci.org/localnet/nspawnci) for building a few [systemd-nspawn](https://www.freedesktop.org/software/systemd/man/systemd-nspawn.html) container images and deploy them to [GitHub Releases](https://github.com/localnet/nspawnci/releases) so it can be downloaded and used easily.

## Use container

To use with [machinectl](https://www.freedesktop.org/software/systemd/man/machinectl.html) on the command line:

```
machinectl pull-tar --verify=checksum https://github.com/localnet/nspawnci/releases/download/container/{image}.tar.xz
machinectl start {image}  # Container start
machinectl login {image}  # Container login
```

To set root password, after container start:

```
machinectl shell root@{image} /bin/bash
passwd
exit
```

**NOTE:** Default configuration to local time and locale of all container is Spanish.
