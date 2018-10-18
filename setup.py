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
  name="fstd2nc_deps",
  version=__version__,
  description = 'Dependencies for the fstd2nc package.',
  long_description = """
Provides the Python-RPN_ package, along with the librmn_ and libdescrip_ libraries.

To access the dependencies in your own scripts, simply add the line
  import fstd2nc_deps

.. _Python-RPN: https://github.com/meteokid/python-rpn
.. _librmn: https://github.com/armnlib/librmn
.. _libdescrip: https://gitlab.com/ECCC_CMDN/vgrid
""",
  author="Mike Neish",
  license = 'LGPL-3',
  classifiers = [
    'Development Status :: 3 - Alpha',
    'Environment :: Console',
    'Intended Audience :: Science/Research',
    'License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)',
    'Operating System :: POSIX :: Linux',
    'Operating System :: Microsoft :: Windows',
    'Programming Language :: Python',
    'Topic :: Scientific/Engineering :: Atmospheric Science',
  ],
  packages = find_packages(exclude=['lib*']),
  install_requires = ['numpy','pytz'],
  package_data = {
    'fstd2nc_deps.rpnpy._sharedlibs': ['*.so','*.so.*','*.dll'],
  },
  distclass=BinaryDistribution
)

