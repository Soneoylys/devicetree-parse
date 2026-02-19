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
HAVE_FOUNDATION := 1
else
CC       ?= cc
HAVE_FOUNDATION := 0
endif

CFLAGS  = -O2 -Wall
LDFLAGS =


ifneq ($(DEBUG),0)
DEFINES += -DDEBUG=$(DEBUG)
endif

FRAMEWORKS =
ifeq ($(HAVE_FOUNDATION),1)
FRAMEWORKS += -framework CoreFoundation -framework Foundation
endif

all: devicetree-parse $(if $(filter 1,$(HAVE_FOUNDATION)),devicetree-repack,)

devicetree-parse: devicetree-parse.o parse.o
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(DEFINES) $(LDFLAGS) -o $@ devicetree-parse.o parse.o

ifeq ($(HAVE_FOUNDATION),1)
devicetree-repack: repack.o
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(DEFINES) $(LDFLAGS) -o $@ repack.m
endif

devicetree-parse.o: devicetree-parse.c $(HEADERS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(DEFINES) $(LDFLAGS) -c -o $@ devicetree-parse.c

parse.o: parse.c $(HEADERS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(DEFINES) $(LDFLAGS) -c -o $@ parse.c

ifeq ($(HAVE_FOUNDATION),1)
repack.o: repack.m $(HEADERS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(DEFINES) $(LDFLAGS) -c -o $@ repack.m
endif

main.o: main.c $(HEADERS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) $(DEFINES) $(LDFLAGS) -c -o $@ main.c

clean:
	rm -f -- *.o devicetree-parse devicetree-repack
