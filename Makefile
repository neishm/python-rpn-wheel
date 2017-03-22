# For compiling librmn

LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10

# Point to our makefile_suffix_rules.inc
RPN_TEMPLATE_LIBS = $(PWD)

.PHONY: all

LIBRMN_DIR = librmn-Release-$(LIBRMN_VERSION)
VGRID_DIR = vgrid-$(VGRID_VERSION)


all: $(LIBRMN_DIR) $(VGRID_DIR)

$(LIBRMN_DIR):
	curl -L https://github.com/armnlib/librmn/archive/Release-$(LIBRMN_VERSION).tar.gz -o $@.tar.gz
	tar -xzvf $@.tar.gz

$(VGRID_DIR):
	curl -L https://gitlab.com/ECCC_CMDN/vgrid/repository/archive.tar.gz?ref=$(VGRID_VERSION) -o $@.tar.gz
	tar -xzvf $@.tar.gz --transform 's/\(^vgrid-[^-]*\)-[a-z0-9]*/\1/'


