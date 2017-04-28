######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

FSTD2NC_VERSION = 0-20170427
RPNPY_VERSION = 2.0.4
LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10

# If no platform specified, build all platforms.
ifeq ($(PLATFORM),)
all:
	make PLATFORM=linux_x86_64
	make PLATFORM=linux_i686
	make PLATFORM=win_amd64
	make PLATFORM=win32
clean:
	make clean PLATFORM=linux_x86_64
	make clean PLATFORM=linux_i686
	make clean PLATFORM=win_amd64
	make clean PLATFORM=win32
else
include include/platforms.mk
all: wheel
clean:
	rm -f *.o *.whl
	rm -Rf *.$(PLATFORM)
endif

# Locations to build static / shared libraries.
RPNPY_BUILDDIR = python-rpn-$(RPNPY_VERSION).$(PLATFORM)
LIBRMN_BUILDDIR = librmn-$(LIBRMN_VERSION).$(PLATFORM)
LIBRMN_STATIC = $(LIBRMN_BUILDDIR)/librmn_$(LIBRMN_VERSION).a
LIBRMN_SHARED_NAME = rmnshared_$(LIBRMN_VERSION)-rpnpy
LIBRMN_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/lib$(LIBRMN_SHARED_NAME).$(SHAREDLIB_SUFFIX)
LIBDESCRIP_BUILDDIR = vgrid-$(VGRID_VERSION).$(PLATFORM)
LIBDESCRIP_STATIC = $(LIBDESCRIP_BUILDDIR)/src/libdescrip.a
LIBDESCRIP_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/libdescripshared_$(VGRID_VERSION).$(SHAREDLIB_SUFFIX)

.PRECIOUS: $(RPNPY_BUILDDIR) $(LIBRMN_BUILDDIR) $(LIBRMN_STATIC) $(LIBDESCRIP_BUILDDIR) $(LIBDESCRIP_STATIC)

.SUFFIXES:
.PHONY: all wheel extra-libs

######################################################################
# Rule for building the wheel file.

wheel: $(RPNPY_BUILDDIR) $(LIBRMN_SHARED) $(LIBDESCRIP_SHARED) extra-libs local_env

# Linux wheel is straight-forward (we're building on a Linux system!)
ifeq ($(OS),linux)
wheel:
	cd $(RPNPY_BUILDDIR) && $(PWD)/local_env/bin/python setup.py bdist_wheel --plat-name=manylinux1_$(ARCH) --dist-dir=$(PWD)

# Need to massage the Windows wheels to have the right ABI tag.
else ifeq ($(OS),win)
ORIG_WHEEL = $(RPNPY_BUILDDIR)/dist/rpnpy-$(RPNPY_VERSION)-cp27-cp27mu-$(PLATFORM).whl
FINAL_WHEEL = rpnpy-$(RPNPY_VERSION)-cp27-cp27m-$(PLATFORM).whl
WHEEL_TMPDIR = $(RPNPY_BUILDDIR)/tmp
WHEEL_TMPDIST = $(WHEEL_TMPDIR)/rpnpy-$(RPNPY_VERSION).dist-info
wheel:
	cd $(RPNPY_BUILDDIR) && $(PWD)/local_env/bin/python setup.py bdist_wheel --plat-name=$(PLATFORM)
	rm -Rf $(WHEEL_TMPDIR)
	mkdir $(WHEEL_TMPDIR)
	cd $(WHEEL_TMPDIR) && unzip $(PWD)/$(ORIG_WHEEL)
	# Fix the ABI tag
	sed -i 's/cp27mu/cp27m/' $(WHEEL_TMPDIST)/WHEEL
	# Update SHA-1 sums for the RECORD file.
	rm -Rf $(WHEEL_TMPDIST)/RECORD
	./local_env/bin/python -c "from distutils.core import Distribution; from wheel.bdist_wheel import bdist_wheel; bdist_wheel(Distribution()).write_record('$(WHEEL_TMPDIR)','$(WHEEL_TMPDIST)')"
	cd $(WHEEL_TMPDIR) && zip -r $(PWD)/$(FINAL_WHEEL) .

endif

# Need an updated 'wheel' package to build linux_i686 on x86_64 machines.
# Tested on wheel v0.29
local_env:
	virtualenv $@
	$@/bin/pip install "wheel>=0.29.0"

# Set up the build directory (does everything except the actual build).
$(RPNPY_BUILDDIR): python-rpn setup.py setup.cfg python-rpn.patch pygeode-rpn
	rm -Rf $@
	git -C $< archive --prefix=$@/ python-rpn_$(RPNPY_VERSION) | tar -xv
	cp setup.py $@
	cp setup.cfg $@
	git apply $<.patch --directory=$@
	cd $@ && env ROOT=$(PWD)/$@ rpnpy=$(PWD)/$@  make -f include/Makefile.local.mk rpnpy_version.py
	mkdir -p $@/lib/rpnpy/_sharedlibs
	touch $@/lib/rpnpy/_sharedlibs/__init__.py
	echo 'import fstd2nc_deps as _deps, os, sys; sys.path.append(os.path.dirname(_deps.__file__)); del _deps, os, sys' > $@/fstd2nc.py
	git -C pygeode-rpn show fstd2nc_$(FSTD2NC_VERSION):fstd2nc.py >> $@/fstd2nc.py
	mv $@/lib $@/fstd2nc_deps
	ln -s $(PWD)/$@/fstd2nc_deps $@/lib
	touch $@/fstd2nc_deps/__init__.py


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


