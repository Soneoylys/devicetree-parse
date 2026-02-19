TARGET = devicetree-parse

DEBUG   ?= 0
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
ARCH    ?= x86_64
SDK     ?= macosx

SYSROOT  := $(shell xcrun --sdk $(SDK) --show-sdk-path)
ifeq ($(SYSROOT),)
$(error Could not find SDK "$(SDK)")
endif
CLANG    := $(shell xcrun --sdk $(SDK) --find clang)
CC       := $(CLANG) -isysroot $(SYSROOT) -arch $(ARCH)
else
CC       ?= cc
endif

CFLAGS  = -O2 -Wall
LDFLAGS =

ifneq ($(DEBUG),0)
DEFINES += -DDEBUG=$(DEBUG)
endif

all: devicetree-parse devicetree-repack

devicetree-parse: devicetree-parse.o parse.o
	$(CC) $(CFLAGS) $(DEFINES) $(LDFLAGS) -o $@ devicetree-parse.o parse.o

devicetree-repack: repack.py
	cp repack.py $@
	chmod +x $@

devicetree-parse.o: devicetree-parse.c $(HEADERS)
	$(CC) $(CFLAGS) $(DEFINES) $(LDFLAGS) -c -o $@ devicetree-parse.c

parse.o: parse.c $(HEADERS)
	$(CC) $(CFLAGS) $(DEFINES) $(LDFLAGS) -c -o $@ parse.c

clean:
	rm -f -- *.o devicetree-parse devicetree-repack
