# Top-level makefile for building the shared library dependencies.
include include/platforms.mk

static:
	cd librmn-016.2 && make PROJECT_ROOT=$(PWD) RPN_TEMPLATE_LIBS=$(PWD)
	cd vgrid-6.4.b2 && PROJECT_ROOT=$(PWD) RPN_TEMPLATE_LIBS=$(PWD)
	cd liburpc-3a2d4f && PROJECT_ROOT=$(PWD) RPN_TEMPLATE_LIBS=$(PWD)
