#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "adder.h"

LIB_EXPORT int add_numbers(int a, int b) {
	return a + b;
}

LIB_EXPORT unsigned char *load_file(char *filename, size_t *loaded) {
	FILE *f = fopen(filename, "r");
	if (f == NULL) {
		puts("cannot open file");
		return NULL;
	}
	fseek(f, 0, SEEK_END);
	size_t s = ftell(f);
	rewind(f);
	void *buf = malloc(s);
	if (buf == NULL) {
		puts("cannot malloc");
		return NULL;
	}
	if (fread(buf, 1, s, f) != s) {
		puts("cannot read file");
		return NULL;
	}
	fclose(f);
	*loaded = s;
	return buf;
}

LIB_EXPORT char *concat_strings(const char *a, const char *b) {
	int lenA = strlen(a);
	int lenB = strlen(b);
	char *ret = malloc(lenA + lenB + 1);
	memcpy(ret, a, lenA);
	memcpy(ret + lenB, b, lenB);
	ret[lenA + lenB] = 0;
	return ret;
}

LIB_EXPORT unsigned char *reverse_bytes(unsigned char *data, int len) {
	unsigned char *rev = malloc(len);
	for (int i = 0; i < len; i++) {
		rev[i] = data[len - i - 1];
	}
	return rev;
}
