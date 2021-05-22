---
title: Running ARM executables on x86
---

# Preamble

This is an old note that I found lying around on my hard drive.  It may
not be accurate. I have added as much background around it as I can
remember, but the original was just 4 lines of shell script.

The original purpose for this was to build an ARM cross compiler
environment that would run on my fast x86 machine. The target platform
had limited memory and disk capacity, and was not capabale of even having
GCC installed. I ended up setting up an ARM chroot within which I could
run ARM executables. I didn't go for fully blown virtualisation because
I wanted to substitute commonly used binaries for native x86 ones. I
substituted GCC for a cross-compiling GCC, and I substituted `tar`. This
meant that cross-compiling a project that executed intermediate results
would still work. For example, when compiling Python, the initial
interpreter is built using GCC, this interpreter is then executed to
coordinate the rest of the build. Without the ability to run arbitrary
ARM executables, the cross compile phase would have stopped here, unable
to run the Python executable it had just built with our cross compiler.

I *strongly* recommend *NOT* using this approach for cross compiling
code. It works really well, reall fast, about 90% of the time, but a
lot of subtle issues can crop up. Instead do one of the following:

* If your target has enough grunt to do basic tasks, and you
  are only compiling C/C++ projects, try using `distcc`.

* Just emulate the whole system. Build times may go up, but you
  will save time in the long run not having to deal with bizarre
  issues.

# The Instructions

The Linux kernel has a special feature called `binfmt_misc`
which allows you to register user-space programs as interpreters
for files that you attempt to execute, similar how `#!` is used,
only more flexible.

These instructions are for getting the kernel to run ARM binaries
using QEMU from within an ARM chroot. We use the static version
of QEMU so that it is easy to get running in the chroot we will
be using, which is going to contain mostly ARM libraries and
executables.

The following command regesters `qemu-arm-static` as the interpreter for
any files that contain the specified magic number. This sequence of
bytes is present in ELF files which target ARM.

```
echo ":qemu-arm-static:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00::/usr/bin/qemu-arm-static:" > /proc/sys/fs/binfmt_misc/register
```

You will also need to register `qemu-arm-static-ld-so` for certain file
types.

```
echo ":qemu-arm-static-ld-so:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x28\x00::/usr/bin/qemu-arm-static:" > /proc/sys/fs/binfmt_misc/register
```

Then make sure that `qemu-arm-static` and friends also exist in your chroot in the correct locations.

```
# This is what I wrote down many years ago. I hope
# that if I find myself needing to do this again,
# I will understand what I meant and where to copy things to.
Copy libc.so.*
Copy ld-linux-x86-64.*
Copy /usr/x86-64-unknown-linux-gnu/arm-lin.... *
```


