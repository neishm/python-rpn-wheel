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
You'll also need `gcc-mingw-w64` and `gfortran-mingw-w64` to compile for Windows.

If you're within the CMC network, then the tool will automatically copy the `env-include` package, which is needed for compiling *librmn*.  If you're not within the CMC network, then you'll need to acquire this package yourself.

You will also need `perl`, which vgrid needs to generate its *dependencies.mk* file.

And, you'll need `python-virtualenv`, in order to build the packages with a more recent `wheel` module.

This tool will generate wheel files for multiple platforms, but the tool itself is designed to be used on a 64-bit `Ubuntu 14.04` system.

