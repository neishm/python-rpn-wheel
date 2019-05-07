Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into a self-contained "wheel" file that can be installed on any system.

How to use
==========
First, you need to install docker.  On an Ubuntu system, you would run:
```
sudo apt-get install docker.io
```

Then, run `make` to generate the Python wheel files for all supported platforms.
These files are saved in the `wheelhouse/` directory.

You can try installing the wheel files on another system (or in a virtualenv) and test it out.
The easiest way to install is through `pip`:
```
pip install <filename>.whl
```

Requirements
============
This tool will automatically download a copy of [Python-RPN](https://github.com/meteokid/python-rpn), [librmn](https://github.com/armnlib/librmn), [vgrid](https://gitlab.com/ECCC_CMDN/vgrid), `libburpc`, [code-tools](https://github.com/mfvalin/code-tools), and `armnlib`.

Limitations
===========
This tool only builds for Linux and Windows platforms, and may not cover all
permutations of those ABI tags.
Please file a bug report if it won't work on your particular system.

There is no support for Mac OS X yet.  I don't have access to a Mac box, and
can't find any reliable tools for cross-compiling from Linux.

