Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into self-contained [wheels](https://pythonwheels.com/) that can be installed on any system.
These wheels could potentially be uploaded to a repository (such as [pypi.org](https://pypi.org/)) to streamline the package installation for end-users.
This tool uses the [manylinux](https://github.com/pypa/manylinux) Docker image for building and bundling the required shared libraries (librmn, vgrid, libburpc, etc.).
Similarly, Windows wheels are built with the [mingw-w64](http://mingw-w64.org/doku.php) compiler inside an Ubuntu Docker container.

**Note:** This build recipe is not part of the `Python-RPN` package, and comes with no support.  Check the [Python-RPN project](https://github.com/meteokid/python-rpn) for official build recipes.

How to use
==========
First, you need to install docker.  On an Ubuntu system, you would run:
```
sudo apt-get install docker.io
```

Then, run `make` to generate the source bundle and Python wheel files for all supported platforms.
These files are saved in the `wheelhouse/` directory.

If you don't have docker installed, you could run `make sdist` to build the source bundle only.

You can try installing the wheel files on another system (or in a virtualenv) and test it out.
The easiest way to install is through `pip`:
```
pip install <filename>.whl
```

Requirements
============
This tool will automatically download a copy of [Python-RPN](https://github.com/meteokid/python-rpn), [librmn](https://github.com/armnlib/librmn), [vgrid](https://gitlab.com/ECCC_CMDN/vgrid), [libburpc](https://github.com/josecmc/libburp), and the `armnlib` headers.

Limitations
===========
This tool only builds for Linux and Windows platforms, and may not cover all
permutations of those ABI tags.
Please file a bug report if it won't work on your particular system.

There is no support for Mac OS X yet.  I don't have access to a Mac box, and
can't find any reliable tools for cross-compiling from Linux.

