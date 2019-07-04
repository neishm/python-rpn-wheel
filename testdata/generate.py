# Generate portable test files from the full suite.

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

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('outdir', help='Where to put the reduced test files.')
args = parser.parse_args()


files_in_progress = set()
def inout (env, *path):
  from os.path import join, dirname, exists
  from os import makedirs, environ, remove
  infile = join(environ[env], *path)
  outfile = join(args.outdir, env, *path)
  outdir = dirname(outfile)
  makedirs(outdir, exist_ok=True)
  print ('->', outfile)
  if exists(outfile) and outfile not in files_in_progress:
    remove(outfile)
  files_in_progress.add(outfile)
  return infile, outfile

def simple_copy (env, *path):
  from shutil import copy
  infile, outfile = inout(env, *path)
  copy(infile, outfile)

def fst_copy (env, *path, **kwargs):
  import rpnpy.librmn.all as rmn
  from os.path import exists
  infile, outfile = inout(env, *path)
  inunit = rmn.fstopenall(infile, rmn.FST_RO)
  if exists(outfile):
    outunit = rmn.fstopenall(outfile, rmn.FST_RW_OLD)
  else:
    outunit = rmn.fstopenall(outfile, rmn.FST_RW)
  for key in rmn.fstinl(inunit, **kwargs):
    rec = rmn.fstluk(key)
    if False and rec['datyp'] < 128 and rec['ni']*rec['nj'] > 9999:
      rec['datyp'] += 128
    rmn.fstecr(outunit, rec)
  rmn.fstcloseall(outunit)
  rmn.fstcloseall(inunit)

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

fst_copy('ATM_MODEL_DFILES','bcmk','2009042700_000')
fst_copy('ATM_MODEL_DFILES','bcmk','2009042700_012')

fst_copy('ATM_MODEL_DFILES','bcmk_vgrid','21001_SLEVE')
fst_copy('ATM_MODEL_DFILES','bcmk_vgrid','21002_SLEVE')

fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='^^')
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='>>')
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='!!')
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='P0')
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='PT')
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='TT',ip2=48)
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='UU',ip2=48)
fst_copy('CMCGRIDF','prog','regeta','2019033000_048',nomvar='VV',ip2=48)

simple_copy('AFSISIO','datafiles','constants','table_b_bufr')
simple_copy('rpnpy','share','table_b_bufr_e')

