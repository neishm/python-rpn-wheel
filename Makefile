######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

RPNPY_VERSION = 2.1.b2
# Wheel files use slightly different version syntax.
RPNPY_VERSION_ALTERNATE = 2.1b2
LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.2.1
# commit id for libburpc version 1.9 with LGPL license
LIBBURPC_VERSION = 3a2d4f

include include/platforms.mk

# This rule bootstraps the build process to run in a docker container for each
# supported platform.
all: docker librmn vgrid libburpc
	sudo docker run --rm -v $(PWD):/io -it rpnpy-windows-build bash -c 'cd /io && make wheel-install PLATFORM=win32 && make wheel-install PLATFORM=win_amd64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-linux64-build bash -c 'cd /io && make wheel-install PLATFORM=manylinux1_x86_64'
	sudo docker run --rm -v $(PWD):/io -it rpnpy-linux32-build linux32 bash -c 'cd /io && make wheel-install PLATFORM=manylinux1_i686'

# Rule for generating images from Dockerfiles.
# This sets up a clean build environment to reduce the likelihood that
# something goes wrong at build-time or run-time.
docker: windows/Dockerfile linux64/Dockerfile linux32/Dockerfile
	sudo docker pull ubuntu:16.04
	sudo docker build --tag rpnpy-windows-build windows
	sudo docker pull quay.io/pypa/manylinux1_x86_64
	sudo docker build --tag rpnpy-linux64-build linux64
	sudo docker pull quay.io/pypa/manylinux1_i686
	sudo docker build --tag rpnpy-linux32-build linux32

# Rule for generating a Dockerfile.
# Fills in userid/groupid information specific to the host system.
# This information is used to create an equivalent user within the docker
# container, so that any files copied out of the container have the correct
# permissions.
%/Dockerfile: %/Dockerfile.template
	sed 's/$$GID/'`id -g`'/;s/$$GROUP/'`id -ng`'/;s/$$UID/'`id -u`'/;s/$$USER/'`id -nu`'/' $< > $@

clean:
	rm -Rf build/ windows/Dockerfile linux32/Dockerfile linux64/Dockerfile

# Locations to build static / shared libraries.
RPNPY_BUILDDIR = build/python-rpn-$(RPNPY_VERSION).$(PLATFORM)
LIBRMN_BUILDDIR = build/librmn-$(LIBRMN_VERSION).$(PLATFORM)
LIBRMN_STATIC = $(LIBRMN_BUILDDIR)/librmn_$(LIBRMN_VERSION).a
LIBRMN_SHARED_NAME = rmnshared_$(LIBRMN_VERSION)-rpnpy
LIBRMN_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/lib$(LIBRMN_SHARED_NAME).$(SHAREDLIB_SUFFIX)
LIBDESCRIP_BUILDDIR = build/vgrid-$(VGRID_VERSION).$(PLATFORM)
LIBDESCRIP_STATIC = $(LIBDESCRIP_BUILDDIR)/src/libdescrip.a
LIBDESCRIP_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/libdescripshared_$(VGRID_VERSION).$(SHAREDLIB_SUFFIX)
LIBBURPC_BUILDDIR = build/libburpc-$(LIBBURPC_VERSION).$(PLATFORM)
LIBBURPC_STATIC = $(LIBBURPC_BUILDDIR)/src/burp_api.a
LIBBURPC_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/libburp_c_shared_$(LIBBURPC_VERSION).$(SHAREDLIB_SUFFIX)

.PRECIOUS: $(RPNPY_BUILDDIR) $(LIBRMN_BUILDDIR) $(LIBRMN_STATIC) $(LIBDESCRIP_BUILDDIR) $(LIBDESCRIP_STATIC) $(LIBBURPC_BUILDDIR) $(LIBBURPC_STATIC)

.SUFFIXES:
.PHONY: all wheel wheel-install extra-libs

######################################################################
# Rule for building the wheel file.

wheel: $(RPNPY_BUILDDIR) $(LIBRMN_SHARED) $(LIBDESCRIP_SHARED) $(LIBBURPC_SHARED) extra-libs

WHEEL_TMPDIR = $(RPNPY_BUILDDIR)/tmp
RETAGGED_WHEEL = rpnpy-$(RPNPY_VERSION)-py2.py3-none-$(PLATFORM).whl
WHEEL_TMPDIST = $(WHEEL_TMPDIR)/rpnpy-$(RPNPY_VERSION_ALTERNATE).dist-info