######################################################################
# Extra libraries needed at runtime.
# Copy these into the package so they're always available.
EXTRA_LIB_DEST = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs

ifeq ($(OS),linux)
extra-libs : $(addprefix $(EXTRA_LIB_DEST)/,libgfortran.so.3 libquadmath.so.0)
ifeq ($(ARCH),x86_64)
EXTRA_LIB_SRC = /usr/lib32
else ifeq ($(ARCH),i686)
EXTRA_LIB_SRC = /usr/lib/x86_64-linux-gnu
endif
$(EXTRA_LIB_DEST)/libgfortran.so.3 : $(EXTRA_LIB_SRC)/libgfortran.so.3
	cp $< $@
$(EXTRA_LIB_DEST)/libquadmath.so.0 : $(EXTRA_LIB_SRC)/libquadmath.so.0
	cp $< $@

else ifeq ($(OS),win)
EXTRA_LIB_SRC1 = /usr/lib/gcc/$(ARCH)-w64-mingw32/4.8
EXTRA_LIB_SRC2 = /usr/$(ARCH)-w64-mingw32/lib
extra-libs : $(addprefix $(EXTRA_LIB_DEST)/,libgcc_s_sjlj-1.dll libgfortran-3.dll libwinpthread-1.dll libquadmath-0.dll)
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
# This is needed for compiling the vgrid code in Ubuntu 14.04.
# It may not be required for Ubuntu 16.04, so if you have a more recent
# distribution you can probably remove this section, and remove the gfortran-
# related stuff from the $(LIBDESCRIP_STATIC) rule.
ifeq ($(OS),linux)
LOCAL_GFORTRAN_DIR = gcc-4.9.4
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/lib64
LOCAL_GFORTRAN_BIN = $(LOCAL_GFORTRAN_DIR)/bin
LOCAL_GFORTRAN_EXTRA = gcc-4.8-infrastructure.tar.xz
$(LOCAL_GFORTRAN_DIR): $(LOCAL_GFORTRAN_DIR).tar.xz $(LOCAL_GFORTRAN_EXTRA)
	tar -xJvf $<
	tar -xJvf $(LOCAL_GFORTRAN_EXTRA) -C $@
	mv $@/bin $@/bin.orig
	mkdir $@/bin
	cd $@/bin && ln -s ../bin.orig/gfortran .
	touch $@
$(LOCAL_GFORTRAN_DIR).tar.xz:
	wget http://gfortran.meteodat.ch/download/x86_64/releases/$@
$(LOCAL_GFORTRAN_EXTRA):
	wget http://gfortran.meteodat.ch/download/x86_64/$@

else ifeq ($(OS),win)
ifeq ($(PLATFORM),win32)
LOCAL_GFORTRAN_DIR = gfortran-mingw-w64-i686_4.9.1-19+14.3_amd64
else ifeq ($(PLATFORM),win_amd64)
LOCAL_GFORTRAN_DIR = gfortran-mingw-w64-x86-64_4.9.1-19+14.3_amd64
endif
LOCAL_GFORTRAN_LIB = $(LOCAL_GFORTRAN_DIR)/usr/lib
LOCAL_GFORTRAN_BIN = $(LOCAL_GFORTRAN_DIR)/usr/bin
$(LOCAL_GFORTRAN_DIR): $(LOCAL_GFORTRAN_DIR).deb
	dpkg-deb -x $< $@
	cd $@/usr/bin && ln -s $(GFORTRAN)-win32 $(GFORTRAN)
	touch $@
$(LOCAL_GFORTRAN_DIR).deb:
	wget http://ftp.us.debian.org/debian/pool/main/g/gcc-mingw-w64/$@

endif
#
######################################################################


######################################################################
# Rules for building the static libraries from source.

$(LIBRMN_STATIC): $(LIBRMN_BUILDDIR) env-include
	cd $< && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) make
	touch $@

$(LIBDESCRIP_STATIC): $(LIBDESCRIP_BUILDDIR) env-include $(LOCAL_GFORTRAN_DIR)
	cd $</src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) PATH=$(PWD)/$(LOCAL_GFORTRAN_BIN):$(PATH) LD_LIBRARY_PATH=$(PWD)/$(LOCAL_GFORTRAN_LIB) make
	touch $@

$(LIBRMN_BUILDDIR): librmn librmn.$(OS).patch
	rm -Rf $@
	git -C $< archive --prefix=$@/ Release-$(LIBRMN_VERSION) | tar -xv
	git apply $<.$(OS).patch --directory=$@
	touch $@

$(LIBDESCRIP_BUILDDIR): vgrid vgrid.patch
	rm -Rf $@
	git -C $< archive --prefix=$@/ $(VGRID_VERSION) | tar -xv
	git apply $<.patch --directory=$@
	touch $@


######################################################################
# Rules for getting the required source packages.

pygeode-rpn:
	git clone https://github.com/neishm/pygeode-rpn.git -b fstd2nc_$(FSTD2NC_VERSION)

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git -b python-rpn_$(RPNPY_VERSION)

librmn:
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION)

vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION)

# This is needed for compiling librmn.  It has some crucial headers like
# rpnmacros.h.
# Unfortunately, I can't find a public-facing version of this repository, so
# it has to be grabbed from the CMC network.
# Alternatively, you can copy the directory from someone else who already has
# a version of it.
env-include:
	git clone joule:/home/dormrb02/GIT-depots/env-include.git


