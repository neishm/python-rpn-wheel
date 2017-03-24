# For compiling librmn

LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10

LIBRMN = librmn/librmn_$(LIBRMN_VERSION).a
LIBVGRID = vgrid/src/libdescrip.a

.PHONY: all packages libs

libs: $(LIBRMN) $(LIBVGRID)

packages: librmn vgrid python-rpn env-include

librmn:
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION) && \
	cd librmn && \
	git apply ../librmn.patch


vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION) && \
	cd vgrid && \
	git apply ../vgrid.patch

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git

env-include:
	git clone joule:/home/dormrb02/GIT-depots/env-include.git


$(LIBRMN): librmn env-include
	cd librmn && \
	env RPN_TEMPLATE_LIBS=$(PWD) make

$(LIBVGRID): vgrid env-include
	cd vgrid/src && \
	env RPN_TEMPLATE_LIBS=$(PWD) make
