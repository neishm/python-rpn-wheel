from setuptools import setup, Distribution, find_packages
import os, sys

# Add rpnpy to the search path, so we can access the version info.
sys.path.append(os.path.join('python-rpn','lib'))
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

setup (
  name = 'rpnpy',
  version = __VERSION__,
  description = 'A Python interface for the RPN libraries at Environment and Climate Change Canada',
  long_description = open(os.path.join('python-rpn','DESCRIPTION')).read(),
  url = 'https://github.com/meteokid/python-rpn',
  author = 'Stephane Chamberland',
  license = 'LGPL-2.1',
  keywords = 'rpnpy python-rpn vgrid libdescrip librmn rmnlib',
  packages = find_packages('python-rpn/lib'),
  package_dir = {'':os.path.join('python-rpn','lib')},
  install_requires = ['numpy','pytz'],
  package_data = {
    'rpnpy.librmn': ['*.so'],
    'rpnpy.vgd': ['*.so'],
  },
  distclass=BinaryDistribution
)
