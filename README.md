Overview
========
The purpose of this tool is to compile and package [Python-RPN](https://github.com/meteokid/python-rpn) into a self-contained "wheel" file that can be installed on any system.

**Note:** This is a work in progress.  It may not work perfectly out-of-the-box.

How to use
==========
To generate a wheel file, run:
```
make
```

If you're lucky, this will generate some `.whl` files.
You can try installing this wheel file on another system (or in a virtualenv) and test it out.
The easiest way to install is through `pip`:
```
pip install <filename>.whl
```

Requirements
============
This tool will automatically download a copy of `Python-RPN`, `librmn`, and `vgrid`.

You'll need `gcc-multilib` and `gfortran-multilib` to compile both the 32-bit and 64-bit versions of the wheels.

If you're within the CMC network, then the tool will automatically copy the `env-include` package, which is needed for compiling *librmn*.  If you're not within the CMC network, then you'll need to acquire this package yourself.

You will also need `perl`, which vgrid needs to generate its *dependencies.mk* file.

And, you'll need `python-wheel` to create the final wheel file.

Limitations
===========
This tool is designed to be used on a Linux x86-64 system.
It has only been tested on Ubuntu 14.04 so far.

