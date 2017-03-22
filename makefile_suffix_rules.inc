INC = -I$(RPN_TEMPLATE_LIBS)/include -I.

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


.cdk90.o:
	#s.compile -O $(OPTIMIZ) -optf "=$(FFLAGS)" $(SUPP_OPT) $(FTN90_SUPP_OPT) -src $<
	echo "Error: WHUT"
	exit 1

