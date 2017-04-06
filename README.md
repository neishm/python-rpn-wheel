Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into a self-contained "wheel" file that can be installed on any system.

**Note:** This is a work in progress.  It may not work perfectly out-of-the-box.

How to use
==========
These instructions assume you are on an `Ubuntu 14.04` system.

First, make sure you have all the dependencies:
```
sudo apt-get install gcc-multilib gfortran-multilib gcc-mingw-w64 gfortran-mingw-w64 perl python-virtualenv wget dpkg
```

To generate wheel files for multiple platforms, run:
```
make
```

To generate a wheel for a particular platform:
```
make PLATFORM=linux_x86_64
```

Available target platforms are `linux_x86_64`, `linux_i686`, `win_amd64`, `win32`.
You can try installing this wheel file on another system (or in a virtualenv) and test it out.
The easiest way to install is through `pip`:
```
pip install <filename>.whl
```

Requirements
============
This tool will automatically download a copy of `Python-RPN`, `librmn`, and `vgrid`.

If you're within the CMC network, then the tool will automatically copy the `env-include` package, which is needed for compiling *librmn*.  If you're not within the CMC network, then you'll need to acquire this package yourself.

Limitations
===========
This tool only builds for Linux and Windows platforms, and may not cover all
permutations of those ABI tags.
Please file a bug report if it won't work on your particular system.

There is no support for Mac OS X yet.  I don't have access to a Mac box, and
can't find any reliable tools for cross-compiling from Linux.

This tool will generate wheel files for multiple platforms, but the tool itself is designed to be used on a 64-bit `Ubuntu 14.04` system.
Other host systems have not been tested yet.

