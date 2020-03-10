from setuptools import setup, find_packages
import sys
from glob import glob
import os

# Build version file.
from subprocess import check_call
versionfile = os.path.join('python-rpn','lib','rpnpy','version.py')
makefile = os.path.join('python-rpn','include','Makefile.local.rpnpy.mk')
if os.path.exists(makefile):
  if os.path.exists(versionfile):
    os.remove(versionfile)
  check_call(['make','-f','python-rpn/include/Makefile.local.rpnpy.mk','rpnpy_version.py'], env={'rpnpy':'python-rpn'})

# Add './lib' to the search path, so we can access the version info.
sys.path.append('python-rpn/lib')

# If the shared library source is available (for librmn, etc.)
# then build the shared libraries and bundle them here.
if os.path.exists(os.path.join('python-rpn','lib','rpnpy','_sharedlibs','librmn','Makefile')):
  from rpnpy._sharedlibs import get_extra_setup_args
  extra_setup_args = get_extra_setup_args('fstd2nc_deps','rpnpy','_sharedlibs')
else:
  extra_setup_args = {}


packages = find_packages('python-rpn/lib')
packages = ['fstd2nc_deps.'+p for p in packages] + ['fstd2nc_deps']


setup (
  name="fstd2nc_deps",
  version='0.20200304.0',
  description = 'Dependencies for the fstd2nc package.',
  long_description = """
Provides the Python-RPN_ package, along with the libraries_ needed for fstd2nc.

.. _Python-RPN: https://github.com/meteokid/python-rpn
.. _libraries: https://github.com/neishm/python-rpn-libsrc
""",
  author="Mike Neish",
  license = 'LGPL-2.1',
  packages = packages,
  package_dir = {'fstd2nc_deps':'python-rpn/lib'},
  install_requires = ['numpy','pytz'],
  **extra_setup_args
)
