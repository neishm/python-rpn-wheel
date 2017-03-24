# For compiling librmn

LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10

LIBRMN = librmn/librmn_$(LIBRMN_VERSION).a

.PHONY: all packages libs

libs: $(LIBRMN)

packages: librmn vgrid python-rpn env-include

librmn:
	git clone https://github.com/armnlib/librmn.git

vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git

env-include:
	git clone joule:/home/dormrb02/GIT-depots/env-include.git


$(LIBRMN): librmn
	cd librmn; env RPN_TEMPLATE_LIBS=$(PWD) make

