LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.4.b2
# commit id for libburpc version 1.9 with LGPL license
LIBBURPC_VERSION = 3a2d4f

include include/platforms.mk

# Locations to build static / shared libraries.
LIBRMN_SRCDIR = $(RPNPY_SRCDIR)/src/librmn-$(LIBRMN_VERSION)
LIBRMN_BUILDDIR = $(BUILDDIR)/librmn-$(LIBRMN_VERSION).$(PLATFORM)
LIBRMN_STATIC = $(LIBRMN_BUILDDIR)/librmn_$(LIBRMN_VERSION).a
LIBRMN_SHARED_NAME = rmnshared_$(LIBRMN_VERSION)-rpnpy
LIBRMN_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/lib$(LIBRMN_SHARED_NAME).$(SHAREDLIB_SUFFIX)
LIBDESCRIP_SRCDIR = $(RPNPY_SRCDIR)/src/vgrid-$(VGRID_VERSION)
LIBDESCRIP_BUILDDIR = $(BUILDDIR)/vgrid-$(VGRID_VERSION).$(PLATFORM)
LIBDESCRIP_STATIC = $(LIBDESCRIP_BUILDDIR)/src/libdescrip.a
LIBDESCRIP_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/libdescripshared_$(VGRID_VERSION).$(SHAREDLIB_SUFFIX)
LIBBURPC_SRCDIR = $(RPNPY_SRCDIR)/src/libburpc-$(LIBBURPC_VERSION)
LIBBURPC_BUILDDIR = $(BUILDDIR)/libburpc-$(LIBBURPC_VERSION).$(PLATFORM)
LIBBURPC_STATIC = $(LIBBURPC_BUILDDIR)/src/burp_api.a
LIBBURPC_SHARED = $(RPNPY_BUILDDIR)/lib/rpnpy/_sharedlibs/libburp_c_shared_$(LIBBURPC_VERSION).$(SHAREDLIB_SUFFIX)

.PRECIOUS: $(RPNPY_BUILDDIR) $(LIBRMN_BUILDDIR) $(LIBRMN_STATIC) $(LIBDESCRIP_BUILDDIR) $(LIBDESCRIP_STATIC) $(LIBBURPC_BUILDDIR) $(LIBBURPC_STATIC)

.SUFFIXES:

######################################################################
# Rules for building the required shared libraries.

# Linux shared libraries need to be explicitly told to look in their current path for dependencies.
%.so: FFLAGS := $(FFLAGS) -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin

$(LIBRMN_SHARED): $(LIBRMN_STATIC) $(RPNPY_BUILDDIR)
	rm -f *.o
	ar -x $<
	$(GFORTRAN) -shared $(FFLAGS) -o $@ *.o $(EXTRA_LINKS)
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
# Rules for building the static libraries from source.

$(LIBRMN_STATIC): $(LIBRMN_BUILDDIR)
	cd $< && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) make
	touch $@

# Note: LOCAL_GFORTRAN_BIN and LOCAL_GFORTRAN_LIB are optional extra paths for
# using a custom version of gfortran to do the initial object creation.
# Useful if the system-installed version is too old to support the latest
# Fortran syntax.
$(LIBDESCRIP_STATIC): $(LIBDESCRIP_BUILDDIR)
	cd $</src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) PATH=$(PWD)/$(LOCAL_GFORTRAN_BIN):$(PATH) LD_LIBRARY_PATH=$(PWD)/$(LOCAL_GFORTRAN_LIB) make
	touch $@

$(LIBBURPC_STATIC): $(LIBBURPC_BUILDDIR)
	cd $</src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PLATFORM=$(PLATFORM) make
	touch $@

$(LIBRMN_BUILDDIR): $(LIBRMN_SRCDIR)
	cp -R $< $@

$(LIBDESCRIP_BUILDDIR): $(LIBDESCRIP_SRCDIR)
	cp -R $< $@

$(LIBBURPC_BUILDDIR): $(LIBBURPC_SRCDIR)
	cp -R $< $@

