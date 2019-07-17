######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

include include/versions.mk

# This rule bootstraps the build process to run in a docker container for each
# supported platform.
all: docker fetch
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) sdist'
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
RPNPY_PACKAGE = build/python-rpn-$(RPNPY_VERSION)
.PRECIOUS: $(RPNPY_PACKAGE)

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


.PHONY: all wheel wheel-retagged wheel-install sdist clean distclean docker native test _test _testpkg


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


# Construct the bundled source package.
# This should contain all the source code needed to compile from scratch.
$(RPNPY_PACKAGE): cache/python-rpn patches/CONTENTS patches/setup.py patches/setup.cfg patches/MANIFEST.in patches/python-rpn.patch patches/tests.patch include patches/Makefile cache/armnlib_2.0u_all cache/librmn patches/librmn.patch cache/vgrid patches/vgrid.patch cache/libburpc patches/libburpc.patch
	#############################################################
	### rpnpy modules
	#############################################################
	rm -Rf $@
	(cd cache/python-rpn && git archive --prefix=$@/ $(RPNPY_COMMIT)) | tar -xv
	# Create a directory stub for the source code of dependent libraries.
	mkdir -p $@/src
	mkdir -p $@/src/patches
	sed 's/librmn-<VERSION>/librmn-$(LIBRMN_VERSION)/;s/vgrid-<VERSION>/vgrid-$(VGRID_VERSION)/;s/libburpc-<VERSION>/libburpc-$(LIBBURPC_VERSION)/;' patches/CONTENTS > $@/src/CONTENTS
	cp patches/setup.py $@
	cp patches/setup.cfg $@
	cp patches/MANIFEST.in $@
	# Apply some patches to rpnpy so it picks up the bundled shared libs.
	git apply patches/python-rpn.patch --directory=$@
	# Apply patches to unit tests, to identify expected failures.
	git apply patches/tests.patch --directory=$@
	# Create shared lib directory.
	mkdir -p $@/lib/rpnpy/_sharedlibs
	touch $@/lib/rpnpy/_sharedlibs/__init__.py
	cp -PR include $@/src/
	# Use simplified make rules for building from source package.
	# (not doing cross-compiling in that context).
	cp patches/Makefile $@/src/
	#############################################################
	### RPN headers and macros
	#############################################################
	cp cache/armnlib_2.0u_all/not_shared/AILLEURS/rpnmacros.h $@/src/include/
	cp cache/armnlib_2.0u_all/not_shared/AILLEURS/ftnmacros.hf $@/src/include/
	cp cache/armnlib_2.0u_all/include/rpnmacros_global.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/rmnlib.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/ftn2c_helper.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/gossip.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/cgossip.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/md5.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/arc4.h $@/src/include/
	cp cache/armnlib_2.0u_all/include/fnom.h $@/src/include/
	#############################################################
	### librmn source
	#############################################################
	(cd cache/librmn && git archive --prefix=$@/src/librmn-$(LIBRMN_VERSION)/ Release-$(LIBRMN_VERSION)) | tar -xv
	# Copy patches to allow librmn to be compiled straight from gfortran,
	# without the usual RPN build tools.  Also allows it to cross-compile
	# to Windows.
	cp patches/librmn.patch $@/src/patches/
	#############################################################
	### vgrid source
	#############################################################
	(cd cache/vgrid && git archive --prefix=$@/src/vgrid-$(VGRID_VERSION)/ $(VGRID_VERSION)) | tar -xv
	# Copy patches to allow vgrid to be compiled straight from gfortran.
	cp patches/vgrid.patch $@/src/patches/
	#############################################################
	### libburpc source
	#############################################################
	(cd cache/libburpc && git archive --prefix=$@/src/libburpc-$(LIBBURPC_VERSION)/ $(LIBBURPC_COMMIT)) | tar -xv
	# Copy patches to allow libburpc to be compiled straight from gfortran.
	cp patches/libburpc.patch $@/src/patches/
	# Remove a binary test file.
	rm $@/src/libburpc-$(LIBBURPC_VERSION)/tests/2004021400_.new1
	touch $@


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
# Rules for getting the required source packages.

# Required RPN headers and macros
cache/armnlib_2.0u_all:
	wget http://collaboration.cmc.ec.gc.ca/science/ssm/armnlib_2.0u_all.ssm -P cache/
	tar -xzvf $@.ssm -C cache/
	touch $@

cache/python-rpn:
	mkdir -p cache
	git clone https://github.com/meteokid/python-rpn.git $@
	cd $@ && git checkout $(RPNPY_COMMIT)

cache/librmn:
	mkdir -p cache
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION) $@

cache/vgrid:
	mkdir -p cache
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION) $@

cache/libburpc:
	mkdir -p cache
	git clone https://github.com/josecmc/libburp.git $@
	cd $@ && git checkout $(LIBBURPC_COMMIT)

# Shortcut for fetching latest tags from the repositories.
# Only needed when updating the library versions.
fetch:
	git -C cache/python-rpn fetch --tags
	git -C cache/librmn fetch --tags
	git -C cache/vgrid fetch --tags
	git -C cache/libburpc fetch --tags


######################################################################
# Rules for generated a bundled source distribution.

sdist: $(RPNPY_PACKAGE)
	cd $< && $(PYTHON) setup.py sdist --formats=zip --dist-dir $(PWD)/wheelhouse/


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
	mkdir -p /tmp/build
	cp -R $(RPNPY_PACKAGE) /tmp/build/
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

