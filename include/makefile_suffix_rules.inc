include $(PROJECT_ROOT)/include/platforms.mk

INC = -I. -I$(PROJECT_ROOT)/include -I$(RPN_MACRO_DIR) -I$(PUBLIC_INCLUDES)

COMPILE_C = $(GCC) -fPIC -O$(OPTIMIZ) $(DEFINE) $(CFLAGS) $(INC) $(xSUPP_OPT) $(xC_SUPP_OPT) -c $<

COMPILE_F77 = $(GFORTRAN) -fPIC -fcray-pointer -O$(OPTIMIZ) $(FFLAGS) $(INC) $(xSUPP_OPT) $(xF_SUPP_OPT) -c $<

COMPILE_F90 = $(GFORTRAN) -fPIC -fcray-pointer -ffree-line-length-none -O$(OPTIMIZ) $(FFLAGS) $(INC) $(xSUPP_OPT) $(xF90_SUPP_OPT) -c $<

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


