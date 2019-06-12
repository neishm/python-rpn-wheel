######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

RPNPY_VERSION = 2.1.b3
# Wheel files use slightly different version syntax.
RPNPY_VERSION_ALTERNATE = 2.1b3

# This rule bootstraps the build process to run in a docker container for each
# supported platform.
all: docker
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) sdist'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && $(MAKE) wheel-retagged wheel-install PLATFORM=win32 && $(MAKE) wheel-retagged wheel-install PLATFORM=win_amd64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-manylinux1_x86_64-build bash -c 'cd /io && $(MAKE) wheel-retagged wheel-install PLATFORM=manylinux1_x86_64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-manylinux1_i686-build linux32 bash -c 'cd /io && $(MAKE) wheel-retagged wheel-install PLATFORM=manylinux1_i686'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-manylinux2010_x86_64-build bash -c 'cd /io && $(MAKE) wheel-retagged wheel-install PLATFORM=manylinux2010_x86_64'

# Build a native wheel file (using host OS, assuming it's Linux-based).
native:
	$(MAKE) wheel wheel-install


# Rule for generating images from Dockerfiles.
# This sets up a clean build environment to reduce the likelihood that
# something goes wrong at build-time or run-time.
docker: dockerfiles/windows/Dockerfile dockerfiles/manylinux1_x86_64-build/Dockerfile dockerfiles/manylinux1_i686-build/Dockerfile dockerfiles/manylinux2010_x86_64-build/Dockerfile dockerfiles/test_from_wheel/Dockerfile dockerfiles/test_from_sdist/Dockerfile
	sudo docker pull ubuntu:16.04
	sudo docker build --tag rpnpy-windows-build dockerfiles/windows
	sudo docker pull quay.io/pypa/manylinux1_x86_64
	sudo docker build --tag rpnpy-manylinux1_x86_64-build dockerfiles/manylinux1_x86_64-build
	sudo docker pull quay.io/pypa/manylinux1_i686
	sudo docker build --tag rpnpy-manylinux1_i686-build dockerfiles/manylinux1_i686-build
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
ifeq ($(PLATFORM),manylinux1_x86_64)
  export CFLAGS = -m64
  export FFLAGS = -m64
else ifeq ($(PLATFORM),manylinux1_i686)
  export CFLAGS = -m32
  export FFLAGS = -m32
else ifeq ($(PLATFORM),manylinux2010_x86_64)
  export CFLAGS = -m64
  export FFLAGS = -m64
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


# Get library version info
include include/libs.mk

.PHONY: all wheel wheel-retagged wheel-install sdist clean distclean docker native test _test


######################################################################
# The stuff below is for getting an updated version of gfortran.
# This is needed for compiling the vgrid code in the manylinux containers.
# Note: the final linking and construction of the shared libraries will be
# done with the original distribution-provided gfortran.

ifneq (,$(findstring manylinux,$(PLATFORM)))
LOCAL_GFORTRAN_VERSION = gcc-4.9.4
ifeq ($(PLATFORM),manylinux1_i686)
ARCH = i686
LOCAL_GFORTRAN_DIR = $(PWD)/cache/$(LOCAL_GFORTRAN_VERSION)-32bit
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure-32bit.tar.xz
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib
else
ARCH = x86_64
LOCAL_GFORTRAN_DIR = $(PWD)/cache/$(LOCAL_GFORTRAN_VERSION)
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure.tar.xz
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib64
endif

LOCAL_GFORTRAN_TAR = $(LOCAL_GFORTRAN_VERSION).$(ARCH).tar.xz
LOCAL_GFORTRAN_BIN = $(LOCAL_GFORTRAN_DIR)/bin
$(LOCAL_GFORTRAN_DIR): cache/$(LOCAL_GFORTRAN_TAR) cache/$(LOCAL_GFORTRAN_EXTRA)
	xzdec $< | tar -xv -C cache/
	xzdec cache/$(LOCAL_GFORTRAN_EXTRA) | tar -xv -C $@
	mv $@/bin $@/bin.orig
	mkdir $@/bin
	cd $@/bin && ln -s ../bin.orig/gfortran .
	touch $@
cache/$(LOCAL_GFORTRAN_TAR):
	wget http://gfortran.meteodat.ch/download/$(ARCH)/releases/$(LOCAL_GFORTRAN_VERSION).tar.xz -P cache/
	mv cache/$(LOCAL_GFORTRAN_VERSION).tar.xz $@
cache/$(LOCAL_GFORTRAN_EXTRA):
	wget http://gfortran.meteodat.ch/download/$(ARCH)/$(LOCAL_GFORTRAN_EXTRA) -P cache/
endif
#
######################################################################


######################################################################
# Rule for building the wheel file.

WHEEL_TMPDIR = $(PWD)/build/$(PLATFORM)
RETAGGED_WHEEL = eccc_rpnpy-$(RPNPY_VERSION_ALTERNATE)-py2.py3-none-$(PLATFORM).whl
WHEEL_TMPDIST = $(WHEEL_TMPDIR)/eccc_rpnpy-$(RPNPY_VERSION_ALTERNATE).dist-info

# Linux builds should be done in the manylinux containers.
ifneq (,$(findstring manylinux,$(PLATFORM)))
PYTHON=/opt/python/cp27-cp27m/bin/python
else
PYTHON=python
endif

