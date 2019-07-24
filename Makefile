######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

RPNPY_VERSION = 2.1.b3c
# Wheel files use slightly different version syntax.
RPNPY_VERSION_WHEEL = 2.1.b3c
RPNPY_COMMIT = 15009a2e

# This rule bootstraps the build process to run in a docker container for each
# supported platform.
all: docker
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) fetch sdist'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) wheel-retagged wheel-install PLATFORM=win32 && $(MAKE) wheel-retagged wheel-install PLATFORM=win_amd64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-manylinux2010_x86_64-build bash -c 'cd /io && $(MAKE) wheel-retagged wheel-install PLATFORM=manylinux2010_x86_64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && $(MAKE) _testpkg WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-manylinux2010_x86_64.whl PYTHON=python3'


# Build a native wheel file (using host OS, assuming it's Linux-based).
native:
	$(MAKE) wheel wheel-install PLATFORM=native


# Rule for generating images from Dockerfiles.
# This sets up a clean build environment to reduce the likelihood that
# something goes wrong at build-time or run-time.
docker: dockerfiles/windows/Dockerfile dockerfiles/manylinux2010_x86_64-build/Dockerfile dockerfiles/test_from_wheel/Dockerfile dockerfiles/test_from_sdist/Dockerfile
	sudo docker pull ubuntu:16.04
	sudo docker build --tag rpnpy-windows-build dockerfiles/windows
	sudo docker pull quay.io/pypa/manylinux2010_x86_64
	sudo docker build --tag rpnpy-manylinux2010_x86_64-build dockerfiles/manylinux2010_x86_64-build
	sudo docker build --tag rpnpy-test-from-wheel dockerfiles/test_from_wheel
	sudo docker build --tag rpnpy-test-from-sdist dockerfiles/test_from_sdist

# Rule for generating a Dockerfile.
# Fills in userid/groupid information specific to the host system.
# This information is used to create an equivalent user within the docker
# container, so that any files copied out of the container have the correct
# permissions.
%/Dockerfile: %/Dockerfile.template
	sed 's/$$GID/'`id -g`'/;s/$$GROUP/'`id -ng`'/;s/$$UID/'`id -u`'/;s/$$USER/'`id -nu`'/' $< > $@

