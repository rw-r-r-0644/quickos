#include <stdio.h>
#include <stdarg.h>
#include <stdbool.h>
#include "outputf.h"

void _stdio_output_buffer(struct _stdio_outputfn* fn, int c) {
	if ((fn->error >= 0) && (fn->written < fn->size)) {
		// TODO: set EOVERFLOW
		char* buffer = (char *)fn->ptr;
		buffer[fn->written] = c;
	} else {
		fn->error = 1;
	}
	fn->written++;
}

void _stdio_output_stdout(struct _stdio_outputfn* fn, int c) {
	if ((fn->error >= 0) && (fn->written < fn->size)) {
		// TODO: set EOVERFLOW
		fn->error = (putchar(c) == EOF) ? -1 : 0;
	}
	fn->written++;
}

void _stdio_outputf(struct _stdio_outputfn* fn, const char* fmt, va_list va) {
	while (*fmt != '\0') {
		bool isalternative = false;
		bool islong = false;
		unsigned long pad = 0;
		char padchr = ' ';

		// Normal text
		while (*fmt != '%') {
			fn->outputchr(fn, *(fmt++));
			if (*fmt == '\0')
				return;
		}

		const char* fmt_start = fmt++;

		// Handle alternative form
		if (*fmt == '#') {
			isalternative = true;
			fmt++;
		}

		// Handle zero pad
		if (*fmt == '0') {
			padchr = '0';
			fmt++;
		}

		// Handle pad length
		while ((*fmt >= '0') && (*fmt <= '9')) {
			pad *= 10;
			pad += (*fmt - '0');
			fmt++;
		}

		// Handle long specifier
		if (*fmt == 'l') {
			islong = true;
			fmt++;
		}

		// Format specifiers
		switch (*fmt) {
			case '\0': return;
			case '%': {
				fn->outputchr(fn, '%');
				break;
			}
			case 's': {
				const char* s = va_arg(va, const char*);
				while(*s)
					fn->outputchr(fn, *(s++));
				break;
			}
			case 'c': {
				char c = (char)va_arg(va, int);
				fn->outputchr(fn, c);
				break;
			}
			case 'n': {
				int* n = va_arg(va, int*);
				*n = (int)fn->written;
				break;
			}
			case 'd': __attribute__ ((fallthrough));
			case 'i': __attribute__ ((fallthrough));
			case 'u': __attribute__ ((fallthrough));
			case 'o': __attribute__ ((fallthrough));
			case 'x': __attribute__ ((fallthrough));
			case 'X': {
				unsigned long base = 10, num = 0, len = 0, div = 0;

				char* digits = (*fmt == 'X')
					? "0123456789ABCDEF"
					: "0123456789abcdef";

				if ((*fmt == 'd') || (*fmt == 'i')) {
					long inum = (islong)
						? (long)va_arg(va, long)
						: (long)va_arg(va, int);

					if (inum < 0) {
						fn->outputchr(fn, '-');
						inum = -inum;
						len++;
					}

					num = (unsigned long)inum;
				} else {
					num = (islong)
						? (unsigned long)va_arg(va, unsigned long)
						: (unsigned long)va_arg(va, unsigned int);

					if (*fmt == 'x' || *fmt == 'X') {
						if (isalternative) {
							fn->outputchr(fn, '0');
							fn->outputchr(fn, *fmt);
							len += 2;
						}
						base = 16;
					} else if (*fmt == 'o') {
						if (isalternative) {
							fn->outputchr(fn, '0');
							len++;
						}
						base = 8;
					}
				}

				for (unsigned long d = 1; (d <= num) && (d >= div); d *= base) {
					div = d;
					len++;
				}

				for (unsigned long i = len; i < pad; i++)
					fn->outputchr(fn, padchr);

				while (div >= 1) {
					fn->outputchr(fn, digits[(num / div) % base]);
					div /= base;
				}
				break;
			}
			default: {
				for (const char* s = fmt_start; s <= fmt; s++)
					fn->outputchr(fn, *s);
				break;
			}
		}
		fmt++;
	}
	fn->outputchr(fn, '\0');
}
