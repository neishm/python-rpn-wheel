# Set this to your current architecture.
# E.g., Linux_x86 or Linux_x86-64
ifeq ($(ARCH),linux-x86_64)
  ARCH_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_x86-64_gfortran
else ifeq ($(ARCH),linux-i686)
  ARCH_MACRO_DIR = $(PROJECT_ROOT)/env-include/Linux_gfortran
  CFLAGS := $(CFLAGS) -m32
  FFLAGS := $(FFLAGS) -m32
else ifeq ($(ARCH),)
  $(error $$ARCH is not defined.)
else
  $(error unrecognized ARCH value '$(ARCH)')
endif
INC = -I. -I$(PROJECT_ROOT)/env-include -I$(ARCH_MACRO_DIR) -I$(PROJECT_ROOT)/librmn/PUBLIC_INCLUDES

COMPILE_C = gcc -fPIC -O$(OPTIMIZ) $(DEFINE) $(CFLAGS) $(INC) $(xSUPP_OPT) $(xC_SUPP_OPT) -c $<

COMPILE_F77 = gfortran -fPIC -fcray-pointer -O$(OPTIMIZ) $(FFLAGS) $(INC) $(xSUPP_OPT) $(xF_SUPP_OPT) -c $<

COMPILE_F90 = gfortran -fPIC -fcray-pointer -ffree-line-length-none -O$(OPTIMIZ) $(FFLAGS) $(INC) $(xSUPP_OPT) $(xF90_SUPP_OPT) -c $<

PREPROCESSOR = cpp $(DEFINE) $(INC) $< $@

.c.o:
	$(COMPILE_C)

.o.a:
	ar rv $@ $<
	rm -f $*.o

.f.o:
	$(COMPILE_F77)

.F.o:
	$(COMPILE_F77)


.ftn.f: 
	$(PREPROCESSOR)

.f90.o:
	$(COMPILE_F90)

.ftn90.f90:
	$(PREPROCESSOR)
 
.F90.o:
	$(COMPILE_F90)


