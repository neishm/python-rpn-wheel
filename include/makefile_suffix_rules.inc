# Header files for linking against librmn
PUBLIC_INCLUDES=$(PROJECT_ROOT)/librmn-016.2/PUBLIC_INCLUDES

# Location of rpn_macros_arch.h
RPN_MACRO_DIR = $(PROJECT_ROOT)/include


# Set default fortran compiler to gfortran.
ifeq ($(origin FC),default)
FC = gfortran
endif
ifneq (,$(findstring gfortran,$(FC)))
FFLAGS := $(FFLAGS) -fcray-pointer -ffree-line-length-none
endif



INC = -I. -I$(PROJECT_ROOT)/include -I$(RPN_MACRO_DIR) -I$(PUBLIC_INCLUDES)

.c.o:
	$(CC) -fPIC -O$(OPTIMIZ) $(CFLAGS) $(INC) -c $<

.o.a:
	ar rv $@ $<
	rm -f $*.o

.ftn.f .ftn90.f90:
	cpp $(INC) $< $@

.f.o .F.o .f90.o .F90.o:
	$(FC) -fPIC -O$(OPTIMIZ) $(FFLAGS) $(INC) -c $<


