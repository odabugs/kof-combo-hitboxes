ifeq ($(USING_BATCH_FILE),true)
CC=gcc # for native compilation with MinGW on Windows
else
CC=i686-pc-mingw32-gcc # for Linux-to-Windows cross-compilation with MinGW (or native with Cygwin)
endif
#TODO: add debug build target

.PHONY: clean luaclean default lua
INCLUDES=-I"./lib/inih" -I"./lib/luajit/src"
LIBS=-L"./lib/luajit/src"
DEFINES=-D UNICODE -D _UNICODE
CFLAGS=-std=c11 -g -mwindows -mconsole $(DEFINES) $(INCLUDES)
LDFLAGS=$(LIBS) -ld3d9 -ld3dx9 -lluajit -lShlwapi 
EXE_NAME=kof-hitboxes.exe
OBJECTS=directx.o playerstruct.o coords.o draw.o gamedefs.o gamestate.o process.o colors.o controlkey.o hotkeys.o util.o boxtypes.o boxset.o primitives.o config.o ini.o
HEADERS=$(subst .o,.h,$(OBJECTS))
KOF98_HEADERS=kof98_roster.h kof98_boxtypemap.h kof98_gamedef.h
KOF02_HEADERS=$(subst 98,02,$(KOF98_HEADERS))
MAIN_AND_OBJECTS=main.o $(OBJECTS)
VPATH=src src/kof98 src/kof02 lib lib/inih lib/luajit

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

playerstruct.o: playerstruct.c
	$(CC) $(CFLAGS) -c $^

coords.o: coords.c playerstruct.h
	$(CC) $(CFLAGS) -c $^

boxset.o: boxset.c playerstruct.h boxtypes.h gamedefs.h
	$(CC) $(CFLAGS) -c $^

draw.o: draw.c coords.h playerstruct.h gamestate.h boxtypes.h boxset.h hotkeys.h colors.h primitives.h
	$(CC) $(CFLAGS) -c $^

gamedefs.o: gamedefs.c gamedefs.h playerstruct.h $(KOF98_HEADERS) $(KOF02_HEADERS)
	$(CC) $(CFLAGS) -c $^

gamestate.o: gamestate.c playerstruct.h coords.h gamedefs.h
	$(CC) $(CFLAGS) -c $^

process.o: process.c gamestate.h controlkey.h util.h colors.h
	$(CC) $(CFLAGS) -c $^

colors.o boxtypes.o controlkey.o hotkeys.o util.o: %.o: %.c
	$(CC) $(CFLAGS) -c $^

ini.o: lib/inih/ini.c
	$(CC) $(CFLAGS) -c $^

config.o: config.c boxtypes.h colors.h hotkeys.h gamedefs.h util.h lib/inih/ini.h
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
