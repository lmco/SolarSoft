include ../Makefile.$(SSW_COMPILE_TYPE)

CFLAGS		= -c -I$(IDL_DIR)/external
FFLAGS          = -c

# Shorthand
E = $(SO_EXT)
.SUFFIXES: .$(E)

all: fmedian.$(E)

install: fmedian.$(E) fmedian.dlm
	cp -p $^ $(SSW_DLM_TOP)/$(SSW_BINARY_TYPE)/

.c.o:
	$(CC) $(CFLAGS) $(X_CFLAGS) $*.c

.o.$(E): 
	$(LD) $(X_LD_FLAGS) -o $@ $?

fmedian.o: fmedian.c

include ../Makefile.etc
