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


def inout (env, *path):
  from os.path import join, dirname
  from os import makedirs, environ
  infile = join(environ[env], *path)
  outfile = join(args.outdir, env, *path)
  outdir = dirname(outfile)
  makedirs(outdir, exist_ok=True)
  print ('->', outfile)
  return infile, outfile

def simple_copy (env, *path):
  from shutil import copy
  infile, outfile = inout(env, *path)
  copy(infile, outfile)

simple_copy('ATM_MODEL_DFILES','bcmk_burp','2007021900.brp')
simple_copy('ATM_MODEL_DFILES','bcmk_p','anlp2015070706_000')
simple_copy('ATM_MODEL_DFILES','bcmk','geophy.fst')
simple_copy('ATM_MODEL_DFILES','bcmk_toctoc','2009042700_000')
simple_copy('ATM_MODEL_DFILES','bcmk','2009042700_000')
simple_copy('ATM_MODEL_DFILES','bcmk','2009042700_012')
simple_copy('ATM_MODEL_DFILES','bcmk_vgrid','21001_SLEVE')
simple_copy('ATM_MODEL_DFILES','bcmk_vgrid','21002_SLEVE')
simple_copy('CMCGRIDF','prog','regeta','2019033000_048')
simple_copy('AFSISIO','datafiles','constants','table_b_bufr')
simple_copy('rpnpy','share','table_b_bufr_e')

