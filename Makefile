######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

RPNPY_VERSION = 2.1.b5
# Wheel files use slightly different version syntax.
RPNPY_VERSION_WHEEL = 2.1b5

# This rule bootstraps the build process to run in a docker container for each
# supported platform.
all: docker .patched
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) sdist'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) wheel PLATFORM=win32 && $(MAKE) wheel PLATFORM=win_amd64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-manylinux2010_x86_64-build bash -c 'cd /io && $(MAKE) wheel PLATFORM=manylinux2010_x86_64'


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

# Rule for patching up the source to work outside the CMC / science networks.
.patched:
	$(MAKE) fetch
	cd python-rpn && patch -p1 < $(PWD)/patches/python-rpn.patch
	cd python-rpn/lib/rpnpy && ln -s ../../../python-rpn-libsrc _sharedlibs
	touch $@

# Rule for initializing the build process to do a fresh build.
clean-submodules:
	git submodule foreach git clean -xdf .
	git submodule foreach git reset --hard HEAD
fetch: clean-submodules
	git submodule foreach git fetch --tags
	git submodule update --init --recursive
clean: clean-submodules
	rm -f .patched
	rm -Rf wheelhouse/ dockerfiles/*/Dockerfile
distclean: clean
	rm -Rf cache/

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


.PHONY: all wheel sdist clean clean-submodules distclean docker native test _test fetch


######################################################################
# Rule for building the wheel file.

RETAGGED_WHEEL = eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-$(PLATFORM).whl

# Linux builds should be done in the manylinux containers.
ifneq (,$(findstring manylinux,$(PLATFORM)))
PYTHON=/opt/python/cp27-cp27m/bin/python
endif
PYTHON ?= python

wheel: .patched
	# Use setup.py to build the shared libraries and create the wheel file.
	# Pass in any extra shared libraries needed for the wheel.
	cd python-rpn && env EXTRA_LIBS="$(EXTRA_LIBS)" $(PYTHON) setup.py clean bdist_wheel --dist-dir $(PWD)/wheelhouse --plat-name $(PLATFORM)

# Build a native wheel file (using host OS, assuming it's Linux-based).
native: .patched
	# Use setup.py to build the shared libraries and create the wheel file.
	# Pass in any extra shared libraries needed for the wheel.
	cd python-rpn && env EXTRA_LIBS="$(EXTRA_LIBS)" $(PYTHON) setup.py clean bdist_wheel --dist-dir $(PWD)/wheelhouse



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

sdist: .patched
	cd python-rpn && $(PYTHON) setup.py sdist --formats=zip --dist-dir $(PWD)/wheelhouse/


######################################################################
# Rules for doing quick tests on the wheels.

test:
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-manylinux2010_x86_64.whl PYTHON=python2'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL)-py2.py3-none-manylinux2010_x86_64.whl PYTHON=python3'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-sdist bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL).zip PYTHON=python2'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-sdist bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_WHEEL).zip PYTHON=python3'

RPNPY_TESTS_WHEEL = wheelhouse/eccc_rpnpy_tests-$(RPNPY_VERSION).zip

# Test with reduced data from eccc-rpnpy-tests package.
_test: $(RPNPY_TESTS_WHEEL)
	mkdir -p cache/py
	virtualenv -p $(PYTHON) /tmp/myenv
	/tmp/myenv/bin/pip install $(PWD)/$(WHEEL) --cache-dir=cache/py
	/tmp/myenv/bin/pip install $(PWD)/$(RPNPY_TESTS_WHEEL) --cache-dir=cache/py
	cd /tmp && /tmp/myenv/bin/rpy.tests

$(RPNPY_TESTS_WHEEL):
	wget ftp://crd-data-donnees-rdc.ec.gc.ca/pub/CCMR/mneish/wheelhouse/$(notdir $@) -P $(dir $@)

