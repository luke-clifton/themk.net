---
title: ARM Development Environment
---

> I would *NOT* recommend this approach to cross-compilation.
> It can cause serious pain and madness, as well as a sudden
> and irretrievable loss of time.
>
> Just suck it up and emulate fully if that is what you need
> to do.

The development environment set up is designed to emulate compilation
on the actual ARM environment as much as possible. The reasoning behind this
is the unfortunate tendency of software writers to not take alternate
platforms into consideration, and rarely provide an adequate solution
for cross compiling their software.

To achieve this goal we use proot, a user space implementation of
chroot, bind, mount and binfmt_misc. These tools allow us to create
a root environment that can use QEMU for emulating an ARM CPU, giving
us the capability to run ARM binaries. The bind and mount capabilities
allow us to push our native binaries into the environment, allowing
us to use a native cross-compiling gcc to provide speed. The fake
chroot lets the executables think that they exist within a contained
environment.

The reason why we do not simply compile all software on the ARM device,
or a fully blown ARM virtualised system, is that these environments
under-perform, or run out of system resources. The reason that our new
system does not suffer from this is that we can compile certain often
used programs natively, and get the full performance required.


## Setting up the Development Environment

Use your systems package manager to install qemu-user, bsdtar, proot,
and arm-linux-gnueabi-gcc

(debian/ubuntu users, there is a separate repository that you need
 to enable to get proot)

    # apt-get install gcc-arm-linux-gnueabi qemu-user proot bsdtar

Extract the def-rootfs.tar.bz2 image to where you want it.

    $ mkdir ~/my_dev_env
    $ cd ~/my_dev_env
    $ tar xvf /path/to/def-rootfs.tar.bz2
    $ cd

Make sure your scripts directory is in your $PATH.

Take a look at the dev-chroot script and make sure the scripts variable
is set up correctly. It should point to the scripts directory in the dev-env
svn repository.

Then you can chroot in with

    $ dev-chroot ~/my_dev_env

If you need to be a root user in the environment use

    $ dev-chroot ~/my_dev_env -0

You can now install and build packages.

You may wish to look into /etc/makepkg.conf to tune some variables.
Specific things may be removing the documentation from built packages.

## Further Reading

The Arch Wiki is a useful guide.

https://wiki.archlinux.org/

https://wiki.archlinux.org/index.php/ABS
https://wiki.archlinux.org/index.php/Pacbuilder

## Known Issues and Workarounds

### I need root access, but sudo does not work

The sudo program requires that various permission bits and ownerships
are set in a particular way. Because this is an unprivileged setup,
these bits are all wrong. If you need to get root access to the system
use

    $ dev-chroot ~/my_dev_env -0

This will make the programs think that you are root, and will usually let
you do what you wanted to do.

### Permissions and security

Sometime PKGBUILDS fail in the `check' step, often in tests to
do with authentication. Authentication is an issue in the development
environment because everything is being faked. Use makepkg with the
option --nocheck to prevent this. Tests can be performed on the target
at a later date.

### PKGBUILD fails in the package stage

PKGBUILDs often install files into the package as particular users.
This is especially true for daemon programs ("http" user). By
default the root environment uses your systems /etc/passwd which
may not contain the same users as is expected by Arch Linux and the
PKGBUILDS. To fix this, simply add a user to your system with

    # useradd http

### Qemu is not perfect.

Some applications might not like qemu (bsdtar is one of them). If you need
an application to run and qemu is crashing, try using the native version
instead.

    $ dev-chroot ~/my_dev_env -b /usr/bin/bsdtar

This will cause any access to /usr/bin/bsdtar in the environment to go to
/usr/bin/bsdtar in the host.

If you don't want to do it that way, you can also access your host rootfs
at /host-rootfs.

    $ /host-rootfs/usr/bin/bsdtar


