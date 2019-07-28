#define HL_NAME(n) ammer_adder_ ## n
#include <hl.h>
#include <adder.h>
HL_PRIM int HL_NAME(w_add_numbers)(int arg_0, int arg_1) {
  return add_numbers(arg_0, arg_1);
}
DEFINE_PRIM(_I32, w_add_numbers, _I32 _I32);
HL_PRIM unsigned char * HL_NAME(w_load_file)(char * arg_0, size_t * arg_1) {
  return load_file(arg_0, arg_1);
}
DEFINE_PRIM(_BYTES, w_load_file, _BYTES _REF(_I32));
HL_PRIM char * HL_NAME(w_concat_strings)(char * arg_0, char * arg_1) {
  return concat_strings(arg_0, arg_1);
}
DEFINE_PRIM(_BYTES, w_concat_strings, _BYTES _BYTES);
HL_PRIM unsigned char * HL_NAME(w_reverse_bytes)(unsigned char * arg_0, int arg_1) {
  return reverse_bytes(arg_0, arg_1);
}
DEFINE_PRIM(_BYTES, w_reverse_bytes, _BYTES _I32);
