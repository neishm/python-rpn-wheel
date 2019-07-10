from setuptools import setup, Distribution, find_packages
from distutils.command.build import build
import sys
from glob import glob

# Add './lib' to the search path, so we can access the version info.
sys.path.append('lib')
from rpnpy.version import __VERSION__

# Need to force Python to treat this as a binary distribution.
# We don't have any binary extension modules, but we do have shared
# libraries that are architecture-specific.
# http://stackoverflow.com/questions/24071491/how-can-i-make-a-python-wheel-from-an-existing-native-library
class BinaryDistribution(Distribution):
  def has_ext_modules(self):
    return True
  def is_pure(self):
    return False

# Need to invoke the Makefile from the src/ directory to build the shared
# libraries.
class BuildSharedLibs(build):
  def run(self):
    import os
    from subprocess import check_call
    import platform

    build.run(self)
    builddir = os.path.abspath(self.build_temp)
    sharedlib_dir = os.path.join(self.build_lib,'rpnpy','_sharedlibs')
    sharedlib_dir = os.path.abspath(sharedlib_dir)
    self.copy_tree('src',builddir)

    if 'SHAREDLIB_SUFFIX' in os.environ:
      sharedlib_suffix = os.environ['SHAREDLIB_SUFFIX']
    else:
      sharedlib_suffix = {
      'Linux': 'so',
      'Windows': 'dll',
      'Darwin': 'dylib',
    }[platform.system()]

    check_call(['make', 'BUILDDIR='+builddir, 'SHAREDLIB_DIR='+sharedlib_dir, 'SHAREDLIB_SUFFIX='+sharedlib_suffix], cwd=builddir)


setup (
  name = 'eccc_rpnpy',
  version = __VERSION__,
  description = 'A Python interface for the RPN libraries at Environment and Climate Change Canada',
  long_description = open('DESCRIPTION').read(),
  url = 'https://github.com/meteokid/python-rpn',
  author = 'Stephane Chamberland',
  license = 'LGPL-2.1',
  keywords = 'rpnpy python-rpn vgrid libdescrip librmn rmnlib',
  packages = find_packages('lib'),
  py_modules = ['Fstdc','rpn_helpers','rpnstd'],
  scripts = glob('bin/rpy.*'),
  package_dir = {'':'lib'},
  install_requires = ['numpy','pytz'],
  package_data = {
    'rpnpy._sharedlibs': ['*.so','*.so.*','*.dll','*.dylib'],
    'rpnpy.librmn.share': ['table_b_bufr_e'],
  },
  distclass=BinaryDistribution,
  cmdclass={'build': BuildSharedLibs},
)
