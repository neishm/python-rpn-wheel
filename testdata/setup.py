# Generate portable test files from the full suite.

files_in_progress = set()
def inout (env, *path):
  from os.path import join, dirname, exists, sep
  from os import makedirs, environ, remove
  from pathlib import Path
  infile = join(environ[env], *path)
  outfile = join(dirname(__file__), 'rpnpy_tests', env, *path)
  outdir = dirname(outfile)
  makedirs(outdir, exist_ok=True)
  print ('->', outfile)
  if exists(outfile) and outfile not in files_in_progress:
    remove(outfile)
  files_in_progress.add(outfile)
  # Treat each subdirectory as a Python sub-package.
  while outdir != '':
    Path(outdir,'__init__.py').touch()
    outdir = dirname(outdir)
  return infile, outfile

def simple_copy (env, *path):
  from shutil import copy
  infile, outfile = inout(env, *path)
  copy(infile, outfile)

def fst_copy (env, *path, **kwargs):
  import rpnpy.librmn.all as rmn
  from os.path import exists
  from scipy.ndimage.fourier import fourier_uniform
  # Smooth the field(s)?
  smoothed = kwargs.pop('smoothed',False)
  # Use single (flat) value for the field(s)?
  flat = kwargs.pop('flat',False)
  # Similar to above, but only apply to 3D field(s)?
  flat_3d = kwargs.pop('flat3d',False)
  # Apply compression to the field(s)?
  compressed = kwargs.pop('compressed',True)
  infile, outfile = inout(env, *path)
  inunit = rmn.fstopenall(infile, rmn.FST_RO)
  if exists(outfile):
    outunit = rmn.fstopenall(outfile, rmn.FST_RW_OLD)
  else:
    outunit = rmn.fstopenall(outfile, rmn.FST_RW)
  for key in rmn.fstinl(inunit, **kwargs):
    rec = rmn.fstluk(key)
    if smoothed:
      rec['d'] = fourier_uniform(rec['d'].transpose(),size=(rec['nj']-10,rec['ni']-5)).transpose()
    elif flat:
      rec['d'][:] = rec['d'].mean()
    elif flat_3d and rec['ip1'] != 0:
      rec['d'][:] = rec['d'].mean()
    if compressed and rec['datyp'] < 128 and rec['ni']*rec['nj'] > 9999:
      # Compression is lossy on datyp=1???
      if rec['datyp'] == 1:
        rec['datyp'] = 6
      rec['datyp'] += 128
    rmn.fstecr(outunit, rec)
  rmn.fstcloseall(outunit)
  rmn.fstcloseall(inunit)

"""
ATM_MODEL_DFILES=$(PWD)/cache/gem-data_4.2.0_all/share/data/dfiles
AFSISIO=$(PWD)/cache/afsisio_1.0u_all/data/
CMCGRIDF=$(PWD)/cache/cmcgridf

${ATM_MODEL_DFILES}/bcmk_burp/2007021900.brp
${ATM_MODEL_DFILES}/bcmk/* - need TT data for ip2=12 and ip2=2, some UU/VV and 26 levels of VF.
-> use climato for ip2=2?
${ATM_MODEL_DFILES}/bcmk_p/anlp2015070706_000 - TT data for ip1 = 500mb
${ATM_MODEL_DFILES}/bcmk/geophy.fst
${ATM_MODEL_DFILES}/bcmk/2009042700_000
${ATM_MODEL_DFILES}/bcmk/2009042700_012 - any data?  need exactly 1083 records though.  Also need P0, TT, MX, LA, LO
${CMCGRIDF}/prog/regeta/YYYYMMDD00_048 - vertical grid, TT at ip2=48
${HOME}/.profile
"""

from setuptools.command.sdist import sdist
class GetData(sdist):
  def run(self):
    simple_copy('ATM_MODEL_DFILES','bcmk_burp','2007021900.brp')

    fst_copy('ATM_MODEL_DFILES','bcmk_p','anlp2015070706_000',nomvar='^^')
    fst_copy('ATM_MODEL_DFILES','bcmk_p','anlp2015070706_000',nomvar='>>')
    fst_copy('ATM_MODEL_DFILES','bcmk_p','anlp2015070706_000',nomvar='TT',ip1=500)

    fst_copy('ATM_MODEL_DFILES','bcmk','geophy.fst')

    fst_copy('ATM_MODEL_DFILES','bcmk_toctoc','2009042700_000',nomvar='^^')
    fst_copy('ATM_MODEL_DFILES','bcmk_toctoc','2009042700_000',nomvar='>>')
    fst_copy('ATM_MODEL_DFILES','bcmk_toctoc','2009042700_000',nomvar='!!')
    fst_copy('ATM_MODEL_DFILES','bcmk_toctoc','2009042700_000',nomvar='HY')
    fst_copy('ATM_MODEL_DFILES','bcmk_toctoc','2009042700_000',nomvar='P0')

    fst_copy('ATM_MODEL_DFILES','bcmk','2009042700_000',flat3d=True,compressed=True)
    fst_copy('ATM_MODEL_DFILES','bcmk','2009042700_012',flat3d=True,compressed=True)

    fst_copy('ATM_MODEL_DFILES','bcmk_vgrid','21001_SLEVE')
    fst_copy('ATM_MODEL_DFILES','bcmk_vgrid','21002_SLEVE')

    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='^^')
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='>>')
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='!!')
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='P0')
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='PT')
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='TT',flat=True)
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='UU',flat=True)
    fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='VV',flat=True)

    simple_copy('AFSISIO','datafiles','constants','table_b_bufr')
    simple_copy('rpnpy','share','table_b_bufr_e')
    simple_copy('rpnpy','share','table_b_bufr_f')
    simple_copy('rpnpy','share','table_b_bufr_e_err')


from setuptools import setup, find_packages
from rpnpy.version import __VERSION__
packages = find_packages()
package_data = dict([(pkg,['*']) for pkg in packages])

setup (
  name = 'eccc_rpnpy_tests',
  version = __VERSION__,
  description = 'Minimal tests for checking an rpnpy installation.',
  packages = packages,
  install_requires = ['pytest','scipy'],
  package_data = package_data,
  entry_points = {
    'console_scripts':[
      'rpy.testenv=rpnpy_tests:testenv',
      'rpy.tests=rpnpy_tests:tests',
    ],
  },
  cmdclass={'getdata': GetData},
)


