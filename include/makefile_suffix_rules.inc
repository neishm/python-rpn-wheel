# Header files for linking against librmn
PUBLIC_INCLUDES=$(PROJECT_ROOT)/librmn-016.2/PUBLIC_INCLUDES

# Location of rpn_macros_arch.h
RPN_MACRO_DIR = $(PROJECT_ROOT)/include

# Check PLATFORM to determine the build environment
ifeq ($(PLATFORM),manylinux1_x86_64)
  CFLAGS := $(CFLAGS) -m64
  FFLAGS := $(FFLAGS) -m64
else ifeq ($(PLATFORM),manylinux1_i686)
  CFLAGS := $(CFLAGS) -m32
  FFLAGS := $(FFLAGS) -m32
else ifeq ($(PLATFORM),manylinux2010_x86_64)
  CFLAGS := $(CFLAGS) -m64
  FFLAGS := $(FFLAGS) -m64
else ifeq ($(PLATFORM),win_amd64)
  CC = x86_64-w64-mingw32-gcc
  FC = x86_64-w64-mingw32-gfortran
  FFLAGS := $(FFLAGS) -lws2_32 -lpthread
  SHAREDLIB_SUFFIX = dll
else ifeq ($(PLATFORM),win32)
  CC = i686-w64-mingw32-gcc
  FC = i686-w64-mingw32-gfortran
  FFLAGS := $(FFLAGS) -lws2_32 -lpthread
  SHAREDLIB_SUFFIX = dll
endif

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


