
RPNPY_VERSION = 2.0.4
LIBRMN_VERSION = 016.2
VGRID_VERSION = 6.1.10
GFORTRAN_VERSION = 4.9.4

LIBRMN = librmn/librmn_$(LIBRMN_VERSION).a
LIBVGRID = vgrid/src/libdescrip.a

.PHONY: test gfortran

test: $(LIBRMN) $(LIBVGRID) python-rpn
	cd python-rpn  && \
	env ROOT=$(PWD)/python-rpn rpnpy=$(PWD)/python-rpn  make -f include/Makefile.local.mk rpnpy_version.py

librmn:
	git clone https://github.com/armnlib/librmn.git -b Release-$(LIBRMN_VERSION) && \
	cd librmn && \
	git apply ../librmn.patch


vgrid:
	git clone https://gitlab.com/ECCC_CMDN/vgrid.git -b $(VGRID_VERSION) && \
	cd vgrid && \
	git apply ../vgrid.patch

python-rpn:
	git clone https://github.com/meteokid/python-rpn.git -b python-rpn_$(RPNPY_VERSION) && \
	cd python-rpn && \
	git apply ../python-rpn.patch

env-include:
	git clone joule:/home/dormrb02/GIT-depots/env-include.git

gfortran: gcc-$(GFORTRAN_VERSION)

gcc-$(GFORTRAN_VERSION): gcc-$(GFORTRAN_VERSION).tar.xz gcc-4.8-infrastructure.tar.xz
	tar -xJvf gcc-$(GFORTRAN_VERSION).tar.xz
	tar -xJvf gcc-4.8-infrastructure.tar.xz -C gcc-$(GFORTRAN_VERSION)
	touch $@

gcc-$(GFORTRAN_VERSION).tar.xz:
	wget http://gfortran.meteodat.ch/download/x86_64/releases/$@

gcc-4.8-infrastructure.tar.xz:
	wget http://gfortran.meteodat.ch/download/x86_64/gcc-4.8-infrastructure.tar.xz

$(LIBRMN): librmn env-include
	cd librmn && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) make

$(LIBVGRID): vgrid env-include gfortran
	cd vgrid/src && \
	env RPN_TEMPLATE_LIBS=$(PWD) PROJECT_ROOT=$(PWD) PATH=$(PWD)/gcc-$(GFORTRAN_VERSION)/bin:$(PATH) LD_LIBRARY_PATH=$(PWD)/gcc-$(GFORTRAN_VERSION)/lib64 CFLAGS="$(CFLAGS) -I/usr/include/x86_64-linux-gnu/" make
