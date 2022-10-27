#pragma once

#ifdef _WIN32
  #define LIB_EXPORT __declspec(dllexport)
#else
  #define LIB_EXPORT
#endif

#include <stdbool.h>

LIB_EXPORT int utf8_decode(unsigned char **ptr);
LIB_EXPORT void utf8_encode(unsigned char **ptr, int codepoint);
