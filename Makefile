#CC=mingw32-gcc # for Linux-to-Windows cross-compilation with MinGW
CC=gcc # for native compilation with MinGW on Windows
#TODO: add debug build target
CFLAGS=-std=c1x -g
LDFLAGS=-lgdi32 -lopengl32 -lglu32
EXE_NAME=kof-hitboxes.exe
OBJECTS=playerstruct.o coords.o draw.o gamedefs.o gamestate.o colors.o controlkey.o util.o boxtypes.o boxset.o
HEADERS=playerstruct.h coords.h draw.h gamedefs.h gamestate.h colors.h controlkey.h util.h boxtypes.h boxset.h
KOF98_HEADERS=kof98_roster.h kof98_boxtypemap.h kof98_gamedef.h
KOF02_HEADERS=kof02_roster.h kof02_boxtypemap.h kof02_gamedef.h
MAIN_AND_OBJECTS=main.o $(OBJECTS)
VPATH=src src/kof98 src/kof02

default: $(MAIN_AND_OBJECTS)
	$(CC) -o $(EXE_NAME) $^ $(LDFLAGS) 

main.o: main.c $(HEADERS)
	$(CC) $(CFLAGS) -c $^

playerstruct.o: playerstruct.c
	$(CC) $(CFLAGS) -c $^

coords.o: coords.c playerstruct.h
	$(CC) $(CFLAGS) -c $^

boxset.o: boxset.c playerstruct.h boxtypes.h gamedefs.h
	$(CC) $(CFLAGS) -c $^

draw.o: draw.c coords.h playerstruct.h gamestate.h boxtypes.h boxset.h
	$(CC) $(CFLAGS) -c $^

gamedefs.o: gamedefs.c gamedefs.h playerstruct.h $(KOF98_HEADERS) $(KOF02_HEADERS)
	$(CC) $(CFLAGS) -c $^

gamestate.o: gamestate.c playerstruct.h coords.h gamedefs.h
	$(CC) $(CFLAGS) -c $^

colors.o boxtypes.o controlkey.o util.o: %.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

clean:
	del "$(EXE_NAME)"
	del /S *.o *.h.gch
