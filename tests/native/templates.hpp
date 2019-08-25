#pragma once

#ifdef _WIN32
	#define LIB_EXPORT __declspec(dllexport)
#else
	#define LIB_EXPORT
#endif

#include <stdlib.h>

template<typename int_t = uint32_t>
int_t templated_add_ints(int_t a, int_t b);

void cpp_nop(void);
