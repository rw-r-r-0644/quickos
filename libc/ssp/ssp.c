#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

// TODO: Dynamicall generate guard.
#if UINT32_MAX == UINTPTR_MAX
#define STACK_CHK_GUARD 0x3fb8f5b1
#else
#define STACK_CHK_GUARD 0xc05c250a7043c4f8
#endif

uintptr_t __stack_chk_guard = STACK_CHK_GUARD;

__attribute__((noreturn))
void __stack_chk_fail(void)
{
	puts("Stack smashing detected");
	abort();
}
