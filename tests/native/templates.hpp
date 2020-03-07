#pragma once

#ifdef _WIN32
	#define LIB_EXPORT __declspec(dllexport)
#else
	#define LIB_EXPORT
#endif

#include <stdint.h>
#include <stdlib.h>

template<typename int_t = uint32_t>
LIB_EXPORT int_t templated_add_ints(int_t a, int_t b);

LIB_EXPORT void cpp_nop(void);
