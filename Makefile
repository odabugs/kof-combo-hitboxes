ifeq ($(USING_BATCH_FILE),true)
CC=gcc # for native compilation with MinGW on Windows
else
CC=i686-w64-mingw32-gcc # for Linux-to-Windows cross-compilation with MinGW (or native with Cygwin)
endif
#TODO: add debug build target

.PHONY: clean luaclean default lua
INCLUDES=-I"./lib/luajit/src"
LIBS=-L"./lib/luajit/src"
DEFINES=-D UNICODE -D _UNICODE
CFLAGS=-std=c99 -g -mwindows -mconsole $(DEFINES) $(INCLUDES)
LDFLAGS=$(LIBS) -ld3d9 -lluajit
EXE_NAME=kof-hitboxes.exe
OBJECTS=luautil.o directx.o
HEADERS=$(subst .o,.h,$(OBJECTS))
MAIN_AND_OBJECTS=main.o $(OBJECTS)
VPATH=src lib lib/luajit

# RUN "make lua" BEFORE THIS TARGET.
# MinGW will complain about "unknown type SOLE_AUTHENTICATION_SERVICE" immediately after a clean build.
# Not sure why it does that, but just run the build again and it should work.
default: $(MAIN_AND_OBJECTS)
	$(CC) -o $(EXE_NAME) $^ $(LDFLAGS) 

# LuaJIT has a separate build target for now; run this BEFORE running the default make target.
# It's like this because LuaJIT takes significantly longer to build than "our" code.
# There's also a separate "luaclean" build target below for the same reason.
lua:
	cd lib/luajit && $(MAKE) PLAT=mingw BUILDMODE=static

main.o: main.c $(HEADERS)
	$(CC) $(CFLAGS) -c $^

directx.o luautil.o: %.o: %.c
	$(CC) $(CFLAGS) -c $^

clean:
ifeq ($(USING_BATCH_FILE),true)
	del "$(EXE_NAME)"
	del /S *.o
	del /S *.h.gch
else
	rm -f "$(EXE_NAME)"
	find . -type f -name '*.o' -delete
	find . -type f -name '*.h.gch' -delete
endif

luaclean: clean
	cd lib/luajit && $(MAKE) clean
