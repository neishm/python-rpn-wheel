include $(PROJECT_ROOT)/include/compiler.mk

# Header files for linking against librmn
PUBLIC_INCLUDES=$(PROJECT_ROOT)/librmn-016.2/PUBLIC_INCLUDES

INC = -I. -I$(PROJECT_ROOT)/include -I$(PUBLIC_INCLUDES)

.c.o:
	$(CC) -fPIC -O$(OPTIMIZ) $(CFLAGS) $(INC) -c $<

.o.a:
	ar rv $@ $<
	rm -f $*.o

.ftn.f .ftn90.f90:
	cpp $(INC) $< $@

.f.o .F.o .f90.o .F90.o:
	$(FC) -fPIC -O$(OPTIMIZ) $(FFLAGS) $(INC) -c $<


