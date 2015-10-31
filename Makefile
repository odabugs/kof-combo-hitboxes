#CC=mingw32-gcc # for Linux-to-Windows cross-compilation with MinGw
CC=gcc # for native compilation with MinGW on Windows
#TODO: add debug build target
CFLAGS=-std=c1x
#LDFLAGS=-lgdi32 -ld3d9
LDFLAGS=-lgdi32 -lopengl32 -lglu32
EXE_NAME=kof-hitboxes.exe
OBJECTS=playerstruct.o coords.o draw.o gamedefs.o gamestate.o
HEADERS=playerstruct.h coords.h draw.h gamedefs.h gamestate.h
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

draw.o: draw.c coords.h playerstruct.h gamestate.h
	$(CC) $(CFLAGS) -c $^

gamedefs.o: gamedefs.c gamedefs.h kof98_roster.h kof02_roster.h
	$(CC) $(CFLAGS) -c $^

gamestate.o: gamestate.c playerstruct.h coords.h gamedefs.h
	$(CC) $(CFLAGS) -c $^

clean:
	del "$(EXE_NAME)"
	del /S *.o *.h.gch
