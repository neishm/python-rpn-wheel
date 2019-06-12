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

# Set default shared library extension for Linux.
SHAREDLIB_SUFFIX ?= so

