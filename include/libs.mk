LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.4.b2
LIBBURPC_VERSION = 1.9
# commit id for libburpc version 1.9 with LGPL license
LIBBURPC_COMMIT = 3a2d4f

include include/makefile_suffix_rules.inc

# Set default shared library extension.
SHAREDLIB_SUFFIX ?= so

# Locations to build static / shared libraries.
LIBRMN_BUILDDIR = $(BUILDDIR)/librmn-$(LIBRMN_VERSION)
LIBRMN_STATIC = $(LIBRMN_BUILDDIR)/librmn_$(LIBRMN_VERSION).a
LIBRMN_SHARED_NAME = rmnshared_$(LIBRMN_VERSION)-rpnpy
LIBRMN_SHARED = $(SHAREDLIB_DIR)/lib$(LIBRMN_SHARED_NAME).$(SHAREDLIB_SUFFIX)
LIBDESCRIP_BUILDDIR = $(BUILDDIR)/vgrid-$(VGRID_VERSION)
LIBDESCRIP_STATIC = $(LIBDESCRIP_BUILDDIR)/src/libdescrip.a
LIBDESCRIP_SHARED = $(SHAREDLIB_DIR)/libdescripshared_$(VGRID_VERSION).$(SHAREDLIB_SUFFIX)
LIBBURPC_BUILDDIR = $(BUILDDIR)/libburpc-$(LIBBURPC_VERSION)
LIBBURPC_STATIC = $(LIBBURPC_BUILDDIR)/src/burp_api.a
LIBBURPC_SHARED = $(SHAREDLIB_DIR)/libburp_c_shared_$(LIBBURPC_VERSION).$(SHAREDLIB_SUFFIX)

.PRECIOUS: $(SHAREDLIB_DIR) $(LIBRMN_BUILDDIR) $(LIBRMN_STATIC) $(LIBDESCRIP_BUILDDIR) $(LIBDESCRIP_STATIC) $(LIBBURPC_BUILDDIR) $(LIBBURPC_STATIC)

.SUFFIXES:

######################################################################
# Rules for building the required shared libraries.

# Linux shared libraries need to be explicitly told to look in their current path for dependencies.
%.so: FFLAGS := $(FFLAGS) -Wl,-rpath,'$$ORIGIN' -Wl,-z,origin

$(LIBRMN_SHARED): $(LIBRMN_STATIC)
	rm -f *.o
	ar -x $<
	$(FC) -shared -o $@ *.o $(FFLAGS)
	rm -f *.o

$(LIBDESCRIP_SHARED): $(LIBDESCRIP_STATIC) $(LIBRMN_SHARED)
	rm -f *.o
	ar -x $<
	$(FC) -shared -o $@ *.o $(FFLAGS) -l$(LIBRMN_SHARED_NAME) -L$(dir $@)
	rm -f *.o

$(LIBBURPC_SHARED): $(LIBBURPC_STATIC) $(LIBRMN_SHARED)
	rm -f *.o
	ar -x $<
	$(FC) -shared -o $@ *.o $(FFLAGS) -l$(LIBRMN_SHARED_NAME) -L$(dir $@)
	rm -f *.o

######################################################################
# Rules for building the static libraries from source.

$(LIBRMN_STATIC): $(LIBRMN_BUILDDIR)
	cd $< && \
	env PROJECT_ROOT=$(BUILDDIR) $(MAKE)
	touch $@

$(LIBDESCRIP_STATIC): $(LIBDESCRIP_BUILDDIR)
	cd $</src && \
	env PROJECT_ROOT=$(BUILDDIR) $(MAKE)
	touch $@

$(LIBBURPC_STATIC): $(LIBBURPC_BUILDDIR)
	cd $</src && \
	env PROJECT_ROOT=$(BUILDDIR) $(MAKE)
	touch $@

