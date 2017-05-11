Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into a self-contained "wheel" file that can be installed on any system.

**Note:** This is a work in progress.  It may not work perfectly out-of-the-box.

How to use
==========
These instructions assume you are on an `Ubuntu 14.04` system.

First, make sure you have all the dependencies:
```
sudo apt-get install docker.io gcc-mingw-w64 gfortran-mingw-w64 perl python-virtualenv wget dpkg
```

To generate wheel files for Windows, run:
```
make PLATFORM=win32
make PLATFORM=win_amd64
```

To generate a wheel for Linux, you need to run `make` from the `manylinux1` docker container.  See `docker.txt` for details on setting up the container.

The final wheel files are saved in the `wheelhouse/` directory.

You can try installing the wheel files on another system (or in a virtualenv) and test it out.
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