wheel: $(RPNPY_PACKAGE) $(LOCAL_GFORTRAN_DIR)
	# Make initial wheel.
	rm -Rf $(WHEEL_TMPDIR)
	mkdir -p $(WHEEL_TMPDIR)
	# Remove old build directories, which may contain incompatible
	# Fortran modules from other architectures / versions of gfortran.
	rm -Rf $(RPNPY_PACKAGE)/build
	# Use setup.py to build the shared libraries and create the initial
	# wheel file.
	# Pass in any overrides for local gfortran.
	cd $(RPNPY_PACKAGE) && env PATH=$(LOCAL_GFORTRAN_BIN):$(PATH) LD_LIBRARY_PATH=$(LOCAL_GFORTRAN_LIB) EXTRA_LIBS="$(EXTRA_LIBS)" $(PYTHON) setup.py bdist_wheel --dist-dir $(WHEEL_TMPDIR)

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
$(RPNPY_PACKAGE): cache/python-rpn patches/CONTENTS patches/setup.py patches/setup.cfg patches/MANIFEST.in patches/python-rpn.patch include patches/Makefile cache/armnlib_2.0u_all cache/librmn patches/librmn.patch cache/vgrid patches/vgrid.patch cache/libburpc patches/libburpc.patch
	#############################################################
	### rpnpy modules
	#############################################################
	rm -Rf $@
	(cd cache/python-rpn && git archive --prefix=$@/ python-rpn_$(RPNPY_VERSION)) | tar -xv
	cp patches/CONTENTS $@
	cp patches/setup.py $@
	cp patches/setup.cfg $@
	cp patches/MANIFEST.in $@
	# Apply some patches to rpnpy so it picks up the bundled shared libs.
	git apply patches/python-rpn.patch --directory=$@
	# Version info.
	cd $@ && env ROOT=$(PWD)/$@ rpnpy=$(PWD)/$@  make -f include/Makefile.local.mk rpnpy_version.py
	# Append a notice to modified source files, as per LGPL requirements.
	for file in $$(grep '^---.*\.py' patches/python-rpn.patch | sed 's/^--- a//' | uniq); do echo "\n# This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/$$file; done
	mkdir -p $@/lib/rpnpy/_sharedlibs
	touch $@/lib/rpnpy/_sharedlibs/__init__.py
	# Create a directory stub for the source code of dependent libraries.
	mkdir -p $@/src
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
	# Apply patches to allow librmn to be compiled straight from gfortran,
	# without the usual RPN build tools.  Also allows it to cross-compile
	# to Windows.
	git apply patches/librmn.patch --directory=$@/src/librmn-$(LIBRMN_VERSION)
	# Append a notice to modified source files, as per LGPL requirements.
	for file in $$(grep '^---.*\.c' patches/librmn.patch | sed 's/^--- a//' | uniq); do echo "\n// This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/src/librmn-$(LIBRMN_VERSION)/$$file; done
	#############################################################
	### vgrid source
	#############################################################
	(cd cache/vgrid && git archive --prefix=$@/src/vgrid-$(VGRID_VERSION)/ $(VGRID_VERSION)) | tar -xv
	# Apply patches to allow vgrid to be compiled straight from gfortran.
	git apply patches/vgrid.patch --directory=$@/src/vgrid-$(VGRID_VERSION)
	# Append a notice to modified source files, as per LGPL requirements.
	for file in $$(grep '^---.*\.F90' patches/vgrid.patch | sed 's/^--- a//' | uniq); do echo "\n! This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/src/vgrid-$(VGRID_VERSION)/$$file; done
	# Construct dependencies.mk ahead of time, to avoid a build-time
	# dependence on perl.
	cd $@/src/vgrid-$(VGRID_VERSION)/src && make dependencies.mk PROJECT_ROOT=$(PWD)/$@/src
	#############################################################
	### libburpc source
	#############################################################
	(cd cache/libburpc && git archive --prefix=$@/src/libburpc-$(LIBBURPC_VERSION)/ $(LIBBURPC_COMMIT)) | tar -xv
	# Apply patches to allow libburpc to be compiled straight from gfortran.
	git apply patches/libburpc.patch --directory=$@/src/libburpc-$(LIBBURPC_VERSION)
	# Append a notice to modified source files, as per LGPL requirements.
	for file in $$(grep '^---.*\.c' patches/python-rpn.patch | sed 's/^--- a//' | uniq); do echo "\n// This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/src/libburpc-$(LIBBURPC_VERSION)/$$file; done
	# Remove broken links - causes problems when building from sdist.
	find $@ -xtype l -delete
	touch $@


######################################################################
# libgfortran and related libraries which are needed at runtime.

ifneq (,$(findstring manylinux,$(PLATFORM)))
EXTRA_LIBS = $(LOCAL_GFORTRAN_LIB)/libgfortran.so.3 \
             $(LOCAL_GFORTRAN_LIB)/libquadmath.so.0

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
	git clone https://github.com/meteokid/python-rpn.git -b python-rpn_$(RPNPY_VERSION) $@

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
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_ALTERNATE)-py2.py3-none-manylinux1_x86_64.whl'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-sdist bash -c 'cd /io && $(MAKE) _test WHEEL=wheelhouse/eccc_rpnpy-$(RPNPY_VERSION_ALTERNATE).zip'

_test: cache/gem-data_4.2.0_all cache/afsisio_1.0u_all cache/cmcgridf
	mkdir -p cache/py
	virtualenv -p python2 /tmp/myenv
	/tmp/myenv/bin/pip install $(PWD)/$(WHEEL) scipy pytest --cache-dir=cache/py
	cd $(RPNPY_PACKAGE)/share/tests && env ATM_MODEL_DFILES=$(PWD)/cache/gem-data_4.2.0_all/share/data/dfiles AFSISIO=$(PWD)/cache/afsisio_1.0u_all/data/ CMCGRIDF=$(PWD)/cache/cmcgridf TMPDIR=/tmp RPNPY_NOLONGTEST=1 /tmp/myenv/bin/python -m pytest --disable-warnings

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

