---
title: makepkg
---

`makepkg` is a tool used in Arch Linux to create packages. A package
is first defined in a `PKGBUILD` file. `PKGBUILD` files are really simple.
You first define things like package names, versions etc, and then
define the functions to build the package. These usually are as simple
as

~~~ {.bash}
build() {
	make
}

package() {
	make install
}
~~~

Once you have a `PKGBUILD`, simply run makepkg in the same directory
as the `PKGBUILD` and it will go and download all the files and build
the package.

## With SVN

`makepkg` has support for building packages directly from version
control systems, including SVN. In order to make use of this simply
name your package `xxxyyy-svn` and provide a `pkgver()` function,

~~~ {.bash}
pkgver() {
	cd local_repo
	svnversion
}
~~~

This will cause `makepkg` to update its checked out copy, run the `pkgver()`
function to see if it needs to rebuild the program, then rebuild it if
required with the version set to the string output by `pkgver()`.

If you wish, you could make `pkgver()` read a version file in the repository,
or even read the svn log to determine what the version should be. However,
simply using the revision number seems kind of clean.

