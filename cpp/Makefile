CC=g++
#CFLAGS= -g -Wall -std=c++11
CFLAGS= -g -Wall -std=c++11 -O3 -fstrict-aliasing
#CFLAGS= -g -Wall -std=c++11 -O3
#CFLAGS= -g -Wall -std=c++11 -O3 -pg

default: run
all: default

litmus.o: litmus.cpp
	$(CC) $(CFLAGS) -c litmus.cpp -o litmus.o

litmus: litmus.o
	$(CC) $(CFLAGS) litmus.o -o litmus

clean:
	rm -f litmus.o litmus gmon.out

run: litmus
	./litmus
