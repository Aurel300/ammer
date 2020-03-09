#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "native.h"
#include "utf8.h"

LIB_EXPORT int take_0(void) {
	return 0;
}
LIB_EXPORT int take_0alt(void) {
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
LIB_EXPORT void prefixed_nop2(void) {}

LIB_EXPORT int add_ints(int a, int b) {
	return a + b;
}
LIB_EXPORT unsigned int add_uints(unsigned int a, unsigned int b) {
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

LIB_EXPORT char *id_string(char *a) {
	return strdup(a);
}
LIB_EXPORT char *rev_string(char *a) {
	int len = strlen(a);
	char *ret = malloc(len + 1);
	int *cc = malloc(len * sizeof(int));
	int pos = 0;
	while (*a != 0) cc[pos++] = utf8_decode((unsigned char **)&a);
	char *retcur = ret;
	while (pos > 0) utf8_encode((unsigned char **)&retcur, cc[--pos]);
	*retcur = '\0';
	return ret;
}

LIB_EXPORT unsigned char *id_bytes(unsigned char *a, size_t b) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *id_bytes_1(unsigned char *a, unsigned char *c, size_t b) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *id_bytes_2(unsigned char *c, unsigned char *a, size_t b) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *id_bytes_3(unsigned char *a, size_t b, unsigned char *c) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *id_bytes_4(unsigned char *c, size_t b, unsigned char *a) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *id_bytes_5(size_t b, unsigned char *a, unsigned char *c) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *id_bytes_6(size_t b, unsigned char *c, unsigned char *a) {
	return memcpy(malloc(b), a, b);
}
LIB_EXPORT unsigned char *give_bytes(int n, size_t *ret_size) {
	unsigned char *ret = malloc(n);
	for (int i = 0; i < n; i++) ret[i] = i + 1;
	*ret_size = n;
	return ret;
}

static int saved_num = 0;
LIB_EXPORT void save_num(int num) {
	saved_num = num;
}
LIB_EXPORT int get_saved_num(void) {
	return saved_num;
}
LIB_EXPORT int *pointer_saved_num(void) {
	return &saved_num;
}

static int (* cached_func)(int, int);
LIB_EXPORT void save_func(int (* func)(int, int)) {
	cached_func = func;
}
LIB_EXPORT int call_func(void) {
	return cached_func(1, 2);
}

LIB_EXPORT opaque_type_ptr create_opaque(void) {
	opaque_type_ptr ret = malloc(sizeof(opaque_type_t));
	ret->member_int = 1;
	ret->member_float = 2.0f;
	ret->member_string = "3";
	return ret;
}
LIB_EXPORT int opaque_get_int(opaque_type_ptr a) {
	return a->member_int;
}
LIB_EXPORT double opaque_get_float(opaque_type_ptr a) {
	return a->member_float;
}
LIB_EXPORT char *opaque_get_string(opaque_type_ptr a) {
	return a->member_string;
}
LIB_EXPORT int opaque_get_int_alt(int a, opaque_type_ptr b, int c) {
	return a + b->member_int + c;
}
