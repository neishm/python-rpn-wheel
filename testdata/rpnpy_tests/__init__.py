def _setenv (varname, value):
  from os import environ
  print ("export %s=%s"%(varname,value))
  environ[varname] = value


def testenv():
  import rpnpy_tests
  from os.path import join, dirname
  from os import makedirs
  from tempfile import mkdtemp
  from shutil import copy
  from datetime import datetime
  root = dirname(rpnpy_tests.__file__)
  for varname in ('ATM_MODEL_DFILES','AFSISIO','rpnpy'):
    value = join(root,varname)
    _setenv (varname, value)
  tmpdir = mkdtemp()
  _setenv ('TMPDIR', tmpdir)
  makedirs(join(tmpdir,'prog','regeta'), exist_ok=True)
  copy( join(root,'CMCGRIDF','prog','regeta','2019033000_048'),
        join(tmpdir,'prog','regeta',datetime.today().strftime('%Y%m%d00_048'))
  )
  _setenv ('CMCGRIDF',tmpdir)
  _setenv ('RPNPY_NOLONGTEST','1')
  makedirs ('tmp', exist_ok=True)

def test():
  import pytest
  from rpnpy import tests
  from os.path import dirname
  testenv()
  pytest.main([dirname(tests.__file__),'--disable-warnings'])

