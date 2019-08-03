#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>

int add_numbers(int a, int b);
unsigned char *load_file(char *filename, size_t *loaded);
char *concat_strings(const char *a, const char *b);
unsigned char *reverse_bytes(unsigned char *data, int len);

#ifdef __cplusplus
}
#endif
