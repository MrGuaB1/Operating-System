#include <mmu.h>
#include <memlayout.h>
    # 告诉汇编器该节是可分配的(a)、可执行的(x)，并且包含数据(@progbits)
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop

    tail kern_init

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack 
bootstack:
    .space KSTACKSIZE  # 留出KSTACKSIZE这么多字节的内存
    .global bootstacktop 
bootstacktop: