######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

RPNPY_VERSION = 2.1.b3
# Wheel files use slightly different version syntax.
RPNPY_VERSION_ALTERNATE = 2.1b3

# This rule bootstraps the build process to run in a docker container for each
# supported platform.
all: docker cache/librmn cache/vgrid cache/libburpc
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && make wheel-retagged wheel-install PLATFORM=win32 && make wheel-retagged wheel-install PLATFORM=win_amd64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-linux64-build bash -c 'cd /io && make wheel-retagged wheel-install PLATFORM=manylinux1_x86_64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-linux32-build linux32 bash -c 'cd /io && make wheel-retagged wheel-install PLATFORM=manylinux1_i686'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-sdist bash -c 'cd /io && make sdist'

# Build a native wheel file (using host OS, assuming it's Linux-based).
native:
	make wheel wheel-install


# Rule for generating images from Dockerfiles.
# This sets up a clean build environment to reduce the likelihood that
# something goes wrong at build-time or run-time.
docker: dockerfiles/windows/Dockerfile dockerfiles/linux64/Dockerfile dockerfiles/linux32/Dockerfile dockerfiles/test_from_wheel/Dockerfile dockerfiles/test_from_sdist/Dockerfile
	sudo docker pull ubuntu:16.04
	sudo docker build --tag rpnpy-windows-build dockerfiles/windows
	sudo docker pull quay.io/pypa/manylinux1_x86_64
	sudo docker build --tag rpnpy-linux64-build dockerfiles/linux64
	sudo docker pull quay.io/pypa/manylinux1_i686
	sudo docker build --tag rpnpy-linux32-build dockerfiles/linux32
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
	rm -Rf src/ build/
distclean: clean
	rm -Rf cache/ wheelhouse/ dockerfiles/*/Dockerfile env-include

# Locations to build static / shared libraries.
BUILDDIR = build
RPNPY_SRCDIR = src/python-rpn-$(RPNPY_VERSION)
RPNPY_BUILDDIR = build/python-rpn-$(RPNPY_VERSION).$(PLATFORM)
include include/libs.mk

.PRECIOUS: $(RPNPY_BUILDDIR)

.SUFFIXES:
.PHONY: all wheel wheel-install extra-libs

######################################################################
# Rule for building the wheel file.

WHEEL_TMPDIR = $(RPNPY_BUILDDIR)/tmp
RETAGGED_WHEEL = rpnpy-$(RPNPY_VERSION)-py2.py3-none-$(PLATFORM).whl
WHEEL_TMPDIST = $(WHEEL_TMPDIR)/rpnpy-$(RPNPY_VERSION_ALTERNATE).dist-info

# Linux builds should be done in the manylinux1 container.
ifneq (,$(findstring manylinux1,$(PLATFORM)))
PYTHON=/opt/python/cp27-cp27m/bin/python
else
PYTHON=python
endif

wheel: $(RPNPY_BUILDDIR) $(LIBRMN_SHARED) $(LIBDESCRIP_SHARED) $(LIBBURPC_SHARED) extra-libs
	rm -Rf $(RPNPY_BUILDDIR)/build $(RPNPY_BUILDDIR)/dist
	# Make initial wheel.
	cd $(RPNPY_BUILDDIR) && $(PYTHON) setup.py bdist_wheel

wheel-retagged: wheel
	# Fix filename and tags
	rm -Rf $(WHEEL_TMPDIR)
	mkdir $(WHEEL_TMPDIR)
	cd $(WHEEL_TMPDIR) && unzip $(PWD)/$(RPNPY_BUILDDIR)/dist/*.whl
	sed -i 's/^Tag:.*/Tag: py2.py3-none-$(PLATFORM)/' $(WHEEL_TMPDIST)/WHEEL
	# Update SHA-1 sums for the RECORD file.
	rm -Rf $(WHEEL_TMPDIST)/RECORD
	$(PYTHON) -c "from distutils.core import Distribution; from wheel.bdist_wheel import bdist_wheel; bdist_wheel(Distribution()).write_record('$(WHEEL_TMPDIR)','$(WHEEL_TMPDIST)')"
	rm $(RPNPY_BUILDDIR)/dist/*.whl
	cd $(WHEEL_TMPDIR) && zip -r $(PWD)/$(RPNPY_BUILDDIR)/dist/$(RETAGGED_WHEEL) .

wheel-install:
	mkdir -p $(PWD)/wheelhouse
	cp $(RPNPY_BUILDDIR)/dist/*.whl $(PWD)/wheelhouse/


# Set up the source directory (does everything except the actual build).
$(RPNPY_SRCDIR): cache/python-rpn patches/setup.py patches/setup.cfg patches/python-rpn.patch env-include
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ python-rpn_$(RPNPY_VERSION)) | tar -xv
	cp patches/setup.py $@
	cp patches/setup.cfg $@
	cp patches/MANIFEST.in $@
	git apply patches/python-rpn.patch --directory=$@
	cd $@ && env ROOT=$(PWD)/$@ rpnpy=$(PWD)/$@  make -f include/Makefile.local.mk rpnpy_version.py
	for file in $$(grep '^---.*\.py' patches/python-rpn.patch | sed 's/^--- a//' | uniq); do echo "\n# This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/$$file; done
	mkdir -p $@/lib/rpnpy/_sharedlibs
	touch $@/lib/rpnpy/_sharedlibs/__init__.py
	mkdir -p $@/src
	cp -PR include $@/src/
	cp -PR env-include $@/src/
	# Use simplified make rules for building from source package.
	# (not doing cross-compiling in this context).
	cp patches/platforms.mk $@/src/include/
	cp patches/Makefile $@/src/
	touch $@

$(RPNPY_BUILDDIR): $(RPNPY_SRCDIR)
	mkdir -p build
	cp -R $< $@


######################################################################
# Copy libgfortran and related libraries which are needed at runtime.

EXTRA_LIB_DEST = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs

ifeq ($(PLATFORM),manylinux1_x86_64)
extra-libs:
	cp /usr/lib64/libgfortran.so.3 $(EXTRA_LIB_DEST)

else ifeq ($(PLATFORM),manylinux1_i686)
extra-libs:
	cp /usr/lib/libgfortran.so.3 $(EXTRA_LIB_DEST)

else ifeq ($(PLATFORM),win_amd64)
EXTRA_LIB_SRC1 = /usr/lib/gcc/$(ARCH)-w64-mingw32/5.3-win32
EXTRA_LIB_SRC2 = /usr/$(ARCH)-w64-mingw32/lib
extra-libs:
	cp $(EXTRA_LIB_SRC1)/libgcc_s_seh-1.dll $(EXTRA_LIB_DEST)
	cp $(EXTRA_LIB_SRC1)/libgfortran-3.dll $(EXTRA_LIB_DEST)
	cp $(EXTRA_LIB_SRC1)/libquadmath-0.dll $(EXTRA_LIB_DEST)
	cp $(EXTRA_LIB_SRC2)/libwinpthread-1.dll $(EXTRA_LIB_DEST)

else ifeq ($(PLATFORM),win32)
EXTRA_LIB_SRC1 = /usr/lib/gcc/$(ARCH)-w64-mingw32/5.3-win32
EXTRA_LIB_SRC2 = /usr/$(ARCH)-w64-mingw32/lib
extra-libs:
	cp $(EXTRA_LIB_SRC1)/libgcc_s_sjlj-1.dll $(EXTRA_LIB_DEST)
	cp $(EXTRA_LIB_SRC1)/libgfortran-3.dll $(EXTRA_LIB_DEST)
	cp $(EXTRA_LIB_SRC1)/libquadmath-0.dll $(EXTRA_LIB_DEST)
	cp $(EXTRA_LIB_SRC2)/libwinpthread-1.dll $(EXTRA_LIB_DEST)
endif


######################################################################
# The stuff below is for getting an updated version of gfortran.
# This is needed for compiling the vgrid code in the manylinux1 container.
ifneq (,$(findstring manylinux1,$(PLATFORM)))
LOCAL_GFORTRAN_VERSION = gcc-4.9.4
ifeq ($(ARCH),x86_64)
LOCAL_GFORTRAN_DIR = cache/$(LOCAL_GFORTRAN_VERSION)
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure.tar.xz
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib64
else ifeq ($(ARCH),i686)
LOCAL_GFORTRAN_DIR = cache/$(LOCAL_GFORTRAN_VERSION)-32bit
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure-32bit.tar.xz
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib
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
# Rules for building the static libraries from source.

# Pre-requisite packages for required headers and compiler rules.
cache/code-tools:
	mkdir -p cache
	git clone https://github.com/mfvalin/code-tools.git $@
cache/armnlib_2.0u_all:
	wget http://armnlib.uqam.ca//armnlib/repository/armnlib_2.0u_all.ssm -P cache/
	tar -xzvf $@.ssm -C cache/
	touch $@
env-include: cache/code-tools cache/armnlib_2.0u_all
	rm -Rf $@
	mkdir -p $@
	cp -R cache/code-tools/include/* $@/
	cp -R cache/armnlib_2.0u_all/include/* $@/
	# Add a quick and dirty 32-bit option.
	mkdir -p $@/Linux_gfortran
	sed 's/PTR_AS_INT long long/PTR_AS_INT int/' $@/Linux_x86-64_gfortran/rpn_macros_arch.h > $@/Linux_gfortran/rpn_macros_arch.h


$(LIBRMN_SRCDIR): cache/librmn patches/librmn.patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ Release-$(LIBRMN_VERSION)) | tar -xv
	git apply patches/librmn.patch --directory=$@
	for file in $$(grep '^---.*\.c' patches/librmn.patch | sed 's/^--- a//' | uniq); do echo "\n// This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/$$file; done
	touch $@

$(LIBDESCRIP_SRCDIR): cache/vgrid patches/vgrid.patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ $(VGRID_VERSION)) | tar -xv
	git apply patches/vgrid.patch --directory=$@
	for file in $$(grep '^---.*\.F90' patches/vgrid.patch | sed 's/^--- a//' | uniq); do echo "\n! This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/$$file; done
	cd $@/src && env make dependencies.mk RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD)
	touch $@

$(LIBBURPC_SRCDIR): cache/libburpc patches/libburpc.patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ $(LIBBURPC_VERSION)) | tar -xv
	git apply patches/libburpc.patch --directory=$@
	for file in $$(grep '^---.*\.c' patches/python-rpn.patch | sed 's/^--- a//' | uniq); do echo "\n// This file was modified from the original source on $$(date +%Y-%m-%d)." >> $@/$$file; done
	touch $@


######################################################################
# Rules for getting the required source packages.

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
	cd $@ && git checkout $(LIBBURPC_VERSION)


######################################################################
# Rules for generated a bundled source distribution.

sdist: $(RPNPY_SRCDIR) $(LIBRMN_SRCDIR) $(LIBDESCRIP_SRCDIR) $(LIBBURPC_SRCDIR) env-include
	cd $< && $(PYTHON) setup.py sdist --formats=gztar,zip --dist-dir $(PWD)/wheelhouse/


######################################################################
# Rules for doing quick tests on the wheels.

test: wheelhouse/rpnpy-$(RPNPY_VERSION)-py2.py3-none-manylinux1_x86_64.whl
	sudo docker run --rm -v $(PWD):/io -it rpnpy-test-from-wheel bash -c 'cd /io && make _test PLATFORM=native WHEEL=$<'

_test: cache/gem-data_4.2.0_all cache/afsisio_1.0u_all cache/cmcgridf
	mkdir -p cache/py
	virtualenv -p python2 /tmp/myenv
	/tmp/myenv/bin/pip install $(PWD)/$(WHEEL) scipy --cache-dir=cache/py
	env ATM_MODEL_DFILES=$(PWD)/cache/gem-data_4.2.0_all/share/data/dfiles AFSISIO=$(PWD)/cache/afsisio_1.0u_all/data/ CMCGRIDF=$(PWD)/cache/cmcgridf TMPDIR=/tmp /tmp/myenv/bin/python -m unittest discover -s /tmp/myenv/lib/python2.7/site-packages/rpnpy/tests -v

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

