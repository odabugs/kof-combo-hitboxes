CC=mingw32-gcc
#TODO: add debug build target
CFLAGS=-std=c99
LDFLAGS=-lgdi32 -ld3d9
EXE_NAME=kof-hitboxes.exe
OBJECTS=playerstruct.o render.o draw.o gamedefs.o gamestate.o
HEADERS=playerstruct.h render.h draw.h gamedefs.h gamestate.h
MAIN_AND_OBJECTS=main.o $(OBJECTS)
VPATH=src

default: $(MAIN_AND_OBJECTS)
	$(CC) -o $(EXE_NAME) $^ $(LDFLAGS) 

main.o: main.c $(HEADERS)
	$(CC) $(CFLAGS) -c $^

playerstruct.o: playerstruct.c
	$(CC) $(CFLAGS) -c $^

render.o: render.c playerstruct.h
	$(CC) $(CFLAGS) -c $^

draw.o: draw.c render.h playerstruct.h gamestate.h
	$(CC) $(CFLAGS) -c $^

gamedefs.o: gamedefs.c
	$(CC) $(CFLAGS) -c $^

gamestate.o: gamestate.c playerstruct.h render.h gamedefs.h
	$(CC) $(CFLAGS) -c $^

clean:
	rm -f $(EXE_NAME) $(MAIN_AND_OBJECTS) src/*.h.gch
