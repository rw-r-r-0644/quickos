#pragma once
#include <string.h>

struct _stdio_outputfn {
	int error;
	size_t written;
	size_t size;
	void *ptr;
	void (*outputchr)(struct _stdio_outputfn *fn, int c);
};

void _stdio_output_buffer(struct _stdio_outputfn *fn, int c);
void _stdio_output_stdout(struct _stdio_outputfn *fn, int c);
void _stdio_outputf(struct _stdio_outputfn *fn, const char *fmt, va_list va);
