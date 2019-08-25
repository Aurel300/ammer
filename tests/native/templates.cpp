#include "templates.hpp"

template<typename int_t>
LIB_EXPORT int_t templated_add_ints(int_t a, int_t b) {
	return a + b;
}

template LIB_EXPORT int templated_add_ints(int a, int b);
template LIB_EXPORT uint64_t templated_add_ints(uint64_t a, uint64_t b);

void cpp_nop(void) {}
