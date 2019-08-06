#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
  #define LIB_EXPORT __declspec(dllexport)
#else
  #define LIB_EXPORT
#endif

#include <stdlib.h>

LIB_EXPORT int take_0(void);
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

LIB_EXPORT int add_ints(int a, int b);
LIB_EXPORT double add_floats(double a, double b);
LIB_EXPORT bool logic_and(bool a, bool b);
LIB_EXPORT bool logic_or(bool a, bool b);
LIB_EXPORT int logic_ternary(bool a, int b, int c);

#ifdef __cplusplus
}
#endif
