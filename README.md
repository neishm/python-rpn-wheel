Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into a self-contained "wheel" file that can be installed on any system.

**Note:** This is a work in progress.  It may not work perfectly out-of-the-box.

How to use
==========
First, you need to install docker.  On an Ubuntu system, you would run:
```
sudo apt-get install docker.io
```

Before you can compile, you'll need to grab a copy of `env-include`:
```
git clone joule:/home/dormrb02/GIT-depots/env-include.git
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
This tool will automatically download a copy of `Python-RPN`, `librmn`, `vgrid`, and `libburpc`.

Limitations
===========
This tool only builds for Linux and Windows platforms, and may not cover all
permutations of those ABI tags.
Please file a bug report if it won't work on your particular system.

There is no support for Mac OS X yet.  I don't have access to a Mac box, and
can't find any reliable tools for cross-compiling from Linux.

