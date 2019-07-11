Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into self-contained [wheels](https://pythonwheels.com/) that can be installed on any system.
These wheels could potentially be uploaded to a repository (such as [pypi.org](https://pypi.org/)) to streamline the package installation for end-users.
This tool uses the [manylinux](https://github.com/pypa/manylinux) Docker image for building and bundling the required shared libraries (librmn, vgrid, libburpc, etc.).
Windows wheels are cross-compiled with the [mingw-w64](http://mingw-w64.org/doku.php) compiler inside an Ubuntu Docker container.

**Note:** This build recipe is not part of the `Python-RPN` package, and comes with no support.  Check the [Python-RPN project](https://github.com/meteokid/python-rpn) for official build recipes.

How to use
==========
First, you need to install docker.  On an Ubuntu system, you would run:
```
sudo apt-get install docker.io
```

Then, run `make` to generate the source bundle and Python wheel files for all supported platforms.
These files are saved in the `wheelhouse/` directory.

If you don't have docker installed, you could run `make sdist` to build the source bundle or `make native` to build a non-portable wheel for your platform.

You can try installing the wheel files on another system (or in a virtualenv) and test it out.
The easiest way to install is through `pip`:
```
pip install <filename>.whl
```

Requirements
============
This tool will automatically download a copy of [Python-RPN](https://github.com/meteokid/python-rpn), [librmn](https://github.com/armnlib/librmn), [vgrid](https://gitlab.com/ECCC_CMDN/vgrid), [libburpc](https://github.com/josecmc/libburp), and the `armnlib` headers.

Building on other platforms
===========================
The build system is designed to run on an x86-64 Linux machine, building Linux and Windows wheels through appropriate Docker containers.

However, you should be able to build on other platforms provided you have the `gfortran` package.

On **MacOSX**, you can install `gfortran` via [Homebrew](https://brew.sh/), with the command `brew install gcc`.

On **Raspbian**, you can install `gfortran` with the command `sudo apt-get install gfortran`.

Once you have a working gfortran, you should be able to build a binary wheel with the command `make native`.

