CFLAGS=-std=c99 -Wall
LIBS=-lsqlite3 -lm -lgsl -lgslcblas

all: o3

o3: o3.c 
	gcc $< -o $@ $(CFLAGS) $(LIBS)

clean:
	rm -f o3
