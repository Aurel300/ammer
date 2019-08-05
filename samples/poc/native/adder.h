#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
  #define LIB_EXPORT __declspec(dllexport)
#else
  #define LIB_EXPORT
#endif

#include <stdlib.h>

LIB_EXPORT int add_numbers(int a, int b);
LIB_EXPORT unsigned char *load_file(char *filename, size_t *loaded);
LIB_EXPORT char *concat_strings(const char *a, const char *b);
LIB_EXPORT unsigned char *reverse_bytes(unsigned char *data, int len);

#ifdef __cplusplus
}
#endif
