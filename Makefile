CFLAGS=-ansi -pedantic

all:
	${CC} ${CFLAGS} machine.c main.c -o machine

clean:
	rm -rf machine
