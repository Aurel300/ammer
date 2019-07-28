all: adder.hdll out/stub.o

adder.hdll: out/stub.o
	#${CC} ${CFLAGS} -shared -o adder.hdll native/adder.o ${LIBFLAGS} -lhl
	${CC} ${CFLAGS} -I native -D LIBHL_EXPORTS -m64 -shared -o ammer_adder.hdll out/stub.o -Lnative -lhl -ladder

out/stub.o: out/stub.c
	${CC} ${CFLAGS} -o out/stub.o -c out/stub.c -I native

.PHONY: all
