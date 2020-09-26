#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
	#define LIB_EXPORT __declspec(dllexport)
#else
	#define LIB_EXPORT
#endif

#include <stdlib.h>
#include <stdbool.h>

LIB_EXPORT int take_0(void);
LIB_EXPORT int take_0alt(void);
LIB_EXPORT int take_1(int a1);
LIB_EXPORT int take_2(int a1, int a2);
LIB_EXPORT int take_3(int a1, int a2, int a3);
LIB_EXPORT int take_4(int a1, int a2, int a3, int a4);
LIB_EXPORT int take_5(int a1, int a2, int a3, int a4, int a5);
LIB_EXPORT int take_6(int a1, int a2, int a3, int a4, int a5, int a6);
LIB_EXPORT int take_7(int a1, int a2, int a3, int a4, int a5, int a6, int a7);
LIB_EXPORT int take_8(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8);
LIB_EXPORT int take_9(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9);
LIB_EXPORT int take_10(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8, int a9, int a10);
LIB_EXPORT void nop(void);
LIB_EXPORT void prefixed_nop2(void);

LIB_EXPORT int add_ints(int a, int b);
LIB_EXPORT unsigned int add_uints(unsigned int a, unsigned int b);
LIB_EXPORT float add_singles(float a, float b);
LIB_EXPORT double add_floats(double a, double b);
LIB_EXPORT bool logic_and(bool a, bool b);
LIB_EXPORT bool logic_or(bool a, bool b);
LIB_EXPORT int logic_ternary(bool a, int b, int c);

LIB_EXPORT const char *id_string(const char *a);
LIB_EXPORT const char *rev_string(const char *a);

LIB_EXPORT unsigned char *id_bytes(unsigned char *a, size_t b);
LIB_EXPORT unsigned char *id_bytes_1(unsigned char *a, unsigned char *c, size_t b);
LIB_EXPORT unsigned char *id_bytes_2(unsigned char *c, unsigned char *a, size_t b);
LIB_EXPORT unsigned char *id_bytes_3(unsigned char *a, size_t b, unsigned char *c);
LIB_EXPORT unsigned char *id_bytes_4(unsigned char *c, size_t b, unsigned char *a);
LIB_EXPORT unsigned char *id_bytes_5(size_t b, unsigned char *a, unsigned char *c);
LIB_EXPORT unsigned char *id_bytes_6(size_t b, unsigned char *c, unsigned char *a);
LIB_EXPORT unsigned char *give_bytes(int n, size_t *ret);

LIB_EXPORT void save_num(int);
LIB_EXPORT int get_saved_num(void);
LIB_EXPORT int *pointer_saved_num(void);

typedef struct {
	void *user_data;
	int foo;
} callback_data_t;

enum enum_constants {
	e_const0 = 0,
	e_const1 = 1,
	e_const10 = 10
};

enum enum_flags {
	e_foo = 1,
	e_bar = 2,
	e_baz = 4
};

LIB_EXPORT void save_func(int (* func)(int, int, void*), void *user_data);
LIB_EXPORT int call_func(void);
LIB_EXPORT int call_func_2(void *user_data, int (* func)(void *, const char *));
LIB_EXPORT int call_func_3(void *user_data, int (* func)(callback_data_t *));
LIB_EXPORT bool call_func_4(void *user_data, enum enum_constants (* func)(void *, enum enum_constants));

typedef struct {
	int member_int;
	double member_float;
	const char *member_string;

	int *member_int_array;
	int member_int_array_size;
	const char **member_string_array;
	int member_string_array_size;
} opaque_type_t;
typedef opaque_type_t *opaque_type_ptr;

LIB_EXPORT opaque_type_ptr create_opaque(void);
LIB_EXPORT int opaque_get_int(opaque_type_ptr a);
LIB_EXPORT double opaque_get_float(opaque_type_ptr a);
LIB_EXPORT const char *opaque_get_string(opaque_type_ptr a);
LIB_EXPORT int opaque_get_int_alt(int a, opaque_type_ptr b, int c);
LIB_EXPORT unsigned char *opaque_get_bytes(opaque_type_ptr a, size_t *b);
LIB_EXPORT void opaque_indirect(opaque_type_ptr *out);

#define DEFINE_INT 42
#define DEFINE_INT_EXPR (8 * 9)
#define DEFINE_STRING "foo"
#define DEFINE_STRING_EXPR ("foo" "bar" "foo")
#define DEFINE_BOOL 1
#define DEFINE_BOOL_EXPR ((1 == 1) ? 1 : 0)
#define DEFINE_FLOAT 5.3
#define DEFINE_FLOAT_EXPR (5.3 * 2)

LIB_EXPORT bool take_enum(enum enum_constants a, enum enum_constants b, enum enum_constants c);
LIB_EXPORT enum enum_constants give_enum(void);

#ifdef __cplusplus
}
#endif
