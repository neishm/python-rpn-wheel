def _setenv (varname, value):
  from os import environ
  print ("export %s=%s"%(varname,value))
  environ[varname] = value


def testenv():
  import rpnpy_tests
  from os.path import join, dirname, exists
  from os import makedirs, walk, chmod
  import stat
  from tempfile import mkdtemp
  from shutil import copy, copytree
  from datetime import datetime
  orig = dirname(rpnpy_tests.__file__)
  tmpdir = mkdtemp()
  _setenv ('TMPDIR', tmpdir)
  for varname in ('ATM_MODEL_DFILES','AFSISIO','rpnpy'):
    src = join(orig,varname)
    dst = join(tmpdir,varname)
    copytree (src,dst)
    _setenv (varname,dst)
    for root, dirs, files in walk(dst):
      for x in dirs+files:
        try:
          chmod(join(root,x),0o555)
        except PermissionError:
          pass
  makedirs(join(tmpdir,'CMCGRIDF','prog','regeta'))
  copy( join(orig,'CMCGRIDF','prog','regeta','2019033000_048'),
        join(tmpdir,'CMCGRIDF','prog','regeta',datetime.today().strftime('%Y%m%d00_048'))
  )
  _setenv ('CMCGRIDF',join(tmpdir,'CMCGRIDF'))
  _setenv ('RPNPY_NOLONGTEST','1')
  if not exists('tmp'):
    makedirs ('tmp')

def tests():
  import pytest
  from os.path import dirname, join
  testenv()
  pytest.main([join(dirname(__file__),'tests'),'--disable-warnings'])

