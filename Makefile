CC=mingw32-gcc
CFLAGS=-std=c99 -w
LDFLAGS=-lgdi32
MAIN_C_FILE=main.c
EXE_NAME=kof-hitboxes.exe
OBJECTS=main.o playerstruct.o render.o draw.o gamedefs.o gamestate.o

kof-hitboxes.exe: $(OBJECTS)
	$(CC) -o $@ $(OBJECTS) $(LDFLAGS) 

main.o: main.c
	$(CC) $(CFLAGS) -c $<

playerstruct.o: playerstruct.c
	$(CC) $(CFLAGS) -c $<

render.o: render.c playerstruct.h
	$(CC) $(CFLAGS) -c $<

draw.o: draw.c render.h playerstruct.h gamestate.o
	$(CC) $(CFLAGS) -c $<

gamedefs.o: gamedefs.c
	$(CC) $(CFLAGS) -c $<

gamestate.o: gamestate.c playerstruct.h render.h gamedefs.h
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(EXE_NAME) $(OBJECTS)
