CFLAGS=-std=c99 -Wall
LIBS=-lsqlite3 -lm -lgsl -lgslcblas

all: estimacao

estimacao: estimacao.c 
	gcc $< -o $@ $(CFLAGS) $(LIBS)

clean:
	rm -f o3
