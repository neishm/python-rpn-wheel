ifeq ($(PLATFORM),linux_x86_64)
  ARCH = x86_64
  OS = linux
  GCC = gcc
  CFLAGS := $(CFLAGS) -m64
  GFORTRAN = gfortran
  FFLAGS := $(FFLAGS) -m64
  SHAREDLIB_SUFFIX = so
  RPN_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_x86-64_gfortran
else ifeq ($(PLATFORM),linux_i686)
  ARCH = i686
  OS = linux
  GCC = gcc
  CFLAGS := $(CFLAGS) -m32
  FFLAGS := $(FFLAGS) -m32
  SHAREDLIB_SUFFIX = so
  RPN_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_gfortran
else ifeq ($(PLATFORM),win_amd64)
  ARCH = x86_64
  OS = win
  GCC = $(ARCH)-w64-mingw32-gcc
  GFORTRAN = $(ARCH)-w64-mingw32-gfortran
  SHAREDLIB_SUFFIX = dll
  RPN_MACRO_DIR = $(PROJECT_ROOT)/include/Windows64_gfortran
else ifeq ($(PLATFORM),win32)
  ARCH = i686
  OS = win
  GCC = $(ARCH)-w64-mingw32-gcc
  GFORTRAN = $(ARCH)-w64-mingw32-gfortran
  SHAREDLIB_SUFFIX = dll
  RPN_MACRO_DIR = $(PROJECT_ROOT)/include/Windows32_gfortran
else ifeq ($(PLATFORM),)
  $(error $$PLATFORM is not defined.)
else
  $(error unrecognized PLATFORM value '$(PLATFORM)')
endif

