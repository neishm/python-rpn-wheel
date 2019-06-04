# Header files for linking against librmn
PUBLIC_INCLUDES=$(PROJECT_ROOT)/librmn-016.2/PUBLIC_INCLUDES

# Location of rpn_macros_arch.h
RPN_MACRO_DIR = $(PROJECT_ROOT)/include

# Check PLATFORM to determine the build environment
ifeq ($(PLATFORM),manylinux1_x86_64)
  ARCH = x86_64
  GCC = gcc
  CFLAGS := $(CFLAGS) -m64
  GFORTRAN = gfortran
  FFLAGS := $(FFLAGS) -m64
  SHAREDLIB_SUFFIX = so
else ifeq ($(PLATFORM),manylinux1_i686)
  ARCH = i686
  GCC = gcc
  CFLAGS := $(CFLAGS) -m32
  GFORTRAN = gfortran
  FFLAGS := $(FFLAGS) -m32
  SHAREDLIB_SUFFIX = so
else ifeq ($(PLATFORM),win_amd64)
  ARCH = x86_64
  GCC = $(ARCH)-w64-mingw32-gcc
  GFORTRAN = $(ARCH)-w64-mingw32-gfortran
  EXTRA_LINKS := -lws2_32 -lpthread
  SHAREDLIB_SUFFIX = dll
else ifeq ($(PLATFORM),win32)
  ARCH = i686
  GCC = $(ARCH)-w64-mingw32-gcc
  GFORTRAN = $(ARCH)-w64-mingw32-gfortran
  EXTRA_LINKS := -lws2_32 -lpthread
  SHAREDLIB_SUFFIX = dll
# Default - assume building on a Linux machine.
else
  GCC = gcc
  GFORTRAN = gfortran
  SHAREDLIB_SUFFIX = so
endif

