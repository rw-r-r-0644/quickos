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

.section .bss

.align 4096

# Reserve a page table and a page directory for higher half boot
boot_page_directory:
.skip 4096
boot_page_table1:
.skip 4096

# Reserve a stack for the initial thread.
stack_bottom:
.skip 16384
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

gdtr_boot:
	.word gdt_end - gdt_start - 1
	.long gdt_start - 0xC0000000

gdtr:
	.word gdt_end - gdt_start - 1
	.long gdt_start


# The kernel entry point
.section .text
.global _start
.type _start, @function
_start:
	# Load boot gdt
	lgdt gdtr_boot - 0xC0000000
	ljmp $0x08, $(1f - 0xC0000000)
1:	movw $0x10, %ax
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs

	# Clear bss
	movl $(_kernel_bss_start - 0xC0000000), %edi
2:	movl $0, (%edi)
	addl $4, %edi
	cmpl $(_kernel_bss_end - 0xC0000000), %edi
	jg 2b


	# Setup boot page table
	movl $(boot_page_table1 - 0xC0000000), %edi
	movl $0, %esi
	movl $1023, %ecx
3:	cmpl $(_kernel_start - 0xC0000000), %esi
	jl 5f
	cmpl $(_kernel_end - 0xC0000000), %esi
	jge 6f
	movl %esi, %edx
	orl $1, %edx
	cmpl $_kernel_rw_start, %esi
	jl 4f
	orl $2, %edx
4:	movl %edx, (%edi)
5:	addl $4096, %esi
	addl $4, %edi
	loop 3b
6:
	# Map VGA buffer
	movl $(0xB8000 + 0x3), boot_page_table1 - 0xC0000000 + 1023 * 4

	# Map page table to 0x00000000 and 0xC0000000
	movl $(boot_page_table1 - 0xC0000000 + 0x3), boot_page_directory - 0xC0000000 + 0x000
	movl $(boot_page_table1 - 0xC0000000 + 0x3), boot_page_directory - 0xC0000000 + 0xC00

	# Set cr3 to the address of the boot_page_directory
	movl $(boot_page_directory - 0xC0000000), %ecx
	movl %ecx, %cr3

	# Enable paging and the write-protect bit
	movl %cr0, %ecx
	orl $0x80010000, %ecx
	movl %ecx, %cr0

	# Load new GDT and jump to higher half
	lgdt gdtr
	ljmp $0x08, $7f
7:	movw $0x10, %ax
	movw %ax, %ds
	movw %ax, %ss
	movw %ax, %es
	movw %ax, %fs
	movw %ax, %gs

	# Unmap the identity mapping as it is now unnecessary.
	movl $0, boot_page_directory + 0

	# Setup stack.
	movl $stack_top, %esp

	# TODO: Global constructors provoke a triple fault
	# Call the global constructors.
	#call _init

	# Transfer control to the main kernel.
	call kernel_main

	# Hang if kernel_main unexpectedly returns.
	cli
1:	hlt
	jmp 1b
.size _start, . - _start
