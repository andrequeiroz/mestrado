CFLAGS=-std=c99 -Wall
LIBS=-lsqlite3 -lm -lgsl -lgslcblas

all: svsim

svsim: svsim.c 
	gcc $< -o $@ $(CFLAGS) $(LIBS)

clean:
	rm -f svsim
