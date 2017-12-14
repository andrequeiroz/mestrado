LIBS=-lsqlite3

.PHONY: all

all: /tmp/o3_raw.db

o3: o3_raw.c
	gcc $< $(LIBS) -o $@

/tmp/o3_raw.db: o3 o3_raw.sql o3_raw
	sqlite2 $@ < o3_raw.sql
	./o3
