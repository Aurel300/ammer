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
LIB_EXPORT float add_singles(float a, float b) {
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

LIB_EXPORT const char *id_string(const char *a) {
	return strdup(a);
}
LIB_EXPORT const char *rev_string(const char *a) {
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

static int (* cached_func)(int, int, void *);
static void *cached_user_data;
LIB_EXPORT void save_func(int (* func)(int, int, void *), void *user_data) {
	cached_func = func;
	cached_user_data = user_data;
}
LIB_EXPORT int call_func(void) {
	return cached_func(1, 2, cached_user_data);
}
LIB_EXPORT int call_func_2(void *user_data, int (* func)(void *, const char *)) {
	return func(user_data, "foobar") * 2;
}
LIB_EXPORT int call_func_3(void *user_data, int (* func)(callback_data_t *)) {
	callback_data_t data = {
		.user_data = user_data,
		.foo = 59
	};
	return func(&data);
}
LIB_EXPORT bool call_func_4(void *user_data, enum enum_constants (* func)(void *, enum enum_constants)) {
	return func(user_data, e_const1) == e_const10;
}

LIB_EXPORT opaque_type_ptr create_opaque(void) {
	opaque_type_ptr ret = malloc(sizeof(opaque_type_t));
	ret->member_int = 1;
	ret->member_float = 2.0f;
	ret->member_string = "3";
	for (int i = 0; i < 8; i++) {
		ret->member_int_array_fixed[i] = 0xB0057ED + i;
	}
	ret->member_int_array = (int *)calloc(17, sizeof(int));
	ret->member_int_array_size = 17;
	for (int i = 0; i < 17; i++) {
		ret->member_int_array[i] = 0xB00573D + i;
	}
	ret->member_string_array = (const char **)calloc(3, sizeof(char *));
	ret->member_string_array_size = 3;
	ret->member_string_array[0] = "arrfoo";
	ret->member_string_array[1] = "arrbar";
	ret->member_string_array[2] = "arrbaz";
	return ret;
}
LIB_EXPORT int opaque_get_int(opaque_type_ptr a) {
	return a->member_int;
}
LIB_EXPORT int opaque_get_int_nested(opaque_type_t a) {
	return a.member_int;
}
LIB_EXPORT double opaque_get_float(opaque_type_ptr a) {
	return a->member_float;
}
LIB_EXPORT const char *opaque_get_string(opaque_type_ptr a) {
	return a->member_string;
}
LIB_EXPORT int opaque_get_int_alt(int a, opaque_type_ptr b, int c) {
	return a + b->member_int + c;
}
LIB_EXPORT unsigned char *opaque_get_bytes(opaque_type_ptr a, size_t *b) {
	size_t len = strlen(a->member_string);
	unsigned char *ret = malloc(len);
	memcpy(ret, a->member_string, len);
	*b = len;
	return ret;
}
LIB_EXPORT void opaque_indirect(opaque_type_ptr *out) {
	opaque_type_ptr ret = malloc(sizeof(opaque_type_t));
	ret->member_int = 10;
	ret->member_float = 4.0f;
	ret->member_string = "indirect";
	*out = ret;
}
LIB_EXPORT opaque_type_t create_opaque_noalloc(void) {
	return (opaque_type_t){
		.member_int = 61,
		.member_float = 5.2f,
		.member_string = "noalloc",
		.member_int_array_fixed = {9, 10, 11, 12, 13, 14, 15, 16},
		.member_int_array = NULL,
		.member_int_array_size = 0,
		.member_string_array = NULL,
		.member_string_array_size = 0,
	};
}
LIB_EXPORT bool opaque_take_nested(opaque_type_t a) {
	float diff = a.member_float - 5.4f;
	return a.member_int == 62
		&& (diff > -.0001f && diff < .0001f)
		&& strcmp(a.member_string, "noalloc") == 0
		&& a.member_int_array_fixed[7] == 47
		&& a.member_int_array == NULL
		&& a.member_string_array == NULL;
}

LIB_EXPORT bool take_enum(enum enum_constants a, enum enum_constants b, enum enum_constants c) {
	return (a == e_const10)
		&& (b == e_const1)
		&& (c == e_const0);
}
LIB_EXPORT enum enum_constants give_enum(void) {
	return e_const10;
}

LIB_EXPORT int take_array_fixed(int a[3]) {
	if (a[0] != 1 || a[1] != 2 || a[2] != 4)
		return -1;
	return a[0] + a[1] + a[2];
}
LIB_EXPORT int take_array(int *a, size_t b) {
	if (b != 3 || a[0] != 1 || a[1] != 2 || a[2] != 4)
		return -1;
	return a[0] + a[1] + a[2];
}
LIB_EXPORT void take_array_modify(int *a) {
	a[1] = 42;
}

LIB_EXPORT bool take_unsupported(void *a, double b) {
	return a == 0 && abs(b) < .0001;
}

LIB_EXPORT int8_t add_i8(int8_t a, int8_t b) {
  return a + b;
}
LIB_EXPORT int16_t add_i16(int16_t a, int16_t b) {
  return a + b;
}
LIB_EXPORT int32_t add_i32(int32_t a, int32_t b) {
  return a + b;
}
LIB_EXPORT int64_t add_i64(int64_t a, int64_t b) {
  return a + b;
}
LIB_EXPORT uint8_t add_u8(uint8_t a, uint8_t b) {
  return a + b;
}
LIB_EXPORT uint16_t add_u16(uint16_t a, uint16_t b) {
  return a + b;
}
LIB_EXPORT uint32_t add_u32(uint32_t a, uint32_t b) {
  return a + b;
}
LIB_EXPORT uint64_t add_u64(uint64_t a, uint64_t b) {
  return a + b;
}
