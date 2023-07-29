#include "utf8.h"

LIB_EXPORT int utf8_decode(unsigned char **ptr) {
  int cc1 = *((*ptr)++); if (cc1 < 0x80) return cc1;
  int cc2 = *((*ptr)++) & 0x7F; if (cc1 < 0xE0) return ((cc1 & 0x3F) << 6) | cc2;
  int cc3 = *((*ptr)++) & 0x7F; if (cc1 < 0xF0) return ((cc1 & 0x1F) << 12) | (cc2 << 6) | cc3;
  int cc4 = *((*ptr)++) & 0x7F; return ((cc1 & 0x0F) << 18) | (cc2 << 12) | (cc3 << 6) | cc4;
}

LIB_EXPORT void utf8_encode(unsigned char **ptr, int cc) {
  if (cc <= 0x7F) {
    *((*ptr)++) = cc;
  } else if (cc <= 0x7FF) {
    *((*ptr)++) = 0xC0 | (cc >> 6);
    *((*ptr)++) = 0x80 | (cc & 0x3F);
  } else if (cc <= 0xFFFF) {
    *((*ptr)++) = 0xE0 | (cc >> 12);
    *((*ptr)++) = 0x80 | ((cc >> 6) & 0x3F);
    *((*ptr)++) = 0x80 | (cc & 0x3F);
  } else {
    *((*ptr)++) = 0xF0 | (cc >> 18);
    *((*ptr)++) = 0x80 | ((cc >> 12) & 0x3F);
    *((*ptr)++) = 0x80 | ((cc >> 6) & 0x3F);
    *((*ptr)++) = 0x80 | (cc & 0x3F);
  }
}
