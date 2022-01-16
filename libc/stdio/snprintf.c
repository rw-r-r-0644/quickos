#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include "outputf.h"

int vsnprintf(char* s, size_t n, const char* restrict fmt, va_list va) {
	struct _stdio_outputfn buffer_out = {0, 0, n-1, s, &_stdio_output_buffer};
	_stdio_outputf(&buffer_out, fmt, va);
	s[n-1] = '\0';
	return (buffer_out.error < 0) ? -1 : (int)buffer_out.written;
}

int snprintf(char* s, size_t n, const char* restrict fmt, ...) {
	va_list va;
	va_start(va, fmt);
	int rc = vsnprintf(s, n, fmt, va);
	va_end(va);
	return rc;
}
