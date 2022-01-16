# Declare constants for the multiboot header.
.set ALIGN,    1<<0             # align loaded modules on page boundaries
.set MEMINFO,  1<<1             # provide memory map
.set FLAGS,    ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,    0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

# Declare a header as in the Multiboot Standard.
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

# Reserve a stack for the initial thread.
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

.section .data

# GDT
.align 4096
gdt_start:
	.quad 0x0000000000000000	# 0x00: null segment
	.quad 0x00cf9a000000ffff	# 0x08: kernel code segment
	.quad 0x00cf92000000ffff	# 0x10: kernel data segment
	.quad 0x00cffa000000ffff	# 0x18: user code segment
	.quad 0x00cff2000000ffff	# 0x20: user data segment
gdt_end:


gdtr:
	.word gdt_end - gdt_start - 1
	.long gdt_start


# The kernel entry point.
.section .text
.global _start
.type _start, @function
_start:
	# Setup GDT.
	lgdt gdtr
	ljmp $0x08, $1f
1:	movw $0x10, %ax
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs

	# Setup stack.
	movl $stack_top, %esp

	# Call the global constructors.
	call _init

	# Transfer control to the main kernel.
	call kernel_main

	# Hang if kernel_main unexpectedly returns.
	cli
1:	hlt
	jmp 1b
.size _start, . - _start