# Linux builds should be done in the manylinux1 container.
ifeq ($(OS),linux)
PYTHON=/opt/python/cp27-cp27m/bin/python
else
PYTHON=python
endif

wheel:
	rm -Rf $(RPNPY_BUILDDIR)/build $(RPNPY_BUILDDIR)/dist
	# Make initial wheel.
	cd $(RPNPY_BUILDDIR) && $(PYTHON) setup.py bdist_wheel
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

wheel-install: wheel
	mkdir -p $(PWD)/wheelhouse
	cp $(RPNPY_BUILDDIR)/dist/*.whl $(PWD)/wheelhouse/


# Set up the build directory (does everything except the actual build).
$(RPNPY_BUILDDIR): python-rpn setup.py setup.cfg python-rpn.patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ python-rpn_$(RPNPY_VERSION)) | tar -xv
	cp setup.py $@
	cp setup.cfg $@
	git apply $<.patch --directory=$@
	cd $@ && env ROOT=$(PWD)/$@ rpnpy=$(PWD)/$@  make -f include/Makefile.local.mk rpnpy_version.py
	mkdir -p $@/lib/rpnpy/_sharedlibs
	touch $@/lib/rpnpy/_sharedlibs/__init__.py


######################################################################
# Rules for building the required shared libraries.

# Linux shared libraries need to be explicitly told to look in their current path for dependencies.
%.so: FFLAGS := $(FFLAGS) -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin

$(LIBRMN_SHARED): $(LIBRMN_STATIC) $(RPNPY_BUILDDIR)
	rm -f *.o
	ar -x $<
	$(GFORTRAN) -shared $(FFLAGS) -o $@ *.o
	rm -f *.o

$(LIBDESCRIP_SHARED): $(LIBDESCRIP_STATIC) $(LIBRMN_SHARED)
	rm -f *.o
	ar -x $<
	$(GFORTRAN) -shared $(FFLAGS) -o $@ *.o -l$(LIBRMN_SHARED_NAME) -L$(dir $@)
	rm -f *.o

$(LIBBURPC_SHARED): $(LIBBURPC_STATIC) $(LIBRMN_SHARED)
	rm -f *.o
	ar -x $<
	$(GFORTRAN) -shared $(FFLAGS) -o $@ *.o -l$(LIBRMN_SHARED_NAME) -L$(dir $@)
	rm -f *.o


######################################################################
# Extra libraries needed at runtime.
# Copy these into the package so they're always available.
EXTRA_LIB_DEST = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs

ifeq ($(OS),linux)

# For Linux builds, assume the user already has libgfortran installed.
# No need to explictly copy it here.
extra-libs : 

# For Windows builds, assume we need to package all the dependencies for the
# user.
else ifeq ($(OS),win)
EXTRA_LIB_SRC1 = /usr/lib/gcc/$(ARCH)-w64-mingw32/5.3-win32
EXTRA_LIB_SRC2 = /usr/$(ARCH)-w64-mingw32/lib
ifeq ($(ARCH),x86_64)
extra-libs : $(addprefix $(EXTRA_LIB_DEST)/,libgcc_s_seh-1.dll libgfortran-3.dll libwinpthread-1.dll libquadmath-0.dll)
else ifeq ($(ARCH),i686)
extra-libs : $(addprefix $(EXTRA_LIB_DEST)/,libgcc_s_sjlj-1.dll libgfortran-3.dll libwinpthread-1.dll libquadmath-0.dll)
endif

$(EXTRA_LIB_DEST)/libgcc_s_seh-1.dll : $(EXTRA_LIB_SRC1)/libgcc_s_seh-1.dll
	cp $< $@
$(EXTRA_LIB_DEST)/libgcc_s_sjlj-1.dll : $(EXTRA_LIB_SRC1)/libgcc_s_sjlj-1.dll
	cp $< $@
$(EXTRA_LIB_DEST)/libgfortran-3.dll : $(EXTRA_LIB_SRC1)/libgfortran-3.dll
	cp $< $@
$(EXTRA_LIB_DEST)/libquadmath-0.dll : $(EXTRA_LIB_SRC1)/libquadmath-0.dll
	cp $< $@
$(EXTRA_LIB_DEST)/libwinpthread-1.dll : $(EXTRA_LIB_SRC2)/libwinpthread-1.dll
	cp $< $@
endif

######################################################################
# The stuff below is for getting an updated version of gfortran.
# This is needed for compiling the vgrid code in the manylinux1 container.
ifeq ($(OS),linux)
LOCAL_GFORTRAN_VERSION = gcc-4.9.4
ifeq ($(ARCH),x86_64)
LOCAL_GFORTRAN_DIR = $(LOCAL_GFORTRAN_VERSION)
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure.tar.xz
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib64
else ifeq ($(ARCH),i686)
LOCAL_GFORTRAN_DIR = $(LOCAL_GFORTRAN_VERSION)-32bit
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure-32bit.tar.xz
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib
endif
LOCAL_GFORTRAN_TAR = $(LOCAL_GFORTRAN_VERSION).$(ARCH).tar.xz
LOCAL_GFORTRAN_BIN = $(LOCAL_GFORTRAN_DIR)/bin
$(LOCAL_GFORTRAN_DIR): $(LOCAL_GFORTRAN_TAR) $(LOCAL_GFORTRAN_EXTRA)
	xzdec $< | tar -xv
	xzdec $(LOCAL_GFORTRAN_EXTRA) | tar -xv -C $@
	mv $@/bin $@/bin.orig
	mkdir $@/bin
	cd $@/bin && ln -s ../bin.orig/gfortran .
	touch $@
$(LOCAL_GFORTRAN_TAR):
	wget http://gfortran.meteodat.ch/download/$(ARCH)/releases/$(LOCAL_GFORTRAN_VERSION).tar.xz
	mv $(LOCAL_GFORTRAN_VERSION).tar.xz $@
$(LOCAL_GFORTRAN_EXTRA):
	wget http://gfortran.meteodat.ch/download/$(ARCH)/$@
endif
#
######################################################################


######################################################################
# Rules for building the static libraries from source.

# Pre-requisite packages for required headers and compiler rules.
code-tools:
	git clone https://github.com/mfvalin/code-tools.git
armnlib_2.0u_all:
	wget http://armnlib.uqam.ca//armnlib/repository/armnlib_2.0u_all.ssm
	tar -xzvf armnlib_2.0u_all.ssm
	touch $@
env-include: code-tools armnlib_2.0u_all
	mkdir -p $@
	cp -R code-tools/include/* $@/
	cp -R armnlib_2.0u_all/include/* $@/
	# Add a quick and dirty 32-bit option.
	mkdir -p $@/Linux_gfortran
	sed 's/PTR_AS_INT long long/PTR_AS_INT int/' $@/Linux_x86-64_gfortran/rpn_macros_arch.h > $@/Linux_gfortran/rpn_macros_arch.h
	cp $@/Linux_x86-64_gfortran/Compiler_rules $@/Linux_gfortran/

$(LIBRMN_STATIC): $(LIBRMN_BUILDDIR) env-include
	cd $< && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) make
	touch $@

$(LIBDESCRIP_STATIC): $(LIBDESCRIP_BUILDDIR) env-include $(LOCAL_GFORTRAN_DIR)
	cd $</src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) PATH=$(PWD)/$(LOCAL_GFORTRAN_BIN):$(PATH) LD_LIBRARY_PATH=$(PWD)/$(LOCAL_GFORTRAN_LIB) make
	touch $@

$(LIBBURPC_STATIC): $(LIBBURPC_BUILDDIR) env-include $(LOCAL_GFORTRAN_DIR)
	cd $</src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) make
	touch $@

$(LIBRMN_BUILDDIR): librmn librmn.$(OS).patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ Release-$(LIBRMN_VERSION)) | tar -xv
	git apply $<.$(OS).patch --directory=$@
	touch $@

$(LIBDESCRIP_BUILDDIR): vgrid vgrid.patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ $(VGRID_VERSION)) | tar -xv
	git apply $<.patch --directory=$@
	touch $@

$(LIBBURPC_BUILDDIR): libburpc libburpc.patch
	rm -Rf $@
	(cd $< && git archive --prefix=$@/ $(LIBBURPC_VERSION)) | tar -xv
	git apply $<.patch --directory=$@
	touch $@


######################################################################
# Rules for getting the required source packages.

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git -b python-rpn_$(RPNPY_VERSION)

librmn:
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION)

vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION)

libburpc:
	git clone https://github.com/josecmc/libburp.git $@
	cd $@ && git checkout $(LIBBURPC_VERSION)

