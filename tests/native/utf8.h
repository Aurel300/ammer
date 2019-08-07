#pragma once

#include <stdbool.h>

int utf8_decode(unsigned char **ptr);
void utf8_encode(unsigned char **ptr, int codepoint);
