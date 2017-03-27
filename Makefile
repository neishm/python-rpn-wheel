######################################################################
# Rules for compiling python-rpn into a standalone package, for use outside
# the CMC network.
# See README.md for proper usage.

RPNPY_VERSION = 2.0.4
LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10

LIBRMN_STATIC = librmn/librmn_$(LIBRMN_VERSION).a
LIBRMN_SHARED_NAME = rmnshared_$(LIBRMN_VERSION)-rpnpy
LIBRMN_SHARED = python-rpn/lib/rpnpy/librmn/lib$(LIBRMN_SHARED_NAME).so
LIBVGRID_STATIC = vgrid/src/libdescrip.a
LIBVGRID_SHARED = python-rpn/lib/rpnpy/vgd/libdescripshared_$(VGRID_VERSION).so

.PHONY: all gfortran


######################################################################
# Rules for building the final package.

all: python-rpn/lib/rpnpy/version.py $(LIBRMN_SHARED) $(LIBVGRID_SHARED)
	python setup.py bdist_wheel

python-rpn/lib/rpnpy/version.py: python-rpn
	cd python-rpn  && \
	env ROOT=$(PWD)/python-rpn rpnpy=$(PWD)/python-rpn  make -f include/Makefile.local.mk rpnpy_version.py

######################################################################
# Rules for building the required shared libraries.
$(LIBRMN_SHARED): $(LIBRMN_STATIC) python-rpn
	rm -f *.o
	ar -x $<
	gfortran -shared -o $@ *.o
	rm -f *.o

$(LIBVGRID_SHARED): $(LIBVGRID_STATIC) python-rpn
	rm -f *.o
	ar -x $<
	gfortran -shared -o $@ *.o -l$(LIBRMN_SHARED_NAME) -L$(dir $(LIBRMN_SHARED)) -Wl,-rpath,'$$ORIGIN/../librmn' -Wl,-z,origin
	rm -f *.o


######################################################################
# Rules for building the static libraries from source.

$(LIBRMN_STATIC): librmn env-include
	cd librmn && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) make

$(LIBVGRID_STATIC): vgrid env-include gfortran
	cd vgrid/src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PATH=$(PWD)/gcc-$(GFORTRAN_VERSION)/bin:$(PATH) LD_LIBRARY_PATH=$(PWD)/gcc-$(GFORTRAN_VERSION)/lib64 make


######################################################################
# Rules for getting the required source packages.

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git -b python-rpn_$(RPNPY_VERSION) && \
	cd python-rpn && \
	git apply ../python-rpn.patch

librmn:
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION) && \
	cd librmn && \
	git apply ../librmn.patch

vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION) && \
	cd vgrid && \
	git apply ../vgrid.patch

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
# related stuff from the $(LIBVGRID_STATIC) rule.

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

