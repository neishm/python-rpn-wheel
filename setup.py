from setuptools import setup, Distribution, find_packages

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
  name = 'fstd2nc',
  version = '0-20170427',
  description = 'Converts FSTD files (from Environment Canada) to netCDF files.',
  long_description = """
Basic usage:
  fstd2nc <fstd_file> <netcdf_file>

or
  python -m fstd2nc <fstd_file> <netcdf_file>

Use "-h" for a list of all command-line options.

This package includes an embedded copy of Python-RPN for reading the FSTD
files.
For more information on Python-RPN, see https://github.com/meteokid/python-rpn
""",
  url = 'https://github.com/neishm/pygeode-rpn/tree/fstd2nc',
  author = 'Mike Neish',
  license = 'LGPL-3',
  classifiers = [
    'Development Status :: 3 - Alpha',
    'Environment :: Console',
    'Intended Audience :: Science/Research'
    'License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)',
    'Operating System :: POSIX :: Linux',
    'Operating System :: Microsoft :: Windows'
    'Programming Language :: Python :: 2.7',
    'Topic :: Scientific/Engineering :: Atmospheric Science',
  ],
  keywords = 'fstd2nc rpnpy',
  packages = find_packages(exclude=['lib*']),
  py_modules = ['fstd2nc'],
  install_requires = ['numpy','pytz','netcdf4'],
  package_data = {
    'fstd2nc_deps.rpnpy._sharedlibs': ['*.so','*.so.*','*.dll'],
  },
  entry_points={
    'console_scripts': [
      'fstd2nc = fstd2nc:_fstd2nc_cmdline',
    ],
  },
  distclass=BinaryDistribution
)