clean:
	rm -Rf build/ wheelhouse/ dockerfiles/*/Dockerfile
distclean: clean
	rm -Rf cache/

# Location of the bundled source package
RPNPY_PACKAGE = cache/python-rpn-neishm
RPNPY_SDIST = wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL).zip

.PRECIOUS: $(RPNPY_SDIST) $(RPNPY_PACKAGE)

# Check PLATFORM to determine the build environment
ifeq ($(PLATFORM),manylinux2010_x86_64)
  export CC = gcc
  export FC = gfortran
else ifeq ($(PLATFORM),win_amd64)
  export CC = x86_64-w64-mingw32-gcc
  export FC = x86_64-w64-mingw32-gfortran
  export FFLAGS = -lws2_32 -lpthread
  export SHAREDLIB_SUFFIX = dll
else ifeq ($(PLATFORM),win32)
  export CC = i686-w64-mingw32-gcc
  export FC = i686-w64-mingw32-gfortran
  export FFLAGS = -lws2_32 -lpthread
  export SHAREDLIB_SUFFIX = dll
endif


.PHONY: all wheel wheel-retagged wheel-install sdist clean distclean docker native test _test _testpkg fetch


######################################################################
# Rule for building the wheel file.

WHEEL_TMPDIR = $(PWD)/build/$(PLATFORM)
RETAGGED_WHEEL = eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-$(PLATFORM).whl
WHEEL_TMPDIST = $(WHEEL_TMPDIR)/eccc_rpnpy-$(RPNPY_VERSION_WHEEL).dist-info

# Linux builds should be done in the manylinux containers.
ifneq (,$(findstring manylinux,$(PLATFORM)))
PYTHON=/opt/python/cp27-cp27m/bin/python
endif
PYTHON ?= python

wheel: $(RPNPY_PACKAGE)
	# Make initial wheel.
	rm -Rf $(WHEEL_TMPDIR)
	mkdir -p $(WHEEL_TMPDIR)
	# Remove old build directories, which may contain incompatible
	# Fortran modules from other architectures / versions of gfortran.
	rm -Rf $(RPNPY_PACKAGE)/build
	# Use setup.py to build the shared libraries and create the initial
	# wheel file.
	# Pass in any overrides for local gfortran.
	cd $(RPNPY_PACKAGE) && env EXTRA_LIBS="$(EXTRA_LIBS)" $(PYTHON) setup.py bdist_wheel --dist-dir $(WHEEL_TMPDIR)

wheel-retagged: wheel
	# Fix filename and tags
	cd $(WHEEL_TMPDIR) && unzip *.whl && rm *.whl
	sed -i 's/^Tag:.*/Tag: py2.py3-none-$(PLATFORM)/' $(WHEEL_TMPDIST)/WHEEL
	# Update SHA-1 sums for the RECORD file.
	rm -Rf $(WHEEL_TMPDIST)/RECORD
	$(PYTHON) -c "from distutils.core import Distribution; from wheel.bdist_wheel import bdist_wheel; bdist_wheel(Distribution()).write_record('$(WHEEL_TMPDIR)','$(WHEEL_TMPDIST)')"
	rm -f $(WHEEL_TMPDIR)/*.whl
	cd $(WHEEL_TMPDIR) && zip -r $(RETAGGED_WHEEL) .

wheel-install:
	mkdir -p $(PWD)/wheelhouse
	cp $(WHEEL_TMPDIR)/*.whl $(PWD)/wheelhouse/



######################################################################
# libgfortran and related libraries which are needed at runtime.

ifeq ($(PLATFORM),manylinux2010_x86_64)
EXTRA_LIBS = /usr/lib64/libgfortran.so.5 \
             /usr/lib64/libquadmath.so.0

else ifeq ($(PLATFORM),win_amd64)
EXTRA_LIB_SRC1 = /usr/lib/gcc/x86_64-w64-mingw32/5.3-win32
EXTRA_LIB_SRC2 = /usr/x86_64-w64-mingw32/lib
EXTRA_LIBS = $(EXTRA_LIB_SRC1)/libgcc_s_seh-1.dll \
             $(EXTRA_LIB_SRC1)/libgfortran-3.dll \
             $(EXTRA_LIB_SRC1)/libquadmath-0.dll \
             $(EXTRA_LIB_SRC2)/libwinpthread-1.dll

else ifeq ($(PLATFORM),win32)
EXTRA_LIB_SRC1 = /usr/lib/gcc/i686-w64-mingw32/5.3-win32
EXTRA_LIB_SRC2 = /usr/i686-w64-mingw32/lib
EXTRA_LIBS = $(EXTRA_LIB_SRC1)/libgcc_s_sjlj-1.dll \
             $(EXTRA_LIB_SRC1)/libgfortran-3.dll \
             $(EXTRA_LIB_SRC1)/libquadmath-0.dll \
             $(EXTRA_LIB_SRC2)/libwinpthread-1.dll
endif



######################################################################
# Rules for generated a bundled source distribution.

sdist: $(RPNPY_SDIST)

$(RPNPY_SDIST): $(RPNPY_PACKAGE)
	cd $< && $(PYTHON) setup.py sdist --formats=zip --dist-dir $(PWD)/wheelhouse/
	touch $@

fetch: $(RPNPY_PACKAGE) patches/python-rpn.patch patches/tests.patch
	cd $< && git reset --hard HEAD && git clean -xdf . && git fetch && git checkout $(RPNPY_COMMIT) && git submodule update --init && git apply $(PWD)/patches/python-rpn.patch && git apply $(PWD)/patches/tests.patch

$(RPNPY_PACKAGE):
	git clone --recursive https://github.com/neishm/python-rpn.git $@


######################################################################
# Rules for doing quick tests on the wheels.

test:
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-manylinux2010_x86_64.whl PYTHON=python2'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-manylinux2010_x86_64.whl PYTHON=python3'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-sdist bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL).zip PYTHON=python2'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-sdist bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL).zip PYTHON=python3'

_test: cache/gem-data_4.2.0_all cache/afsisio_1.0u_all cache/cmcgridf
	mkdir -p cache/py
	virtualenv -p $(PYTHON) /tmp/myenv
	/tmp/myenv/bin/pip install $(PWD)/$(WHEEL) scipy pytest --cache-dir=cache/py
	mkdir -p /tmp/cache
	cp -R $(RPNPY_PACKAGE) /tmp/cache/
	# Test with full data files
	cd /tmp/$(RPNPY_PACKAGE)/share/tests && env ATM_MODEL_DFILES=$(PWD)/cache/gem-data_4.2.0_all/share/data/dfiles AFSISIO=$(PWD)/cache/afsisio_1.0u_all/data/ CMCGRIDF=$(PWD)/cache/cmcgridf rpnpy=/tmp/$(RPNPY_PACKAGE) TMPDIR=/tmp RPNPY_NOLONGTEST=1 /tmp/myenv/bin/python -m pytest --disable-warnings
	# Test again with the reduced data from eccc-rpnpy-tests package.
	/tmp/myenv/bin/pip install $(PWD)/wheelhouse/eccc_rpnpy_tests-$(RPNPY_VERSION_WHEEL).zip --cache-dir=cache/py
	/tmp/myenv/bin/rpy.tests

_testpkg: cache/gem-data_4.2.0_all cache/afsisio_1.0u_all cache/python-rpn-lfs $(RPNPY_PACKAGE)
	mkdir -p cache/py
	virtualenv -p $(PYTHON) /tmp/myenv
	/tmp/myenv/bin/pip install $(PWD)/$(WHEEL) scipy setuptools --cache-dir=cache/py
	cp -R testdata /tmp
	cd /tmp/testdata && env ATM_MODEL_DFILES=$(PWD)/cache/gem-data_4.2.0_all/share/data/dfiles AFSISIO=$(PWD)/cache/afsisio_1.0u_all/data/ CMCGRIDF=$(PWD)/cache/python-rpn-lfs/cmcgridf rpnpy=$(PWD)/$(RPNPY_PACKAGE) TMPDIR=/tmp /tmp/myenv/bin/python setup.py getdata
	mkdir -p /tmp/testdata/rpnpy_tests/tests
	touch /tmp/testdata/rpnpy_tests/tests/__init__.py
	cp $(RPNPY_PACKAGE)/share/tests/test*.py /tmp/testdata/rpnpy_tests/tests
	cd /tmp/testdata && /tmp/myenv/bin/python setup.py sdist --formats=zip --dist-dir $(PWD)/wheelhouse/

cache/gem-data_4.2.0_all:
	wget http://collaboration.cmc.ec.gc.ca/science/ssm/gem-data_4.2.0_all.ssm -P cache/
	tar -xzvf $@.ssm -C cache/
	touch $@

cache/afsisio_1.0u_all:
	wget http://collaboration.cmc.ec.gc.ca/science/ssm/afsisio_1.0u_all.ssm -P cache/
	tar -xzvf $@.ssm -C cache/
	touch $@

REGETA_FILE=cache/cmcgridf/prog/regeta/$(shell date +%Y%m%d)00_048

cache/cmcgridf: $(REGETA_FILE)
$(REGETA_FILE): cache/python-rpn-lfs
	mkdir -p cache/cmcgridf/prog/regeta/
	ln -sf $(PWD)/cache/python-rpn-lfs/cmcgridf/prog/regeta/2019033000_048 $(REGETA_FILE)

cache/python-rpn-lfs:
	git clone https://github.com/jeixav/python-rpn.git $@ -b feat/travis
	git -C $@ lfs install --local
	git -C $@ lfs pull

