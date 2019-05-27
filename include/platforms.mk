ifeq ($(PLATFORM),native)
  ARCH = x86_64
  GCC = gcc
  GFORTRAN = gfortran
  SHAREDLIB_SUFFIX = so
  RPN_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_x86-64_gfortran
else ifeq ($(PLATFORM),manylinux1_x86_64)
  ARCH = x86_64
  GCC = gcc
  CFLAGS := $(CFLAGS) -m64
  GFORTRAN = gfortran
  FFLAGS := $(FFLAGS) -m64
  SHAREDLIB_SUFFIX = so
  RPN_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_x86-64_gfortran
else ifeq ($(PLATFORM),manylinux1_i686)
  ARCH = i686
  GCC = gcc
  CFLAGS := $(CFLAGS) -m32
  GFORTRAN = gfortran
  FFLAGS := $(FFLAGS) -m32
  SHAREDLIB_SUFFIX = so
  RPN_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_gfortran
else ifeq ($(PLATFORM),win_amd64)
  ARCH = x86_64
  GCC = $(ARCH)-w64-mingw32-gcc
  GFORTRAN = $(ARCH)-w64-mingw32-gfortran
  EXTRA_LINKS := -lws2_32 -lpthread
  SHAREDLIB_SUFFIX = dll
  RPN_MACRO_DIR = $(PROJECT_ROOT)/include/Windows64_gfortran
else ifeq ($(PLATFORM),win32)
  ARCH = i686
  GCC = $(ARCH)-w64-mingw32-gcc
  GFORTRAN = $(ARCH)-w64-mingw32-gfortran
  EXTRA_LINKS := -lws2_32 -lpthread
  SHAREDLIB_SUFFIX = dll
  RPN_MACRO_DIR = $(PROJECT_ROOT)/include/Windows32_gfortran
endif

