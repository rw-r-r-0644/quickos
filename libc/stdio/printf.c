#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include "outputf.h"

int vprintf(const char* restrict fmt, va_list va) {
	struct _stdio_outputfn stdout_fn = {0, 0, INT_MAX, NULL, &_stdio_output_stdout};
	_stdio_outputf(&stdout_fn, fmt, va);
	return (stdout_fn.error < 0) ? -1 : (int)stdout_fn.written;
}

int printf(const char* restrict fmt, ...) {
	va_list va;
	va_start(va, fmt);
	int rc = vprintf(fmt, va);
	va_end(va);
	return rc;
}
