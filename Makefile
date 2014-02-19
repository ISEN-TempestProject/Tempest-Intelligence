
SRC := $(shell find source/ -name "*.d")
# OBJ := $(SRC:.d=.o)
OBJ := $(patsubst source/%.d,.obj/%.o,	$(SRC))

CC=gdc
CROSSCC=/opt/arm-unknown-linux-gnueabi/bin/arm-unknown-linux-gnueabi-gdc

PLATFORM=x86

CFLAGS=
LDFLAGS=

INCLUDEDIR := -Isource
LIBDIR= 

CFLAGS_UNIT = -funittest

CFLAGS_DEBUG = -fdebug -Wall
CFLAGS_RELEASE = -frelease -fno-bounds-check -O2

#Default
all: debug

#Native targets
unit: CFLAGS += $(CFLAGS_UNIT) $(CFLAGS_DEBUG)
unit: exe

debug: CFLAGS += $(CFLAGS_DEBUG)
debug: exe

release: CFLAGS += $(CFLAGS_RELEASE)
release: exe

#Cross targets
cross: CC = $(CROSSCC)
cross: exe

crossdebug: CFLAGS += $(CFLAGS_DEBUG)
crossdebug: cross

crossunit: CFLAGS += $(CFLAGS_UNIT) $(CFLAGS_DEBUG)
crossunit: cross

crossrelease: CFLAGS += $(CFLAGS_RELEASE)
crossrelease: cross


#Create Executable
exe: .obj autoboat

#Create tmp directory
.obj: 
	mkdir -p .obj
	mkdir -p .obj/hardware

#Link executable
autoboat: $(OBJ)
	$(CC) $(LIBDIR) -o autoboat $^ $(LDFLAGS)

#Build d files
.obj/%.o: source/%.d
	$(CC) $(CFLAGS) $(INCLUDEDIR) -c $< -o $@ 

#clean build objects
clean:
	rm -rf .obj
