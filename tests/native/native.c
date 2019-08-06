#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "native.h"

LIB_EXPORT int take_0(void) {
	return 0;
}
LIB_EXPORT int take_1(int a1) {
	return 1;
}
LIB_EXPORT int take_2(int a1, int a2) {
	return 2;
}
LIB_EXPORT int take_3(int a1, int a2, int a3) {
	return 3;
}
LIB_EXPORT int take_4(int a1, int a2, int a3, int a4) {
	return 4;
}
LIB_EXPORT int take_5(int a1, int a2, int a3, int a4, int a5) {
	return 5;
}
LIB_EXPORT int take_6(int a1, int a2, int a3, int a4, int a5, int a6) {
	return 6;
}
LIB_EXPORT int take_7(int a1, int a2, int a3, int a4, int a5, int a6, int a7) {
	return 7;
}
LIB_EXPORT int take_8(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8) {
	return 8;
}
LIB_EXPORT int take_9(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9) {
	return 9;
}
LIB_EXPORT int take_10(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9, int a10) {
	return 10;
}
LIB_EXPORT void nop(void) {}

LIB_EXPORT int add_ints(int a, int b) {
	return a + b;
}
LIB_EXPORT double add_floats(double a, double b) {
	return a + b;
}
LIB_EXPORT bool logic_and(bool a, bool b) {
	return a && b;
}
LIB_EXPORT bool logic_or(bool a, bool b) {
	return a || b;
}
LIB_EXPORT int logic_ternary(bool a, int b, int c) {
	return a ? b : c;
}
