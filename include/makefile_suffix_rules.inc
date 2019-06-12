include $(PROJECT_ROOT)/include/platforms.mk

INC = -I. -I$(PROJECT_ROOT)/include -I$(RPN_MACRO_DIR) -I$(PUBLIC_INCLUDES)

.c.o:
	$(CC) -O$(OPTIMIZ) $(CFLAGS) $(INC) -c $<

.o.a:
	ar rv $@ $<
	rm -f $*.o

.f.o:
	$(FC) -fcray-pointer -O$(OPTIMIZ) $(FFLAGS) $(INC) -c $<

.F.o:
	$(FC) -fcray-pointer -O$(OPTIMIZ) $(FFLAGS) $(INC) -c $<


.ftn.f: 
	cpp $(INC) $< $@

.f90.o:
	$(FC) -fcray-pointer -ffree-line-length-none -O$(OPTIMIZ) $(FFLAGS) $(INC) -c $<

.ftn90.f90:
	cpp $(INC) $< $@
 
.F90.o:
	$(FC) -fcray-pointer -ffree-line-length-none -O$(OPTIMIZ) $(FFLAGS) $(INC) -c $<


