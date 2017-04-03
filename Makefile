######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

include include/platforms.mk

RPNPY_VERSION = 2.0.4
LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10

# Locations to build static / shared libraries.
# Here, '%' is a pattern rule to match a particlar architecture.
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
.PHONY: all wheel extra-libs gfortran

######################################################################
# Rules for building the final package.

all: wheel

wheel: $(RPNPY_BUILDDIR) $(LIBRMN_SHARED) $(LIBDESCRIP_SHARED) extra-libs local_env
	cd $< && $(PWD)/local_env/bin/python setup.py bdist_wheel --dist-dir=$(PWD) --plat-name=$(PLATFORM)
	exit 0


# Need an updated 'wheel' package to build linux_i686 on x86_64 machines.
# Tested on wheel v0.29
local_env:
	virtualenv $@
	$@/bin/pip install "wheel>=0.29.0"

$(RPNPY_BUILDDIR): python-rpn setup.py setup.cfg python-rpn.patch
	rm -Rf $@
	git -C $< archive --prefix=$@/ python-rpn_$(RPNPY_VERSION) | tar -xv
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


######################################################################
# Extra libraries needed at runtime.
EXTRA_LIB_DEST = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs
ifeq ($(OS),win)
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
# Rules for building the static libraries from source.

$(LIBRMN_STATIC): $(LIBRMN_BUILDDIR) env-include
	cd $< && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) make
	touch $@

$(LIBDESCRIP_STATIC): $(LIBDESCRIP_BUILDDIR) env-include $(MINGW_GFORTRAN_DIR)
	cd $</src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) PATH=$(PWD)/$(MINGW_GFORTRAN_DIR)/usr/bin:$(PATH) LD_LIBRARY_PATH=$(PWD)/$(MINGW_GFORTRAN_DIR)/usr/lib/ make
	touch $@
#	cd $</src && \
#	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) ARCH=$(ARCH_FROM_BUILDDIR) PATH=$(PWD)/gcc-$(GFORTRAN_VERSION)/bin:$(PATH) LD_LIBRARY_PATH=$(PWD)/gcc-$(GFORTRAN_VERSION)/lib64 make

$(LIBRMN_BUILDDIR): librmn librmn.patch
	rm -Rf $@
	git -C $< archive --prefix=$@/ Release-$(LIBRMN_VERSION) | tar -xv
	git apply $<.patch --directory=$@

$(LIBDESCRIP_BUILDDIR): vgrid vgrid.patch
	rm -Rf $@
	git -C $< archive --prefix=$@/ $(VGRID_VERSION) | tar -xv
	git apply $<.patch --directory=$@


######################################################################
# Rules for getting the required source packages.

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git -b python-rpn_$(RPNPY_VERSION) && \

librmn:
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION) && \

vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION) && \

# This is needed for compiling librmn.  It has some crucial headers like
# rpnmacros.h.
# Unfortunately, I can't find a public-facing version of this repository, so
# it has to be grabbed from the CMC network.
# Alternatively, you can copy the directory from someone else who already has
# a version of it.
env-include:
	git clone joule:/home/dormrb02/GIT-depots/env-include.git


######################################################################
# The stuff below is for getting an updated version of gfortran.
# This is needed for compiling the vgrid code in Ubuntu 14.04.
# It may not be required for Ubuntu 16.04, so if you have a mroe recent
# distribution you can probably remove this section, and remove the gfortran-
# related stuff from the $(LIBDESCRIP_STATIC) rule.

GFORTRAN_VERSION = 4.9.4

gfortran: gcc-$(GFORTRAN_VERSION)

gcc-$(GFORTRAN_VERSION): gcc-$(GFORTRAN_VERSION).tar.xz gcc-4.8-infrastructure.tar.xz
	tar -xJvf gcc-$(GFORTRAN_VERSION).tar.xz
	tar -xJvf gcc-4.8-infrastructure.tar.xz -C $@
	mv $@/bin $@/bin.orig
	mkdir $@/bin
	cd $@/bin && ln -s ../bin.orig/gfortran .
	touch $@

gcc-$(GFORTRAN_VERSION).tar.xz:
	wget http://gfortran.meteodat.ch/download/x86_64/releases/$@

gcc-4.8-infrastructure.tar.xz:
	wget http://gfortran.meteodat.ch/download/x86_64/$@

######################################################################
# The following stuff is required for compiling vgrid for Windows.
# The default mingw-w64 package on Ubuntu 14.04 has the same problem as
# the gfortran package in the section above - so, need to download
# a local copy.
ifeq ($(ARCH),i686)
MINGW_GFORTRAN_DIR = gfortran-mingw-w64-i686_4.9.1-19+14.3_amd64
else ifeq ($(ARCH),x86_64)
MINGW_GFORTRAN_DIR = gfortran-mingw-w64-x86-64_4.9.1-19+14.3_amd64
endif

$(MINGW_GFORTRAN_DIR): $(MINGW_GFORTRAN_DIR).deb
	dpkg-deb -x $< $@
	cd $@/usr/bin && ln -s $(GFORTRAN)-win32 $(GFORTRAN)
	touch $@
	
$(MINGW_GFORTRAN_DIR).deb:
	wget http://ftp.us.debian.org/debian/pool/main/g/gcc-mingw-w64/$@

