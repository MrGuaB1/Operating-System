
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	0000a517          	auipc	a0,0xa
ffffffffc020003a:	04a50513          	addi	a0,a0,74 # ffffffffc020a080 <edata>
ffffffffc020003e:	00011617          	auipc	a2,0x11
ffffffffc0200042:	59a60613          	addi	a2,a2,1434 # ffffffffc02115d8 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	1c9040ef          	jal	ra,ffffffffc0204a16 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00005597          	auipc	a1,0x5
ffffffffc0200056:	9ee58593          	addi	a1,a1,-1554 # ffffffffc0204a40 <etext>
ffffffffc020005a:	00005517          	auipc	a0,0x5
ffffffffc020005e:	a0650513          	addi	a0,a0,-1530 # ffffffffc0204a60 <etext+0x20>
ffffffffc0200062:	05c000ef          	jal	ra,ffffffffc02000be <cprintf>

    print_kerninfo();
ffffffffc0200066:	0a0000ef          	jal	ra,ffffffffc0200106 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	2ad010ef          	jal	ra,ffffffffc0201b16 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006e:	504000ef          	jal	ra,ffffffffc0200572 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200072:	4bb030ef          	jal	ra,ffffffffc0203d2c <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200076:	426000ef          	jal	ra,ffffffffc020049c <ide_init>
    swap_init();                // init swap
ffffffffc020007a:	1e5020ef          	jal	ra,ffffffffc0202a5e <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007e:	356000ef          	jal	ra,ffffffffc02003d4 <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc0200082:	a001                	j	ffffffffc0200082 <kern_init+0x4c>

ffffffffc0200084 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200084:	1141                	addi	sp,sp,-16
ffffffffc0200086:	e022                	sd	s0,0(sp)
ffffffffc0200088:	e406                	sd	ra,8(sp)
ffffffffc020008a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020008c:	39e000ef          	jal	ra,ffffffffc020042a <cons_putc>
    (*cnt) ++;
ffffffffc0200090:	401c                	lw	a5,0(s0)
}
ffffffffc0200092:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200094:	2785                	addiw	a5,a5,1
ffffffffc0200096:	c01c                	sw	a5,0(s0)
}
ffffffffc0200098:	6402                	ld	s0,0(sp)
ffffffffc020009a:	0141                	addi	sp,sp,16
ffffffffc020009c:	8082                	ret

ffffffffc020009e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	86ae                	mv	a3,a1
ffffffffc02000a2:	862a                	mv	a2,a0
ffffffffc02000a4:	006c                	addi	a1,sp,12
ffffffffc02000a6:	00000517          	auipc	a0,0x0
ffffffffc02000aa:	fde50513          	addi	a0,a0,-34 # ffffffffc0200084 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ae:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000b0:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	47c040ef          	jal	ra,ffffffffc020452e <vprintfmt>
    return cnt;
}
ffffffffc02000b6:	60e2                	ld	ra,24(sp)
ffffffffc02000b8:	4532                	lw	a0,12(sp)
ffffffffc02000ba:	6105                	addi	sp,sp,32
ffffffffc02000bc:	8082                	ret

ffffffffc02000be <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000be:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000c0:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c4:	f42e                	sd	a1,40(sp)
ffffffffc02000c6:	f832                	sd	a2,48(sp)
ffffffffc02000c8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ca:	862a                	mv	a2,a0
ffffffffc02000cc:	004c                	addi	a1,sp,4
ffffffffc02000ce:	00000517          	auipc	a0,0x0
ffffffffc02000d2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200084 <cputch>
ffffffffc02000d6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	ec06                	sd	ra,24(sp)
ffffffffc02000da:	e0ba                	sd	a4,64(sp)
ffffffffc02000dc:	e4be                	sd	a5,72(sp)
ffffffffc02000de:	e8c2                	sd	a6,80(sp)
ffffffffc02000e0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	448040ef          	jal	ra,ffffffffc020452e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000ea:	60e2                	ld	ra,24(sp)
ffffffffc02000ec:	4512                	lw	a0,4(sp)
ffffffffc02000ee:	6125                	addi	sp,sp,96
ffffffffc02000f0:	8082                	ret

ffffffffc02000f2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f2:	3380006f          	j	ffffffffc020042a <cons_putc>

ffffffffc02000f6 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f6:	1141                	addi	sp,sp,-16
ffffffffc02000f8:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000fa:	366000ef          	jal	ra,ffffffffc0200460 <cons_getc>
ffffffffc02000fe:	dd75                	beqz	a0,ffffffffc02000fa <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200100:	60a2                	ld	ra,8(sp)
ffffffffc0200102:	0141                	addi	sp,sp,16
ffffffffc0200104:	8082                	ret

ffffffffc0200106 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200106:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200108:	00005517          	auipc	a0,0x5
ffffffffc020010c:	99050513          	addi	a0,a0,-1648 # ffffffffc0204a98 <etext+0x58>
void print_kerninfo(void) {
ffffffffc0200110:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200112:	fadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200116:	00000597          	auipc	a1,0x0
ffffffffc020011a:	f2058593          	addi	a1,a1,-224 # ffffffffc0200036 <kern_init>
ffffffffc020011e:	00005517          	auipc	a0,0x5
ffffffffc0200122:	99a50513          	addi	a0,a0,-1638 # ffffffffc0204ab8 <etext+0x78>
ffffffffc0200126:	f99ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020012a:	00005597          	auipc	a1,0x5
ffffffffc020012e:	91658593          	addi	a1,a1,-1770 # ffffffffc0204a40 <etext>
ffffffffc0200132:	00005517          	auipc	a0,0x5
ffffffffc0200136:	9a650513          	addi	a0,a0,-1626 # ffffffffc0204ad8 <etext+0x98>
ffffffffc020013a:	f85ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020013e:	0000a597          	auipc	a1,0xa
ffffffffc0200142:	f4258593          	addi	a1,a1,-190 # ffffffffc020a080 <edata>
ffffffffc0200146:	00005517          	auipc	a0,0x5
ffffffffc020014a:	9b250513          	addi	a0,a0,-1614 # ffffffffc0204af8 <etext+0xb8>
ffffffffc020014e:	f71ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200152:	00011597          	auipc	a1,0x11
ffffffffc0200156:	48658593          	addi	a1,a1,1158 # ffffffffc02115d8 <end>
ffffffffc020015a:	00005517          	auipc	a0,0x5
ffffffffc020015e:	9be50513          	addi	a0,a0,-1602 # ffffffffc0204b18 <etext+0xd8>
ffffffffc0200162:	f5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200166:	00012597          	auipc	a1,0x12
ffffffffc020016a:	87158593          	addi	a1,a1,-1935 # ffffffffc02119d7 <end+0x3ff>
ffffffffc020016e:	00000797          	auipc	a5,0x0
ffffffffc0200172:	ec878793          	addi	a5,a5,-312 # ffffffffc0200036 <kern_init>
ffffffffc0200176:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020017a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020017e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200180:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200184:	95be                	add	a1,a1,a5
ffffffffc0200186:	85a9                	srai	a1,a1,0xa
ffffffffc0200188:	00005517          	auipc	a0,0x5
ffffffffc020018c:	9b050513          	addi	a0,a0,-1616 # ffffffffc0204b38 <etext+0xf8>
}
ffffffffc0200190:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200192:	f2dff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200196 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200196:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc0200198:	00005617          	auipc	a2,0x5
ffffffffc020019c:	8d060613          	addi	a2,a2,-1840 # ffffffffc0204a68 <etext+0x28>
ffffffffc02001a0:	04e00593          	li	a1,78
ffffffffc02001a4:	00005517          	auipc	a0,0x5
ffffffffc02001a8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0204a80 <etext+0x40>
void print_stackframe(void) {
ffffffffc02001ac:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001ae:	1c6000ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02001b2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001b2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001b4:	00005617          	auipc	a2,0x5
ffffffffc02001b8:	a8c60613          	addi	a2,a2,-1396 # ffffffffc0204c40 <commands+0xd8>
ffffffffc02001bc:	00005597          	auipc	a1,0x5
ffffffffc02001c0:	aa458593          	addi	a1,a1,-1372 # ffffffffc0204c60 <commands+0xf8>
ffffffffc02001c4:	00005517          	auipc	a0,0x5
ffffffffc02001c8:	aa450513          	addi	a0,a0,-1372 # ffffffffc0204c68 <commands+0x100>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001cc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ce:	ef1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02001d2:	00005617          	auipc	a2,0x5
ffffffffc02001d6:	aa660613          	addi	a2,a2,-1370 # ffffffffc0204c78 <commands+0x110>
ffffffffc02001da:	00005597          	auipc	a1,0x5
ffffffffc02001de:	ac658593          	addi	a1,a1,-1338 # ffffffffc0204ca0 <commands+0x138>
ffffffffc02001e2:	00005517          	auipc	a0,0x5
ffffffffc02001e6:	a8650513          	addi	a0,a0,-1402 # ffffffffc0204c68 <commands+0x100>
ffffffffc02001ea:	ed5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc02001ee:	00005617          	auipc	a2,0x5
ffffffffc02001f2:	ac260613          	addi	a2,a2,-1342 # ffffffffc0204cb0 <commands+0x148>
ffffffffc02001f6:	00005597          	auipc	a1,0x5
ffffffffc02001fa:	ada58593          	addi	a1,a1,-1318 # ffffffffc0204cd0 <commands+0x168>
ffffffffc02001fe:	00005517          	auipc	a0,0x5
ffffffffc0200202:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0204c68 <commands+0x100>
ffffffffc0200206:	eb9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    }
    return 0;
}
ffffffffc020020a:	60a2                	ld	ra,8(sp)
ffffffffc020020c:	4501                	li	a0,0
ffffffffc020020e:	0141                	addi	sp,sp,16
ffffffffc0200210:	8082                	ret

ffffffffc0200212 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200212:	1141                	addi	sp,sp,-16
ffffffffc0200214:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200216:	ef1ff0ef          	jal	ra,ffffffffc0200106 <print_kerninfo>
    return 0;
}
ffffffffc020021a:	60a2                	ld	ra,8(sp)
ffffffffc020021c:	4501                	li	a0,0
ffffffffc020021e:	0141                	addi	sp,sp,16
ffffffffc0200220:	8082                	ret

ffffffffc0200222 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200222:	1141                	addi	sp,sp,-16
ffffffffc0200224:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200226:	f71ff0ef          	jal	ra,ffffffffc0200196 <print_stackframe>
    return 0;
}
ffffffffc020022a:	60a2                	ld	ra,8(sp)
ffffffffc020022c:	4501                	li	a0,0
ffffffffc020022e:	0141                	addi	sp,sp,16
ffffffffc0200230:	8082                	ret

ffffffffc0200232 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200232:	7115                	addi	sp,sp,-224
ffffffffc0200234:	e962                	sd	s8,144(sp)
ffffffffc0200236:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200238:	00005517          	auipc	a0,0x5
ffffffffc020023c:	97850513          	addi	a0,a0,-1672 # ffffffffc0204bb0 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200240:	ed86                	sd	ra,216(sp)
ffffffffc0200242:	e9a2                	sd	s0,208(sp)
ffffffffc0200244:	e5a6                	sd	s1,200(sp)
ffffffffc0200246:	e1ca                	sd	s2,192(sp)
ffffffffc0200248:	fd4e                	sd	s3,184(sp)
ffffffffc020024a:	f952                	sd	s4,176(sp)
ffffffffc020024c:	f556                	sd	s5,168(sp)
ffffffffc020024e:	f15a                	sd	s6,160(sp)
ffffffffc0200250:	ed5e                	sd	s7,152(sp)
ffffffffc0200252:	e566                	sd	s9,136(sp)
ffffffffc0200254:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200256:	e69ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020025a:	00005517          	auipc	a0,0x5
ffffffffc020025e:	97e50513          	addi	a0,a0,-1666 # ffffffffc0204bd8 <commands+0x70>
ffffffffc0200262:	e5dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    if (tf != NULL) {
ffffffffc0200266:	000c0563          	beqz	s8,ffffffffc0200270 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020026a:	8562                	mv	a0,s8
ffffffffc020026c:	4f2000ef          	jal	ra,ffffffffc020075e <print_trapframe>
ffffffffc0200270:	00005c97          	auipc	s9,0x5
ffffffffc0200274:	8f8c8c93          	addi	s9,s9,-1800 # ffffffffc0204b68 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc0200278:	00006997          	auipc	s3,0x6
ffffffffc020027c:	ed098993          	addi	s3,s3,-304 # ffffffffc0206148 <default_pmm_manager+0x9d8>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200280:	00005917          	auipc	s2,0x5
ffffffffc0200284:	98090913          	addi	s2,s2,-1664 # ffffffffc0204c00 <commands+0x98>
        if (argc == MAXARGS - 1) {
ffffffffc0200288:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020028a:	00005b17          	auipc	s6,0x5
ffffffffc020028e:	97eb0b13          	addi	s6,s6,-1666 # ffffffffc0204c08 <commands+0xa0>
    if (argc == 0) {
ffffffffc0200292:	00005a97          	auipc	s5,0x5
ffffffffc0200296:	9cea8a93          	addi	s5,s5,-1586 # ffffffffc0204c60 <commands+0xf8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020029a:	4b8d                	li	s7,3
        if ((buf = readline("")) != NULL) {
ffffffffc020029c:	854e                	mv	a0,s3
ffffffffc020029e:	61c040ef          	jal	ra,ffffffffc02048ba <readline>
ffffffffc02002a2:	842a                	mv	s0,a0
ffffffffc02002a4:	dd65                	beqz	a0,ffffffffc020029c <kmonitor+0x6a>
ffffffffc02002a6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002aa:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002ac:	c999                	beqz	a1,ffffffffc02002c2 <kmonitor+0x90>
ffffffffc02002ae:	854a                	mv	a0,s2
ffffffffc02002b0:	748040ef          	jal	ra,ffffffffc02049f8 <strchr>
ffffffffc02002b4:	c925                	beqz	a0,ffffffffc0200324 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002b6:	00144583          	lbu	a1,1(s0)
ffffffffc02002ba:	00040023          	sb	zero,0(s0)
ffffffffc02002be:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002c0:	f5fd                	bnez	a1,ffffffffc02002ae <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002c2:	dce9                	beqz	s1,ffffffffc020029c <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002c4:	6582                	ld	a1,0(sp)
ffffffffc02002c6:	00005d17          	auipc	s10,0x5
ffffffffc02002ca:	8a2d0d13          	addi	s10,s10,-1886 # ffffffffc0204b68 <commands>
    if (argc == 0) {
ffffffffc02002ce:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002d2:	0d61                	addi	s10,s10,24
ffffffffc02002d4:	6fa040ef          	jal	ra,ffffffffc02049ce <strcmp>
ffffffffc02002d8:	c919                	beqz	a0,ffffffffc02002ee <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002da:	2405                	addiw	s0,s0,1
ffffffffc02002dc:	09740463          	beq	s0,s7,ffffffffc0200364 <kmonitor+0x132>
ffffffffc02002e0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	0d61                	addi	s10,s10,24
ffffffffc02002e8:	6e6040ef          	jal	ra,ffffffffc02049ce <strcmp>
ffffffffc02002ec:	f57d                	bnez	a0,ffffffffc02002da <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02002ee:	00141793          	slli	a5,s0,0x1
ffffffffc02002f2:	97a2                	add	a5,a5,s0
ffffffffc02002f4:	078e                	slli	a5,a5,0x3
ffffffffc02002f6:	97e6                	add	a5,a5,s9
ffffffffc02002f8:	6b9c                	ld	a5,16(a5)
ffffffffc02002fa:	8662                	mv	a2,s8
ffffffffc02002fc:	002c                	addi	a1,sp,8
ffffffffc02002fe:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200302:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200304:	f8055ce3          	bgez	a0,ffffffffc020029c <kmonitor+0x6a>
}
ffffffffc0200308:	60ee                	ld	ra,216(sp)
ffffffffc020030a:	644e                	ld	s0,208(sp)
ffffffffc020030c:	64ae                	ld	s1,200(sp)
ffffffffc020030e:	690e                	ld	s2,192(sp)
ffffffffc0200310:	79ea                	ld	s3,184(sp)
ffffffffc0200312:	7a4a                	ld	s4,176(sp)
ffffffffc0200314:	7aaa                	ld	s5,168(sp)
ffffffffc0200316:	7b0a                	ld	s6,160(sp)
ffffffffc0200318:	6bea                	ld	s7,152(sp)
ffffffffc020031a:	6c4a                	ld	s8,144(sp)
ffffffffc020031c:	6caa                	ld	s9,136(sp)
ffffffffc020031e:	6d0a                	ld	s10,128(sp)
ffffffffc0200320:	612d                	addi	sp,sp,224
ffffffffc0200322:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200324:	00044783          	lbu	a5,0(s0)
ffffffffc0200328:	dfc9                	beqz	a5,ffffffffc02002c2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020032a:	03448863          	beq	s1,s4,ffffffffc020035a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020032e:	00349793          	slli	a5,s1,0x3
ffffffffc0200332:	0118                	addi	a4,sp,128
ffffffffc0200334:	97ba                	add	a5,a5,a4
ffffffffc0200336:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020033a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020033e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200340:	e591                	bnez	a1,ffffffffc020034c <kmonitor+0x11a>
ffffffffc0200342:	b749                	j	ffffffffc02002c4 <kmonitor+0x92>
            buf ++;
ffffffffc0200344:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200346:	00044583          	lbu	a1,0(s0)
ffffffffc020034a:	ddad                	beqz	a1,ffffffffc02002c4 <kmonitor+0x92>
ffffffffc020034c:	854a                	mv	a0,s2
ffffffffc020034e:	6aa040ef          	jal	ra,ffffffffc02049f8 <strchr>
ffffffffc0200352:	d96d                	beqz	a0,ffffffffc0200344 <kmonitor+0x112>
ffffffffc0200354:	00044583          	lbu	a1,0(s0)
ffffffffc0200358:	bf91                	j	ffffffffc02002ac <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020035a:	45c1                	li	a1,16
ffffffffc020035c:	855a                	mv	a0,s6
ffffffffc020035e:	d61ff0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0200362:	b7f1                	j	ffffffffc020032e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200364:	6582                	ld	a1,0(sp)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	8c250513          	addi	a0,a0,-1854 # ffffffffc0204c28 <commands+0xc0>
ffffffffc020036e:	d51ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    return 0;
ffffffffc0200372:	b72d                	j	ffffffffc020029c <kmonitor+0x6a>

ffffffffc0200374 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200374:	00011317          	auipc	t1,0x11
ffffffffc0200378:	10c30313          	addi	t1,t1,268 # ffffffffc0211480 <is_panic>
ffffffffc020037c:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200380:	715d                	addi	sp,sp,-80
ffffffffc0200382:	ec06                	sd	ra,24(sp)
ffffffffc0200384:	e822                	sd	s0,16(sp)
ffffffffc0200386:	f436                	sd	a3,40(sp)
ffffffffc0200388:	f83a                	sd	a4,48(sp)
ffffffffc020038a:	fc3e                	sd	a5,56(sp)
ffffffffc020038c:	e0c2                	sd	a6,64(sp)
ffffffffc020038e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200390:	02031c63          	bnez	t1,ffffffffc02003c8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200394:	4785                	li	a5,1
ffffffffc0200396:	8432                	mv	s0,a2
ffffffffc0200398:	00011717          	auipc	a4,0x11
ffffffffc020039c:	0ef72423          	sw	a5,232(a4) # ffffffffc0211480 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003a0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003a2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003a4:	85aa                	mv	a1,a0
ffffffffc02003a6:	00005517          	auipc	a0,0x5
ffffffffc02003aa:	93a50513          	addi	a0,a0,-1734 # ffffffffc0204ce0 <commands+0x178>
    va_start(ap, fmt);
ffffffffc02003ae:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003b0:	d0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003b4:	65a2                	ld	a1,8(sp)
ffffffffc02003b6:	8522                	mv	a0,s0
ffffffffc02003b8:	ce7ff0ef          	jal	ra,ffffffffc020009e <vcprintf>
    cprintf("\n");
ffffffffc02003bc:	00006517          	auipc	a0,0x6
ffffffffc02003c0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0205c58 <default_pmm_manager+0x4e8>
ffffffffc02003c4:	cfbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003c8:	132000ef          	jal	ra,ffffffffc02004fa <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02003cc:	4501                	li	a0,0
ffffffffc02003ce:	e65ff0ef          	jal	ra,ffffffffc0200232 <kmonitor>
ffffffffc02003d2:	bfed                	j	ffffffffc02003cc <__panic+0x58>

ffffffffc02003d4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02003d4:	67e1                	lui	a5,0x18
ffffffffc02003d6:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc02003da:	00011717          	auipc	a4,0x11
ffffffffc02003de:	0af73723          	sd	a5,174(a4) # ffffffffc0211488 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02003e2:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02003e6:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02003e8:	953e                	add	a0,a0,a5
ffffffffc02003ea:	4601                	li	a2,0
ffffffffc02003ec:	4881                	li	a7,0
ffffffffc02003ee:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02003f2:	02000793          	li	a5,32
ffffffffc02003f6:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02003fa:	00005517          	auipc	a0,0x5
ffffffffc02003fe:	90650513          	addi	a0,a0,-1786 # ffffffffc0204d00 <commands+0x198>
    ticks = 0;
ffffffffc0200402:	00011797          	auipc	a5,0x11
ffffffffc0200406:	0a07b723          	sd	zero,174(a5) # ffffffffc02114b0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020040a:	cb5ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020040e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020040e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200412:	00011797          	auipc	a5,0x11
ffffffffc0200416:	07678793          	addi	a5,a5,118 # ffffffffc0211488 <timebase>
ffffffffc020041a:	639c                	ld	a5,0(a5)
ffffffffc020041c:	4581                	li	a1,0
ffffffffc020041e:	4601                	li	a2,0
ffffffffc0200420:	953e                	add	a0,a0,a5
ffffffffc0200422:	4881                	li	a7,0
ffffffffc0200424:	00000073          	ecall
ffffffffc0200428:	8082                	ret

ffffffffc020042a <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020042a:	100027f3          	csrr	a5,sstatus
ffffffffc020042e:	8b89                	andi	a5,a5,2
ffffffffc0200430:	0ff57513          	andi	a0,a0,255
ffffffffc0200434:	e799                	bnez	a5,ffffffffc0200442 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200436:	4581                	li	a1,0
ffffffffc0200438:	4601                	li	a2,0
ffffffffc020043a:	4885                	li	a7,1
ffffffffc020043c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200440:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200442:	1101                	addi	sp,sp,-32
ffffffffc0200444:	ec06                	sd	ra,24(sp)
ffffffffc0200446:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200448:	0b2000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc020044c:	6522                	ld	a0,8(sp)
ffffffffc020044e:	4581                	li	a1,0
ffffffffc0200450:	4601                	li	a2,0
ffffffffc0200452:	4885                	li	a7,1
ffffffffc0200454:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200458:	60e2                	ld	ra,24(sp)
ffffffffc020045a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020045c:	0980006f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc0200460 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200460:	100027f3          	csrr	a5,sstatus
ffffffffc0200464:	8b89                	andi	a5,a5,2
ffffffffc0200466:	eb89                	bnez	a5,ffffffffc0200478 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200468:	4501                	li	a0,0
ffffffffc020046a:	4581                	li	a1,0
ffffffffc020046c:	4601                	li	a2,0
ffffffffc020046e:	4889                	li	a7,2
ffffffffc0200470:	00000073          	ecall
ffffffffc0200474:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200476:	8082                	ret
int cons_getc(void) {
ffffffffc0200478:	1101                	addi	sp,sp,-32
ffffffffc020047a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020047c:	07e000ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc0200480:	4501                	li	a0,0
ffffffffc0200482:	4581                	li	a1,0
ffffffffc0200484:	4601                	li	a2,0
ffffffffc0200486:	4889                	li	a7,2
ffffffffc0200488:	00000073          	ecall
ffffffffc020048c:	2501                	sext.w	a0,a0
ffffffffc020048e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200490:	064000ef          	jal	ra,ffffffffc02004f4 <intr_enable>
}
ffffffffc0200494:	60e2                	ld	ra,24(sp)
ffffffffc0200496:	6522                	ld	a0,8(sp)
ffffffffc0200498:	6105                	addi	sp,sp,32
ffffffffc020049a:	8082                	ret

ffffffffc020049c <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc020049c:	8082                	ret

ffffffffc020049e <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc020049e:	00253513          	sltiu	a0,a0,2
ffffffffc02004a2:	8082                	ret

ffffffffc02004a4 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004a4:	03800513          	li	a0,56
ffffffffc02004a8:	8082                	ret

ffffffffc02004aa <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004aa:	0000a797          	auipc	a5,0xa
ffffffffc02004ae:	bd678793          	addi	a5,a5,-1066 # ffffffffc020a080 <edata>
ffffffffc02004b2:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02004b6:	1141                	addi	sp,sp,-16
ffffffffc02004b8:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004ba:	95be                	add	a1,a1,a5
ffffffffc02004bc:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004c0:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c2:	566040ef          	jal	ra,ffffffffc0204a28 <memcpy>
    return 0;
}
ffffffffc02004c6:	60a2                	ld	ra,8(sp)
ffffffffc02004c8:	4501                	li	a0,0
ffffffffc02004ca:	0141                	addi	sp,sp,16
ffffffffc02004cc:	8082                	ret

ffffffffc02004ce <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc02004ce:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004d0:	0095979b          	slliw	a5,a1,0x9
ffffffffc02004d4:	0000a517          	auipc	a0,0xa
ffffffffc02004d8:	bac50513          	addi	a0,a0,-1108 # ffffffffc020a080 <edata>
                   size_t nsecs) {
ffffffffc02004dc:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004de:	00969613          	slli	a2,a3,0x9
ffffffffc02004e2:	85ba                	mv	a1,a4
ffffffffc02004e4:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc02004e6:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e8:	540040ef          	jal	ra,ffffffffc0204a28 <memcpy>
    return 0;
}
ffffffffc02004ec:	60a2                	ld	ra,8(sp)
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	0141                	addi	sp,sp,16
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004f4:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004f8:	8082                	ret

ffffffffc02004fa <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004fa:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004fe:	8082                	ret

ffffffffc0200500 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200500:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200504:	1141                	addi	sp,sp,-16
ffffffffc0200506:	e022                	sd	s0,0(sp)
ffffffffc0200508:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020050a:	1007f793          	andi	a5,a5,256
static int pgfault_handler(struct trapframe *tf) {
ffffffffc020050e:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc0200510:	11053583          	ld	a1,272(a0)
ffffffffc0200514:	05500613          	li	a2,85
ffffffffc0200518:	c399                	beqz	a5,ffffffffc020051e <pgfault_handler+0x1e>
ffffffffc020051a:	04b00613          	li	a2,75
ffffffffc020051e:	11843703          	ld	a4,280(s0)
ffffffffc0200522:	47bd                	li	a5,15
ffffffffc0200524:	05700693          	li	a3,87
ffffffffc0200528:	00f70463          	beq	a4,a5,ffffffffc0200530 <pgfault_handler+0x30>
ffffffffc020052c:	05200693          	li	a3,82
ffffffffc0200530:	00005517          	auipc	a0,0x5
ffffffffc0200534:	ac850513          	addi	a0,a0,-1336 # ffffffffc0204ff8 <commands+0x490>
ffffffffc0200538:	b87ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc020053c:	00011797          	auipc	a5,0x11
ffffffffc0200540:	09478793          	addi	a5,a5,148 # ffffffffc02115d0 <check_mm_struct>
ffffffffc0200544:	6388                	ld	a0,0(a5)
ffffffffc0200546:	c911                	beqz	a0,ffffffffc020055a <pgfault_handler+0x5a>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200548:	11043603          	ld	a2,272(s0)
ffffffffc020054c:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200550:	6402                	ld	s0,0(sp)
ffffffffc0200552:	60a2                	ld	ra,8(sp)
ffffffffc0200554:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200556:	5150306f          	j	ffffffffc020426a <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc020055a:	00005617          	auipc	a2,0x5
ffffffffc020055e:	abe60613          	addi	a2,a2,-1346 # ffffffffc0205018 <commands+0x4b0>
ffffffffc0200562:	07800593          	li	a1,120
ffffffffc0200566:	00005517          	auipc	a0,0x5
ffffffffc020056a:	aca50513          	addi	a0,a0,-1334 # ffffffffc0205030 <commands+0x4c8>
ffffffffc020056e:	e07ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0200572 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200572:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200576:	00000797          	auipc	a5,0x0
ffffffffc020057a:	49a78793          	addi	a5,a5,1178 # ffffffffc0200a10 <__alltraps>
ffffffffc020057e:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200582:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200586:	000407b7          	lui	a5,0x40
ffffffffc020058a:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020058e:	8082                	ret

ffffffffc0200590 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200590:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200592:	1141                	addi	sp,sp,-16
ffffffffc0200594:	e022                	sd	s0,0(sp)
ffffffffc0200596:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200598:	00005517          	auipc	a0,0x5
ffffffffc020059c:	ab050513          	addi	a0,a0,-1360 # ffffffffc0205048 <commands+0x4e0>
void print_regs(struct pushregs *gpr) {
ffffffffc02005a0:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02005a2:	b1dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02005a6:	640c                	ld	a1,8(s0)
ffffffffc02005a8:	00005517          	auipc	a0,0x5
ffffffffc02005ac:	ab850513          	addi	a0,a0,-1352 # ffffffffc0205060 <commands+0x4f8>
ffffffffc02005b0:	b0fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005b4:	680c                	ld	a1,16(s0)
ffffffffc02005b6:	00005517          	auipc	a0,0x5
ffffffffc02005ba:	ac250513          	addi	a0,a0,-1342 # ffffffffc0205078 <commands+0x510>
ffffffffc02005be:	b01ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005c2:	6c0c                	ld	a1,24(s0)
ffffffffc02005c4:	00005517          	auipc	a0,0x5
ffffffffc02005c8:	acc50513          	addi	a0,a0,-1332 # ffffffffc0205090 <commands+0x528>
ffffffffc02005cc:	af3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005d0:	700c                	ld	a1,32(s0)
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	ad650513          	addi	a0,a0,-1322 # ffffffffc02050a8 <commands+0x540>
ffffffffc02005da:	ae5ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005de:	740c                	ld	a1,40(s0)
ffffffffc02005e0:	00005517          	auipc	a0,0x5
ffffffffc02005e4:	ae050513          	addi	a0,a0,-1312 # ffffffffc02050c0 <commands+0x558>
ffffffffc02005e8:	ad7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005ec:	780c                	ld	a1,48(s0)
ffffffffc02005ee:	00005517          	auipc	a0,0x5
ffffffffc02005f2:	aea50513          	addi	a0,a0,-1302 # ffffffffc02050d8 <commands+0x570>
ffffffffc02005f6:	ac9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005fa:	7c0c                	ld	a1,56(s0)
ffffffffc02005fc:	00005517          	auipc	a0,0x5
ffffffffc0200600:	af450513          	addi	a0,a0,-1292 # ffffffffc02050f0 <commands+0x588>
ffffffffc0200604:	abbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200608:	602c                	ld	a1,64(s0)
ffffffffc020060a:	00005517          	auipc	a0,0x5
ffffffffc020060e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0205108 <commands+0x5a0>
ffffffffc0200612:	aadff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200616:	642c                	ld	a1,72(s0)
ffffffffc0200618:	00005517          	auipc	a0,0x5
ffffffffc020061c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0205120 <commands+0x5b8>
ffffffffc0200620:	a9fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200624:	682c                	ld	a1,80(s0)
ffffffffc0200626:	00005517          	auipc	a0,0x5
ffffffffc020062a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0205138 <commands+0x5d0>
ffffffffc020062e:	a91ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200632:	6c2c                	ld	a1,88(s0)
ffffffffc0200634:	00005517          	auipc	a0,0x5
ffffffffc0200638:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0205150 <commands+0x5e8>
ffffffffc020063c:	a83ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200640:	702c                	ld	a1,96(s0)
ffffffffc0200642:	00005517          	auipc	a0,0x5
ffffffffc0200646:	b2650513          	addi	a0,a0,-1242 # ffffffffc0205168 <commands+0x600>
ffffffffc020064a:	a75ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020064e:	742c                	ld	a1,104(s0)
ffffffffc0200650:	00005517          	auipc	a0,0x5
ffffffffc0200654:	b3050513          	addi	a0,a0,-1232 # ffffffffc0205180 <commands+0x618>
ffffffffc0200658:	a67ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020065c:	782c                	ld	a1,112(s0)
ffffffffc020065e:	00005517          	auipc	a0,0x5
ffffffffc0200662:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0205198 <commands+0x630>
ffffffffc0200666:	a59ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020066a:	7c2c                	ld	a1,120(s0)
ffffffffc020066c:	00005517          	auipc	a0,0x5
ffffffffc0200670:	b4450513          	addi	a0,a0,-1212 # ffffffffc02051b0 <commands+0x648>
ffffffffc0200674:	a4bff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200678:	604c                	ld	a1,128(s0)
ffffffffc020067a:	00005517          	auipc	a0,0x5
ffffffffc020067e:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02051c8 <commands+0x660>
ffffffffc0200682:	a3dff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200686:	644c                	ld	a1,136(s0)
ffffffffc0200688:	00005517          	auipc	a0,0x5
ffffffffc020068c:	b5850513          	addi	a0,a0,-1192 # ffffffffc02051e0 <commands+0x678>
ffffffffc0200690:	a2fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200694:	684c                	ld	a1,144(s0)
ffffffffc0200696:	00005517          	auipc	a0,0x5
ffffffffc020069a:	b6250513          	addi	a0,a0,-1182 # ffffffffc02051f8 <commands+0x690>
ffffffffc020069e:	a21ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02006a2:	6c4c                	ld	a1,152(s0)
ffffffffc02006a4:	00005517          	auipc	a0,0x5
ffffffffc02006a8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0205210 <commands+0x6a8>
ffffffffc02006ac:	a13ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006b0:	704c                	ld	a1,160(s0)
ffffffffc02006b2:	00005517          	auipc	a0,0x5
ffffffffc02006b6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0205228 <commands+0x6c0>
ffffffffc02006ba:	a05ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006be:	744c                	ld	a1,168(s0)
ffffffffc02006c0:	00005517          	auipc	a0,0x5
ffffffffc02006c4:	b8050513          	addi	a0,a0,-1152 # ffffffffc0205240 <commands+0x6d8>
ffffffffc02006c8:	9f7ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006cc:	784c                	ld	a1,176(s0)
ffffffffc02006ce:	00005517          	auipc	a0,0x5
ffffffffc02006d2:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0205258 <commands+0x6f0>
ffffffffc02006d6:	9e9ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006da:	7c4c                	ld	a1,184(s0)
ffffffffc02006dc:	00005517          	auipc	a0,0x5
ffffffffc02006e0:	b9450513          	addi	a0,a0,-1132 # ffffffffc0205270 <commands+0x708>
ffffffffc02006e4:	9dbff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006e8:	606c                	ld	a1,192(s0)
ffffffffc02006ea:	00005517          	auipc	a0,0x5
ffffffffc02006ee:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0205288 <commands+0x720>
ffffffffc02006f2:	9cdff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006f6:	646c                	ld	a1,200(s0)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	ba850513          	addi	a0,a0,-1112 # ffffffffc02052a0 <commands+0x738>
ffffffffc0200700:	9bfff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200704:	686c                	ld	a1,208(s0)
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	bb250513          	addi	a0,a0,-1102 # ffffffffc02052b8 <commands+0x750>
ffffffffc020070e:	9b1ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200712:	6c6c                	ld	a1,216(s0)
ffffffffc0200714:	00005517          	auipc	a0,0x5
ffffffffc0200718:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02052d0 <commands+0x768>
ffffffffc020071c:	9a3ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200720:	706c                	ld	a1,224(s0)
ffffffffc0200722:	00005517          	auipc	a0,0x5
ffffffffc0200726:	bc650513          	addi	a0,a0,-1082 # ffffffffc02052e8 <commands+0x780>
ffffffffc020072a:	995ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020072e:	746c                	ld	a1,232(s0)
ffffffffc0200730:	00005517          	auipc	a0,0x5
ffffffffc0200734:	bd050513          	addi	a0,a0,-1072 # ffffffffc0205300 <commands+0x798>
ffffffffc0200738:	987ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020073c:	786c                	ld	a1,240(s0)
ffffffffc020073e:	00005517          	auipc	a0,0x5
ffffffffc0200742:	bda50513          	addi	a0,a0,-1062 # ffffffffc0205318 <commands+0x7b0>
ffffffffc0200746:	979ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020074a:	7c6c                	ld	a1,248(s0)
}
ffffffffc020074c:	6402                	ld	s0,0(sp)
ffffffffc020074e:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200750:	00005517          	auipc	a0,0x5
ffffffffc0200754:	be050513          	addi	a0,a0,-1056 # ffffffffc0205330 <commands+0x7c8>
}
ffffffffc0200758:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020075a:	965ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc020075e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020075e:	1141                	addi	sp,sp,-16
ffffffffc0200760:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200762:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200764:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200766:	00005517          	auipc	a0,0x5
ffffffffc020076a:	be250513          	addi	a0,a0,-1054 # ffffffffc0205348 <commands+0x7e0>
void print_trapframe(struct trapframe *tf) {
ffffffffc020076e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200770:	94fff0ef          	jal	ra,ffffffffc02000be <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200774:	8522                	mv	a0,s0
ffffffffc0200776:	e1bff0ef          	jal	ra,ffffffffc0200590 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020077a:	10043583          	ld	a1,256(s0)
ffffffffc020077e:	00005517          	auipc	a0,0x5
ffffffffc0200782:	be250513          	addi	a0,a0,-1054 # ffffffffc0205360 <commands+0x7f8>
ffffffffc0200786:	939ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020078a:	10843583          	ld	a1,264(s0)
ffffffffc020078e:	00005517          	auipc	a0,0x5
ffffffffc0200792:	bea50513          	addi	a0,a0,-1046 # ffffffffc0205378 <commands+0x810>
ffffffffc0200796:	929ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020079a:	11043583          	ld	a1,272(s0)
ffffffffc020079e:	00005517          	auipc	a0,0x5
ffffffffc02007a2:	bf250513          	addi	a0,a0,-1038 # ffffffffc0205390 <commands+0x828>
ffffffffc02007a6:	919ff0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007aa:	11843583          	ld	a1,280(s0)
}
ffffffffc02007ae:	6402                	ld	s0,0(sp)
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007b2:	00005517          	auipc	a0,0x5
ffffffffc02007b6:	bf650513          	addi	a0,a0,-1034 # ffffffffc02053a8 <commands+0x840>
}
ffffffffc02007ba:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007bc:	903ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc02007c0 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007c0:	11853783          	ld	a5,280(a0)
ffffffffc02007c4:	577d                	li	a4,-1
ffffffffc02007c6:	8305                	srli	a4,a4,0x1
ffffffffc02007c8:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02007ca:	472d                	li	a4,11
ffffffffc02007cc:	06f76f63          	bltu	a4,a5,ffffffffc020084a <interrupt_handler+0x8a>
ffffffffc02007d0:	00004717          	auipc	a4,0x4
ffffffffc02007d4:	54c70713          	addi	a4,a4,1356 # ffffffffc0204d1c <commands+0x1b4>
ffffffffc02007d8:	078a                	slli	a5,a5,0x2
ffffffffc02007da:	97ba                	add	a5,a5,a4
ffffffffc02007dc:	439c                	lw	a5,0(a5)
ffffffffc02007de:	97ba                	add	a5,a5,a4
ffffffffc02007e0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007e2:	00004517          	auipc	a0,0x4
ffffffffc02007e6:	7c650513          	addi	a0,a0,1990 # ffffffffc0204fa8 <commands+0x440>
ffffffffc02007ea:	8d5ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007ee:	00004517          	auipc	a0,0x4
ffffffffc02007f2:	79a50513          	addi	a0,a0,1946 # ffffffffc0204f88 <commands+0x420>
ffffffffc02007f6:	8c9ff06f          	j	ffffffffc02000be <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007fa:	00004517          	auipc	a0,0x4
ffffffffc02007fe:	74e50513          	addi	a0,a0,1870 # ffffffffc0204f48 <commands+0x3e0>
ffffffffc0200802:	8bdff06f          	j	ffffffffc02000be <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200806:	00004517          	auipc	a0,0x4
ffffffffc020080a:	76250513          	addi	a0,a0,1890 # ffffffffc0204f68 <commands+0x400>
ffffffffc020080e:	8b1ff06f          	j	ffffffffc02000be <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200812:	00004517          	auipc	a0,0x4
ffffffffc0200816:	7c650513          	addi	a0,a0,1990 # ffffffffc0204fd8 <commands+0x470>
ffffffffc020081a:	8a5ff06f          	j	ffffffffc02000be <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc020081e:	1141                	addi	sp,sp,-16
ffffffffc0200820:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200822:	bedff0ef          	jal	ra,ffffffffc020040e <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200826:	00011797          	auipc	a5,0x11
ffffffffc020082a:	c8a78793          	addi	a5,a5,-886 # ffffffffc02114b0 <ticks>
ffffffffc020082e:	639c                	ld	a5,0(a5)
ffffffffc0200830:	06400713          	li	a4,100
ffffffffc0200834:	0785                	addi	a5,a5,1
ffffffffc0200836:	02e7f733          	remu	a4,a5,a4
ffffffffc020083a:	00011697          	auipc	a3,0x11
ffffffffc020083e:	c6f6bb23          	sd	a5,-906(a3) # ffffffffc02114b0 <ticks>
ffffffffc0200842:	c711                	beqz	a4,ffffffffc020084e <interrupt_handler+0x8e>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200844:	60a2                	ld	ra,8(sp)
ffffffffc0200846:	0141                	addi	sp,sp,16
ffffffffc0200848:	8082                	ret
            print_trapframe(tf);
ffffffffc020084a:	f15ff06f          	j	ffffffffc020075e <print_trapframe>
}
ffffffffc020084e:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200850:	06400593          	li	a1,100
ffffffffc0200854:	00004517          	auipc	a0,0x4
ffffffffc0200858:	77450513          	addi	a0,a0,1908 # ffffffffc0204fc8 <commands+0x460>
}
ffffffffc020085c:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020085e:	861ff06f          	j	ffffffffc02000be <cprintf>

ffffffffc0200862 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200862:	11853783          	ld	a5,280(a0)
ffffffffc0200866:	473d                	li	a4,15
ffffffffc0200868:	16f76563          	bltu	a4,a5,ffffffffc02009d2 <exception_handler+0x170>
ffffffffc020086c:	00004717          	auipc	a4,0x4
ffffffffc0200870:	4e070713          	addi	a4,a4,1248 # ffffffffc0204d4c <commands+0x1e4>
ffffffffc0200874:	078a                	slli	a5,a5,0x2
ffffffffc0200876:	97ba                	add	a5,a5,a4
ffffffffc0200878:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc020087a:	1101                	addi	sp,sp,-32
ffffffffc020087c:	e822                	sd	s0,16(sp)
ffffffffc020087e:	ec06                	sd	ra,24(sp)
ffffffffc0200880:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200882:	97ba                	add	a5,a5,a4
ffffffffc0200884:	842a                	mv	s0,a0
ffffffffc0200886:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200888:	00004517          	auipc	a0,0x4
ffffffffc020088c:	6a850513          	addi	a0,a0,1704 # ffffffffc0204f30 <commands+0x3c8>
ffffffffc0200890:	82fff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200894:	8522                	mv	a0,s0
ffffffffc0200896:	c6bff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc020089a:	84aa                	mv	s1,a0
ffffffffc020089c:	12051d63          	bnez	a0,ffffffffc02009d6 <exception_handler+0x174>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02008a0:	60e2                	ld	ra,24(sp)
ffffffffc02008a2:	6442                	ld	s0,16(sp)
ffffffffc02008a4:	64a2                	ld	s1,8(sp)
ffffffffc02008a6:	6105                	addi	sp,sp,32
ffffffffc02008a8:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc02008aa:	00004517          	auipc	a0,0x4
ffffffffc02008ae:	4e650513          	addi	a0,a0,1254 # ffffffffc0204d90 <commands+0x228>
}
ffffffffc02008b2:	6442                	ld	s0,16(sp)
ffffffffc02008b4:	60e2                	ld	ra,24(sp)
ffffffffc02008b6:	64a2                	ld	s1,8(sp)
ffffffffc02008b8:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008ba:	805ff06f          	j	ffffffffc02000be <cprintf>
ffffffffc02008be:	00004517          	auipc	a0,0x4
ffffffffc02008c2:	4f250513          	addi	a0,a0,1266 # ffffffffc0204db0 <commands+0x248>
ffffffffc02008c6:	b7f5                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008c8:	00004517          	auipc	a0,0x4
ffffffffc02008cc:	50850513          	addi	a0,a0,1288 # ffffffffc0204dd0 <commands+0x268>
ffffffffc02008d0:	b7cd                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008d2:	00004517          	auipc	a0,0x4
ffffffffc02008d6:	51650513          	addi	a0,a0,1302 # ffffffffc0204de8 <commands+0x280>
ffffffffc02008da:	bfe1                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008dc:	00004517          	auipc	a0,0x4
ffffffffc02008e0:	51c50513          	addi	a0,a0,1308 # ffffffffc0204df8 <commands+0x290>
ffffffffc02008e4:	b7f9                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	53250513          	addi	a0,a0,1330 # ffffffffc0204e18 <commands+0x2b0>
ffffffffc02008ee:	fd0ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008f2:	8522                	mv	a0,s0
ffffffffc02008f4:	c0dff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02008f8:	84aa                	mv	s1,a0
ffffffffc02008fa:	d15d                	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008fc:	8522                	mv	a0,s0
ffffffffc02008fe:	e61ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200902:	86a6                	mv	a3,s1
ffffffffc0200904:	00004617          	auipc	a2,0x4
ffffffffc0200908:	52c60613          	addi	a2,a2,1324 # ffffffffc0204e30 <commands+0x2c8>
ffffffffc020090c:	0ca00593          	li	a1,202
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	72050513          	addi	a0,a0,1824 # ffffffffc0205030 <commands+0x4c8>
ffffffffc0200918:	a5dff0ef          	jal	ra,ffffffffc0200374 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc020091c:	00004517          	auipc	a0,0x4
ffffffffc0200920:	53450513          	addi	a0,a0,1332 # ffffffffc0204e50 <commands+0x2e8>
ffffffffc0200924:	b779                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc0200926:	00004517          	auipc	a0,0x4
ffffffffc020092a:	54250513          	addi	a0,a0,1346 # ffffffffc0204e68 <commands+0x300>
ffffffffc020092e:	f90ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200932:	8522                	mv	a0,s0
ffffffffc0200934:	bcdff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc0200938:	84aa                	mv	s1,a0
ffffffffc020093a:	d13d                	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020093c:	8522                	mv	a0,s0
ffffffffc020093e:	e21ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200942:	86a6                	mv	a3,s1
ffffffffc0200944:	00004617          	auipc	a2,0x4
ffffffffc0200948:	4ec60613          	addi	a2,a2,1260 # ffffffffc0204e30 <commands+0x2c8>
ffffffffc020094c:	0d400593          	li	a1,212
ffffffffc0200950:	00004517          	auipc	a0,0x4
ffffffffc0200954:	6e050513          	addi	a0,a0,1760 # ffffffffc0205030 <commands+0x4c8>
ffffffffc0200958:	a1dff0ef          	jal	ra,ffffffffc0200374 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc020095c:	00004517          	auipc	a0,0x4
ffffffffc0200960:	52450513          	addi	a0,a0,1316 # ffffffffc0204e80 <commands+0x318>
ffffffffc0200964:	b7b9                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200966:	00004517          	auipc	a0,0x4
ffffffffc020096a:	53a50513          	addi	a0,a0,1338 # ffffffffc0204ea0 <commands+0x338>
ffffffffc020096e:	b791                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200970:	00004517          	auipc	a0,0x4
ffffffffc0200974:	55050513          	addi	a0,a0,1360 # ffffffffc0204ec0 <commands+0x358>
ffffffffc0200978:	bf2d                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc020097a:	00004517          	auipc	a0,0x4
ffffffffc020097e:	56650513          	addi	a0,a0,1382 # ffffffffc0204ee0 <commands+0x378>
ffffffffc0200982:	bf05                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200984:	00004517          	auipc	a0,0x4
ffffffffc0200988:	57c50513          	addi	a0,a0,1404 # ffffffffc0204f00 <commands+0x398>
ffffffffc020098c:	b71d                	j	ffffffffc02008b2 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	58a50513          	addi	a0,a0,1418 # ffffffffc0204f18 <commands+0x3b0>
ffffffffc0200996:	f28ff0ef          	jal	ra,ffffffffc02000be <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020099a:	8522                	mv	a0,s0
ffffffffc020099c:	b65ff0ef          	jal	ra,ffffffffc0200500 <pgfault_handler>
ffffffffc02009a0:	84aa                	mv	s1,a0
ffffffffc02009a2:	ee050fe3          	beqz	a0,ffffffffc02008a0 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009a6:	8522                	mv	a0,s0
ffffffffc02009a8:	db7ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009ac:	86a6                	mv	a3,s1
ffffffffc02009ae:	00004617          	auipc	a2,0x4
ffffffffc02009b2:	48260613          	addi	a2,a2,1154 # ffffffffc0204e30 <commands+0x2c8>
ffffffffc02009b6:	0ea00593          	li	a1,234
ffffffffc02009ba:	00004517          	auipc	a0,0x4
ffffffffc02009be:	67650513          	addi	a0,a0,1654 # ffffffffc0205030 <commands+0x4c8>
ffffffffc02009c2:	9b3ff0ef          	jal	ra,ffffffffc0200374 <__panic>
}
ffffffffc02009c6:	6442                	ld	s0,16(sp)
ffffffffc02009c8:	60e2                	ld	ra,24(sp)
ffffffffc02009ca:	64a2                	ld	s1,8(sp)
ffffffffc02009cc:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009ce:	d91ff06f          	j	ffffffffc020075e <print_trapframe>
ffffffffc02009d2:	d8dff06f          	j	ffffffffc020075e <print_trapframe>
                print_trapframe(tf);
ffffffffc02009d6:	8522                	mv	a0,s0
ffffffffc02009d8:	d87ff0ef          	jal	ra,ffffffffc020075e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009dc:	86a6                	mv	a3,s1
ffffffffc02009de:	00004617          	auipc	a2,0x4
ffffffffc02009e2:	45260613          	addi	a2,a2,1106 # ffffffffc0204e30 <commands+0x2c8>
ffffffffc02009e6:	0f100593          	li	a1,241
ffffffffc02009ea:	00004517          	auipc	a0,0x4
ffffffffc02009ee:	64650513          	addi	a0,a0,1606 # ffffffffc0205030 <commands+0x4c8>
ffffffffc02009f2:	983ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02009f6 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009f6:	11853783          	ld	a5,280(a0)
ffffffffc02009fa:	0007c463          	bltz	a5,ffffffffc0200a02 <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009fe:	e65ff06f          	j	ffffffffc0200862 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200a02:	dbfff06f          	j	ffffffffc02007c0 <interrupt_handler>
	...

ffffffffc0200a10 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200a10:	14011073          	csrw	sscratch,sp
ffffffffc0200a14:	712d                	addi	sp,sp,-288
ffffffffc0200a16:	e406                	sd	ra,8(sp)
ffffffffc0200a18:	ec0e                	sd	gp,24(sp)
ffffffffc0200a1a:	f012                	sd	tp,32(sp)
ffffffffc0200a1c:	f416                	sd	t0,40(sp)
ffffffffc0200a1e:	f81a                	sd	t1,48(sp)
ffffffffc0200a20:	fc1e                	sd	t2,56(sp)
ffffffffc0200a22:	e0a2                	sd	s0,64(sp)
ffffffffc0200a24:	e4a6                	sd	s1,72(sp)
ffffffffc0200a26:	e8aa                	sd	a0,80(sp)
ffffffffc0200a28:	ecae                	sd	a1,88(sp)
ffffffffc0200a2a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a2c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a2e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a30:	fcbe                	sd	a5,120(sp)
ffffffffc0200a32:	e142                	sd	a6,128(sp)
ffffffffc0200a34:	e546                	sd	a7,136(sp)
ffffffffc0200a36:	e94a                	sd	s2,144(sp)
ffffffffc0200a38:	ed4e                	sd	s3,152(sp)
ffffffffc0200a3a:	f152                	sd	s4,160(sp)
ffffffffc0200a3c:	f556                	sd	s5,168(sp)
ffffffffc0200a3e:	f95a                	sd	s6,176(sp)
ffffffffc0200a40:	fd5e                	sd	s7,184(sp)
ffffffffc0200a42:	e1e2                	sd	s8,192(sp)
ffffffffc0200a44:	e5e6                	sd	s9,200(sp)
ffffffffc0200a46:	e9ea                	sd	s10,208(sp)
ffffffffc0200a48:	edee                	sd	s11,216(sp)
ffffffffc0200a4a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a4c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a4e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a50:	fdfe                	sd	t6,248(sp)
ffffffffc0200a52:	14002473          	csrr	s0,sscratch
ffffffffc0200a56:	100024f3          	csrr	s1,sstatus
ffffffffc0200a5a:	14102973          	csrr	s2,sepc
ffffffffc0200a5e:	143029f3          	csrr	s3,stval
ffffffffc0200a62:	14202a73          	csrr	s4,scause
ffffffffc0200a66:	e822                	sd	s0,16(sp)
ffffffffc0200a68:	e226                	sd	s1,256(sp)
ffffffffc0200a6a:	e64a                	sd	s2,264(sp)
ffffffffc0200a6c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a6e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a70:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a72:	f85ff0ef          	jal	ra,ffffffffc02009f6 <trap>

ffffffffc0200a76 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a76:	6492                	ld	s1,256(sp)
ffffffffc0200a78:	6932                	ld	s2,264(sp)
ffffffffc0200a7a:	10049073          	csrw	sstatus,s1
ffffffffc0200a7e:	14191073          	csrw	sepc,s2
ffffffffc0200a82:	60a2                	ld	ra,8(sp)
ffffffffc0200a84:	61e2                	ld	gp,24(sp)
ffffffffc0200a86:	7202                	ld	tp,32(sp)
ffffffffc0200a88:	72a2                	ld	t0,40(sp)
ffffffffc0200a8a:	7342                	ld	t1,48(sp)
ffffffffc0200a8c:	73e2                	ld	t2,56(sp)
ffffffffc0200a8e:	6406                	ld	s0,64(sp)
ffffffffc0200a90:	64a6                	ld	s1,72(sp)
ffffffffc0200a92:	6546                	ld	a0,80(sp)
ffffffffc0200a94:	65e6                	ld	a1,88(sp)
ffffffffc0200a96:	7606                	ld	a2,96(sp)
ffffffffc0200a98:	76a6                	ld	a3,104(sp)
ffffffffc0200a9a:	7746                	ld	a4,112(sp)
ffffffffc0200a9c:	77e6                	ld	a5,120(sp)
ffffffffc0200a9e:	680a                	ld	a6,128(sp)
ffffffffc0200aa0:	68aa                	ld	a7,136(sp)
ffffffffc0200aa2:	694a                	ld	s2,144(sp)
ffffffffc0200aa4:	69ea                	ld	s3,152(sp)
ffffffffc0200aa6:	7a0a                	ld	s4,160(sp)
ffffffffc0200aa8:	7aaa                	ld	s5,168(sp)
ffffffffc0200aaa:	7b4a                	ld	s6,176(sp)
ffffffffc0200aac:	7bea                	ld	s7,184(sp)
ffffffffc0200aae:	6c0e                	ld	s8,192(sp)
ffffffffc0200ab0:	6cae                	ld	s9,200(sp)
ffffffffc0200ab2:	6d4e                	ld	s10,208(sp)
ffffffffc0200ab4:	6dee                	ld	s11,216(sp)
ffffffffc0200ab6:	7e0e                	ld	t3,224(sp)
ffffffffc0200ab8:	7eae                	ld	t4,232(sp)
ffffffffc0200aba:	7f4e                	ld	t5,240(sp)
ffffffffc0200abc:	7fee                	ld	t6,248(sp)
ffffffffc0200abe:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200ac0:	10200073          	sret
	...

ffffffffc0200ad0 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ad0:	00011797          	auipc	a5,0x11
ffffffffc0200ad4:	9e878793          	addi	a5,a5,-1560 # ffffffffc02114b8 <free_area>
ffffffffc0200ad8:	e79c                	sd	a5,8(a5)
ffffffffc0200ada:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200adc:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ae0:	8082                	ret

ffffffffc0200ae2 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200ae2:	00011517          	auipc	a0,0x11
ffffffffc0200ae6:	9e656503          	lwu	a0,-1562(a0) # ffffffffc02114c8 <free_area+0x10>
ffffffffc0200aea:	8082                	ret

ffffffffc0200aec <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200aec:	715d                	addi	sp,sp,-80
ffffffffc0200aee:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200af0:	00011917          	auipc	s2,0x11
ffffffffc0200af4:	9c890913          	addi	s2,s2,-1592 # ffffffffc02114b8 <free_area>
ffffffffc0200af8:	00893783          	ld	a5,8(s2)
ffffffffc0200afc:	e486                	sd	ra,72(sp)
ffffffffc0200afe:	e0a2                	sd	s0,64(sp)
ffffffffc0200b00:	fc26                	sd	s1,56(sp)
ffffffffc0200b02:	f44e                	sd	s3,40(sp)
ffffffffc0200b04:	f052                	sd	s4,32(sp)
ffffffffc0200b06:	ec56                	sd	s5,24(sp)
ffffffffc0200b08:	e85a                	sd	s6,16(sp)
ffffffffc0200b0a:	e45e                	sd	s7,8(sp)
ffffffffc0200b0c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b0e:	31278f63          	beq	a5,s2,ffffffffc0200e2c <default_check+0x340>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200b12:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200b16:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200b18:	8b05                	andi	a4,a4,1
ffffffffc0200b1a:	30070d63          	beqz	a4,ffffffffc0200e34 <default_check+0x348>
    int count = 0, total = 0;
ffffffffc0200b1e:	4401                	li	s0,0
ffffffffc0200b20:	4481                	li	s1,0
ffffffffc0200b22:	a031                	j	ffffffffc0200b2e <default_check+0x42>
ffffffffc0200b24:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0200b28:	8b09                	andi	a4,a4,2
ffffffffc0200b2a:	30070563          	beqz	a4,ffffffffc0200e34 <default_check+0x348>
        count ++, total += p->property;
ffffffffc0200b2e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200b32:	679c                	ld	a5,8(a5)
ffffffffc0200b34:	2485                	addiw	s1,s1,1
ffffffffc0200b36:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200b38:	ff2796e3          	bne	a5,s2,ffffffffc0200b24 <default_check+0x38>
ffffffffc0200b3c:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200b3e:	3ef000ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0200b42:	75351963          	bne	a0,s3,ffffffffc0201294 <default_check+0x7a8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b46:	4505                	li	a0,1
ffffffffc0200b48:	317000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200b4c:	8a2a                	mv	s4,a0
ffffffffc0200b4e:	48050363          	beqz	a0,ffffffffc0200fd4 <default_check+0x4e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200b52:	4505                	li	a0,1
ffffffffc0200b54:	30b000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200b58:	89aa                	mv	s3,a0
ffffffffc0200b5a:	74050d63          	beqz	a0,ffffffffc02012b4 <default_check+0x7c8>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b5e:	4505                	li	a0,1
ffffffffc0200b60:	2ff000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200b64:	8aaa                	mv	s5,a0
ffffffffc0200b66:	4e050763          	beqz	a0,ffffffffc0201054 <default_check+0x568>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b6a:	2f3a0563          	beq	s4,s3,ffffffffc0200e54 <default_check+0x368>
ffffffffc0200b6e:	2eaa0363          	beq	s4,a0,ffffffffc0200e54 <default_check+0x368>
ffffffffc0200b72:	2ea98163          	beq	s3,a0,ffffffffc0200e54 <default_check+0x368>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b76:	000a2783          	lw	a5,0(s4)
ffffffffc0200b7a:	2e079d63          	bnez	a5,ffffffffc0200e74 <default_check+0x388>
ffffffffc0200b7e:	0009a783          	lw	a5,0(s3)
ffffffffc0200b82:	2e079963          	bnez	a5,ffffffffc0200e74 <default_check+0x388>
ffffffffc0200b86:	411c                	lw	a5,0(a0)
ffffffffc0200b88:	2e079663          	bnez	a5,ffffffffc0200e74 <default_check+0x388>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b8c:	00011797          	auipc	a5,0x11
ffffffffc0200b90:	95c78793          	addi	a5,a5,-1700 # ffffffffc02114e8 <pages>
ffffffffc0200b94:	639c                	ld	a5,0(a5)
ffffffffc0200b96:	00005717          	auipc	a4,0x5
ffffffffc0200b9a:	82a70713          	addi	a4,a4,-2006 # ffffffffc02053c0 <commands+0x858>
ffffffffc0200b9e:	630c                	ld	a1,0(a4)
ffffffffc0200ba0:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ba4:	870d                	srai	a4,a4,0x3
ffffffffc0200ba6:	02b70733          	mul	a4,a4,a1
ffffffffc0200baa:	00006697          	auipc	a3,0x6
ffffffffc0200bae:	e7668693          	addi	a3,a3,-394 # ffffffffc0206a20 <nbase>
ffffffffc0200bb2:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200bb4:	00011697          	auipc	a3,0x11
ffffffffc0200bb8:	8e468693          	addi	a3,a3,-1820 # ffffffffc0211498 <npage>
ffffffffc0200bbc:	6294                	ld	a3,0(a3)
ffffffffc0200bbe:	06b2                	slli	a3,a3,0xc
ffffffffc0200bc0:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bc2:	0732                	slli	a4,a4,0xc
ffffffffc0200bc4:	2cd77863          	bleu	a3,a4,ffffffffc0200e94 <default_check+0x3a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bc8:	40f98733          	sub	a4,s3,a5
ffffffffc0200bcc:	870d                	srai	a4,a4,0x3
ffffffffc0200bce:	02b70733          	mul	a4,a4,a1
ffffffffc0200bd2:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bd4:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200bd6:	4ed77f63          	bleu	a3,a4,ffffffffc02010d4 <default_check+0x5e8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bda:	40f507b3          	sub	a5,a0,a5
ffffffffc0200bde:	878d                	srai	a5,a5,0x3
ffffffffc0200be0:	02b787b3          	mul	a5,a5,a1
ffffffffc0200be4:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200be6:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200be8:	34d7f663          	bleu	a3,a5,ffffffffc0200f34 <default_check+0x448>
    assert(alloc_page() == NULL);
ffffffffc0200bec:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200bee:	00093c03          	ld	s8,0(s2)
ffffffffc0200bf2:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200bf6:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200bfa:	00011797          	auipc	a5,0x11
ffffffffc0200bfe:	8d27b323          	sd	s2,-1850(a5) # ffffffffc02114c0 <free_area+0x8>
ffffffffc0200c02:	00011797          	auipc	a5,0x11
ffffffffc0200c06:	8b27bb23          	sd	s2,-1866(a5) # ffffffffc02114b8 <free_area>
    nr_free = 0;
ffffffffc0200c0a:	00011797          	auipc	a5,0x11
ffffffffc0200c0e:	8a07af23          	sw	zero,-1858(a5) # ffffffffc02114c8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200c12:	24d000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c16:	2e051f63          	bnez	a0,ffffffffc0200f14 <default_check+0x428>
    free_page(p0);
ffffffffc0200c1a:	4585                	li	a1,1
ffffffffc0200c1c:	8552                	mv	a0,s4
ffffffffc0200c1e:	2c9000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p1);
ffffffffc0200c22:	4585                	li	a1,1
ffffffffc0200c24:	854e                	mv	a0,s3
ffffffffc0200c26:	2c1000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p2);
ffffffffc0200c2a:	4585                	li	a1,1
ffffffffc0200c2c:	8556                	mv	a0,s5
ffffffffc0200c2e:	2b9000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert(nr_free == 3);
ffffffffc0200c32:	01092703          	lw	a4,16(s2)
ffffffffc0200c36:	478d                	li	a5,3
ffffffffc0200c38:	2af71e63          	bne	a4,a5,ffffffffc0200ef4 <default_check+0x408>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c3c:	4505                	li	a0,1
ffffffffc0200c3e:	221000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c42:	89aa                	mv	s3,a0
ffffffffc0200c44:	28050863          	beqz	a0,ffffffffc0200ed4 <default_check+0x3e8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c48:	4505                	li	a0,1
ffffffffc0200c4a:	215000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c4e:	8aaa                	mv	s5,a0
ffffffffc0200c50:	3e050263          	beqz	a0,ffffffffc0201034 <default_check+0x548>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c54:	4505                	li	a0,1
ffffffffc0200c56:	209000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c5a:	8a2a                	mv	s4,a0
ffffffffc0200c5c:	3a050c63          	beqz	a0,ffffffffc0201014 <default_check+0x528>
    assert(alloc_page() == NULL);
ffffffffc0200c60:	4505                	li	a0,1
ffffffffc0200c62:	1fd000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c66:	38051763          	bnez	a0,ffffffffc0200ff4 <default_check+0x508>
    free_page(p0);
ffffffffc0200c6a:	4585                	li	a1,1
ffffffffc0200c6c:	854e                	mv	a0,s3
ffffffffc0200c6e:	279000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200c72:	00893783          	ld	a5,8(s2)
ffffffffc0200c76:	23278f63          	beq	a5,s2,ffffffffc0200eb4 <default_check+0x3c8>
    assert((p = alloc_page()) == p0);
ffffffffc0200c7a:	4505                	li	a0,1
ffffffffc0200c7c:	1e3000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c80:	32a99a63          	bne	s3,a0,ffffffffc0200fb4 <default_check+0x4c8>
    assert(alloc_page() == NULL);
ffffffffc0200c84:	4505                	li	a0,1
ffffffffc0200c86:	1d9000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200c8a:	30051563          	bnez	a0,ffffffffc0200f94 <default_check+0x4a8>
    assert(nr_free == 0);
ffffffffc0200c8e:	01092783          	lw	a5,16(s2)
ffffffffc0200c92:	2e079163          	bnez	a5,ffffffffc0200f74 <default_check+0x488>
    free_page(p);
ffffffffc0200c96:	854e                	mv	a0,s3
ffffffffc0200c98:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200c9a:	00011797          	auipc	a5,0x11
ffffffffc0200c9e:	8187bf23          	sd	s8,-2018(a5) # ffffffffc02114b8 <free_area>
ffffffffc0200ca2:	00011797          	auipc	a5,0x11
ffffffffc0200ca6:	8177bf23          	sd	s7,-2018(a5) # ffffffffc02114c0 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200caa:	00011797          	auipc	a5,0x11
ffffffffc0200cae:	8167af23          	sw	s6,-2018(a5) # ffffffffc02114c8 <free_area+0x10>
    free_page(p);
ffffffffc0200cb2:	235000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p1);
ffffffffc0200cb6:	4585                	li	a1,1
ffffffffc0200cb8:	8556                	mv	a0,s5
ffffffffc0200cba:	22d000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p2);
ffffffffc0200cbe:	4585                	li	a1,1
ffffffffc0200cc0:	8552                	mv	a0,s4
ffffffffc0200cc2:	225000ef          	jal	ra,ffffffffc02016e6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200cc6:	4515                	li	a0,5
ffffffffc0200cc8:	197000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200ccc:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200cce:	28050363          	beqz	a0,ffffffffc0200f54 <default_check+0x468>
ffffffffc0200cd2:	651c                	ld	a5,8(a0)
ffffffffc0200cd4:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200cd6:	8b85                	andi	a5,a5,1
ffffffffc0200cd8:	54079e63          	bnez	a5,ffffffffc0201234 <default_check+0x748>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200cdc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200cde:	00093b03          	ld	s6,0(s2)
ffffffffc0200ce2:	00893a83          	ld	s5,8(s2)
ffffffffc0200ce6:	00010797          	auipc	a5,0x10
ffffffffc0200cea:	7d27b923          	sd	s2,2002(a5) # ffffffffc02114b8 <free_area>
ffffffffc0200cee:	00010797          	auipc	a5,0x10
ffffffffc0200cf2:	7d27b923          	sd	s2,2002(a5) # ffffffffc02114c0 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200cf6:	169000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200cfa:	50051d63          	bnez	a0,ffffffffc0201214 <default_check+0x728>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200cfe:	09098a13          	addi	s4,s3,144
ffffffffc0200d02:	8552                	mv	a0,s4
ffffffffc0200d04:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200d06:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc0200d0a:	00010797          	auipc	a5,0x10
ffffffffc0200d0e:	7a07af23          	sw	zero,1982(a5) # ffffffffc02114c8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200d12:	1d5000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200d16:	4511                	li	a0,4
ffffffffc0200d18:	147000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d1c:	4c051c63          	bnez	a0,ffffffffc02011f4 <default_check+0x708>
ffffffffc0200d20:	0989b783          	ld	a5,152(s3)
ffffffffc0200d24:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200d26:	8b85                	andi	a5,a5,1
ffffffffc0200d28:	4a078663          	beqz	a5,ffffffffc02011d4 <default_check+0x6e8>
ffffffffc0200d2c:	0a89a703          	lw	a4,168(s3)
ffffffffc0200d30:	478d                	li	a5,3
ffffffffc0200d32:	4af71163          	bne	a4,a5,ffffffffc02011d4 <default_check+0x6e8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200d36:	450d                	li	a0,3
ffffffffc0200d38:	127000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d3c:	8c2a                	mv	s8,a0
ffffffffc0200d3e:	46050b63          	beqz	a0,ffffffffc02011b4 <default_check+0x6c8>
    assert(alloc_page() == NULL);
ffffffffc0200d42:	4505                	li	a0,1
ffffffffc0200d44:	11b000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d48:	44051663          	bnez	a0,ffffffffc0201194 <default_check+0x6a8>
    assert(p0 + 2 == p1);
ffffffffc0200d4c:	438a1463          	bne	s4,s8,ffffffffc0201174 <default_check+0x688>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200d50:	4585                	li	a1,1
ffffffffc0200d52:	854e                	mv	a0,s3
ffffffffc0200d54:	193000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_pages(p1, 3);
ffffffffc0200d58:	458d                	li	a1,3
ffffffffc0200d5a:	8552                	mv	a0,s4
ffffffffc0200d5c:	18b000ef          	jal	ra,ffffffffc02016e6 <free_pages>
ffffffffc0200d60:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200d64:	04898c13          	addi	s8,s3,72
ffffffffc0200d68:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200d6a:	8b85                	andi	a5,a5,1
ffffffffc0200d6c:	3e078463          	beqz	a5,ffffffffc0201154 <default_check+0x668>
ffffffffc0200d70:	0189a703          	lw	a4,24(s3)
ffffffffc0200d74:	4785                	li	a5,1
ffffffffc0200d76:	3cf71f63          	bne	a4,a5,ffffffffc0201154 <default_check+0x668>
ffffffffc0200d7a:	008a3783          	ld	a5,8(s4)
ffffffffc0200d7e:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200d80:	8b85                	andi	a5,a5,1
ffffffffc0200d82:	3a078963          	beqz	a5,ffffffffc0201134 <default_check+0x648>
ffffffffc0200d86:	018a2703          	lw	a4,24(s4)
ffffffffc0200d8a:	478d                	li	a5,3
ffffffffc0200d8c:	3af71463          	bne	a4,a5,ffffffffc0201134 <default_check+0x648>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200d90:	4505                	li	a0,1
ffffffffc0200d92:	0cd000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200d96:	36a99f63          	bne	s3,a0,ffffffffc0201114 <default_check+0x628>
    free_page(p0);
ffffffffc0200d9a:	4585                	li	a1,1
ffffffffc0200d9c:	14b000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200da0:	4509                	li	a0,2
ffffffffc0200da2:	0bd000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200da6:	34aa1763          	bne	s4,a0,ffffffffc02010f4 <default_check+0x608>

    free_pages(p0, 2);
ffffffffc0200daa:	4589                	li	a1,2
ffffffffc0200dac:	13b000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    free_page(p2);
ffffffffc0200db0:	4585                	li	a1,1
ffffffffc0200db2:	8562                	mv	a0,s8
ffffffffc0200db4:	133000ef          	jal	ra,ffffffffc02016e6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200db8:	4515                	li	a0,5
ffffffffc0200dba:	0a5000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200dbe:	89aa                	mv	s3,a0
ffffffffc0200dc0:	48050a63          	beqz	a0,ffffffffc0201254 <default_check+0x768>
    assert(alloc_page() == NULL);
ffffffffc0200dc4:	4505                	li	a0,1
ffffffffc0200dc6:	099000ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0200dca:	2e051563          	bnez	a0,ffffffffc02010b4 <default_check+0x5c8>

    assert(nr_free == 0);
ffffffffc0200dce:	01092783          	lw	a5,16(s2)
ffffffffc0200dd2:	2c079163          	bnez	a5,ffffffffc0201094 <default_check+0x5a8>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200dd6:	4595                	li	a1,5
ffffffffc0200dd8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200dda:	00010797          	auipc	a5,0x10
ffffffffc0200dde:	6f77a723          	sw	s7,1774(a5) # ffffffffc02114c8 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200de2:	00010797          	auipc	a5,0x10
ffffffffc0200de6:	6d67bb23          	sd	s6,1750(a5) # ffffffffc02114b8 <free_area>
ffffffffc0200dea:	00010797          	auipc	a5,0x10
ffffffffc0200dee:	6d57bb23          	sd	s5,1750(a5) # ffffffffc02114c0 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200df2:	0f5000ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return listelm->next;
ffffffffc0200df6:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200dfa:	01278963          	beq	a5,s2,ffffffffc0200e0c <default_check+0x320>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200dfe:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e02:	679c                	ld	a5,8(a5)
ffffffffc0200e04:	34fd                	addiw	s1,s1,-1
ffffffffc0200e06:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e08:	ff279be3          	bne	a5,s2,ffffffffc0200dfe <default_check+0x312>
    }
    assert(count == 0);
ffffffffc0200e0c:	26049463          	bnez	s1,ffffffffc0201074 <default_check+0x588>
    assert(total == 0);
ffffffffc0200e10:	46041263          	bnez	s0,ffffffffc0201274 <default_check+0x788>
}
ffffffffc0200e14:	60a6                	ld	ra,72(sp)
ffffffffc0200e16:	6406                	ld	s0,64(sp)
ffffffffc0200e18:	74e2                	ld	s1,56(sp)
ffffffffc0200e1a:	7942                	ld	s2,48(sp)
ffffffffc0200e1c:	79a2                	ld	s3,40(sp)
ffffffffc0200e1e:	7a02                	ld	s4,32(sp)
ffffffffc0200e20:	6ae2                	ld	s5,24(sp)
ffffffffc0200e22:	6b42                	ld	s6,16(sp)
ffffffffc0200e24:	6ba2                	ld	s7,8(sp)
ffffffffc0200e26:	6c02                	ld	s8,0(sp)
ffffffffc0200e28:	6161                	addi	sp,sp,80
ffffffffc0200e2a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e2c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200e2e:	4401                	li	s0,0
ffffffffc0200e30:	4481                	li	s1,0
ffffffffc0200e32:	b331                	j	ffffffffc0200b3e <default_check+0x52>
        assert(PageProperty(p));
ffffffffc0200e34:	00004697          	auipc	a3,0x4
ffffffffc0200e38:	59468693          	addi	a3,a3,1428 # ffffffffc02053c8 <commands+0x860>
ffffffffc0200e3c:	00004617          	auipc	a2,0x4
ffffffffc0200e40:	59c60613          	addi	a2,a2,1436 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200e44:	0f000593          	li	a1,240
ffffffffc0200e48:	00004517          	auipc	a0,0x4
ffffffffc0200e4c:	5a850513          	addi	a0,a0,1448 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200e50:	d24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e54:	00004697          	auipc	a3,0x4
ffffffffc0200e58:	63468693          	addi	a3,a3,1588 # ffffffffc0205488 <commands+0x920>
ffffffffc0200e5c:	00004617          	auipc	a2,0x4
ffffffffc0200e60:	57c60613          	addi	a2,a2,1404 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200e64:	0bd00593          	li	a1,189
ffffffffc0200e68:	00004517          	auipc	a0,0x4
ffffffffc0200e6c:	58850513          	addi	a0,a0,1416 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200e70:	d04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e74:	00004697          	auipc	a3,0x4
ffffffffc0200e78:	63c68693          	addi	a3,a3,1596 # ffffffffc02054b0 <commands+0x948>
ffffffffc0200e7c:	00004617          	auipc	a2,0x4
ffffffffc0200e80:	55c60613          	addi	a2,a2,1372 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200e84:	0be00593          	li	a1,190
ffffffffc0200e88:	00004517          	auipc	a0,0x4
ffffffffc0200e8c:	56850513          	addi	a0,a0,1384 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200e90:	ce4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e94:	00004697          	auipc	a3,0x4
ffffffffc0200e98:	65c68693          	addi	a3,a3,1628 # ffffffffc02054f0 <commands+0x988>
ffffffffc0200e9c:	00004617          	auipc	a2,0x4
ffffffffc0200ea0:	53c60613          	addi	a2,a2,1340 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200ea4:	0c000593          	li	a1,192
ffffffffc0200ea8:	00004517          	auipc	a0,0x4
ffffffffc0200eac:	54850513          	addi	a0,a0,1352 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200eb0:	cc4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200eb4:	00004697          	auipc	a3,0x4
ffffffffc0200eb8:	6c468693          	addi	a3,a3,1732 # ffffffffc0205578 <commands+0xa10>
ffffffffc0200ebc:	00004617          	auipc	a2,0x4
ffffffffc0200ec0:	51c60613          	addi	a2,a2,1308 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200ec4:	0d900593          	li	a1,217
ffffffffc0200ec8:	00004517          	auipc	a0,0x4
ffffffffc0200ecc:	52850513          	addi	a0,a0,1320 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200ed0:	ca4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ed4:	00004697          	auipc	a3,0x4
ffffffffc0200ed8:	55468693          	addi	a3,a3,1364 # ffffffffc0205428 <commands+0x8c0>
ffffffffc0200edc:	00004617          	auipc	a2,0x4
ffffffffc0200ee0:	4fc60613          	addi	a2,a2,1276 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200ee4:	0d200593          	li	a1,210
ffffffffc0200ee8:	00004517          	auipc	a0,0x4
ffffffffc0200eec:	50850513          	addi	a0,a0,1288 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200ef0:	c84ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 3);
ffffffffc0200ef4:	00004697          	auipc	a3,0x4
ffffffffc0200ef8:	67468693          	addi	a3,a3,1652 # ffffffffc0205568 <commands+0xa00>
ffffffffc0200efc:	00004617          	auipc	a2,0x4
ffffffffc0200f00:	4dc60613          	addi	a2,a2,1244 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200f04:	0d000593          	li	a1,208
ffffffffc0200f08:	00004517          	auipc	a0,0x4
ffffffffc0200f0c:	4e850513          	addi	a0,a0,1256 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200f10:	c64ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f14:	00004697          	auipc	a3,0x4
ffffffffc0200f18:	63c68693          	addi	a3,a3,1596 # ffffffffc0205550 <commands+0x9e8>
ffffffffc0200f1c:	00004617          	auipc	a2,0x4
ffffffffc0200f20:	4bc60613          	addi	a2,a2,1212 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200f24:	0cb00593          	li	a1,203
ffffffffc0200f28:	00004517          	auipc	a0,0x4
ffffffffc0200f2c:	4c850513          	addi	a0,a0,1224 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200f30:	c44ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f34:	00004697          	auipc	a3,0x4
ffffffffc0200f38:	5fc68693          	addi	a3,a3,1532 # ffffffffc0205530 <commands+0x9c8>
ffffffffc0200f3c:	00004617          	auipc	a2,0x4
ffffffffc0200f40:	49c60613          	addi	a2,a2,1180 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200f44:	0c200593          	li	a1,194
ffffffffc0200f48:	00004517          	auipc	a0,0x4
ffffffffc0200f4c:	4a850513          	addi	a0,a0,1192 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200f50:	c24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 != NULL);
ffffffffc0200f54:	00004697          	auipc	a3,0x4
ffffffffc0200f58:	66c68693          	addi	a3,a3,1644 # ffffffffc02055c0 <commands+0xa58>
ffffffffc0200f5c:	00004617          	auipc	a2,0x4
ffffffffc0200f60:	47c60613          	addi	a2,a2,1148 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200f64:	0f800593          	li	a1,248
ffffffffc0200f68:	00004517          	auipc	a0,0x4
ffffffffc0200f6c:	48850513          	addi	a0,a0,1160 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200f70:	c04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 0);
ffffffffc0200f74:	00004697          	auipc	a3,0x4
ffffffffc0200f78:	63c68693          	addi	a3,a3,1596 # ffffffffc02055b0 <commands+0xa48>
ffffffffc0200f7c:	00004617          	auipc	a2,0x4
ffffffffc0200f80:	45c60613          	addi	a2,a2,1116 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200f84:	0df00593          	li	a1,223
ffffffffc0200f88:	00004517          	auipc	a0,0x4
ffffffffc0200f8c:	46850513          	addi	a0,a0,1128 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200f90:	be4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f94:	00004697          	auipc	a3,0x4
ffffffffc0200f98:	5bc68693          	addi	a3,a3,1468 # ffffffffc0205550 <commands+0x9e8>
ffffffffc0200f9c:	00004617          	auipc	a2,0x4
ffffffffc0200fa0:	43c60613          	addi	a2,a2,1084 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200fa4:	0dd00593          	li	a1,221
ffffffffc0200fa8:	00004517          	auipc	a0,0x4
ffffffffc0200fac:	44850513          	addi	a0,a0,1096 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200fb0:	bc4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200fb4:	00004697          	auipc	a3,0x4
ffffffffc0200fb8:	5dc68693          	addi	a3,a3,1500 # ffffffffc0205590 <commands+0xa28>
ffffffffc0200fbc:	00004617          	auipc	a2,0x4
ffffffffc0200fc0:	41c60613          	addi	a2,a2,1052 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200fc4:	0dc00593          	li	a1,220
ffffffffc0200fc8:	00004517          	auipc	a0,0x4
ffffffffc0200fcc:	42850513          	addi	a0,a0,1064 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200fd0:	ba4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fd4:	00004697          	auipc	a3,0x4
ffffffffc0200fd8:	45468693          	addi	a3,a3,1108 # ffffffffc0205428 <commands+0x8c0>
ffffffffc0200fdc:	00004617          	auipc	a2,0x4
ffffffffc0200fe0:	3fc60613          	addi	a2,a2,1020 # ffffffffc02053d8 <commands+0x870>
ffffffffc0200fe4:	0b900593          	li	a1,185
ffffffffc0200fe8:	00004517          	auipc	a0,0x4
ffffffffc0200fec:	40850513          	addi	a0,a0,1032 # ffffffffc02053f0 <commands+0x888>
ffffffffc0200ff0:	b84ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ff4:	00004697          	auipc	a3,0x4
ffffffffc0200ff8:	55c68693          	addi	a3,a3,1372 # ffffffffc0205550 <commands+0x9e8>
ffffffffc0200ffc:	00004617          	auipc	a2,0x4
ffffffffc0201000:	3dc60613          	addi	a2,a2,988 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201004:	0d600593          	li	a1,214
ffffffffc0201008:	00004517          	auipc	a0,0x4
ffffffffc020100c:	3e850513          	addi	a0,a0,1000 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201010:	b64ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201014:	00004697          	auipc	a3,0x4
ffffffffc0201018:	45468693          	addi	a3,a3,1108 # ffffffffc0205468 <commands+0x900>
ffffffffc020101c:	00004617          	auipc	a2,0x4
ffffffffc0201020:	3bc60613          	addi	a2,a2,956 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201024:	0d400593          	li	a1,212
ffffffffc0201028:	00004517          	auipc	a0,0x4
ffffffffc020102c:	3c850513          	addi	a0,a0,968 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201030:	b44ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201034:	00004697          	auipc	a3,0x4
ffffffffc0201038:	41468693          	addi	a3,a3,1044 # ffffffffc0205448 <commands+0x8e0>
ffffffffc020103c:	00004617          	auipc	a2,0x4
ffffffffc0201040:	39c60613          	addi	a2,a2,924 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201044:	0d300593          	li	a1,211
ffffffffc0201048:	00004517          	auipc	a0,0x4
ffffffffc020104c:	3a850513          	addi	a0,a0,936 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201050:	b24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201054:	00004697          	auipc	a3,0x4
ffffffffc0201058:	41468693          	addi	a3,a3,1044 # ffffffffc0205468 <commands+0x900>
ffffffffc020105c:	00004617          	auipc	a2,0x4
ffffffffc0201060:	37c60613          	addi	a2,a2,892 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201064:	0bb00593          	li	a1,187
ffffffffc0201068:	00004517          	auipc	a0,0x4
ffffffffc020106c:	38850513          	addi	a0,a0,904 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201070:	b04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(count == 0);
ffffffffc0201074:	00004697          	auipc	a3,0x4
ffffffffc0201078:	69c68693          	addi	a3,a3,1692 # ffffffffc0205710 <commands+0xba8>
ffffffffc020107c:	00004617          	auipc	a2,0x4
ffffffffc0201080:	35c60613          	addi	a2,a2,860 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201084:	12500593          	li	a1,293
ffffffffc0201088:	00004517          	auipc	a0,0x4
ffffffffc020108c:	36850513          	addi	a0,a0,872 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201090:	ae4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free == 0);
ffffffffc0201094:	00004697          	auipc	a3,0x4
ffffffffc0201098:	51c68693          	addi	a3,a3,1308 # ffffffffc02055b0 <commands+0xa48>
ffffffffc020109c:	00004617          	auipc	a2,0x4
ffffffffc02010a0:	33c60613          	addi	a2,a2,828 # ffffffffc02053d8 <commands+0x870>
ffffffffc02010a4:	11a00593          	li	a1,282
ffffffffc02010a8:	00004517          	auipc	a0,0x4
ffffffffc02010ac:	34850513          	addi	a0,a0,840 # ffffffffc02053f0 <commands+0x888>
ffffffffc02010b0:	ac4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010b4:	00004697          	auipc	a3,0x4
ffffffffc02010b8:	49c68693          	addi	a3,a3,1180 # ffffffffc0205550 <commands+0x9e8>
ffffffffc02010bc:	00004617          	auipc	a2,0x4
ffffffffc02010c0:	31c60613          	addi	a2,a2,796 # ffffffffc02053d8 <commands+0x870>
ffffffffc02010c4:	11800593          	li	a1,280
ffffffffc02010c8:	00004517          	auipc	a0,0x4
ffffffffc02010cc:	32850513          	addi	a0,a0,808 # ffffffffc02053f0 <commands+0x888>
ffffffffc02010d0:	aa4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010d4:	00004697          	auipc	a3,0x4
ffffffffc02010d8:	43c68693          	addi	a3,a3,1084 # ffffffffc0205510 <commands+0x9a8>
ffffffffc02010dc:	00004617          	auipc	a2,0x4
ffffffffc02010e0:	2fc60613          	addi	a2,a2,764 # ffffffffc02053d8 <commands+0x870>
ffffffffc02010e4:	0c100593          	li	a1,193
ffffffffc02010e8:	00004517          	auipc	a0,0x4
ffffffffc02010ec:	30850513          	addi	a0,a0,776 # ffffffffc02053f0 <commands+0x888>
ffffffffc02010f0:	a84ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02010f4:	00004697          	auipc	a3,0x4
ffffffffc02010f8:	5dc68693          	addi	a3,a3,1500 # ffffffffc02056d0 <commands+0xb68>
ffffffffc02010fc:	00004617          	auipc	a2,0x4
ffffffffc0201100:	2dc60613          	addi	a2,a2,732 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201104:	11200593          	li	a1,274
ffffffffc0201108:	00004517          	auipc	a0,0x4
ffffffffc020110c:	2e850513          	addi	a0,a0,744 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201110:	a64ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201114:	00004697          	auipc	a3,0x4
ffffffffc0201118:	59c68693          	addi	a3,a3,1436 # ffffffffc02056b0 <commands+0xb48>
ffffffffc020111c:	00004617          	auipc	a2,0x4
ffffffffc0201120:	2bc60613          	addi	a2,a2,700 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201124:	11000593          	li	a1,272
ffffffffc0201128:	00004517          	auipc	a0,0x4
ffffffffc020112c:	2c850513          	addi	a0,a0,712 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201130:	a44ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201134:	00004697          	auipc	a3,0x4
ffffffffc0201138:	55468693          	addi	a3,a3,1364 # ffffffffc0205688 <commands+0xb20>
ffffffffc020113c:	00004617          	auipc	a2,0x4
ffffffffc0201140:	29c60613          	addi	a2,a2,668 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201144:	10e00593          	li	a1,270
ffffffffc0201148:	00004517          	auipc	a0,0x4
ffffffffc020114c:	2a850513          	addi	a0,a0,680 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201150:	a24ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201154:	00004697          	auipc	a3,0x4
ffffffffc0201158:	50c68693          	addi	a3,a3,1292 # ffffffffc0205660 <commands+0xaf8>
ffffffffc020115c:	00004617          	auipc	a2,0x4
ffffffffc0201160:	27c60613          	addi	a2,a2,636 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201164:	10d00593          	li	a1,269
ffffffffc0201168:	00004517          	auipc	a0,0x4
ffffffffc020116c:	28850513          	addi	a0,a0,648 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201170:	a04ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201174:	00004697          	auipc	a3,0x4
ffffffffc0201178:	4dc68693          	addi	a3,a3,1244 # ffffffffc0205650 <commands+0xae8>
ffffffffc020117c:	00004617          	auipc	a2,0x4
ffffffffc0201180:	25c60613          	addi	a2,a2,604 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201184:	10800593          	li	a1,264
ffffffffc0201188:	00004517          	auipc	a0,0x4
ffffffffc020118c:	26850513          	addi	a0,a0,616 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201190:	9e4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201194:	00004697          	auipc	a3,0x4
ffffffffc0201198:	3bc68693          	addi	a3,a3,956 # ffffffffc0205550 <commands+0x9e8>
ffffffffc020119c:	00004617          	auipc	a2,0x4
ffffffffc02011a0:	23c60613          	addi	a2,a2,572 # ffffffffc02053d8 <commands+0x870>
ffffffffc02011a4:	10700593          	li	a1,263
ffffffffc02011a8:	00004517          	auipc	a0,0x4
ffffffffc02011ac:	24850513          	addi	a0,a0,584 # ffffffffc02053f0 <commands+0x888>
ffffffffc02011b0:	9c4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011b4:	00004697          	auipc	a3,0x4
ffffffffc02011b8:	47c68693          	addi	a3,a3,1148 # ffffffffc0205630 <commands+0xac8>
ffffffffc02011bc:	00004617          	auipc	a2,0x4
ffffffffc02011c0:	21c60613          	addi	a2,a2,540 # ffffffffc02053d8 <commands+0x870>
ffffffffc02011c4:	10600593          	li	a1,262
ffffffffc02011c8:	00004517          	auipc	a0,0x4
ffffffffc02011cc:	22850513          	addi	a0,a0,552 # ffffffffc02053f0 <commands+0x888>
ffffffffc02011d0:	9a4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011d4:	00004697          	auipc	a3,0x4
ffffffffc02011d8:	42c68693          	addi	a3,a3,1068 # ffffffffc0205600 <commands+0xa98>
ffffffffc02011dc:	00004617          	auipc	a2,0x4
ffffffffc02011e0:	1fc60613          	addi	a2,a2,508 # ffffffffc02053d8 <commands+0x870>
ffffffffc02011e4:	10500593          	li	a1,261
ffffffffc02011e8:	00004517          	auipc	a0,0x4
ffffffffc02011ec:	20850513          	addi	a0,a0,520 # ffffffffc02053f0 <commands+0x888>
ffffffffc02011f0:	984ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02011f4:	00004697          	auipc	a3,0x4
ffffffffc02011f8:	3f468693          	addi	a3,a3,1012 # ffffffffc02055e8 <commands+0xa80>
ffffffffc02011fc:	00004617          	auipc	a2,0x4
ffffffffc0201200:	1dc60613          	addi	a2,a2,476 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201204:	10400593          	li	a1,260
ffffffffc0201208:	00004517          	auipc	a0,0x4
ffffffffc020120c:	1e850513          	addi	a0,a0,488 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201210:	964ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201214:	00004697          	auipc	a3,0x4
ffffffffc0201218:	33c68693          	addi	a3,a3,828 # ffffffffc0205550 <commands+0x9e8>
ffffffffc020121c:	00004617          	auipc	a2,0x4
ffffffffc0201220:	1bc60613          	addi	a2,a2,444 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201224:	0fe00593          	li	a1,254
ffffffffc0201228:	00004517          	auipc	a0,0x4
ffffffffc020122c:	1c850513          	addi	a0,a0,456 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201230:	944ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201234:	00004697          	auipc	a3,0x4
ffffffffc0201238:	39c68693          	addi	a3,a3,924 # ffffffffc02055d0 <commands+0xa68>
ffffffffc020123c:	00004617          	auipc	a2,0x4
ffffffffc0201240:	19c60613          	addi	a2,a2,412 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201244:	0f900593          	li	a1,249
ffffffffc0201248:	00004517          	auipc	a0,0x4
ffffffffc020124c:	1a850513          	addi	a0,a0,424 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201250:	924ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201254:	00004697          	auipc	a3,0x4
ffffffffc0201258:	49c68693          	addi	a3,a3,1180 # ffffffffc02056f0 <commands+0xb88>
ffffffffc020125c:	00004617          	auipc	a2,0x4
ffffffffc0201260:	17c60613          	addi	a2,a2,380 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201264:	11700593          	li	a1,279
ffffffffc0201268:	00004517          	auipc	a0,0x4
ffffffffc020126c:	18850513          	addi	a0,a0,392 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201270:	904ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(total == 0);
ffffffffc0201274:	00004697          	auipc	a3,0x4
ffffffffc0201278:	4ac68693          	addi	a3,a3,1196 # ffffffffc0205720 <commands+0xbb8>
ffffffffc020127c:	00004617          	auipc	a2,0x4
ffffffffc0201280:	15c60613          	addi	a2,a2,348 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201284:	12600593          	li	a1,294
ffffffffc0201288:	00004517          	auipc	a0,0x4
ffffffffc020128c:	16850513          	addi	a0,a0,360 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201290:	8e4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201294:	00004697          	auipc	a3,0x4
ffffffffc0201298:	17468693          	addi	a3,a3,372 # ffffffffc0205408 <commands+0x8a0>
ffffffffc020129c:	00004617          	auipc	a2,0x4
ffffffffc02012a0:	13c60613          	addi	a2,a2,316 # ffffffffc02053d8 <commands+0x870>
ffffffffc02012a4:	0f300593          	li	a1,243
ffffffffc02012a8:	00004517          	auipc	a0,0x4
ffffffffc02012ac:	14850513          	addi	a0,a0,328 # ffffffffc02053f0 <commands+0x888>
ffffffffc02012b0:	8c4ff0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02012b4:	00004697          	auipc	a3,0x4
ffffffffc02012b8:	19468693          	addi	a3,a3,404 # ffffffffc0205448 <commands+0x8e0>
ffffffffc02012bc:	00004617          	auipc	a2,0x4
ffffffffc02012c0:	11c60613          	addi	a2,a2,284 # ffffffffc02053d8 <commands+0x870>
ffffffffc02012c4:	0ba00593          	li	a1,186
ffffffffc02012c8:	00004517          	auipc	a0,0x4
ffffffffc02012cc:	12850513          	addi	a0,a0,296 # ffffffffc02053f0 <commands+0x888>
ffffffffc02012d0:	8a4ff0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02012d4 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02012d4:	1141                	addi	sp,sp,-16
ffffffffc02012d6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02012d8:	18058063          	beqz	a1,ffffffffc0201458 <default_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc02012dc:	00359693          	slli	a3,a1,0x3
ffffffffc02012e0:	96ae                	add	a3,a3,a1
ffffffffc02012e2:	068e                	slli	a3,a3,0x3
ffffffffc02012e4:	96aa                	add	a3,a3,a0
ffffffffc02012e6:	02d50d63          	beq	a0,a3,ffffffffc0201320 <default_free_pages+0x4c>
ffffffffc02012ea:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02012ec:	8b85                	andi	a5,a5,1
ffffffffc02012ee:	14079563          	bnez	a5,ffffffffc0201438 <default_free_pages+0x164>
ffffffffc02012f2:	651c                	ld	a5,8(a0)
ffffffffc02012f4:	8385                	srli	a5,a5,0x1
ffffffffc02012f6:	8b85                	andi	a5,a5,1
ffffffffc02012f8:	14079063          	bnez	a5,ffffffffc0201438 <default_free_pages+0x164>
ffffffffc02012fc:	87aa                	mv	a5,a0
ffffffffc02012fe:	a809                	j	ffffffffc0201310 <default_free_pages+0x3c>
ffffffffc0201300:	6798                	ld	a4,8(a5)
ffffffffc0201302:	8b05                	andi	a4,a4,1
ffffffffc0201304:	12071a63          	bnez	a4,ffffffffc0201438 <default_free_pages+0x164>
ffffffffc0201308:	6798                	ld	a4,8(a5)
ffffffffc020130a:	8b09                	andi	a4,a4,2
ffffffffc020130c:	12071663          	bnez	a4,ffffffffc0201438 <default_free_pages+0x164>
        p->flags = 0;
ffffffffc0201310:	0007b423          	sd	zero,8(a5)
    return pa2page(PDE_ADDR(pde));
}

static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201314:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201318:	04878793          	addi	a5,a5,72
ffffffffc020131c:	fed792e3          	bne	a5,a3,ffffffffc0201300 <default_free_pages+0x2c>
    base->property = n;
ffffffffc0201320:	2581                	sext.w	a1,a1
ffffffffc0201322:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0201324:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201328:	4789                	li	a5,2
ffffffffc020132a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020132e:	00010697          	auipc	a3,0x10
ffffffffc0201332:	18a68693          	addi	a3,a3,394 # ffffffffc02114b8 <free_area>
ffffffffc0201336:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201338:	669c                	ld	a5,8(a3)
ffffffffc020133a:	9db9                	addw	a1,a1,a4
ffffffffc020133c:	00010717          	auipc	a4,0x10
ffffffffc0201340:	18b72623          	sw	a1,396(a4) # ffffffffc02114c8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201344:	08d78f63          	beq	a5,a3,ffffffffc02013e2 <default_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc0201348:	fe078713          	addi	a4,a5,-32
ffffffffc020134c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020134e:	4801                	li	a6,0
ffffffffc0201350:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc0201354:	00e56a63          	bltu	a0,a4,ffffffffc0201368 <default_free_pages+0x94>
    return listelm->next;
ffffffffc0201358:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020135a:	02d70563          	beq	a4,a3,ffffffffc0201384 <default_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020135e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201360:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0201364:	fee57ae3          	bleu	a4,a0,ffffffffc0201358 <default_free_pages+0x84>
ffffffffc0201368:	00080663          	beqz	a6,ffffffffc0201374 <default_free_pages+0xa0>
ffffffffc020136c:	00010817          	auipc	a6,0x10
ffffffffc0201370:	14b83623          	sd	a1,332(a6) # ffffffffc02114b8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201374:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201376:	e390                	sd	a2,0(a5)
ffffffffc0201378:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020137a:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020137c:	f10c                	sd	a1,32(a0)
    if (le != &free_list) {
ffffffffc020137e:	02d59163          	bne	a1,a3,ffffffffc02013a0 <default_free_pages+0xcc>
ffffffffc0201382:	a091                	j	ffffffffc02013c6 <default_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0201384:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201386:	f514                	sd	a3,40(a0)
ffffffffc0201388:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020138a:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc020138c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020138e:	00d70563          	beq	a4,a3,ffffffffc0201398 <default_free_pages+0xc4>
ffffffffc0201392:	4805                	li	a6,1
ffffffffc0201394:	87ba                	mv	a5,a4
ffffffffc0201396:	b7e9                	j	ffffffffc0201360 <default_free_pages+0x8c>
ffffffffc0201398:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020139a:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020139c:	02d78163          	beq	a5,a3,ffffffffc02013be <default_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc02013a0:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc02013a4:	fe058613          	addi	a2,a1,-32
        if (p + p->property == base) {
ffffffffc02013a8:	02081713          	slli	a4,a6,0x20
ffffffffc02013ac:	9301                	srli	a4,a4,0x20
ffffffffc02013ae:	00371793          	slli	a5,a4,0x3
ffffffffc02013b2:	97ba                	add	a5,a5,a4
ffffffffc02013b4:	078e                	slli	a5,a5,0x3
ffffffffc02013b6:	97b2                	add	a5,a5,a2
ffffffffc02013b8:	02f50e63          	beq	a0,a5,ffffffffc02013f4 <default_free_pages+0x120>
ffffffffc02013bc:	751c                	ld	a5,40(a0)
    if (le != &free_list) {
ffffffffc02013be:	fe078713          	addi	a4,a5,-32
ffffffffc02013c2:	00d78d63          	beq	a5,a3,ffffffffc02013dc <default_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc02013c6:	4d0c                	lw	a1,24(a0)
ffffffffc02013c8:	02059613          	slli	a2,a1,0x20
ffffffffc02013cc:	9201                	srli	a2,a2,0x20
ffffffffc02013ce:	00361693          	slli	a3,a2,0x3
ffffffffc02013d2:	96b2                	add	a3,a3,a2
ffffffffc02013d4:	068e                	slli	a3,a3,0x3
ffffffffc02013d6:	96aa                	add	a3,a3,a0
ffffffffc02013d8:	04d70063          	beq	a4,a3,ffffffffc0201418 <default_free_pages+0x144>
}
ffffffffc02013dc:	60a2                	ld	ra,8(sp)
ffffffffc02013de:	0141                	addi	sp,sp,16
ffffffffc02013e0:	8082                	ret
ffffffffc02013e2:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02013e4:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02013e8:	e398                	sd	a4,0(a5)
ffffffffc02013ea:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02013ec:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02013ee:	f11c                	sd	a5,32(a0)
}
ffffffffc02013f0:	0141                	addi	sp,sp,16
ffffffffc02013f2:	8082                	ret
            p->property += base->property;
ffffffffc02013f4:	4d1c                	lw	a5,24(a0)
ffffffffc02013f6:	0107883b          	addw	a6,a5,a6
ffffffffc02013fa:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02013fe:	57f5                	li	a5,-3
ffffffffc0201400:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201404:	02053803          	ld	a6,32(a0)
ffffffffc0201408:	7518                	ld	a4,40(a0)
            base = p;
ffffffffc020140a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020140c:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201410:	659c                	ld	a5,8(a1)
ffffffffc0201412:	01073023          	sd	a6,0(a4)
ffffffffc0201416:	b765                	j	ffffffffc02013be <default_free_pages+0xea>
            base->property += p->property;
ffffffffc0201418:	ff87a703          	lw	a4,-8(a5)
ffffffffc020141c:	fe878693          	addi	a3,a5,-24
ffffffffc0201420:	9db9                	addw	a1,a1,a4
ffffffffc0201422:	cd0c                	sw	a1,24(a0)
ffffffffc0201424:	5775                	li	a4,-3
ffffffffc0201426:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020142a:	6398                	ld	a4,0(a5)
ffffffffc020142c:	679c                	ld	a5,8(a5)
}
ffffffffc020142e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201430:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201432:	e398                	sd	a4,0(a5)
ffffffffc0201434:	0141                	addi	sp,sp,16
ffffffffc0201436:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201438:	00004697          	auipc	a3,0x4
ffffffffc020143c:	2f868693          	addi	a3,a3,760 # ffffffffc0205730 <commands+0xbc8>
ffffffffc0201440:	00004617          	auipc	a2,0x4
ffffffffc0201444:	f9860613          	addi	a2,a2,-104 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201448:	08300593          	li	a1,131
ffffffffc020144c:	00004517          	auipc	a0,0x4
ffffffffc0201450:	fa450513          	addi	a0,a0,-92 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201454:	f21fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(n > 0);
ffffffffc0201458:	00004697          	auipc	a3,0x4
ffffffffc020145c:	30068693          	addi	a3,a3,768 # ffffffffc0205758 <commands+0xbf0>
ffffffffc0201460:	00004617          	auipc	a2,0x4
ffffffffc0201464:	f7860613          	addi	a2,a2,-136 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201468:	08000593          	li	a1,128
ffffffffc020146c:	00004517          	auipc	a0,0x4
ffffffffc0201470:	f8450513          	addi	a0,a0,-124 # ffffffffc02053f0 <commands+0x888>
ffffffffc0201474:	f01fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201478 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201478:	cd51                	beqz	a0,ffffffffc0201514 <default_alloc_pages+0x9c>
    if (n > nr_free) {
ffffffffc020147a:	00010597          	auipc	a1,0x10
ffffffffc020147e:	03e58593          	addi	a1,a1,62 # ffffffffc02114b8 <free_area>
ffffffffc0201482:	0105a803          	lw	a6,16(a1)
ffffffffc0201486:	862a                	mv	a2,a0
ffffffffc0201488:	02081793          	slli	a5,a6,0x20
ffffffffc020148c:	9381                	srli	a5,a5,0x20
ffffffffc020148e:	00a7ee63          	bltu	a5,a0,ffffffffc02014aa <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201492:	87ae                	mv	a5,a1
ffffffffc0201494:	a801                	j	ffffffffc02014a4 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201496:	ff87a703          	lw	a4,-8(a5)
ffffffffc020149a:	02071693          	slli	a3,a4,0x20
ffffffffc020149e:	9281                	srli	a3,a3,0x20
ffffffffc02014a0:	00c6f763          	bleu	a2,a3,ffffffffc02014ae <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02014a4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02014a6:	feb798e3          	bne	a5,a1,ffffffffc0201496 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02014aa:	4501                	li	a0,0
}
ffffffffc02014ac:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc02014ae:	fe078513          	addi	a0,a5,-32
    if (page != NULL) {
ffffffffc02014b2:	dd6d                	beqz	a0,ffffffffc02014ac <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc02014b4:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014b8:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc02014bc:	00060e1b          	sext.w	t3,a2
ffffffffc02014c0:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02014c4:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02014c8:	02d67b63          	bleu	a3,a2,ffffffffc02014fe <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02014cc:	00361693          	slli	a3,a2,0x3
ffffffffc02014d0:	96b2                	add	a3,a3,a2
ffffffffc02014d2:	068e                	slli	a3,a3,0x3
ffffffffc02014d4:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02014d6:	41c7073b          	subw	a4,a4,t3
ffffffffc02014da:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014dc:	00868613          	addi	a2,a3,8
ffffffffc02014e0:	4709                	li	a4,2
ffffffffc02014e2:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02014e6:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02014ea:	02068613          	addi	a2,a3,32
    prev->next = next->prev = elm;
ffffffffc02014ee:	0105a803          	lw	a6,16(a1)
ffffffffc02014f2:	e310                	sd	a2,0(a4)
ffffffffc02014f4:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02014f8:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc02014fa:	0316b023          	sd	a7,32(a3)
        nr_free -= n;
ffffffffc02014fe:	41c8083b          	subw	a6,a6,t3
ffffffffc0201502:	00010717          	auipc	a4,0x10
ffffffffc0201506:	fd072323          	sw	a6,-58(a4) # ffffffffc02114c8 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020150a:	5775                	li	a4,-3
ffffffffc020150c:	17a1                	addi	a5,a5,-24
ffffffffc020150e:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201512:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201514:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201516:	00004697          	auipc	a3,0x4
ffffffffc020151a:	24268693          	addi	a3,a3,578 # ffffffffc0205758 <commands+0xbf0>
ffffffffc020151e:	00004617          	auipc	a2,0x4
ffffffffc0201522:	eba60613          	addi	a2,a2,-326 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201526:	06200593          	li	a1,98
ffffffffc020152a:	00004517          	auipc	a0,0x4
ffffffffc020152e:	ec650513          	addi	a0,a0,-314 # ffffffffc02053f0 <commands+0x888>
default_alloc_pages(size_t n) {
ffffffffc0201532:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201534:	e41fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201538 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201538:	1141                	addi	sp,sp,-16
ffffffffc020153a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020153c:	c1fd                	beqz	a1,ffffffffc0201622 <default_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc020153e:	00359693          	slli	a3,a1,0x3
ffffffffc0201542:	96ae                	add	a3,a3,a1
ffffffffc0201544:	068e                	slli	a3,a3,0x3
ffffffffc0201546:	96aa                	add	a3,a3,a0
ffffffffc0201548:	02d50463          	beq	a0,a3,ffffffffc0201570 <default_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020154c:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc020154e:	87aa                	mv	a5,a0
ffffffffc0201550:	8b05                	andi	a4,a4,1
ffffffffc0201552:	e709                	bnez	a4,ffffffffc020155c <default_init_memmap+0x24>
ffffffffc0201554:	a07d                	j	ffffffffc0201602 <default_init_memmap+0xca>
ffffffffc0201556:	6798                	ld	a4,8(a5)
ffffffffc0201558:	8b05                	andi	a4,a4,1
ffffffffc020155a:	c745                	beqz	a4,ffffffffc0201602 <default_init_memmap+0xca>
        p->flags = p->property = 0;
ffffffffc020155c:	0007ac23          	sw	zero,24(a5)
ffffffffc0201560:	0007b423          	sd	zero,8(a5)
ffffffffc0201564:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201568:	04878793          	addi	a5,a5,72
ffffffffc020156c:	fed795e3          	bne	a5,a3,ffffffffc0201556 <default_init_memmap+0x1e>
    base->property = n;
ffffffffc0201570:	2581                	sext.w	a1,a1
ffffffffc0201572:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201574:	4789                	li	a5,2
ffffffffc0201576:	00850713          	addi	a4,a0,8
ffffffffc020157a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020157e:	00010697          	auipc	a3,0x10
ffffffffc0201582:	f3a68693          	addi	a3,a3,-198 # ffffffffc02114b8 <free_area>
ffffffffc0201586:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201588:	669c                	ld	a5,8(a3)
ffffffffc020158a:	9db9                	addw	a1,a1,a4
ffffffffc020158c:	00010717          	auipc	a4,0x10
ffffffffc0201590:	f2b72e23          	sw	a1,-196(a4) # ffffffffc02114c8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201594:	04d78a63          	beq	a5,a3,ffffffffc02015e8 <default_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0201598:	fe078713          	addi	a4,a5,-32
ffffffffc020159c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020159e:	4801                	li	a6,0
ffffffffc02015a0:	02050613          	addi	a2,a0,32
            if (base < page) {
ffffffffc02015a4:	00e56a63          	bltu	a0,a4,ffffffffc02015b8 <default_init_memmap+0x80>
    return listelm->next;
ffffffffc02015a8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02015aa:	02d70563          	beq	a4,a3,ffffffffc02015d4 <default_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015ae:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02015b0:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc02015b4:	fee57ae3          	bleu	a4,a0,ffffffffc02015a8 <default_init_memmap+0x70>
ffffffffc02015b8:	00080663          	beqz	a6,ffffffffc02015c4 <default_init_memmap+0x8c>
ffffffffc02015bc:	00010717          	auipc	a4,0x10
ffffffffc02015c0:	eeb73e23          	sd	a1,-260(a4) # ffffffffc02114b8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015c4:	6398                	ld	a4,0(a5)
}
ffffffffc02015c6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02015c8:	e390                	sd	a2,0(a5)
ffffffffc02015ca:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015cc:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02015ce:	f118                	sd	a4,32(a0)
ffffffffc02015d0:	0141                	addi	sp,sp,16
ffffffffc02015d2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015d4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015d6:	f514                	sd	a3,40(a0)
ffffffffc02015d8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015da:	f11c                	sd	a5,32(a0)
                list_add(le, &(base->page_link));
ffffffffc02015dc:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02015de:	00d70e63          	beq	a4,a3,ffffffffc02015fa <default_init_memmap+0xc2>
ffffffffc02015e2:	4805                	li	a6,1
ffffffffc02015e4:	87ba                	mv	a5,a4
ffffffffc02015e6:	b7e9                	j	ffffffffc02015b0 <default_init_memmap+0x78>
}
ffffffffc02015e8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02015ea:	02050713          	addi	a4,a0,32
    prev->next = next->prev = elm;
ffffffffc02015ee:	e398                	sd	a4,0(a5)
ffffffffc02015f0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02015f2:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02015f4:	f11c                	sd	a5,32(a0)
}
ffffffffc02015f6:	0141                	addi	sp,sp,16
ffffffffc02015f8:	8082                	ret
ffffffffc02015fa:	60a2                	ld	ra,8(sp)
ffffffffc02015fc:	e290                	sd	a2,0(a3)
ffffffffc02015fe:	0141                	addi	sp,sp,16
ffffffffc0201600:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201602:	00004697          	auipc	a3,0x4
ffffffffc0201606:	15e68693          	addi	a3,a3,350 # ffffffffc0205760 <commands+0xbf8>
ffffffffc020160a:	00004617          	auipc	a2,0x4
ffffffffc020160e:	dce60613          	addi	a2,a2,-562 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201612:	04900593          	li	a1,73
ffffffffc0201616:	00004517          	auipc	a0,0x4
ffffffffc020161a:	dda50513          	addi	a0,a0,-550 # ffffffffc02053f0 <commands+0x888>
ffffffffc020161e:	d57fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(n > 0);
ffffffffc0201622:	00004697          	auipc	a3,0x4
ffffffffc0201626:	13668693          	addi	a3,a3,310 # ffffffffc0205758 <commands+0xbf0>
ffffffffc020162a:	00004617          	auipc	a2,0x4
ffffffffc020162e:	dae60613          	addi	a2,a2,-594 # ffffffffc02053d8 <commands+0x870>
ffffffffc0201632:	04600593          	li	a1,70
ffffffffc0201636:	00004517          	auipc	a0,0x4
ffffffffc020163a:	dba50513          	addi	a0,a0,-582 # ffffffffc02053f0 <commands+0x888>
ffffffffc020163e:	d37fe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0201642 <pa2page.part.4>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201642:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201644:	00004617          	auipc	a2,0x4
ffffffffc0201648:	1f460613          	addi	a2,a2,500 # ffffffffc0205838 <default_pmm_manager+0xc8>
ffffffffc020164c:	06500593          	li	a1,101
ffffffffc0201650:	00004517          	auipc	a0,0x4
ffffffffc0201654:	20850513          	addi	a0,a0,520 # ffffffffc0205858 <default_pmm_manager+0xe8>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0201658:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020165a:	d1bfe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020165e <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc020165e:	715d                	addi	sp,sp,-80
ffffffffc0201660:	e0a2                	sd	s0,64(sp)
ffffffffc0201662:	fc26                	sd	s1,56(sp)
ffffffffc0201664:	f84a                	sd	s2,48(sp)
ffffffffc0201666:	f44e                	sd	s3,40(sp)
ffffffffc0201668:	f052                	sd	s4,32(sp)
ffffffffc020166a:	ec56                	sd	s5,24(sp)
ffffffffc020166c:	e486                	sd	ra,72(sp)
ffffffffc020166e:	842a                	mv	s0,a0
ffffffffc0201670:	00010497          	auipc	s1,0x10
ffffffffc0201674:	e6048493          	addi	s1,s1,-416 # ffffffffc02114d0 <pmm_manager>
    while (1) {
        local_intr_save(intr_flag);
        { page = pmm_manager->alloc_pages(n); }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201678:	4985                	li	s3,1
ffffffffc020167a:	00010a17          	auipc	s4,0x10
ffffffffc020167e:	e2ea0a13          	addi	s4,s4,-466 # ffffffffc02114a8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201682:	0005091b          	sext.w	s2,a0
ffffffffc0201686:	00010a97          	auipc	s5,0x10
ffffffffc020168a:	f4aa8a93          	addi	s5,s5,-182 # ffffffffc02115d0 <check_mm_struct>
ffffffffc020168e:	a00d                	j	ffffffffc02016b0 <alloc_pages+0x52>
        { page = pmm_manager->alloc_pages(n); }
ffffffffc0201690:	609c                	ld	a5,0(s1)
ffffffffc0201692:	6f9c                	ld	a5,24(a5)
ffffffffc0201694:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0201696:	4601                	li	a2,0
ffffffffc0201698:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020169a:	ed0d                	bnez	a0,ffffffffc02016d4 <alloc_pages+0x76>
ffffffffc020169c:	0289ec63          	bltu	s3,s0,ffffffffc02016d4 <alloc_pages+0x76>
ffffffffc02016a0:	000a2783          	lw	a5,0(s4)
ffffffffc02016a4:	2781                	sext.w	a5,a5
ffffffffc02016a6:	c79d                	beqz	a5,ffffffffc02016d4 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc02016a8:	000ab503          	ld	a0,0(s5)
ffffffffc02016ac:	180010ef          	jal	ra,ffffffffc020282c <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016b0:	100027f3          	csrr	a5,sstatus
ffffffffc02016b4:	8b89                	andi	a5,a5,2
        { page = pmm_manager->alloc_pages(n); }
ffffffffc02016b6:	8522                	mv	a0,s0
ffffffffc02016b8:	dfe1                	beqz	a5,ffffffffc0201690 <alloc_pages+0x32>
        intr_disable();
ffffffffc02016ba:	e41fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
ffffffffc02016be:	609c                	ld	a5,0(s1)
ffffffffc02016c0:	8522                	mv	a0,s0
ffffffffc02016c2:	6f9c                	ld	a5,24(a5)
ffffffffc02016c4:	9782                	jalr	a5
ffffffffc02016c6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02016c8:	e2dfe0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
ffffffffc02016cc:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc02016ce:	4601                	li	a2,0
ffffffffc02016d0:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc02016d2:	d569                	beqz	a0,ffffffffc020169c <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc02016d4:	60a6                	ld	ra,72(sp)
ffffffffc02016d6:	6406                	ld	s0,64(sp)
ffffffffc02016d8:	74e2                	ld	s1,56(sp)
ffffffffc02016da:	7942                	ld	s2,48(sp)
ffffffffc02016dc:	79a2                	ld	s3,40(sp)
ffffffffc02016de:	7a02                	ld	s4,32(sp)
ffffffffc02016e0:	6ae2                	ld	s5,24(sp)
ffffffffc02016e2:	6161                	addi	sp,sp,80
ffffffffc02016e4:	8082                	ret

ffffffffc02016e6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016e6:	100027f3          	csrr	a5,sstatus
ffffffffc02016ea:	8b89                	andi	a5,a5,2
ffffffffc02016ec:	eb89                	bnez	a5,ffffffffc02016fe <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;

    local_intr_save(intr_flag);
    { pmm_manager->free_pages(base, n); }
ffffffffc02016ee:	00010797          	auipc	a5,0x10
ffffffffc02016f2:	de278793          	addi	a5,a5,-542 # ffffffffc02114d0 <pmm_manager>
ffffffffc02016f6:	639c                	ld	a5,0(a5)
ffffffffc02016f8:	0207b303          	ld	t1,32(a5)
ffffffffc02016fc:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc02016fe:	1101                	addi	sp,sp,-32
ffffffffc0201700:	ec06                	sd	ra,24(sp)
ffffffffc0201702:	e822                	sd	s0,16(sp)
ffffffffc0201704:	e426                	sd	s1,8(sp)
ffffffffc0201706:	842a                	mv	s0,a0
ffffffffc0201708:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020170a:	df1fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
    { pmm_manager->free_pages(base, n); }
ffffffffc020170e:	00010797          	auipc	a5,0x10
ffffffffc0201712:	dc278793          	addi	a5,a5,-574 # ffffffffc02114d0 <pmm_manager>
ffffffffc0201716:	639c                	ld	a5,0(a5)
ffffffffc0201718:	85a6                	mv	a1,s1
ffffffffc020171a:	8522                	mv	a0,s0
ffffffffc020171c:	739c                	ld	a5,32(a5)
ffffffffc020171e:	9782                	jalr	a5
    local_intr_restore(intr_flag);
}
ffffffffc0201720:	6442                	ld	s0,16(sp)
ffffffffc0201722:	60e2                	ld	ra,24(sp)
ffffffffc0201724:	64a2                	ld	s1,8(sp)
ffffffffc0201726:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201728:	dcdfe06f          	j	ffffffffc02004f4 <intr_enable>

ffffffffc020172c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020172c:	100027f3          	csrr	a5,sstatus
ffffffffc0201730:	8b89                	andi	a5,a5,2
ffffffffc0201732:	eb89                	bnez	a5,ffffffffc0201744 <nr_free_pages+0x18>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0201734:	00010797          	auipc	a5,0x10
ffffffffc0201738:	d9c78793          	addi	a5,a5,-612 # ffffffffc02114d0 <pmm_manager>
ffffffffc020173c:	639c                	ld	a5,0(a5)
ffffffffc020173e:	0287b303          	ld	t1,40(a5)
ffffffffc0201742:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0201744:	1141                	addi	sp,sp,-16
ffffffffc0201746:	e406                	sd	ra,8(sp)
ffffffffc0201748:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020174a:	db1fe0ef          	jal	ra,ffffffffc02004fa <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020174e:	00010797          	auipc	a5,0x10
ffffffffc0201752:	d8278793          	addi	a5,a5,-638 # ffffffffc02114d0 <pmm_manager>
ffffffffc0201756:	639c                	ld	a5,0(a5)
ffffffffc0201758:	779c                	ld	a5,40(a5)
ffffffffc020175a:	9782                	jalr	a5
ffffffffc020175c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020175e:	d97fe0ef          	jal	ra,ffffffffc02004f4 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201762:	8522                	mv	a0,s0
ffffffffc0201764:	60a2                	ld	ra,8(sp)
ffffffffc0201766:	6402                	ld	s0,0(sp)
ffffffffc0201768:	0141                	addi	sp,sp,16
ffffffffc020176a:	8082                	ret

ffffffffc020176c <get_pte>:
// parameter:
//  pgdir:  PDT的内核虚拟基地址
//  la:     需要映射的线性地址
//  create: 决定是否为 PT 分配页面的逻辑值
// return vaule: 该 pte 的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc020176c:	715d                	addi	sp,sp,-80
ffffffffc020176e:	fc26                	sd	s1,56(sp)
     *   PTE_W           0x002                   // 页表/目录项
     * flags bit : Writeable
     *   PTE_U           0x004                   // 页表/目录项
     * flags bit : User can access
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201770:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201774:	1ff4f493          	andi	s1,s1,511
ffffffffc0201778:	048e                	slli	s1,s1,0x3
ffffffffc020177a:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc020177c:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc020177e:	f84a                	sd	s2,48(sp)
ffffffffc0201780:	f44e                	sd	s3,40(sp)
ffffffffc0201782:	f052                	sd	s4,32(sp)
ffffffffc0201784:	e486                	sd	ra,72(sp)
ffffffffc0201786:	e0a2                	sd	s0,64(sp)
ffffffffc0201788:	ec56                	sd	s5,24(sp)
ffffffffc020178a:	e85a                	sd	s6,16(sp)
ffffffffc020178c:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc020178e:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201792:	892e                	mv	s2,a1
ffffffffc0201794:	8a32                	mv	s4,a2
ffffffffc0201796:	00010997          	auipc	s3,0x10
ffffffffc020179a:	d0298993          	addi	s3,s3,-766 # ffffffffc0211498 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc020179e:	e3c9                	bnez	a5,ffffffffc0201820 <get_pte+0xb4>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc02017a0:	16060163          	beqz	a2,ffffffffc0201902 <get_pte+0x196>
ffffffffc02017a4:	4505                	li	a0,1
ffffffffc02017a6:	eb9ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc02017aa:	842a                	mv	s0,a0
ffffffffc02017ac:	14050b63          	beqz	a0,ffffffffc0201902 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017b0:	00010b97          	auipc	s7,0x10
ffffffffc02017b4:	d38b8b93          	addi	s7,s7,-712 # ffffffffc02114e8 <pages>
ffffffffc02017b8:	000bb503          	ld	a0,0(s7)
ffffffffc02017bc:	00004797          	auipc	a5,0x4
ffffffffc02017c0:	c0478793          	addi	a5,a5,-1020 # ffffffffc02053c0 <commands+0x858>
ffffffffc02017c4:	0007bb03          	ld	s6,0(a5)
ffffffffc02017c8:	40a40533          	sub	a0,s0,a0
ffffffffc02017cc:	850d                	srai	a0,a0,0x3
ffffffffc02017ce:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02017d2:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02017d4:	00010997          	auipc	s3,0x10
ffffffffc02017d8:	cc498993          	addi	s3,s3,-828 # ffffffffc0211498 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017dc:	00080ab7          	lui	s5,0x80
ffffffffc02017e0:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02017e4:	c01c                	sw	a5,0(s0)
ffffffffc02017e6:	57fd                	li	a5,-1
ffffffffc02017e8:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02017ea:	9556                	add	a0,a0,s5
ffffffffc02017ec:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02017ee:	0532                	slli	a0,a0,0xc
ffffffffc02017f0:	16e7f063          	bleu	a4,a5,ffffffffc0201950 <get_pte+0x1e4>
ffffffffc02017f4:	00010797          	auipc	a5,0x10
ffffffffc02017f8:	ce478793          	addi	a5,a5,-796 # ffffffffc02114d8 <va_pa_offset>
ffffffffc02017fc:	639c                	ld	a5,0(a5)
ffffffffc02017fe:	6605                	lui	a2,0x1
ffffffffc0201800:	4581                	li	a1,0
ffffffffc0201802:	953e                	add	a0,a0,a5
ffffffffc0201804:	212030ef          	jal	ra,ffffffffc0204a16 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201808:	000bb683          	ld	a3,0(s7)
ffffffffc020180c:	40d406b3          	sub	a3,s0,a3
ffffffffc0201810:	868d                	srai	a3,a3,0x3
ffffffffc0201812:	036686b3          	mul	a3,a3,s6
ffffffffc0201816:	96d6                	add	a3,a3,s5

static inline void flush_tlb() { asm volatile("sfence.vma"); }

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201818:	06aa                	slli	a3,a3,0xa
ffffffffc020181a:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020181e:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201820:	77fd                	lui	a5,0xfffff
ffffffffc0201822:	068a                	slli	a3,a3,0x2
ffffffffc0201824:	0009b703          	ld	a4,0(s3)
ffffffffc0201828:	8efd                	and	a3,a3,a5
ffffffffc020182a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020182e:	0ce7fc63          	bleu	a4,a5,ffffffffc0201906 <get_pte+0x19a>
ffffffffc0201832:	00010a97          	auipc	s5,0x10
ffffffffc0201836:	ca6a8a93          	addi	s5,s5,-858 # ffffffffc02114d8 <va_pa_offset>
ffffffffc020183a:	000ab403          	ld	s0,0(s5)
ffffffffc020183e:	01595793          	srli	a5,s2,0x15
ffffffffc0201842:	1ff7f793          	andi	a5,a5,511
ffffffffc0201846:	96a2                	add	a3,a3,s0
ffffffffc0201848:	00379413          	slli	s0,a5,0x3
ffffffffc020184c:	9436                	add	s0,s0,a3
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
ffffffffc020184e:	6014                	ld	a3,0(s0)
ffffffffc0201850:	0016f793          	andi	a5,a3,1
ffffffffc0201854:	ebbd                	bnez	a5,ffffffffc02018ca <get_pte+0x15e>
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201856:	0a0a0663          	beqz	s4,ffffffffc0201902 <get_pte+0x196>
ffffffffc020185a:	4505                	li	a0,1
ffffffffc020185c:	e03ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201860:	84aa                	mv	s1,a0
ffffffffc0201862:	c145                	beqz	a0,ffffffffc0201902 <get_pte+0x196>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201864:	00010b97          	auipc	s7,0x10
ffffffffc0201868:	c84b8b93          	addi	s7,s7,-892 # ffffffffc02114e8 <pages>
ffffffffc020186c:	000bb503          	ld	a0,0(s7)
ffffffffc0201870:	00004797          	auipc	a5,0x4
ffffffffc0201874:	b5078793          	addi	a5,a5,-1200 # ffffffffc02053c0 <commands+0x858>
ffffffffc0201878:	0007bb03          	ld	s6,0(a5)
ffffffffc020187c:	40a48533          	sub	a0,s1,a0
ffffffffc0201880:	850d                	srai	a0,a0,0x3
ffffffffc0201882:	03650533          	mul	a0,a0,s6
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201886:	4785                	li	a5,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201888:	00080a37          	lui	s4,0x80
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc020188c:	0009b703          	ld	a4,0(s3)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201890:	c09c                	sw	a5,0(s1)
ffffffffc0201892:	57fd                	li	a5,-1
ffffffffc0201894:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201896:	9552                	add	a0,a0,s4
ffffffffc0201898:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020189a:	0532                	slli	a0,a0,0xc
ffffffffc020189c:	08e7fd63          	bleu	a4,a5,ffffffffc0201936 <get_pte+0x1ca>
ffffffffc02018a0:	000ab783          	ld	a5,0(s5)
ffffffffc02018a4:	6605                	lui	a2,0x1
ffffffffc02018a6:	4581                	li	a1,0
ffffffffc02018a8:	953e                	add	a0,a0,a5
ffffffffc02018aa:	16c030ef          	jal	ra,ffffffffc0204a16 <memset>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02018ae:	000bb683          	ld	a3,0(s7)
ffffffffc02018b2:	40d486b3          	sub	a3,s1,a3
ffffffffc02018b6:	868d                	srai	a3,a3,0x3
ffffffffc02018b8:	036686b3          	mul	a3,a3,s6
ffffffffc02018bc:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02018be:	06aa                	slli	a3,a3,0xa
ffffffffc02018c0:	0116e693          	ori	a3,a3,17
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02018c4:	e014                	sd	a3,0(s0)
ffffffffc02018c6:	0009b703          	ld	a4,0(s3)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02018ca:	068a                	slli	a3,a3,0x2
ffffffffc02018cc:	757d                	lui	a0,0xfffff
ffffffffc02018ce:	8ee9                	and	a3,a3,a0
ffffffffc02018d0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02018d4:	04e7f563          	bleu	a4,a5,ffffffffc020191e <get_pte+0x1b2>
ffffffffc02018d8:	000ab503          	ld	a0,0(s5)
ffffffffc02018dc:	00c95793          	srli	a5,s2,0xc
ffffffffc02018e0:	1ff7f793          	andi	a5,a5,511
ffffffffc02018e4:	96aa                	add	a3,a3,a0
ffffffffc02018e6:	00379513          	slli	a0,a5,0x3
ffffffffc02018ea:	9536                	add	a0,a0,a3
}
ffffffffc02018ec:	60a6                	ld	ra,72(sp)
ffffffffc02018ee:	6406                	ld	s0,64(sp)
ffffffffc02018f0:	74e2                	ld	s1,56(sp)
ffffffffc02018f2:	7942                	ld	s2,48(sp)
ffffffffc02018f4:	79a2                	ld	s3,40(sp)
ffffffffc02018f6:	7a02                	ld	s4,32(sp)
ffffffffc02018f8:	6ae2                	ld	s5,24(sp)
ffffffffc02018fa:	6b42                	ld	s6,16(sp)
ffffffffc02018fc:	6ba2                	ld	s7,8(sp)
ffffffffc02018fe:	6161                	addi	sp,sp,80
ffffffffc0201900:	8082                	ret
            return NULL;
ffffffffc0201902:	4501                	li	a0,0
ffffffffc0201904:	b7e5                	j	ffffffffc02018ec <get_pte+0x180>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201906:	00004617          	auipc	a2,0x4
ffffffffc020190a:	eba60613          	addi	a2,a2,-326 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc020190e:	0fa00593          	li	a1,250
ffffffffc0201912:	00004517          	auipc	a0,0x4
ffffffffc0201916:	ed650513          	addi	a0,a0,-298 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020191a:	a5bfe0ef          	jal	ra,ffffffffc0200374 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020191e:	00004617          	auipc	a2,0x4
ffffffffc0201922:	ea260613          	addi	a2,a2,-350 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc0201926:	10700593          	li	a1,263
ffffffffc020192a:	00004517          	auipc	a0,0x4
ffffffffc020192e:	ebe50513          	addi	a0,a0,-322 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0201932:	a43fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    	memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201936:	86aa                	mv	a3,a0
ffffffffc0201938:	00004617          	auipc	a2,0x4
ffffffffc020193c:	e8860613          	addi	a2,a2,-376 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc0201940:	10300593          	li	a1,259
ffffffffc0201944:	00004517          	auipc	a0,0x4
ffffffffc0201948:	ea450513          	addi	a0,a0,-348 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020194c:	a29fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201950:	86aa                	mv	a3,a0
ffffffffc0201952:	00004617          	auipc	a2,0x4
ffffffffc0201956:	e6e60613          	addi	a2,a2,-402 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc020195a:	0f700593          	li	a1,247
ffffffffc020195e:	00004517          	auipc	a0,0x4
ffffffffc0201962:	e8a50513          	addi	a0,a0,-374 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0201966:	a0ffe0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020196a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020196a:	1141                	addi	sp,sp,-16
ffffffffc020196c:	e022                	sd	s0,0(sp)
ffffffffc020196e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201970:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201972:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201974:	df9ff0ef          	jal	ra,ffffffffc020176c <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201978:	c011                	beqz	s0,ffffffffc020197c <get_page+0x12>
        *ptep_store = ptep;
ffffffffc020197a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020197c:	c521                	beqz	a0,ffffffffc02019c4 <get_page+0x5a>
ffffffffc020197e:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201980:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201982:	0017f713          	andi	a4,a5,1
ffffffffc0201986:	e709                	bnez	a4,ffffffffc0201990 <get_page+0x26>
}
ffffffffc0201988:	60a2                	ld	ra,8(sp)
ffffffffc020198a:	6402                	ld	s0,0(sp)
ffffffffc020198c:	0141                	addi	sp,sp,16
ffffffffc020198e:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201990:	00010717          	auipc	a4,0x10
ffffffffc0201994:	b0870713          	addi	a4,a4,-1272 # ffffffffc0211498 <npage>
ffffffffc0201998:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc020199a:	078a                	slli	a5,a5,0x2
ffffffffc020199c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020199e:	02e7f863          	bleu	a4,a5,ffffffffc02019ce <get_page+0x64>
    return &pages[PPN(pa) - nbase];
ffffffffc02019a2:	fff80537          	lui	a0,0xfff80
ffffffffc02019a6:	97aa                	add	a5,a5,a0
ffffffffc02019a8:	00010697          	auipc	a3,0x10
ffffffffc02019ac:	b4068693          	addi	a3,a3,-1216 # ffffffffc02114e8 <pages>
ffffffffc02019b0:	6288                	ld	a0,0(a3)
ffffffffc02019b2:	60a2                	ld	ra,8(sp)
ffffffffc02019b4:	6402                	ld	s0,0(sp)
ffffffffc02019b6:	00379713          	slli	a4,a5,0x3
ffffffffc02019ba:	97ba                	add	a5,a5,a4
ffffffffc02019bc:	078e                	slli	a5,a5,0x3
ffffffffc02019be:	953e                	add	a0,a0,a5
ffffffffc02019c0:	0141                	addi	sp,sp,16
ffffffffc02019c2:	8082                	ret
ffffffffc02019c4:	60a2                	ld	ra,8(sp)
ffffffffc02019c6:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc02019c8:	4501                	li	a0,0
}
ffffffffc02019ca:	0141                	addi	sp,sp,16
ffffffffc02019cc:	8082                	ret
ffffffffc02019ce:	c75ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>

ffffffffc02019d2 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02019d2:	1141                	addi	sp,sp,-16
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02019d4:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02019d6:	e406                	sd	ra,8(sp)
ffffffffc02019d8:	e022                	sd	s0,0(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02019da:	d93ff0ef          	jal	ra,ffffffffc020176c <get_pte>
    if (ptep != NULL) {
ffffffffc02019de:	c511                	beqz	a0,ffffffffc02019ea <page_remove+0x18>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02019e0:	611c                	ld	a5,0(a0)
ffffffffc02019e2:	842a                	mv	s0,a0
ffffffffc02019e4:	0017f713          	andi	a4,a5,1
ffffffffc02019e8:	e709                	bnez	a4,ffffffffc02019f2 <page_remove+0x20>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc02019ea:	60a2                	ld	ra,8(sp)
ffffffffc02019ec:	6402                	ld	s0,0(sp)
ffffffffc02019ee:	0141                	addi	sp,sp,16
ffffffffc02019f0:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02019f2:	00010717          	auipc	a4,0x10
ffffffffc02019f6:	aa670713          	addi	a4,a4,-1370 # ffffffffc0211498 <npage>
ffffffffc02019fa:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02019fc:	078a                	slli	a5,a5,0x2
ffffffffc02019fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201a00:	04e7f063          	bleu	a4,a5,ffffffffc0201a40 <page_remove+0x6e>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a04:	fff80737          	lui	a4,0xfff80
ffffffffc0201a08:	97ba                	add	a5,a5,a4
ffffffffc0201a0a:	00010717          	auipc	a4,0x10
ffffffffc0201a0e:	ade70713          	addi	a4,a4,-1314 # ffffffffc02114e8 <pages>
ffffffffc0201a12:	6308                	ld	a0,0(a4)
ffffffffc0201a14:	00379713          	slli	a4,a5,0x3
ffffffffc0201a18:	97ba                	add	a5,a5,a4
ffffffffc0201a1a:	078e                	slli	a5,a5,0x3
ffffffffc0201a1c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201a1e:	411c                	lw	a5,0(a0)
ffffffffc0201a20:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201a24:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201a26:	cb09                	beqz	a4,ffffffffc0201a38 <page_remove+0x66>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201a28:	00043023          	sd	zero,0(s0)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201a2c:	12000073          	sfence.vma
}
ffffffffc0201a30:	60a2                	ld	ra,8(sp)
ffffffffc0201a32:	6402                	ld	s0,0(sp)
ffffffffc0201a34:	0141                	addi	sp,sp,16
ffffffffc0201a36:	8082                	ret
            free_page(page);
ffffffffc0201a38:	4585                	li	a1,1
ffffffffc0201a3a:	cadff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
ffffffffc0201a3e:	b7ed                	j	ffffffffc0201a28 <page_remove+0x56>
ffffffffc0201a40:	c03ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>

ffffffffc0201a44 <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201a44:	7179                	addi	sp,sp,-48
ffffffffc0201a46:	87b2                	mv	a5,a2
ffffffffc0201a48:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a4a:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201a4c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a4e:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0201a50:	ec26                	sd	s1,24(sp)
ffffffffc0201a52:	f406                	sd	ra,40(sp)
ffffffffc0201a54:	e84a                	sd	s2,16(sp)
ffffffffc0201a56:	e44e                	sd	s3,8(sp)
ffffffffc0201a58:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201a5a:	d13ff0ef          	jal	ra,ffffffffc020176c <get_pte>
    if (ptep == NULL) {
ffffffffc0201a5e:	c945                	beqz	a0,ffffffffc0201b0e <page_insert+0xca>
    page->ref += 1;
ffffffffc0201a60:	4014                	lw	a3,0(s0)
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
ffffffffc0201a62:	611c                	ld	a5,0(a0)
ffffffffc0201a64:	892a                	mv	s2,a0
ffffffffc0201a66:	0016871b          	addiw	a4,a3,1
ffffffffc0201a6a:	c018                	sw	a4,0(s0)
ffffffffc0201a6c:	0017f713          	andi	a4,a5,1
ffffffffc0201a70:	e339                	bnez	a4,ffffffffc0201ab6 <page_insert+0x72>
ffffffffc0201a72:	00010797          	auipc	a5,0x10
ffffffffc0201a76:	a7678793          	addi	a5,a5,-1418 # ffffffffc02114e8 <pages>
ffffffffc0201a7a:	639c                	ld	a5,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a7c:	00004717          	auipc	a4,0x4
ffffffffc0201a80:	94470713          	addi	a4,a4,-1724 # ffffffffc02053c0 <commands+0x858>
ffffffffc0201a84:	40f407b3          	sub	a5,s0,a5
ffffffffc0201a88:	6300                	ld	s0,0(a4)
ffffffffc0201a8a:	878d                	srai	a5,a5,0x3
ffffffffc0201a8c:	000806b7          	lui	a3,0x80
ffffffffc0201a90:	028787b3          	mul	a5,a5,s0
ffffffffc0201a94:	97b6                	add	a5,a5,a3
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201a96:	07aa                	slli	a5,a5,0xa
ffffffffc0201a98:	8fc5                	or	a5,a5,s1
ffffffffc0201a9a:	0017e793          	ori	a5,a5,1
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0201a9e:	00f93023          	sd	a5,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201aa2:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la);
    return 0;
ffffffffc0201aa6:	4501                	li	a0,0
}
ffffffffc0201aa8:	70a2                	ld	ra,40(sp)
ffffffffc0201aaa:	7402                	ld	s0,32(sp)
ffffffffc0201aac:	64e2                	ld	s1,24(sp)
ffffffffc0201aae:	6942                	ld	s2,16(sp)
ffffffffc0201ab0:	69a2                	ld	s3,8(sp)
ffffffffc0201ab2:	6145                	addi	sp,sp,48
ffffffffc0201ab4:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0201ab6:	00010717          	auipc	a4,0x10
ffffffffc0201aba:	9e270713          	addi	a4,a4,-1566 # ffffffffc0211498 <npage>
ffffffffc0201abe:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ac0:	00279513          	slli	a0,a5,0x2
ffffffffc0201ac4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ac6:	04e57663          	bleu	a4,a0,ffffffffc0201b12 <page_insert+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201aca:	fff807b7          	lui	a5,0xfff80
ffffffffc0201ace:	953e                	add	a0,a0,a5
ffffffffc0201ad0:	00010997          	auipc	s3,0x10
ffffffffc0201ad4:	a1898993          	addi	s3,s3,-1512 # ffffffffc02114e8 <pages>
ffffffffc0201ad8:	0009b783          	ld	a5,0(s3)
ffffffffc0201adc:	00351713          	slli	a4,a0,0x3
ffffffffc0201ae0:	953a                	add	a0,a0,a4
ffffffffc0201ae2:	050e                	slli	a0,a0,0x3
ffffffffc0201ae4:	953e                	add	a0,a0,a5
        if (p == page) {
ffffffffc0201ae6:	00a40e63          	beq	s0,a0,ffffffffc0201b02 <page_insert+0xbe>
    page->ref -= 1;
ffffffffc0201aea:	411c                	lw	a5,0(a0)
ffffffffc0201aec:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201af0:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201af2:	cb11                	beqz	a4,ffffffffc0201b06 <page_insert+0xc2>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0201af4:	00093023          	sd	zero,0(s2)
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc0201af8:	12000073          	sfence.vma
ffffffffc0201afc:	0009b783          	ld	a5,0(s3)
ffffffffc0201b00:	bfb5                	j	ffffffffc0201a7c <page_insert+0x38>
    page->ref -= 1;
ffffffffc0201b02:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0201b04:	bfa5                	j	ffffffffc0201a7c <page_insert+0x38>
            free_page(page);
ffffffffc0201b06:	4585                	li	a1,1
ffffffffc0201b08:	bdfff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
ffffffffc0201b0c:	b7e5                	j	ffffffffc0201af4 <page_insert+0xb0>
        return -E_NO_MEM;
ffffffffc0201b0e:	5571                	li	a0,-4
ffffffffc0201b10:	bf61                	j	ffffffffc0201aa8 <page_insert+0x64>
ffffffffc0201b12:	b31ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>

ffffffffc0201b16 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201b16:	00004797          	auipc	a5,0x4
ffffffffc0201b1a:	c5a78793          	addi	a5,a5,-934 # ffffffffc0205770 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b1e:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0201b20:	711d                	addi	sp,sp,-96
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b22:	00004517          	auipc	a0,0x4
ffffffffc0201b26:	d5e50513          	addi	a0,a0,-674 # ffffffffc0205880 <default_pmm_manager+0x110>
void pmm_init(void) {
ffffffffc0201b2a:	ec86                	sd	ra,88(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b2c:	00010717          	auipc	a4,0x10
ffffffffc0201b30:	9af73223          	sd	a5,-1628(a4) # ffffffffc02114d0 <pmm_manager>
void pmm_init(void) {
ffffffffc0201b34:	e8a2                	sd	s0,80(sp)
ffffffffc0201b36:	e4a6                	sd	s1,72(sp)
ffffffffc0201b38:	e0ca                	sd	s2,64(sp)
ffffffffc0201b3a:	fc4e                	sd	s3,56(sp)
ffffffffc0201b3c:	f852                	sd	s4,48(sp)
ffffffffc0201b3e:	f456                	sd	s5,40(sp)
ffffffffc0201b40:	f05a                	sd	s6,32(sp)
ffffffffc0201b42:	ec5e                	sd	s7,24(sp)
ffffffffc0201b44:	e862                	sd	s8,16(sp)
ffffffffc0201b46:	e466                	sd	s9,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201b48:	00010417          	auipc	s0,0x10
ffffffffc0201b4c:	98840413          	addi	s0,s0,-1656 # ffffffffc02114d0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201b50:	d6efe0ef          	jal	ra,ffffffffc02000be <cprintf>
    pmm_manager->init();
ffffffffc0201b54:	601c                	ld	a5,0(s0)
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b56:	49c5                	li	s3,17
ffffffffc0201b58:	40100a13          	li	s4,1025
    pmm_manager->init();
ffffffffc0201b5c:	679c                	ld	a5,8(a5)
ffffffffc0201b5e:	00010497          	auipc	s1,0x10
ffffffffc0201b62:	93a48493          	addi	s1,s1,-1734 # ffffffffc0211498 <npage>
ffffffffc0201b66:	00010917          	auipc	s2,0x10
ffffffffc0201b6a:	98290913          	addi	s2,s2,-1662 # ffffffffc02114e8 <pages>
ffffffffc0201b6e:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b70:	57f5                	li	a5,-3
ffffffffc0201b72:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b74:	07e006b7          	lui	a3,0x7e00
ffffffffc0201b78:	01b99613          	slli	a2,s3,0x1b
ffffffffc0201b7c:	015a1593          	slli	a1,s4,0x15
ffffffffc0201b80:	00004517          	auipc	a0,0x4
ffffffffc0201b84:	d1850513          	addi	a0,a0,-744 # ffffffffc0205898 <default_pmm_manager+0x128>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0201b88:	00010717          	auipc	a4,0x10
ffffffffc0201b8c:	94f73823          	sd	a5,-1712(a4) # ffffffffc02114d8 <va_pa_offset>
    cprintf("membegin %llx memend %llx mem_size %llx\n",mem_begin, mem_end, mem_size);
ffffffffc0201b90:	d2efe0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("physcial memory map:\n");
ffffffffc0201b94:	00004517          	auipc	a0,0x4
ffffffffc0201b98:	d3450513          	addi	a0,a0,-716 # ffffffffc02058c8 <default_pmm_manager+0x158>
ffffffffc0201b9c:	d22fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0201ba0:	01b99693          	slli	a3,s3,0x1b
ffffffffc0201ba4:	16fd                	addi	a3,a3,-1
ffffffffc0201ba6:	015a1613          	slli	a2,s4,0x15
ffffffffc0201baa:	07e005b7          	lui	a1,0x7e00
ffffffffc0201bae:	00004517          	auipc	a0,0x4
ffffffffc0201bb2:	d3250513          	addi	a0,a0,-718 # ffffffffc02058e0 <default_pmm_manager+0x170>
ffffffffc0201bb6:	d08fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201bba:	777d                	lui	a4,0xfffff
ffffffffc0201bbc:	00011797          	auipc	a5,0x11
ffffffffc0201bc0:	a1b78793          	addi	a5,a5,-1509 # ffffffffc02125d7 <end+0xfff>
ffffffffc0201bc4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201bc6:	00088737          	lui	a4,0x88
ffffffffc0201bca:	00010697          	auipc	a3,0x10
ffffffffc0201bce:	8ce6b723          	sd	a4,-1842(a3) # ffffffffc0211498 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201bd2:	00010717          	auipc	a4,0x10
ffffffffc0201bd6:	90f73b23          	sd	a5,-1770(a4) # ffffffffc02114e8 <pages>
ffffffffc0201bda:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201bdc:	4701                	li	a4,0
ffffffffc0201bde:	4585                	li	a1,1
ffffffffc0201be0:	fff80637          	lui	a2,0xfff80
ffffffffc0201be4:	a019                	j	ffffffffc0201bea <pmm_init+0xd4>
ffffffffc0201be6:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc0201bea:	97b6                	add	a5,a5,a3
ffffffffc0201bec:	07a1                	addi	a5,a5,8
ffffffffc0201bee:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201bf2:	609c                	ld	a5,0(s1)
ffffffffc0201bf4:	0705                	addi	a4,a4,1
ffffffffc0201bf6:	04868693          	addi	a3,a3,72
ffffffffc0201bfa:	00c78533          	add	a0,a5,a2
ffffffffc0201bfe:	fea764e3          	bltu	a4,a0,ffffffffc0201be6 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c02:	00093503          	ld	a0,0(s2)
ffffffffc0201c06:	00379693          	slli	a3,a5,0x3
ffffffffc0201c0a:	96be                	add	a3,a3,a5
ffffffffc0201c0c:	fdc00737          	lui	a4,0xfdc00
ffffffffc0201c10:	972a                	add	a4,a4,a0
ffffffffc0201c12:	068e                	slli	a3,a3,0x3
ffffffffc0201c14:	96ba                	add	a3,a3,a4
ffffffffc0201c16:	c0200737          	lui	a4,0xc0200
ffffffffc0201c1a:	58e6ea63          	bltu	a3,a4,ffffffffc02021ae <pmm_init+0x698>
ffffffffc0201c1e:	00010997          	auipc	s3,0x10
ffffffffc0201c22:	8ba98993          	addi	s3,s3,-1862 # ffffffffc02114d8 <va_pa_offset>
ffffffffc0201c26:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) {
ffffffffc0201c2a:	45c5                	li	a1,17
ffffffffc0201c2c:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201c2e:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201c30:	44b6ef63          	bltu	a3,a1,ffffffffc020208e <pmm_init+0x578>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201c34:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201c36:	00010417          	auipc	s0,0x10
ffffffffc0201c3a:	85a40413          	addi	s0,s0,-1958 # ffffffffc0211490 <boot_pgdir>
    pmm_manager->check();
ffffffffc0201c3e:	7b9c                	ld	a5,48(a5)
ffffffffc0201c40:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201c42:	00004517          	auipc	a0,0x4
ffffffffc0201c46:	cee50513          	addi	a0,a0,-786 # ffffffffc0205930 <default_pmm_manager+0x1c0>
ffffffffc0201c4a:	c74fe0ef          	jal	ra,ffffffffc02000be <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0201c4e:	00007697          	auipc	a3,0x7
ffffffffc0201c52:	3b268693          	addi	a3,a3,946 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0201c56:	00010797          	auipc	a5,0x10
ffffffffc0201c5a:	82d7bd23          	sd	a3,-1990(a5) # ffffffffc0211490 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0201c5e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201c62:	0ef6ece3          	bltu	a3,a5,ffffffffc020255a <pmm_init+0xa44>
ffffffffc0201c66:	0009b783          	ld	a5,0(s3)
ffffffffc0201c6a:	8e9d                	sub	a3,a3,a5
ffffffffc0201c6c:	00010797          	auipc	a5,0x10
ffffffffc0201c70:	86d7ba23          	sd	a3,-1932(a5) # ffffffffc02114e0 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc0201c74:	ab9ff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201c78:	6098                	ld	a4,0(s1)
ffffffffc0201c7a:	c80007b7          	lui	a5,0xc8000
ffffffffc0201c7e:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc0201c80:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0201c82:	0ae7ece3          	bltu	a5,a4,ffffffffc020253a <pmm_init+0xa24>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0201c86:	6008                	ld	a0,0(s0)
ffffffffc0201c88:	4c050363          	beqz	a0,ffffffffc020214e <pmm_init+0x638>
ffffffffc0201c8c:	6785                	lui	a5,0x1
ffffffffc0201c8e:	17fd                	addi	a5,a5,-1
ffffffffc0201c90:	8fe9                	and	a5,a5,a0
ffffffffc0201c92:	2781                	sext.w	a5,a5
ffffffffc0201c94:	4a079d63          	bnez	a5,ffffffffc020214e <pmm_init+0x638>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0201c98:	4601                	li	a2,0
ffffffffc0201c9a:	4581                	li	a1,0
ffffffffc0201c9c:	ccfff0ef          	jal	ra,ffffffffc020196a <get_page>
ffffffffc0201ca0:	4c051763          	bnez	a0,ffffffffc020216e <pmm_init+0x658>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0201ca4:	4505                	li	a0,1
ffffffffc0201ca6:	9b9ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201caa:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0201cac:	6008                	ld	a0,0(s0)
ffffffffc0201cae:	4681                	li	a3,0
ffffffffc0201cb0:	4601                	li	a2,0
ffffffffc0201cb2:	85d6                	mv	a1,s5
ffffffffc0201cb4:	d91ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201cb8:	52051763          	bnez	a0,ffffffffc02021e6 <pmm_init+0x6d0>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0201cbc:	6008                	ld	a0,0(s0)
ffffffffc0201cbe:	4601                	li	a2,0
ffffffffc0201cc0:	4581                	li	a1,0
ffffffffc0201cc2:	aabff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201cc6:	50050063          	beqz	a0,ffffffffc02021c6 <pmm_init+0x6b0>
    assert(pte2page(*ptep) == p1);
ffffffffc0201cca:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201ccc:	0017f713          	andi	a4,a5,1
ffffffffc0201cd0:	46070363          	beqz	a4,ffffffffc0202136 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0201cd4:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201cd6:	078a                	slli	a5,a5,0x2
ffffffffc0201cd8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201cda:	44c7f063          	bleu	a2,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201cde:	fff80737          	lui	a4,0xfff80
ffffffffc0201ce2:	97ba                	add	a5,a5,a4
ffffffffc0201ce4:	00379713          	slli	a4,a5,0x3
ffffffffc0201ce8:	00093683          	ld	a3,0(s2)
ffffffffc0201cec:	97ba                	add	a5,a5,a4
ffffffffc0201cee:	078e                	slli	a5,a5,0x3
ffffffffc0201cf0:	97b6                	add	a5,a5,a3
ffffffffc0201cf2:	5efa9463          	bne	s5,a5,ffffffffc02022da <pmm_init+0x7c4>
    assert(page_ref(p1) == 1);
ffffffffc0201cf6:	000aab83          	lw	s7,0(s5)
ffffffffc0201cfa:	4785                	li	a5,1
ffffffffc0201cfc:	5afb9f63          	bne	s7,a5,ffffffffc02022ba <pmm_init+0x7a4>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0201d00:	6008                	ld	a0,0(s0)
ffffffffc0201d02:	76fd                	lui	a3,0xfffff
ffffffffc0201d04:	611c                	ld	a5,0(a0)
ffffffffc0201d06:	078a                	slli	a5,a5,0x2
ffffffffc0201d08:	8ff5                	and	a5,a5,a3
ffffffffc0201d0a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0201d0e:	58c77963          	bleu	a2,a4,ffffffffc02022a0 <pmm_init+0x78a>
ffffffffc0201d12:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d16:	97e2                	add	a5,a5,s8
ffffffffc0201d18:	0007bb03          	ld	s6,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc0201d1c:	0b0a                	slli	s6,s6,0x2
ffffffffc0201d1e:	00db7b33          	and	s6,s6,a3
ffffffffc0201d22:	00cb5793          	srli	a5,s6,0xc
ffffffffc0201d26:	56c7f063          	bleu	a2,a5,ffffffffc0202286 <pmm_init+0x770>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d2a:	4601                	li	a2,0
ffffffffc0201d2c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d2e:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d30:	a3dff0ef          	jal	ra,ffffffffc020176c <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0201d34:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0201d36:	53651863          	bne	a0,s6,ffffffffc0202266 <pmm_init+0x750>

    p2 = alloc_page();
ffffffffc0201d3a:	4505                	li	a0,1
ffffffffc0201d3c:	923ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201d40:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0201d42:	6008                	ld	a0,0(s0)
ffffffffc0201d44:	46d1                	li	a3,20
ffffffffc0201d46:	6605                	lui	a2,0x1
ffffffffc0201d48:	85da                	mv	a1,s6
ffffffffc0201d4a:	cfbff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201d4e:	4e051c63          	bnez	a0,ffffffffc0202246 <pmm_init+0x730>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201d52:	6008                	ld	a0,0(s0)
ffffffffc0201d54:	4601                	li	a2,0
ffffffffc0201d56:	6585                	lui	a1,0x1
ffffffffc0201d58:	a15ff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201d5c:	4c050563          	beqz	a0,ffffffffc0202226 <pmm_init+0x710>
    assert(*ptep & PTE_U);
ffffffffc0201d60:	611c                	ld	a5,0(a0)
ffffffffc0201d62:	0107f713          	andi	a4,a5,16
ffffffffc0201d66:	4a070063          	beqz	a4,ffffffffc0202206 <pmm_init+0x6f0>
    assert(*ptep & PTE_W);
ffffffffc0201d6a:	8b91                	andi	a5,a5,4
ffffffffc0201d6c:	66078763          	beqz	a5,ffffffffc02023da <pmm_init+0x8c4>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0201d70:	6008                	ld	a0,0(s0)
ffffffffc0201d72:	611c                	ld	a5,0(a0)
ffffffffc0201d74:	8bc1                	andi	a5,a5,16
ffffffffc0201d76:	64078263          	beqz	a5,ffffffffc02023ba <pmm_init+0x8a4>
    assert(page_ref(p2) == 1);
ffffffffc0201d7a:	000b2783          	lw	a5,0(s6)
ffffffffc0201d7e:	61779e63          	bne	a5,s7,ffffffffc020239a <pmm_init+0x884>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0201d82:	4681                	li	a3,0
ffffffffc0201d84:	6605                	lui	a2,0x1
ffffffffc0201d86:	85d6                	mv	a1,s5
ffffffffc0201d88:	cbdff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201d8c:	5e051763          	bnez	a0,ffffffffc020237a <pmm_init+0x864>
    assert(page_ref(p1) == 2);
ffffffffc0201d90:	000aa703          	lw	a4,0(s5)
ffffffffc0201d94:	4789                	li	a5,2
ffffffffc0201d96:	5cf71263          	bne	a4,a5,ffffffffc020235a <pmm_init+0x844>
    assert(page_ref(p2) == 0);
ffffffffc0201d9a:	000b2783          	lw	a5,0(s6)
ffffffffc0201d9e:	58079e63          	bnez	a5,ffffffffc020233a <pmm_init+0x824>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0201da2:	6008                	ld	a0,0(s0)
ffffffffc0201da4:	4601                	li	a2,0
ffffffffc0201da6:	6585                	lui	a1,0x1
ffffffffc0201da8:	9c5ff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201dac:	56050763          	beqz	a0,ffffffffc020231a <pmm_init+0x804>
    assert(pte2page(*ptep) == p1);
ffffffffc0201db0:	6114                	ld	a3,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201db2:	0016f793          	andi	a5,a3,1
ffffffffc0201db6:	38078063          	beqz	a5,ffffffffc0202136 <pmm_init+0x620>
    if (PPN(pa) >= npage) {
ffffffffc0201dba:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201dbc:	00269793          	slli	a5,a3,0x2
ffffffffc0201dc0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201dc2:	34e7fc63          	bleu	a4,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dc6:	fff80737          	lui	a4,0xfff80
ffffffffc0201dca:	97ba                	add	a5,a5,a4
ffffffffc0201dcc:	00379713          	slli	a4,a5,0x3
ffffffffc0201dd0:	00093603          	ld	a2,0(s2)
ffffffffc0201dd4:	97ba                	add	a5,a5,a4
ffffffffc0201dd6:	078e                	slli	a5,a5,0x3
ffffffffc0201dd8:	97b2                	add	a5,a5,a2
ffffffffc0201dda:	52fa9063          	bne	s5,a5,ffffffffc02022fa <pmm_init+0x7e4>
    assert((*ptep & PTE_U) == 0);
ffffffffc0201dde:	8ac1                	andi	a3,a3,16
ffffffffc0201de0:	6e069d63          	bnez	a3,ffffffffc02024da <pmm_init+0x9c4>

    page_remove(boot_pgdir, 0x0);
ffffffffc0201de4:	6008                	ld	a0,0(s0)
ffffffffc0201de6:	4581                	li	a1,0
ffffffffc0201de8:	bebff0ef          	jal	ra,ffffffffc02019d2 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0201dec:	000aa703          	lw	a4,0(s5)
ffffffffc0201df0:	4785                	li	a5,1
ffffffffc0201df2:	6cf71463          	bne	a4,a5,ffffffffc02024ba <pmm_init+0x9a4>
    assert(page_ref(p2) == 0);
ffffffffc0201df6:	000b2783          	lw	a5,0(s6)
ffffffffc0201dfa:	6a079063          	bnez	a5,ffffffffc020249a <pmm_init+0x984>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0201dfe:	6008                	ld	a0,0(s0)
ffffffffc0201e00:	6585                	lui	a1,0x1
ffffffffc0201e02:	bd1ff0ef          	jal	ra,ffffffffc02019d2 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0201e06:	000aa783          	lw	a5,0(s5)
ffffffffc0201e0a:	66079863          	bnez	a5,ffffffffc020247a <pmm_init+0x964>
    assert(page_ref(p2) == 0);
ffffffffc0201e0e:	000b2783          	lw	a5,0(s6)
ffffffffc0201e12:	70079463          	bnez	a5,ffffffffc020251a <pmm_init+0xa04>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0201e16:	00043b03          	ld	s6,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201e1a:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e1c:	000b3783          	ld	a5,0(s6)
ffffffffc0201e20:	078a                	slli	a5,a5,0x2
ffffffffc0201e22:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e24:	2eb7fb63          	bleu	a1,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e28:	fff80737          	lui	a4,0xfff80
ffffffffc0201e2c:	973e                	add	a4,a4,a5
ffffffffc0201e2e:	00371793          	slli	a5,a4,0x3
ffffffffc0201e32:	00093603          	ld	a2,0(s2)
ffffffffc0201e36:	97ba                	add	a5,a5,a4
ffffffffc0201e38:	078e                	slli	a5,a5,0x3
ffffffffc0201e3a:	00f60733          	add	a4,a2,a5
ffffffffc0201e3e:	4314                	lw	a3,0(a4)
ffffffffc0201e40:	4705                	li	a4,1
ffffffffc0201e42:	6ae69c63          	bne	a3,a4,ffffffffc02024fa <pmm_init+0x9e4>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e46:	00003a97          	auipc	s5,0x3
ffffffffc0201e4a:	57aa8a93          	addi	s5,s5,1402 # ffffffffc02053c0 <commands+0x858>
ffffffffc0201e4e:	000ab703          	ld	a4,0(s5)
ffffffffc0201e52:	4037d693          	srai	a3,a5,0x3
ffffffffc0201e56:	00080bb7          	lui	s7,0x80
ffffffffc0201e5a:	02e686b3          	mul	a3,a3,a4
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e5e:	577d                	li	a4,-1
ffffffffc0201e60:	8331                	srli	a4,a4,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201e62:	96de                	add	a3,a3,s7
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e64:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e66:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201e68:	2ab77b63          	bleu	a1,a4,ffffffffc020211e <pmm_init+0x608>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0201e6c:	0009b783          	ld	a5,0(s3)
ffffffffc0201e70:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e72:	629c                	ld	a5,0(a3)
ffffffffc0201e74:	078a                	slli	a5,a5,0x2
ffffffffc0201e76:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e78:	2ab7f163          	bleu	a1,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e7c:	417787b3          	sub	a5,a5,s7
ffffffffc0201e80:	00379513          	slli	a0,a5,0x3
ffffffffc0201e84:	97aa                	add	a5,a5,a0
ffffffffc0201e86:	00379513          	slli	a0,a5,0x3
ffffffffc0201e8a:	9532                	add	a0,a0,a2
ffffffffc0201e8c:	4585                	li	a1,1
ffffffffc0201e8e:	859ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e92:	000b3503          	ld	a0,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0201e96:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201e98:	050a                	slli	a0,a0,0x2
ffffffffc0201e9a:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201e9c:	26f57f63          	bleu	a5,a0,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ea0:	417507b3          	sub	a5,a0,s7
ffffffffc0201ea4:	00379513          	slli	a0,a5,0x3
ffffffffc0201ea8:	00093703          	ld	a4,0(s2)
ffffffffc0201eac:	953e                	add	a0,a0,a5
ffffffffc0201eae:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0201eb0:	4585                	li	a1,1
ffffffffc0201eb2:	953a                	add	a0,a0,a4
ffffffffc0201eb4:	833ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0201eb8:	601c                	ld	a5,0(s0)
ffffffffc0201eba:	0007b023          	sd	zero,0(a5)

    assert(nr_free_store==nr_free_pages());
ffffffffc0201ebe:	86fff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0201ec2:	2caa1663          	bne	s4,a0,ffffffffc020218e <pmm_init+0x678>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0201ec6:	00004517          	auipc	a0,0x4
ffffffffc0201eca:	d7a50513          	addi	a0,a0,-646 # ffffffffc0205c40 <default_pmm_manager+0x4d0>
ffffffffc0201ece:	9f0fe0ef          	jal	ra,ffffffffc02000be <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc0201ed2:	85bff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201ed6:	6098                	ld	a4,0(s1)
ffffffffc0201ed8:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc0201edc:	8b2a                	mv	s6,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201ede:	00c71693          	slli	a3,a4,0xc
ffffffffc0201ee2:	1cd7fd63          	bleu	a3,a5,ffffffffc02020bc <pmm_init+0x5a6>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201ee6:	83b1                	srli	a5,a5,0xc
ffffffffc0201ee8:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201eea:	c0200a37          	lui	s4,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201eee:	1ce7f963          	bleu	a4,a5,ffffffffc02020c0 <pmm_init+0x5aa>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201ef2:	7c7d                	lui	s8,0xfffff
ffffffffc0201ef4:	6b85                	lui	s7,0x1
ffffffffc0201ef6:	a029                	j	ffffffffc0201f00 <pmm_init+0x3ea>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0201ef8:	00ca5713          	srli	a4,s4,0xc
ffffffffc0201efc:	1cf77263          	bleu	a5,a4,ffffffffc02020c0 <pmm_init+0x5aa>
ffffffffc0201f00:	0009b583          	ld	a1,0(s3)
ffffffffc0201f04:	4601                	li	a2,0
ffffffffc0201f06:	95d2                	add	a1,a1,s4
ffffffffc0201f08:	865ff0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0201f0c:	1c050763          	beqz	a0,ffffffffc02020da <pmm_init+0x5c4>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0201f10:	611c                	ld	a5,0(a0)
ffffffffc0201f12:	078a                	slli	a5,a5,0x2
ffffffffc0201f14:	0187f7b3          	and	a5,a5,s8
ffffffffc0201f18:	1f479163          	bne	a5,s4,ffffffffc02020fa <pmm_init+0x5e4>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0201f1c:	609c                	ld	a5,0(s1)
ffffffffc0201f1e:	9a5e                	add	s4,s4,s7
ffffffffc0201f20:	6008                	ld	a0,0(s0)
ffffffffc0201f22:	00c79713          	slli	a4,a5,0xc
ffffffffc0201f26:	fcea69e3          	bltu	s4,a4,ffffffffc0201ef8 <pmm_init+0x3e2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0201f2a:	611c                	ld	a5,0(a0)
ffffffffc0201f2c:	6a079363          	bnez	a5,ffffffffc02025d2 <pmm_init+0xabc>

    struct Page *p;
    p = alloc_page();
ffffffffc0201f30:	4505                	li	a0,1
ffffffffc0201f32:	f2cff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0201f36:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0201f38:	6008                	ld	a0,0(s0)
ffffffffc0201f3a:	4699                	li	a3,6
ffffffffc0201f3c:	10000613          	li	a2,256
ffffffffc0201f40:	85d2                	mv	a1,s4
ffffffffc0201f42:	b03ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201f46:	66051663          	bnez	a0,ffffffffc02025b2 <pmm_init+0xa9c>
    assert(page_ref(p) == 1);
ffffffffc0201f4a:	000a2703          	lw	a4,0(s4) # ffffffffc0200000 <kern_entry>
ffffffffc0201f4e:	4785                	li	a5,1
ffffffffc0201f50:	64f71163          	bne	a4,a5,ffffffffc0202592 <pmm_init+0xa7c>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0201f54:	6008                	ld	a0,0(s0)
ffffffffc0201f56:	6b85                	lui	s7,0x1
ffffffffc0201f58:	4699                	li	a3,6
ffffffffc0201f5a:	100b8613          	addi	a2,s7,256 # 1100 <BASE_ADDRESS-0xffffffffc01fef00>
ffffffffc0201f5e:	85d2                	mv	a1,s4
ffffffffc0201f60:	ae5ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0201f64:	60051763          	bnez	a0,ffffffffc0202572 <pmm_init+0xa5c>
    assert(page_ref(p) == 2);
ffffffffc0201f68:	000a2703          	lw	a4,0(s4)
ffffffffc0201f6c:	4789                	li	a5,2
ffffffffc0201f6e:	4ef71663          	bne	a4,a5,ffffffffc020245a <pmm_init+0x944>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0201f72:	00004597          	auipc	a1,0x4
ffffffffc0201f76:	e0658593          	addi	a1,a1,-506 # ffffffffc0205d78 <default_pmm_manager+0x608>
ffffffffc0201f7a:	10000513          	li	a0,256
ffffffffc0201f7e:	23f020ef          	jal	ra,ffffffffc02049bc <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0201f82:	100b8593          	addi	a1,s7,256
ffffffffc0201f86:	10000513          	li	a0,256
ffffffffc0201f8a:	245020ef          	jal	ra,ffffffffc02049ce <strcmp>
ffffffffc0201f8e:	4a051663          	bnez	a0,ffffffffc020243a <pmm_init+0x924>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201f92:	00093683          	ld	a3,0(s2)
ffffffffc0201f96:	000abc83          	ld	s9,0(s5)
ffffffffc0201f9a:	00080c37          	lui	s8,0x80
ffffffffc0201f9e:	40da06b3          	sub	a3,s4,a3
ffffffffc0201fa2:	868d                	srai	a3,a3,0x3
ffffffffc0201fa4:	039686b3          	mul	a3,a3,s9
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fa8:	5afd                	li	s5,-1
ffffffffc0201faa:	609c                	ld	a5,0(s1)
ffffffffc0201fac:	00cada93          	srli	s5,s5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fb0:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fb2:	0156f733          	and	a4,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fb6:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201fb8:	16f77363          	bleu	a5,a4,ffffffffc020211e <pmm_init+0x608>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201fbc:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201fc0:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0201fc4:	96be                	add	a3,a3,a5
ffffffffc0201fc6:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fdedb28>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0201fca:	1af020ef          	jal	ra,ffffffffc0204978 <strlen>
ffffffffc0201fce:	44051663          	bnez	a0,ffffffffc020241a <pmm_init+0x904>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201fd2:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0201fd6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201fd8:	000bb783          	ld	a5,0(s7)
ffffffffc0201fdc:	078a                	slli	a5,a5,0x2
ffffffffc0201fde:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201fe0:	12e7fd63          	bleu	a4,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fe4:	418787b3          	sub	a5,a5,s8
ffffffffc0201fe8:	00379693          	slli	a3,a5,0x3
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201fec:	96be                	add	a3,a3,a5
ffffffffc0201fee:	039686b3          	mul	a3,a3,s9
ffffffffc0201ff2:	96e2                	add	a3,a3,s8
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ff4:	0156fab3          	and	s5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ff8:	06b2                	slli	a3,a3,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0201ffa:	12eaf263          	bleu	a4,s5,ffffffffc020211e <pmm_init+0x608>
ffffffffc0201ffe:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202002:	4585                	li	a1,1
ffffffffc0202004:	8552                	mv	a0,s4
ffffffffc0202006:	99b6                	add	s3,s3,a3
ffffffffc0202008:	edeff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020200c:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202010:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202012:	078a                	slli	a5,a5,0x2
ffffffffc0202014:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202016:	10e7f263          	bleu	a4,a5,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc020201a:	fff809b7          	lui	s3,0xfff80
ffffffffc020201e:	97ce                	add	a5,a5,s3
ffffffffc0202020:	00379513          	slli	a0,a5,0x3
ffffffffc0202024:	00093703          	ld	a4,0(s2)
ffffffffc0202028:	97aa                	add	a5,a5,a0
ffffffffc020202a:	00379513          	slli	a0,a5,0x3
    free_page(pde2page(pd0[0]));
ffffffffc020202e:	953a                	add	a0,a0,a4
ffffffffc0202030:	4585                	li	a1,1
ffffffffc0202032:	eb4ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202036:	000bb503          	ld	a0,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc020203a:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020203c:	050a                	slli	a0,a0,0x2
ffffffffc020203e:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202040:	0cf57d63          	bleu	a5,a0,ffffffffc020211a <pmm_init+0x604>
    return &pages[PPN(pa) - nbase];
ffffffffc0202044:	013507b3          	add	a5,a0,s3
ffffffffc0202048:	00379513          	slli	a0,a5,0x3
ffffffffc020204c:	00093703          	ld	a4,0(s2)
ffffffffc0202050:	953e                	add	a0,a0,a5
ffffffffc0202052:	050e                	slli	a0,a0,0x3
    free_page(pde2page(pd1[0]));
ffffffffc0202054:	4585                	li	a1,1
ffffffffc0202056:	953a                	add	a0,a0,a4
ffffffffc0202058:	e8eff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
    boot_pgdir[0] = 0;
ffffffffc020205c:	601c                	ld	a5,0(s0)
ffffffffc020205e:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>

    assert(nr_free_store==nr_free_pages());
ffffffffc0202062:	ecaff0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0202066:	38ab1a63          	bne	s6,a0,ffffffffc02023fa <pmm_init+0x8e4>
}
ffffffffc020206a:	6446                	ld	s0,80(sp)
ffffffffc020206c:	60e6                	ld	ra,88(sp)
ffffffffc020206e:	64a6                	ld	s1,72(sp)
ffffffffc0202070:	6906                	ld	s2,64(sp)
ffffffffc0202072:	79e2                	ld	s3,56(sp)
ffffffffc0202074:	7a42                	ld	s4,48(sp)
ffffffffc0202076:	7aa2                	ld	s5,40(sp)
ffffffffc0202078:	7b02                	ld	s6,32(sp)
ffffffffc020207a:	6be2                	ld	s7,24(sp)
ffffffffc020207c:	6c42                	ld	s8,16(sp)
ffffffffc020207e:	6ca2                	ld	s9,8(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202080:	00004517          	auipc	a0,0x4
ffffffffc0202084:	d7050513          	addi	a0,a0,-656 # ffffffffc0205df0 <default_pmm_manager+0x680>
}
ffffffffc0202088:	6125                	addi	sp,sp,96
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020208a:	834fe06f          	j	ffffffffc02000be <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020208e:	6705                	lui	a4,0x1
ffffffffc0202090:	177d                	addi	a4,a4,-1
ffffffffc0202092:	96ba                	add	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0202094:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202098:	08f77163          	bleu	a5,a4,ffffffffc020211a <pmm_init+0x604>
    pmm_manager->init_memmap(base, n);
ffffffffc020209c:	00043803          	ld	a6,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc02020a0:	9732                	add	a4,a4,a2
ffffffffc02020a2:	00371793          	slli	a5,a4,0x3
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02020a6:	767d                	lui	a2,0xfffff
ffffffffc02020a8:	8ef1                	and	a3,a3,a2
ffffffffc02020aa:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc02020ac:	01083703          	ld	a4,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02020b0:	8d95                	sub	a1,a1,a3
ffffffffc02020b2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02020b4:	81b1                	srli	a1,a1,0xc
ffffffffc02020b6:	953e                	add	a0,a0,a5
ffffffffc02020b8:	9702                	jalr	a4
ffffffffc02020ba:	bead                	j	ffffffffc0201c34 <pmm_init+0x11e>
ffffffffc02020bc:	6008                	ld	a0,0(s0)
ffffffffc02020be:	b5b5                	j	ffffffffc0201f2a <pmm_init+0x414>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02020c0:	86d2                	mv	a3,s4
ffffffffc02020c2:	00003617          	auipc	a2,0x3
ffffffffc02020c6:	6fe60613          	addi	a2,a2,1790 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc02020ca:	1c500593          	li	a1,453
ffffffffc02020ce:	00003517          	auipc	a0,0x3
ffffffffc02020d2:	71a50513          	addi	a0,a0,1818 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02020d6:	a9efe0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02020da:	00004697          	auipc	a3,0x4
ffffffffc02020de:	b8668693          	addi	a3,a3,-1146 # ffffffffc0205c60 <default_pmm_manager+0x4f0>
ffffffffc02020e2:	00003617          	auipc	a2,0x3
ffffffffc02020e6:	2f660613          	addi	a2,a2,758 # ffffffffc02053d8 <commands+0x870>
ffffffffc02020ea:	1c500593          	li	a1,453
ffffffffc02020ee:	00003517          	auipc	a0,0x3
ffffffffc02020f2:	6fa50513          	addi	a0,a0,1786 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02020f6:	a7efe0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02020fa:	00004697          	auipc	a3,0x4
ffffffffc02020fe:	ba668693          	addi	a3,a3,-1114 # ffffffffc0205ca0 <default_pmm_manager+0x530>
ffffffffc0202102:	00003617          	auipc	a2,0x3
ffffffffc0202106:	2d660613          	addi	a2,a2,726 # ffffffffc02053d8 <commands+0x870>
ffffffffc020210a:	1c600593          	li	a1,454
ffffffffc020210e:	00003517          	auipc	a0,0x3
ffffffffc0202112:	6da50513          	addi	a0,a0,1754 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202116:	a5efe0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc020211a:	d28ff0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020211e:	00003617          	auipc	a2,0x3
ffffffffc0202122:	6a260613          	addi	a2,a2,1698 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc0202126:	06a00593          	li	a1,106
ffffffffc020212a:	00003517          	auipc	a0,0x3
ffffffffc020212e:	72e50513          	addi	a0,a0,1838 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc0202132:	a42fe0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202136:	00004617          	auipc	a2,0x4
ffffffffc020213a:	8fa60613          	addi	a2,a2,-1798 # ffffffffc0205a30 <default_pmm_manager+0x2c0>
ffffffffc020213e:	07000593          	li	a1,112
ffffffffc0202142:	00003517          	auipc	a0,0x3
ffffffffc0202146:	71650513          	addi	a0,a0,1814 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc020214a:	a2afe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020214e:	00004697          	auipc	a3,0x4
ffffffffc0202152:	82268693          	addi	a3,a3,-2014 # ffffffffc0205970 <default_pmm_manager+0x200>
ffffffffc0202156:	00003617          	auipc	a2,0x3
ffffffffc020215a:	28260613          	addi	a2,a2,642 # ffffffffc02053d8 <commands+0x870>
ffffffffc020215e:	18b00593          	li	a1,395
ffffffffc0202162:	00003517          	auipc	a0,0x3
ffffffffc0202166:	68650513          	addi	a0,a0,1670 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020216a:	a0afe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc020216e:	00004697          	auipc	a3,0x4
ffffffffc0202172:	83a68693          	addi	a3,a3,-1990 # ffffffffc02059a8 <default_pmm_manager+0x238>
ffffffffc0202176:	00003617          	auipc	a2,0x3
ffffffffc020217a:	26260613          	addi	a2,a2,610 # ffffffffc02053d8 <commands+0x870>
ffffffffc020217e:	18c00593          	li	a1,396
ffffffffc0202182:	00003517          	auipc	a0,0x3
ffffffffc0202186:	66650513          	addi	a0,a0,1638 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020218a:	9eafe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020218e:	00004697          	auipc	a3,0x4
ffffffffc0202192:	a9268693          	addi	a3,a3,-1390 # ffffffffc0205c20 <default_pmm_manager+0x4b0>
ffffffffc0202196:	00003617          	auipc	a2,0x3
ffffffffc020219a:	24260613          	addi	a2,a2,578 # ffffffffc02053d8 <commands+0x870>
ffffffffc020219e:	1b800593          	li	a1,440
ffffffffc02021a2:	00003517          	auipc	a0,0x3
ffffffffc02021a6:	64650513          	addi	a0,a0,1606 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02021aa:	9cafe0ef          	jal	ra,ffffffffc0200374 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021ae:	00003617          	auipc	a2,0x3
ffffffffc02021b2:	75a60613          	addi	a2,a2,1882 # ffffffffc0205908 <default_pmm_manager+0x198>
ffffffffc02021b6:	07700593          	li	a1,119
ffffffffc02021ba:	00003517          	auipc	a0,0x3
ffffffffc02021be:	62e50513          	addi	a0,a0,1582 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02021c2:	9b2fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02021c6:	00004697          	auipc	a3,0x4
ffffffffc02021ca:	83a68693          	addi	a3,a3,-1990 # ffffffffc0205a00 <default_pmm_manager+0x290>
ffffffffc02021ce:	00003617          	auipc	a2,0x3
ffffffffc02021d2:	20a60613          	addi	a2,a2,522 # ffffffffc02053d8 <commands+0x870>
ffffffffc02021d6:	19200593          	li	a1,402
ffffffffc02021da:	00003517          	auipc	a0,0x3
ffffffffc02021de:	60e50513          	addi	a0,a0,1550 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02021e2:	992fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02021e6:	00003697          	auipc	a3,0x3
ffffffffc02021ea:	7ea68693          	addi	a3,a3,2026 # ffffffffc02059d0 <default_pmm_manager+0x260>
ffffffffc02021ee:	00003617          	auipc	a2,0x3
ffffffffc02021f2:	1ea60613          	addi	a2,a2,490 # ffffffffc02053d8 <commands+0x870>
ffffffffc02021f6:	19000593          	li	a1,400
ffffffffc02021fa:	00003517          	auipc	a0,0x3
ffffffffc02021fe:	5ee50513          	addi	a0,a0,1518 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202202:	972fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202206:	00004697          	auipc	a3,0x4
ffffffffc020220a:	91268693          	addi	a3,a3,-1774 # ffffffffc0205b18 <default_pmm_manager+0x3a8>
ffffffffc020220e:	00003617          	auipc	a2,0x3
ffffffffc0202212:	1ca60613          	addi	a2,a2,458 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202216:	19d00593          	li	a1,413
ffffffffc020221a:	00003517          	auipc	a0,0x3
ffffffffc020221e:	5ce50513          	addi	a0,a0,1486 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202222:	952fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202226:	00004697          	auipc	a3,0x4
ffffffffc020222a:	8c268693          	addi	a3,a3,-1854 # ffffffffc0205ae8 <default_pmm_manager+0x378>
ffffffffc020222e:	00003617          	auipc	a2,0x3
ffffffffc0202232:	1aa60613          	addi	a2,a2,426 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202236:	19c00593          	li	a1,412
ffffffffc020223a:	00003517          	auipc	a0,0x3
ffffffffc020223e:	5ae50513          	addi	a0,a0,1454 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202242:	932fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202246:	00004697          	auipc	a3,0x4
ffffffffc020224a:	86a68693          	addi	a3,a3,-1942 # ffffffffc0205ab0 <default_pmm_manager+0x340>
ffffffffc020224e:	00003617          	auipc	a2,0x3
ffffffffc0202252:	18a60613          	addi	a2,a2,394 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202256:	19b00593          	li	a1,411
ffffffffc020225a:	00003517          	auipc	a0,0x3
ffffffffc020225e:	58e50513          	addi	a0,a0,1422 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202262:	912fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202266:	00004697          	auipc	a3,0x4
ffffffffc020226a:	82268693          	addi	a3,a3,-2014 # ffffffffc0205a88 <default_pmm_manager+0x318>
ffffffffc020226e:	00003617          	auipc	a2,0x3
ffffffffc0202272:	16a60613          	addi	a2,a2,362 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202276:	19800593          	li	a1,408
ffffffffc020227a:	00003517          	auipc	a0,0x3
ffffffffc020227e:	56e50513          	addi	a0,a0,1390 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202282:	8f2fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202286:	86da                	mv	a3,s6
ffffffffc0202288:	00003617          	auipc	a2,0x3
ffffffffc020228c:	53860613          	addi	a2,a2,1336 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc0202290:	19700593          	li	a1,407
ffffffffc0202294:	00003517          	auipc	a0,0x3
ffffffffc0202298:	55450513          	addi	a0,a0,1364 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020229c:	8d8fe0ef          	jal	ra,ffffffffc0200374 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02022a0:	86be                	mv	a3,a5
ffffffffc02022a2:	00003617          	auipc	a2,0x3
ffffffffc02022a6:	51e60613          	addi	a2,a2,1310 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc02022aa:	19600593          	li	a1,406
ffffffffc02022ae:	00003517          	auipc	a0,0x3
ffffffffc02022b2:	53a50513          	addi	a0,a0,1338 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02022b6:	8befe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02022ba:	00003697          	auipc	a3,0x3
ffffffffc02022be:	7b668693          	addi	a3,a3,1974 # ffffffffc0205a70 <default_pmm_manager+0x300>
ffffffffc02022c2:	00003617          	auipc	a2,0x3
ffffffffc02022c6:	11660613          	addi	a2,a2,278 # ffffffffc02053d8 <commands+0x870>
ffffffffc02022ca:	19400593          	li	a1,404
ffffffffc02022ce:	00003517          	auipc	a0,0x3
ffffffffc02022d2:	51a50513          	addi	a0,a0,1306 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02022d6:	89efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02022da:	00003697          	auipc	a3,0x3
ffffffffc02022de:	77e68693          	addi	a3,a3,1918 # ffffffffc0205a58 <default_pmm_manager+0x2e8>
ffffffffc02022e2:	00003617          	auipc	a2,0x3
ffffffffc02022e6:	0f660613          	addi	a2,a2,246 # ffffffffc02053d8 <commands+0x870>
ffffffffc02022ea:	19300593          	li	a1,403
ffffffffc02022ee:	00003517          	auipc	a0,0x3
ffffffffc02022f2:	4fa50513          	addi	a0,a0,1274 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02022f6:	87efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02022fa:	00003697          	auipc	a3,0x3
ffffffffc02022fe:	75e68693          	addi	a3,a3,1886 # ffffffffc0205a58 <default_pmm_manager+0x2e8>
ffffffffc0202302:	00003617          	auipc	a2,0x3
ffffffffc0202306:	0d660613          	addi	a2,a2,214 # ffffffffc02053d8 <commands+0x870>
ffffffffc020230a:	1a600593          	li	a1,422
ffffffffc020230e:	00003517          	auipc	a0,0x3
ffffffffc0202312:	4da50513          	addi	a0,a0,1242 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202316:	85efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020231a:	00003697          	auipc	a3,0x3
ffffffffc020231e:	7ce68693          	addi	a3,a3,1998 # ffffffffc0205ae8 <default_pmm_manager+0x378>
ffffffffc0202322:	00003617          	auipc	a2,0x3
ffffffffc0202326:	0b660613          	addi	a2,a2,182 # ffffffffc02053d8 <commands+0x870>
ffffffffc020232a:	1a500593          	li	a1,421
ffffffffc020232e:	00003517          	auipc	a0,0x3
ffffffffc0202332:	4ba50513          	addi	a0,a0,1210 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202336:	83efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020233a:	00004697          	auipc	a3,0x4
ffffffffc020233e:	87668693          	addi	a3,a3,-1930 # ffffffffc0205bb0 <default_pmm_manager+0x440>
ffffffffc0202342:	00003617          	auipc	a2,0x3
ffffffffc0202346:	09660613          	addi	a2,a2,150 # ffffffffc02053d8 <commands+0x870>
ffffffffc020234a:	1a400593          	li	a1,420
ffffffffc020234e:	00003517          	auipc	a0,0x3
ffffffffc0202352:	49a50513          	addi	a0,a0,1178 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202356:	81efe0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020235a:	00004697          	auipc	a3,0x4
ffffffffc020235e:	83e68693          	addi	a3,a3,-1986 # ffffffffc0205b98 <default_pmm_manager+0x428>
ffffffffc0202362:	00003617          	auipc	a2,0x3
ffffffffc0202366:	07660613          	addi	a2,a2,118 # ffffffffc02053d8 <commands+0x870>
ffffffffc020236a:	1a300593          	li	a1,419
ffffffffc020236e:	00003517          	auipc	a0,0x3
ffffffffc0202372:	47a50513          	addi	a0,a0,1146 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202376:	ffffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc020237a:	00003697          	auipc	a3,0x3
ffffffffc020237e:	7ee68693          	addi	a3,a3,2030 # ffffffffc0205b68 <default_pmm_manager+0x3f8>
ffffffffc0202382:	00003617          	auipc	a2,0x3
ffffffffc0202386:	05660613          	addi	a2,a2,86 # ffffffffc02053d8 <commands+0x870>
ffffffffc020238a:	1a200593          	li	a1,418
ffffffffc020238e:	00003517          	auipc	a0,0x3
ffffffffc0202392:	45a50513          	addi	a0,a0,1114 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202396:	fdffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc020239a:	00003697          	auipc	a3,0x3
ffffffffc020239e:	7b668693          	addi	a3,a3,1974 # ffffffffc0205b50 <default_pmm_manager+0x3e0>
ffffffffc02023a2:	00003617          	auipc	a2,0x3
ffffffffc02023a6:	03660613          	addi	a2,a2,54 # ffffffffc02053d8 <commands+0x870>
ffffffffc02023aa:	1a000593          	li	a1,416
ffffffffc02023ae:	00003517          	auipc	a0,0x3
ffffffffc02023b2:	43a50513          	addi	a0,a0,1082 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02023b6:	fbffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02023ba:	00003697          	auipc	a3,0x3
ffffffffc02023be:	77e68693          	addi	a3,a3,1918 # ffffffffc0205b38 <default_pmm_manager+0x3c8>
ffffffffc02023c2:	00003617          	auipc	a2,0x3
ffffffffc02023c6:	01660613          	addi	a2,a2,22 # ffffffffc02053d8 <commands+0x870>
ffffffffc02023ca:	19f00593          	li	a1,415
ffffffffc02023ce:	00003517          	auipc	a0,0x3
ffffffffc02023d2:	41a50513          	addi	a0,a0,1050 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02023d6:	f9ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02023da:	00003697          	auipc	a3,0x3
ffffffffc02023de:	74e68693          	addi	a3,a3,1870 # ffffffffc0205b28 <default_pmm_manager+0x3b8>
ffffffffc02023e2:	00003617          	auipc	a2,0x3
ffffffffc02023e6:	ff660613          	addi	a2,a2,-10 # ffffffffc02053d8 <commands+0x870>
ffffffffc02023ea:	19e00593          	li	a1,414
ffffffffc02023ee:	00003517          	auipc	a0,0x3
ffffffffc02023f2:	3fa50513          	addi	a0,a0,1018 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02023f6:	f7ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc02023fa:	00004697          	auipc	a3,0x4
ffffffffc02023fe:	82668693          	addi	a3,a3,-2010 # ffffffffc0205c20 <default_pmm_manager+0x4b0>
ffffffffc0202402:	00003617          	auipc	a2,0x3
ffffffffc0202406:	fd660613          	addi	a2,a2,-42 # ffffffffc02053d8 <commands+0x870>
ffffffffc020240a:	1e000593          	li	a1,480
ffffffffc020240e:	00003517          	auipc	a0,0x3
ffffffffc0202412:	3da50513          	addi	a0,a0,986 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202416:	f5ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020241a:	00004697          	auipc	a3,0x4
ffffffffc020241e:	9ae68693          	addi	a3,a3,-1618 # ffffffffc0205dc8 <default_pmm_manager+0x658>
ffffffffc0202422:	00003617          	auipc	a2,0x3
ffffffffc0202426:	fb660613          	addi	a2,a2,-74 # ffffffffc02053d8 <commands+0x870>
ffffffffc020242a:	1d800593          	li	a1,472
ffffffffc020242e:	00003517          	auipc	a0,0x3
ffffffffc0202432:	3ba50513          	addi	a0,a0,954 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202436:	f3ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020243a:	00004697          	auipc	a3,0x4
ffffffffc020243e:	95668693          	addi	a3,a3,-1706 # ffffffffc0205d90 <default_pmm_manager+0x620>
ffffffffc0202442:	00003617          	auipc	a2,0x3
ffffffffc0202446:	f9660613          	addi	a2,a2,-106 # ffffffffc02053d8 <commands+0x870>
ffffffffc020244a:	1d500593          	li	a1,469
ffffffffc020244e:	00003517          	auipc	a0,0x3
ffffffffc0202452:	39a50513          	addi	a0,a0,922 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202456:	f1ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020245a:	00004697          	auipc	a3,0x4
ffffffffc020245e:	90668693          	addi	a3,a3,-1786 # ffffffffc0205d60 <default_pmm_manager+0x5f0>
ffffffffc0202462:	00003617          	auipc	a2,0x3
ffffffffc0202466:	f7660613          	addi	a2,a2,-138 # ffffffffc02053d8 <commands+0x870>
ffffffffc020246a:	1d100593          	li	a1,465
ffffffffc020246e:	00003517          	auipc	a0,0x3
ffffffffc0202472:	37a50513          	addi	a0,a0,890 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202476:	efffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020247a:	00003697          	auipc	a3,0x3
ffffffffc020247e:	76668693          	addi	a3,a3,1894 # ffffffffc0205be0 <default_pmm_manager+0x470>
ffffffffc0202482:	00003617          	auipc	a2,0x3
ffffffffc0202486:	f5660613          	addi	a2,a2,-170 # ffffffffc02053d8 <commands+0x870>
ffffffffc020248a:	1ae00593          	li	a1,430
ffffffffc020248e:	00003517          	auipc	a0,0x3
ffffffffc0202492:	35a50513          	addi	a0,a0,858 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202496:	edffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020249a:	00003697          	auipc	a3,0x3
ffffffffc020249e:	71668693          	addi	a3,a3,1814 # ffffffffc0205bb0 <default_pmm_manager+0x440>
ffffffffc02024a2:	00003617          	auipc	a2,0x3
ffffffffc02024a6:	f3660613          	addi	a2,a2,-202 # ffffffffc02053d8 <commands+0x870>
ffffffffc02024aa:	1ab00593          	li	a1,427
ffffffffc02024ae:	00003517          	auipc	a0,0x3
ffffffffc02024b2:	33a50513          	addi	a0,a0,826 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02024b6:	ebffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02024ba:	00003697          	auipc	a3,0x3
ffffffffc02024be:	5b668693          	addi	a3,a3,1462 # ffffffffc0205a70 <default_pmm_manager+0x300>
ffffffffc02024c2:	00003617          	auipc	a2,0x3
ffffffffc02024c6:	f1660613          	addi	a2,a2,-234 # ffffffffc02053d8 <commands+0x870>
ffffffffc02024ca:	1aa00593          	li	a1,426
ffffffffc02024ce:	00003517          	auipc	a0,0x3
ffffffffc02024d2:	31a50513          	addi	a0,a0,794 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02024d6:	e9ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02024da:	00003697          	auipc	a3,0x3
ffffffffc02024de:	6ee68693          	addi	a3,a3,1774 # ffffffffc0205bc8 <default_pmm_manager+0x458>
ffffffffc02024e2:	00003617          	auipc	a2,0x3
ffffffffc02024e6:	ef660613          	addi	a2,a2,-266 # ffffffffc02053d8 <commands+0x870>
ffffffffc02024ea:	1a700593          	li	a1,423
ffffffffc02024ee:	00003517          	auipc	a0,0x3
ffffffffc02024f2:	2fa50513          	addi	a0,a0,762 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02024f6:	e7ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02024fa:	00003697          	auipc	a3,0x3
ffffffffc02024fe:	6fe68693          	addi	a3,a3,1790 # ffffffffc0205bf8 <default_pmm_manager+0x488>
ffffffffc0202502:	00003617          	auipc	a2,0x3
ffffffffc0202506:	ed660613          	addi	a2,a2,-298 # ffffffffc02053d8 <commands+0x870>
ffffffffc020250a:	1b100593          	li	a1,433
ffffffffc020250e:	00003517          	auipc	a0,0x3
ffffffffc0202512:	2da50513          	addi	a0,a0,730 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202516:	e5ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020251a:	00003697          	auipc	a3,0x3
ffffffffc020251e:	69668693          	addi	a3,a3,1686 # ffffffffc0205bb0 <default_pmm_manager+0x440>
ffffffffc0202522:	00003617          	auipc	a2,0x3
ffffffffc0202526:	eb660613          	addi	a2,a2,-330 # ffffffffc02053d8 <commands+0x870>
ffffffffc020252a:	1af00593          	li	a1,431
ffffffffc020252e:	00003517          	auipc	a0,0x3
ffffffffc0202532:	2ba50513          	addi	a0,a0,698 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202536:	e3ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020253a:	00003697          	auipc	a3,0x3
ffffffffc020253e:	41668693          	addi	a3,a3,1046 # ffffffffc0205950 <default_pmm_manager+0x1e0>
ffffffffc0202542:	00003617          	auipc	a2,0x3
ffffffffc0202546:	e9660613          	addi	a2,a2,-362 # ffffffffc02053d8 <commands+0x870>
ffffffffc020254a:	18a00593          	li	a1,394
ffffffffc020254e:	00003517          	auipc	a0,0x3
ffffffffc0202552:	29a50513          	addi	a0,a0,666 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202556:	e1ffd0ef          	jal	ra,ffffffffc0200374 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020255a:	00003617          	auipc	a2,0x3
ffffffffc020255e:	3ae60613          	addi	a2,a2,942 # ffffffffc0205908 <default_pmm_manager+0x198>
ffffffffc0202562:	0bd00593          	li	a1,189
ffffffffc0202566:	00003517          	auipc	a0,0x3
ffffffffc020256a:	28250513          	addi	a0,a0,642 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020256e:	e07fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202572:	00003697          	auipc	a3,0x3
ffffffffc0202576:	7ae68693          	addi	a3,a3,1966 # ffffffffc0205d20 <default_pmm_manager+0x5b0>
ffffffffc020257a:	00003617          	auipc	a2,0x3
ffffffffc020257e:	e5e60613          	addi	a2,a2,-418 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202582:	1d000593          	li	a1,464
ffffffffc0202586:	00003517          	auipc	a0,0x3
ffffffffc020258a:	26250513          	addi	a0,a0,610 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020258e:	de7fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202592:	00003697          	auipc	a3,0x3
ffffffffc0202596:	77668693          	addi	a3,a3,1910 # ffffffffc0205d08 <default_pmm_manager+0x598>
ffffffffc020259a:	00003617          	auipc	a2,0x3
ffffffffc020259e:	e3e60613          	addi	a2,a2,-450 # ffffffffc02053d8 <commands+0x870>
ffffffffc02025a2:	1cf00593          	li	a1,463
ffffffffc02025a6:	00003517          	auipc	a0,0x3
ffffffffc02025aa:	24250513          	addi	a0,a0,578 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02025ae:	dc7fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02025b2:	00003697          	auipc	a3,0x3
ffffffffc02025b6:	71e68693          	addi	a3,a3,1822 # ffffffffc0205cd0 <default_pmm_manager+0x560>
ffffffffc02025ba:	00003617          	auipc	a2,0x3
ffffffffc02025be:	e1e60613          	addi	a2,a2,-482 # ffffffffc02053d8 <commands+0x870>
ffffffffc02025c2:	1ce00593          	li	a1,462
ffffffffc02025c6:	00003517          	auipc	a0,0x3
ffffffffc02025ca:	22250513          	addi	a0,a0,546 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02025ce:	da7fd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02025d2:	00003697          	auipc	a3,0x3
ffffffffc02025d6:	6e668693          	addi	a3,a3,1766 # ffffffffc0205cb8 <default_pmm_manager+0x548>
ffffffffc02025da:	00003617          	auipc	a2,0x3
ffffffffc02025de:	dfe60613          	addi	a2,a2,-514 # ffffffffc02053d8 <commands+0x870>
ffffffffc02025e2:	1ca00593          	li	a1,458
ffffffffc02025e6:	00003517          	auipc	a0,0x3
ffffffffc02025ea:	20250513          	addi	a0,a0,514 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02025ee:	d87fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02025f2 <tlb_invalidate>:
static inline void flush_tlb() { asm volatile("sfence.vma"); }
ffffffffc02025f2:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc02025f6:	8082                	ret

ffffffffc02025f8 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02025f8:	7179                	addi	sp,sp,-48
ffffffffc02025fa:	e84a                	sd	s2,16(sp)
ffffffffc02025fc:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02025fe:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0202600:	f022                	sd	s0,32(sp)
ffffffffc0202602:	ec26                	sd	s1,24(sp)
ffffffffc0202604:	e44e                	sd	s3,8(sp)
ffffffffc0202606:	f406                	sd	ra,40(sp)
ffffffffc0202608:	84ae                	mv	s1,a1
ffffffffc020260a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020260c:	852ff0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0202610:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0202612:	cd19                	beqz	a0,ffffffffc0202630 <pgdir_alloc_page+0x38>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0202614:	85aa                	mv	a1,a0
ffffffffc0202616:	86ce                	mv	a3,s3
ffffffffc0202618:	8626                	mv	a2,s1
ffffffffc020261a:	854a                	mv	a0,s2
ffffffffc020261c:	c28ff0ef          	jal	ra,ffffffffc0201a44 <page_insert>
ffffffffc0202620:	ed39                	bnez	a0,ffffffffc020267e <pgdir_alloc_page+0x86>
        if (swap_init_ok) {
ffffffffc0202622:	0000f797          	auipc	a5,0xf
ffffffffc0202626:	e8678793          	addi	a5,a5,-378 # ffffffffc02114a8 <swap_init_ok>
ffffffffc020262a:	439c                	lw	a5,0(a5)
ffffffffc020262c:	2781                	sext.w	a5,a5
ffffffffc020262e:	eb89                	bnez	a5,ffffffffc0202640 <pgdir_alloc_page+0x48>
}
ffffffffc0202630:	8522                	mv	a0,s0
ffffffffc0202632:	70a2                	ld	ra,40(sp)
ffffffffc0202634:	7402                	ld	s0,32(sp)
ffffffffc0202636:	64e2                	ld	s1,24(sp)
ffffffffc0202638:	6942                	ld	s2,16(sp)
ffffffffc020263a:	69a2                	ld	s3,8(sp)
ffffffffc020263c:	6145                	addi	sp,sp,48
ffffffffc020263e:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0202640:	0000f797          	auipc	a5,0xf
ffffffffc0202644:	f9078793          	addi	a5,a5,-112 # ffffffffc02115d0 <check_mm_struct>
ffffffffc0202648:	6388                	ld	a0,0(a5)
ffffffffc020264a:	4681                	li	a3,0
ffffffffc020264c:	8622                	mv	a2,s0
ffffffffc020264e:	85a6                	mv	a1,s1
ffffffffc0202650:	1cc000ef          	jal	ra,ffffffffc020281c <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0202654:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0202656:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1);
ffffffffc0202658:	4785                	li	a5,1
ffffffffc020265a:	fcf70be3          	beq	a4,a5,ffffffffc0202630 <pgdir_alloc_page+0x38>
ffffffffc020265e:	00003697          	auipc	a3,0x3
ffffffffc0202662:	20a68693          	addi	a3,a3,522 # ffffffffc0205868 <default_pmm_manager+0xf8>
ffffffffc0202666:	00003617          	auipc	a2,0x3
ffffffffc020266a:	d7260613          	addi	a2,a2,-654 # ffffffffc02053d8 <commands+0x870>
ffffffffc020266e:	17200593          	li	a1,370
ffffffffc0202672:	00003517          	auipc	a0,0x3
ffffffffc0202676:	17650513          	addi	a0,a0,374 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020267a:	cfbfd0ef          	jal	ra,ffffffffc0200374 <__panic>
            free_page(page);
ffffffffc020267e:	8522                	mv	a0,s0
ffffffffc0202680:	4585                	li	a1,1
ffffffffc0202682:	864ff0ef          	jal	ra,ffffffffc02016e6 <free_pages>
            return NULL;
ffffffffc0202686:	4401                	li	s0,0
ffffffffc0202688:	b765                	j	ffffffffc0202630 <pgdir_alloc_page+0x38>

ffffffffc020268a <kmalloc>:
}

void *kmalloc(size_t n) {
ffffffffc020268a:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020268c:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc020268e:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202690:	fff50713          	addi	a4,a0,-1
ffffffffc0202694:	17f9                	addi	a5,a5,-2
ffffffffc0202696:	04e7ee63          	bltu	a5,a4,ffffffffc02026f2 <kmalloc+0x68>
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc020269a:	6785                	lui	a5,0x1
ffffffffc020269c:	17fd                	addi	a5,a5,-1
ffffffffc020269e:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages);
ffffffffc02026a0:	8131                	srli	a0,a0,0xc
ffffffffc02026a2:	fbdfe0ef          	jal	ra,ffffffffc020165e <alloc_pages>
    assert(base != NULL);
ffffffffc02026a6:	c159                	beqz	a0,ffffffffc020272c <kmalloc+0xa2>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026a8:	0000f797          	auipc	a5,0xf
ffffffffc02026ac:	e4078793          	addi	a5,a5,-448 # ffffffffc02114e8 <pages>
ffffffffc02026b0:	639c                	ld	a5,0(a5)
ffffffffc02026b2:	8d1d                	sub	a0,a0,a5
ffffffffc02026b4:	00003797          	auipc	a5,0x3
ffffffffc02026b8:	d0c78793          	addi	a5,a5,-756 # ffffffffc02053c0 <commands+0x858>
ffffffffc02026bc:	6394                	ld	a3,0(a5)
ffffffffc02026be:	850d                	srai	a0,a0,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026c0:	0000f797          	auipc	a5,0xf
ffffffffc02026c4:	dd878793          	addi	a5,a5,-552 # ffffffffc0211498 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026c8:	02d50533          	mul	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026cc:	6398                	ld	a4,0(a5)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026ce:	000806b7          	lui	a3,0x80
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026d2:	57fd                	li	a5,-1
ffffffffc02026d4:	83b1                	srli	a5,a5,0xc
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02026d6:	9536                	add	a0,a0,a3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026d8:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02026da:	0532                	slli	a0,a0,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02026dc:	02e7fb63          	bleu	a4,a5,ffffffffc0202712 <kmalloc+0x88>
ffffffffc02026e0:	0000f797          	auipc	a5,0xf
ffffffffc02026e4:	df878793          	addi	a5,a5,-520 # ffffffffc02114d8 <va_pa_offset>
ffffffffc02026e8:	639c                	ld	a5,0(a5)
    ptr = page2kva(base);
    return ptr;
}
ffffffffc02026ea:	60a2                	ld	ra,8(sp)
ffffffffc02026ec:	953e                	add	a0,a0,a5
ffffffffc02026ee:	0141                	addi	sp,sp,16
ffffffffc02026f0:	8082                	ret
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02026f2:	00003697          	auipc	a3,0x3
ffffffffc02026f6:	11668693          	addi	a3,a3,278 # ffffffffc0205808 <default_pmm_manager+0x98>
ffffffffc02026fa:	00003617          	auipc	a2,0x3
ffffffffc02026fe:	cde60613          	addi	a2,a2,-802 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202702:	1e800593          	li	a1,488
ffffffffc0202706:	00003517          	auipc	a0,0x3
ffffffffc020270a:	0e250513          	addi	a0,a0,226 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc020270e:	c67fd0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0202712:	86aa                	mv	a3,a0
ffffffffc0202714:	00003617          	auipc	a2,0x3
ffffffffc0202718:	0ac60613          	addi	a2,a2,172 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc020271c:	06a00593          	li	a1,106
ffffffffc0202720:	00003517          	auipc	a0,0x3
ffffffffc0202724:	13850513          	addi	a0,a0,312 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc0202728:	c4dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(base != NULL);
ffffffffc020272c:	00003697          	auipc	a3,0x3
ffffffffc0202730:	0fc68693          	addi	a3,a3,252 # ffffffffc0205828 <default_pmm_manager+0xb8>
ffffffffc0202734:	00003617          	auipc	a2,0x3
ffffffffc0202738:	ca460613          	addi	a2,a2,-860 # ffffffffc02053d8 <commands+0x870>
ffffffffc020273c:	1eb00593          	li	a1,491
ffffffffc0202740:	00003517          	auipc	a0,0x3
ffffffffc0202744:	0a850513          	addi	a0,a0,168 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202748:	c2dfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020274c <kfree>:

void kfree(void *ptr, size_t n) {
ffffffffc020274c:	1141                	addi	sp,sp,-16
    assert(n > 0 && n < 1024 * 0124);
ffffffffc020274e:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc0202750:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124);
ffffffffc0202752:	fff58713          	addi	a4,a1,-1
ffffffffc0202756:	17f9                	addi	a5,a5,-2
ffffffffc0202758:	04e7eb63          	bltu	a5,a4,ffffffffc02027ae <kfree+0x62>
    assert(ptr != NULL);
ffffffffc020275c:	c941                	beqz	a0,ffffffffc02027ec <kfree+0xa0>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
ffffffffc020275e:	6785                	lui	a5,0x1
ffffffffc0202760:	17fd                	addi	a5,a5,-1
ffffffffc0202762:	95be                	add	a1,a1,a5
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202764:	c02007b7          	lui	a5,0xc0200
ffffffffc0202768:	81b1                	srli	a1,a1,0xc
ffffffffc020276a:	06f56463          	bltu	a0,a5,ffffffffc02027d2 <kfree+0x86>
ffffffffc020276e:	0000f797          	auipc	a5,0xf
ffffffffc0202772:	d6a78793          	addi	a5,a5,-662 # ffffffffc02114d8 <va_pa_offset>
ffffffffc0202776:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0202778:	0000f717          	auipc	a4,0xf
ffffffffc020277c:	d2070713          	addi	a4,a4,-736 # ffffffffc0211498 <npage>
ffffffffc0202780:	6318                	ld	a4,0(a4)
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc0202782:	40f507b3          	sub	a5,a0,a5
    if (PPN(pa) >= npage) {
ffffffffc0202786:	83b1                	srli	a5,a5,0xc
ffffffffc0202788:	04e7f363          	bleu	a4,a5,ffffffffc02027ce <kfree+0x82>
    return &pages[PPN(pa) - nbase];
ffffffffc020278c:	fff80537          	lui	a0,0xfff80
ffffffffc0202790:	97aa                	add	a5,a5,a0
ffffffffc0202792:	0000f697          	auipc	a3,0xf
ffffffffc0202796:	d5668693          	addi	a3,a3,-682 # ffffffffc02114e8 <pages>
ffffffffc020279a:	6288                	ld	a0,0(a3)
ffffffffc020279c:	00379713          	slli	a4,a5,0x3
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
ffffffffc02027a0:	60a2                	ld	ra,8(sp)
ffffffffc02027a2:	97ba                	add	a5,a5,a4
ffffffffc02027a4:	078e                	slli	a5,a5,0x3
    free_pages(base, num_pages);
ffffffffc02027a6:	953e                	add	a0,a0,a5
}
ffffffffc02027a8:	0141                	addi	sp,sp,16
    free_pages(base, num_pages);
ffffffffc02027aa:	f3dfe06f          	j	ffffffffc02016e6 <free_pages>
    assert(n > 0 && n < 1024 * 0124);
ffffffffc02027ae:	00003697          	auipc	a3,0x3
ffffffffc02027b2:	05a68693          	addi	a3,a3,90 # ffffffffc0205808 <default_pmm_manager+0x98>
ffffffffc02027b6:	00003617          	auipc	a2,0x3
ffffffffc02027ba:	c2260613          	addi	a2,a2,-990 # ffffffffc02053d8 <commands+0x870>
ffffffffc02027be:	1f100593          	li	a1,497
ffffffffc02027c2:	00003517          	auipc	a0,0x3
ffffffffc02027c6:	02650513          	addi	a0,a0,38 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc02027ca:	babfd0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02027ce:	e75fe0ef          	jal	ra,ffffffffc0201642 <pa2page.part.4>
static inline struct Page *kva2page(void *kva) { return pa2page(PADDR(kva)); }
ffffffffc02027d2:	86aa                	mv	a3,a0
ffffffffc02027d4:	00003617          	auipc	a2,0x3
ffffffffc02027d8:	13460613          	addi	a2,a2,308 # ffffffffc0205908 <default_pmm_manager+0x198>
ffffffffc02027dc:	06c00593          	li	a1,108
ffffffffc02027e0:	00003517          	auipc	a0,0x3
ffffffffc02027e4:	07850513          	addi	a0,a0,120 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc02027e8:	b8dfd0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(ptr != NULL);
ffffffffc02027ec:	00003697          	auipc	a3,0x3
ffffffffc02027f0:	00c68693          	addi	a3,a3,12 # ffffffffc02057f8 <default_pmm_manager+0x88>
ffffffffc02027f4:	00003617          	auipc	a2,0x3
ffffffffc02027f8:	be460613          	addi	a2,a2,-1052 # ffffffffc02053d8 <commands+0x870>
ffffffffc02027fc:	1f200593          	li	a1,498
ffffffffc0202800:	00003517          	auipc	a0,0x3
ffffffffc0202804:	fe850513          	addi	a0,a0,-24 # ffffffffc02057e8 <default_pmm_manager+0x78>
ffffffffc0202808:	b6dfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020280c <swap_init_mm>:
}

int
swap_init_mm(struct mm_struct *mm)
{
     return sm->init_mm(mm);
ffffffffc020280c:	0000f797          	auipc	a5,0xf
ffffffffc0202810:	c9478793          	addi	a5,a5,-876 # ffffffffc02114a0 <sm>
ffffffffc0202814:	639c                	ld	a5,0(a5)
ffffffffc0202816:	0107b303          	ld	t1,16(a5)
ffffffffc020281a:	8302                	jr	t1

ffffffffc020281c <swap_map_swappable>:
}

int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc020281c:	0000f797          	auipc	a5,0xf
ffffffffc0202820:	c8478793          	addi	a5,a5,-892 # ffffffffc02114a0 <sm>
ffffffffc0202824:	639c                	ld	a5,0(a5)
ffffffffc0202826:	0207b303          	ld	t1,32(a5)
ffffffffc020282a:	8302                	jr	t1

ffffffffc020282c <swap_out>:

volatile unsigned int swap_out_num=0;

int
swap_out(struct mm_struct *mm, int n, int in_tick)
{
ffffffffc020282c:	711d                	addi	sp,sp,-96
ffffffffc020282e:	ec86                	sd	ra,88(sp)
ffffffffc0202830:	e8a2                	sd	s0,80(sp)
ffffffffc0202832:	e4a6                	sd	s1,72(sp)
ffffffffc0202834:	e0ca                	sd	s2,64(sp)
ffffffffc0202836:	fc4e                	sd	s3,56(sp)
ffffffffc0202838:	f852                	sd	s4,48(sp)
ffffffffc020283a:	f456                	sd	s5,40(sp)
ffffffffc020283c:	f05a                	sd	s6,32(sp)
ffffffffc020283e:	ec5e                	sd	s7,24(sp)
ffffffffc0202840:	e862                	sd	s8,16(sp)
     int i;
     for (i = 0; i != n; ++ i)
ffffffffc0202842:	cde9                	beqz	a1,ffffffffc020291c <swap_out+0xf0>
ffffffffc0202844:	8ab2                	mv	s5,a2
ffffffffc0202846:	892a                	mv	s2,a0
ffffffffc0202848:	8a2e                	mv	s4,a1
ffffffffc020284a:	4401                	li	s0,0
ffffffffc020284c:	0000f997          	auipc	s3,0xf
ffffffffc0202850:	c5498993          	addi	s3,s3,-940 # ffffffffc02114a0 <sm>
                    cprintf("SWAP: failed to save\n");
                    sm->map_swappable(mm, v, page, 0);
                    continue;
          }
          else {
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202854:	00004b17          	auipc	s6,0x4
ffffffffc0202858:	96cb0b13          	addi	s6,s6,-1684 # ffffffffc02061c0 <default_pmm_manager+0xa50>
                    cprintf("SWAP: failed to save\n");
ffffffffc020285c:	00004b97          	auipc	s7,0x4
ffffffffc0202860:	94cb8b93          	addi	s7,s7,-1716 # ffffffffc02061a8 <default_pmm_manager+0xa38>
ffffffffc0202864:	a825                	j	ffffffffc020289c <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202866:	67a2                	ld	a5,8(sp)
ffffffffc0202868:	8626                	mv	a2,s1
ffffffffc020286a:	85a2                	mv	a1,s0
ffffffffc020286c:	63b4                	ld	a3,64(a5)
ffffffffc020286e:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0202870:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202872:	82b1                	srli	a3,a3,0xc
ffffffffc0202874:	0685                	addi	a3,a3,1
ffffffffc0202876:	849fd0ef          	jal	ra,ffffffffc02000be <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020287a:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc020287c:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020287e:	613c                	ld	a5,64(a0)
ffffffffc0202880:	83b1                	srli	a5,a5,0xc
ffffffffc0202882:	0785                	addi	a5,a5,1
ffffffffc0202884:	07a2                	slli	a5,a5,0x8
ffffffffc0202886:	00fc3023          	sd	a5,0(s8) # 80000 <BASE_ADDRESS-0xffffffffc0180000>
                    free_page(page);
ffffffffc020288a:	e5dfe0ef          	jal	ra,ffffffffc02016e6 <free_pages>
          }
          
          tlb_invalidate(mm->pgdir, v);
ffffffffc020288e:	01893503          	ld	a0,24(s2)
ffffffffc0202892:	85a6                	mv	a1,s1
ffffffffc0202894:	d5fff0ef          	jal	ra,ffffffffc02025f2 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0202898:	048a0d63          	beq	s4,s0,ffffffffc02028f2 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc020289c:	0009b783          	ld	a5,0(s3)
ffffffffc02028a0:	8656                	mv	a2,s5
ffffffffc02028a2:	002c                	addi	a1,sp,8
ffffffffc02028a4:	7b9c                	ld	a5,48(a5)
ffffffffc02028a6:	854a                	mv	a0,s2
ffffffffc02028a8:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02028aa:	e12d                	bnez	a0,ffffffffc020290c <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc02028ac:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02028ae:	01893503          	ld	a0,24(s2)
ffffffffc02028b2:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02028b4:	63a4                	ld	s1,64(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02028b6:	85a6                	mv	a1,s1
ffffffffc02028b8:	eb5fe0ef          	jal	ra,ffffffffc020176c <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02028bc:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02028be:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02028c0:	8b85                	andi	a5,a5,1
ffffffffc02028c2:	cfb9                	beqz	a5,ffffffffc0202920 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02028c4:	65a2                	ld	a1,8(sp)
ffffffffc02028c6:	61bc                	ld	a5,64(a1)
ffffffffc02028c8:	83b1                	srli	a5,a5,0xc
ffffffffc02028ca:	00178513          	addi	a0,a5,1
ffffffffc02028ce:	0522                	slli	a0,a0,0x8
ffffffffc02028d0:	34d010ef          	jal	ra,ffffffffc020441c <swapfs_write>
ffffffffc02028d4:	d949                	beqz	a0,ffffffffc0202866 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc02028d6:	855e                	mv	a0,s7
ffffffffc02028d8:	fe6fd0ef          	jal	ra,ffffffffc02000be <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02028dc:	0009b783          	ld	a5,0(s3)
ffffffffc02028e0:	6622                	ld	a2,8(sp)
ffffffffc02028e2:	4681                	li	a3,0
ffffffffc02028e4:	739c                	ld	a5,32(a5)
ffffffffc02028e6:	85a6                	mv	a1,s1
ffffffffc02028e8:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02028ea:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02028ec:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc02028ee:	fa8a17e3          	bne	s4,s0,ffffffffc020289c <swap_out+0x70>
     }
     return i;
}
ffffffffc02028f2:	8522                	mv	a0,s0
ffffffffc02028f4:	60e6                	ld	ra,88(sp)
ffffffffc02028f6:	6446                	ld	s0,80(sp)
ffffffffc02028f8:	64a6                	ld	s1,72(sp)
ffffffffc02028fa:	6906                	ld	s2,64(sp)
ffffffffc02028fc:	79e2                	ld	s3,56(sp)
ffffffffc02028fe:	7a42                	ld	s4,48(sp)
ffffffffc0202900:	7aa2                	ld	s5,40(sp)
ffffffffc0202902:	7b02                	ld	s6,32(sp)
ffffffffc0202904:	6be2                	ld	s7,24(sp)
ffffffffc0202906:	6c42                	ld	s8,16(sp)
ffffffffc0202908:	6125                	addi	sp,sp,96
ffffffffc020290a:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc020290c:	85a2                	mv	a1,s0
ffffffffc020290e:	00004517          	auipc	a0,0x4
ffffffffc0202912:	84250513          	addi	a0,a0,-1982 # ffffffffc0206150 <default_pmm_manager+0x9e0>
ffffffffc0202916:	fa8fd0ef          	jal	ra,ffffffffc02000be <cprintf>
                  break;
ffffffffc020291a:	bfe1                	j	ffffffffc02028f2 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc020291c:	4401                	li	s0,0
ffffffffc020291e:	bfd1                	j	ffffffffc02028f2 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202920:	00004697          	auipc	a3,0x4
ffffffffc0202924:	86068693          	addi	a3,a3,-1952 # ffffffffc0206180 <default_pmm_manager+0xa10>
ffffffffc0202928:	00003617          	auipc	a2,0x3
ffffffffc020292c:	ab060613          	addi	a2,a2,-1360 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202930:	06700593          	li	a1,103
ffffffffc0202934:	00004517          	auipc	a0,0x4
ffffffffc0202938:	86450513          	addi	a0,a0,-1948 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020293c:	a39fd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0202940 <swap_in>:

int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)
{
ffffffffc0202940:	7179                	addi	sp,sp,-48
ffffffffc0202942:	ec26                	sd	s1,24(sp)
ffffffffc0202944:	84aa                	mv	s1,a0
     struct Page *result = alloc_page();
ffffffffc0202946:	4505                	li	a0,1
{
ffffffffc0202948:	e84a                	sd	s2,16(sp)
ffffffffc020294a:	e44e                	sd	s3,8(sp)
ffffffffc020294c:	f406                	sd	ra,40(sp)
ffffffffc020294e:	f022                	sd	s0,32(sp)
ffffffffc0202950:	892e                	mv	s2,a1
ffffffffc0202952:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0202954:	d0bfe0ef          	jal	ra,ffffffffc020165e <alloc_pages>
     assert(result!=NULL);
ffffffffc0202958:	c92d                	beqz	a0,ffffffffc02029ca <swap_in+0x8a>

     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc020295a:	842a                	mv	s0,a0
ffffffffc020295c:	6c88                	ld	a0,24(s1)
ffffffffc020295e:	85ca                	mv	a1,s2
ffffffffc0202960:	4601                	li	a2,0
ffffffffc0202962:	e0bfe0ef          	jal	ra,ffffffffc020176c <get_pte>
     cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
ffffffffc0202966:	0000f797          	auipc	a5,0xf
ffffffffc020296a:	b8278793          	addi	a5,a5,-1150 # ffffffffc02114e8 <pages>
ffffffffc020296e:	639c                	ld	a5,0(a5)
ffffffffc0202970:	00003717          	auipc	a4,0x3
ffffffffc0202974:	a5070713          	addi	a4,a4,-1456 # ffffffffc02053c0 <commands+0x858>
ffffffffc0202978:	6318                	ld	a4,0(a4)
ffffffffc020297a:	40f407b3          	sub	a5,s0,a5
ffffffffc020297e:	878d                	srai	a5,a5,0x3
ffffffffc0202980:	02e787b3          	mul	a5,a5,a4
ffffffffc0202984:	6110                	ld	a2,0(a0)
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0202986:	84aa                	mv	s1,a0
     cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
ffffffffc0202988:	8722                	mv	a4,s0
ffffffffc020298a:	86ca                	mv	a3,s2
ffffffffc020298c:	8221                	srli	a2,a2,0x8
ffffffffc020298e:	85aa                	mv	a1,a0
ffffffffc0202990:	00003517          	auipc	a0,0x3
ffffffffc0202994:	4a050513          	addi	a0,a0,1184 # ffffffffc0205e30 <default_pmm_manager+0x6c0>
ffffffffc0202998:	f26fd0ef          	jal	ra,ffffffffc02000be <cprintf>
    
     int r;
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc020299c:	6088                	ld	a0,0(s1)
ffffffffc020299e:	85a2                	mv	a1,s0
ffffffffc02029a0:	1d7010ef          	jal	ra,ffffffffc0204376 <swapfs_read>
     {
        assert(r!=0);
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc02029a4:	608c                	ld	a1,0(s1)
ffffffffc02029a6:	864a                	mv	a2,s2
ffffffffc02029a8:	00003517          	auipc	a0,0x3
ffffffffc02029ac:	4d050513          	addi	a0,a0,1232 # ffffffffc0205e78 <default_pmm_manager+0x708>
ffffffffc02029b0:	81a1                	srli	a1,a1,0x8
ffffffffc02029b2:	f0cfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     *ptr_result=result;
     return 0;
}
ffffffffc02029b6:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc02029b8:	0089b023          	sd	s0,0(s3)
}
ffffffffc02029bc:	7402                	ld	s0,32(sp)
ffffffffc02029be:	64e2                	ld	s1,24(sp)
ffffffffc02029c0:	6942                	ld	s2,16(sp)
ffffffffc02029c2:	69a2                	ld	s3,8(sp)
ffffffffc02029c4:	4501                	li	a0,0
ffffffffc02029c6:	6145                	addi	sp,sp,48
ffffffffc02029c8:	8082                	ret
     assert(result!=NULL);
ffffffffc02029ca:	00003697          	auipc	a3,0x3
ffffffffc02029ce:	45668693          	addi	a3,a3,1110 # ffffffffc0205e20 <default_pmm_manager+0x6b0>
ffffffffc02029d2:	00003617          	auipc	a2,0x3
ffffffffc02029d6:	a0660613          	addi	a2,a2,-1530 # ffffffffc02053d8 <commands+0x870>
ffffffffc02029da:	07d00593          	li	a1,125
ffffffffc02029de:	00003517          	auipc	a0,0x3
ffffffffc02029e2:	7ba50513          	addi	a0,a0,1978 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02029e6:	98ffd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02029ea <lru_update>:

//模拟硬件的lru计数器
void lru_update(int addr){
ffffffffc02029ea:	1141                	addi	sp,sp,-16
ffffffffc02029ec:	e022                	sd	s0,0(sp)
    extern struct mm_struct *check_mm_struct;
    struct Page* page2 = get_page(check_mm_struct->pgdir, addr, NULL);
ffffffffc02029ee:	0000f417          	auipc	s0,0xf
ffffffffc02029f2:	be240413          	addi	s0,s0,-1054 # ffffffffc02115d0 <check_mm_struct>
ffffffffc02029f6:	601c                	ld	a5,0(s0)
ffffffffc02029f8:	85aa                	mv	a1,a0
ffffffffc02029fa:	4601                	li	a2,0
ffffffffc02029fc:	6f88                	ld	a0,24(a5)
void lru_update(int addr){
ffffffffc02029fe:	e406                	sd	ra,8(sp)
    struct Page* page2 = get_page(check_mm_struct->pgdir, addr, NULL);
ffffffffc0202a00:	f6bfe0ef          	jal	ra,ffffffffc020196a <get_page>
    if(check_mm_struct!=NULL){
ffffffffc0202a04:	601c                	ld	a5,0(s0)
ffffffffc0202a06:	cb85                	beqz	a5,ffffffffc0202a36 <lru_update+0x4c>
        list_entry_t *head=(list_entry_t*) check_mm_struct->sm_priv;
ffffffffc0202a08:	7794                	ld	a3,40(a5)
        assert(head != NULL);
ffffffffc0202a0a:	ca95                	beqz	a3,ffffffffc0202a3e <lru_update+0x54>
        list_entry_t *le = head->next;
ffffffffc0202a0c:	669c                	ld	a5,8(a3)
        // 遍历mm的链表，visited加1,若是刚刚访问的addr，visited改为0
        while (le!=head) {
ffffffffc0202a0e:	00f69b63          	bne	a3,a5,ffffffffc0202a24 <lru_update+0x3a>
ffffffffc0202a12:	a015                	j	ffffffffc0202a36 <lru_update+0x4c>
            struct Page* page = le2page(le,pra_page_link);
            if(page!=page2) page->visited++;
ffffffffc0202a14:	fe07b703          	ld	a4,-32(a5)
ffffffffc0202a18:	0705                	addi	a4,a4,1
ffffffffc0202a1a:	fee7b023          	sd	a4,-32(a5)
            else page->visited =0;
            le = le->next;
ffffffffc0202a1e:	679c                	ld	a5,8(a5)
        while (le!=head) {
ffffffffc0202a20:	00f68b63          	beq	a3,a5,ffffffffc0202a36 <lru_update+0x4c>
            struct Page* page = le2page(le,pra_page_link);
ffffffffc0202a24:	fd078713          	addi	a4,a5,-48
            if(page!=page2) page->visited++;
ffffffffc0202a28:	fee516e3          	bne	a0,a4,ffffffffc0202a14 <lru_update+0x2a>
            else page->visited =0;
ffffffffc0202a2c:	fe07b023          	sd	zero,-32(a5)
            le = le->next;
ffffffffc0202a30:	679c                	ld	a5,8(a5)
        while (le!=head) {
ffffffffc0202a32:	fef699e3          	bne	a3,a5,ffffffffc0202a24 <lru_update+0x3a>
        }
        return;
    }
    return;
}
ffffffffc0202a36:	60a2                	ld	ra,8(sp)
ffffffffc0202a38:	6402                	ld	s0,0(sp)
ffffffffc0202a3a:	0141                	addi	sp,sp,16
ffffffffc0202a3c:	8082                	ret
        assert(head != NULL);
ffffffffc0202a3e:	00003697          	auipc	a3,0x3
ffffffffc0202a42:	3d268693          	addi	a3,a3,978 # ffffffffc0205e10 <default_pmm_manager+0x6a0>
ffffffffc0202a46:	00003617          	auipc	a2,0x3
ffffffffc0202a4a:	99260613          	addi	a2,a2,-1646 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202a4e:	09200593          	li	a1,146
ffffffffc0202a52:	00003517          	auipc	a0,0x3
ffffffffc0202a56:	74650513          	addi	a0,a0,1862 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202a5a:	91bfd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0202a5e <swap_init>:
{
ffffffffc0202a5e:	7135                	addi	sp,sp,-160
ffffffffc0202a60:	ed06                	sd	ra,152(sp)
ffffffffc0202a62:	e922                	sd	s0,144(sp)
ffffffffc0202a64:	e526                	sd	s1,136(sp)
ffffffffc0202a66:	e14a                	sd	s2,128(sp)
ffffffffc0202a68:	fcce                	sd	s3,120(sp)
ffffffffc0202a6a:	f8d2                	sd	s4,112(sp)
ffffffffc0202a6c:	f4d6                	sd	s5,104(sp)
ffffffffc0202a6e:	f0da                	sd	s6,96(sp)
ffffffffc0202a70:	ecde                	sd	s7,88(sp)
ffffffffc0202a72:	e8e2                	sd	s8,80(sp)
ffffffffc0202a74:	e4e6                	sd	s9,72(sp)
ffffffffc0202a76:	e0ea                	sd	s10,64(sp)
ffffffffc0202a78:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0202a7a:	0c5010ef          	jal	ra,ffffffffc020433e <swapfs_init>
     if (!(7 <= max_swap_offset &&
ffffffffc0202a7e:	0000f797          	auipc	a5,0xf
ffffffffc0202a82:	afa78793          	addi	a5,a5,-1286 # ffffffffc0211578 <max_swap_offset>
ffffffffc0202a86:	6394                	ld	a3,0(a5)
ffffffffc0202a88:	010007b7          	lui	a5,0x1000
ffffffffc0202a8c:	17e1                	addi	a5,a5,-8
ffffffffc0202a8e:	ff968713          	addi	a4,a3,-7
ffffffffc0202a92:	54e7ea63          	bltu	a5,a4,ffffffffc0202fe6 <swap_init+0x588>
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc0202a96:	00007797          	auipc	a5,0x7
ffffffffc0202a9a:	56a78793          	addi	a5,a5,1386 # ffffffffc020a000 <swap_manager_clock>
     int r = sm->init();
ffffffffc0202a9e:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock;//use first in first out Page Replacement Algorithm
ffffffffc0202aa0:	0000f697          	auipc	a3,0xf
ffffffffc0202aa4:	a0f6b023          	sd	a5,-1536(a3) # ffffffffc02114a0 <sm>
ffffffffc0202aa8:	0000fc97          	auipc	s9,0xf
ffffffffc0202aac:	9f8c8c93          	addi	s9,s9,-1544 # ffffffffc02114a0 <sm>
     int r = sm->init();
ffffffffc0202ab0:	9702                	jalr	a4
ffffffffc0202ab2:	8b2a                	mv	s6,a0
     if (r == 0)
ffffffffc0202ab4:	c10d                	beqz	a0,ffffffffc0202ad6 <swap_init+0x78>
}
ffffffffc0202ab6:	60ea                	ld	ra,152(sp)
ffffffffc0202ab8:	644a                	ld	s0,144(sp)
ffffffffc0202aba:	855a                	mv	a0,s6
ffffffffc0202abc:	64aa                	ld	s1,136(sp)
ffffffffc0202abe:	690a                	ld	s2,128(sp)
ffffffffc0202ac0:	79e6                	ld	s3,120(sp)
ffffffffc0202ac2:	7a46                	ld	s4,112(sp)
ffffffffc0202ac4:	7aa6                	ld	s5,104(sp)
ffffffffc0202ac6:	7b06                	ld	s6,96(sp)
ffffffffc0202ac8:	6be6                	ld	s7,88(sp)
ffffffffc0202aca:	6c46                	ld	s8,80(sp)
ffffffffc0202acc:	6ca6                	ld	s9,72(sp)
ffffffffc0202ace:	6d06                	ld	s10,64(sp)
ffffffffc0202ad0:	7de2                	ld	s11,56(sp)
ffffffffc0202ad2:	610d                	addi	sp,sp,160
ffffffffc0202ad4:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202ad6:	000cb783          	ld	a5,0(s9)
ffffffffc0202ada:	00003517          	auipc	a0,0x3
ffffffffc0202ade:	3fe50513          	addi	a0,a0,1022 # ffffffffc0205ed8 <default_pmm_manager+0x768>
    return listelm->next;
ffffffffc0202ae2:	0000f417          	auipc	s0,0xf
ffffffffc0202ae6:	9d640413          	addi	s0,s0,-1578 # ffffffffc02114b8 <free_area>
ffffffffc0202aea:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202aec:	4785                	li	a5,1
ffffffffc0202aee:	0000f717          	auipc	a4,0xf
ffffffffc0202af2:	9af72d23          	sw	a5,-1606(a4) # ffffffffc02114a8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0202af6:	dc8fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202afa:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202afc:	40878963          	beq	a5,s0,ffffffffc0202f0e <swap_init+0x4b0>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202b00:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202b04:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202b06:	8b05                	andi	a4,a4,1
ffffffffc0202b08:	40070763          	beqz	a4,ffffffffc0202f16 <swap_init+0x4b8>
     int ret, count = 0, total = 0, i;
ffffffffc0202b0c:	4481                	li	s1,0
ffffffffc0202b0e:	4901                	li	s2,0
ffffffffc0202b10:	a031                	j	ffffffffc0202b1c <swap_init+0xbe>
ffffffffc0202b12:	fe87b703          	ld	a4,-24(a5)
        assert(PageProperty(p));
ffffffffc0202b16:	8b09                	andi	a4,a4,2
ffffffffc0202b18:	3e070f63          	beqz	a4,ffffffffc0202f16 <swap_init+0x4b8>
        count ++, total += p->property;
ffffffffc0202b1c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202b20:	679c                	ld	a5,8(a5)
ffffffffc0202b22:	2905                	addiw	s2,s2,1
ffffffffc0202b24:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202b26:	fe8796e3          	bne	a5,s0,ffffffffc0202b12 <swap_init+0xb4>
ffffffffc0202b2a:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc0202b2c:	c01fe0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0202b30:	5b351763          	bne	a0,s3,ffffffffc02030de <swap_init+0x680>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0202b34:	8626                	mv	a2,s1
ffffffffc0202b36:	85ca                	mv	a1,s2
ffffffffc0202b38:	00003517          	auipc	a0,0x3
ffffffffc0202b3c:	3b850513          	addi	a0,a0,952 # ffffffffc0205ef0 <default_pmm_manager+0x780>
ffffffffc0202b40:	d7efd0ef          	jal	ra,ffffffffc02000be <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0202b44:	02c010ef          	jal	ra,ffffffffc0203b70 <mm_create>
ffffffffc0202b48:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc0202b4a:	50050a63          	beqz	a0,ffffffffc020305e <swap_init+0x600>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202b4e:	0000f797          	auipc	a5,0xf
ffffffffc0202b52:	a8278793          	addi	a5,a5,-1406 # ffffffffc02115d0 <check_mm_struct>
ffffffffc0202b56:	639c                	ld	a5,0(a5)
ffffffffc0202b58:	52079363          	bnez	a5,ffffffffc020307e <swap_init+0x620>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202b5c:	0000f797          	auipc	a5,0xf
ffffffffc0202b60:	93478793          	addi	a5,a5,-1740 # ffffffffc0211490 <boot_pgdir>
ffffffffc0202b64:	6398                	ld	a4,0(a5)
     check_mm_struct = mm;
ffffffffc0202b66:	0000f797          	auipc	a5,0xf
ffffffffc0202b6a:	a6a7b523          	sd	a0,-1430(a5) # ffffffffc02115d0 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0202b6e:	631c                	ld	a5,0(a4)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202b70:	ec3a                	sd	a4,24(sp)
ffffffffc0202b72:	ed18                	sd	a4,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0202b74:	4a079563          	bnez	a5,ffffffffc020301e <swap_init+0x5c0>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202b78:	6599                	lui	a1,0x6
ffffffffc0202b7a:	460d                	li	a2,3
ffffffffc0202b7c:	6505                	lui	a0,0x1
ffffffffc0202b7e:	03e010ef          	jal	ra,ffffffffc0203bbc <vma_create>
ffffffffc0202b82:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0202b84:	4a050d63          	beqz	a0,ffffffffc020303e <swap_init+0x5e0>

     insert_vma_struct(mm, vma);
ffffffffc0202b88:	855e                	mv	a0,s7
ffffffffc0202b8a:	09e010ef          	jal	ra,ffffffffc0203c28 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0202b8e:	00003517          	auipc	a0,0x3
ffffffffc0202b92:	3d250513          	addi	a0,a0,978 # ffffffffc0205f60 <default_pmm_manager+0x7f0>
ffffffffc0202b96:	d28fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0202b9a:	018bb503          	ld	a0,24(s7)
ffffffffc0202b9e:	4605                	li	a2,1
ffffffffc0202ba0:	6585                	lui	a1,0x1
ffffffffc0202ba2:	bcbfe0ef          	jal	ra,ffffffffc020176c <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0202ba6:	44050c63          	beqz	a0,ffffffffc0202ffe <swap_init+0x5a0>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202baa:	00003517          	auipc	a0,0x3
ffffffffc0202bae:	40650513          	addi	a0,a0,1030 # ffffffffc0205fb0 <default_pmm_manager+0x840>
ffffffffc0202bb2:	0000fa17          	auipc	s4,0xf
ffffffffc0202bb6:	93ea0a13          	addi	s4,s4,-1730 # ffffffffc02114f0 <check_rp>
ffffffffc0202bba:	d04fd0ef          	jal	ra,ffffffffc02000be <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202bbe:	0000fa97          	auipc	s5,0xf
ffffffffc0202bc2:	952a8a93          	addi	s5,s5,-1710 # ffffffffc0211510 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0202bc6:	89d2                	mv	s3,s4
          check_rp[i] = alloc_page();
ffffffffc0202bc8:	4505                	li	a0,1
ffffffffc0202bca:	a95fe0ef          	jal	ra,ffffffffc020165e <alloc_pages>
ffffffffc0202bce:	00a9b023          	sd	a0,0(s3)
          assert(check_rp[i] != NULL );
ffffffffc0202bd2:	36050263          	beqz	a0,ffffffffc0202f36 <swap_init+0x4d8>
ffffffffc0202bd6:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0202bd8:	8b89                	andi	a5,a5,2
ffffffffc0202bda:	38079e63          	bnez	a5,ffffffffc0202f76 <swap_init+0x518>
ffffffffc0202bde:	09a1                	addi	s3,s3,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202be0:	ff5994e3          	bne	s3,s5,ffffffffc0202bc8 <swap_init+0x16a>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0202be4:	601c                	ld	a5,0(s0)
ffffffffc0202be6:	00843983          	ld	s3,8(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0202bea:	0000fd17          	auipc	s10,0xf
ffffffffc0202bee:	906d0d13          	addi	s10,s10,-1786 # ffffffffc02114f0 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0202bf2:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202bf4:	481c                	lw	a5,16(s0)
ffffffffc0202bf6:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc0202bf8:	0000f797          	auipc	a5,0xf
ffffffffc0202bfc:	8c87b423          	sd	s0,-1848(a5) # ffffffffc02114c0 <free_area+0x8>
ffffffffc0202c00:	0000f797          	auipc	a5,0xf
ffffffffc0202c04:	8a87bc23          	sd	s0,-1864(a5) # ffffffffc02114b8 <free_area>
     nr_free = 0;
ffffffffc0202c08:	0000f797          	auipc	a5,0xf
ffffffffc0202c0c:	8c07a023          	sw	zero,-1856(a5) # ffffffffc02114c8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0202c10:	000d3503          	ld	a0,0(s10)
ffffffffc0202c14:	4585                	li	a1,1
ffffffffc0202c16:	0d21                	addi	s10,s10,8
ffffffffc0202c18:	acffe0ef          	jal	ra,ffffffffc02016e6 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202c1c:	ff5d1ae3          	bne	s10,s5,ffffffffc0202c10 <swap_init+0x1b2>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202c20:	01042d03          	lw	s10,16(s0)
ffffffffc0202c24:	4791                	li	a5,4
ffffffffc0202c26:	5cfd1c63          	bne	s10,a5,ffffffffc02031fe <swap_init+0x7a0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202c2a:	00003517          	auipc	a0,0x3
ffffffffc0202c2e:	40e50513          	addi	a0,a0,1038 # ffffffffc0206038 <default_pmm_manager+0x8c8>
ffffffffc0202c32:	c8cfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     if (sm == &swap_manager_lru){
ffffffffc0202c36:	000cb703          	ld	a4,0(s9)
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202c3a:	0000f797          	auipc	a5,0xf
ffffffffc0202c3e:	8607a923          	sw	zero,-1934(a5) # ffffffffc02114ac <pgfault_num>
     if (sm == &swap_manager_lru){
ffffffffc0202c42:	00007797          	auipc	a5,0x7
ffffffffc0202c46:	3fe78793          	addi	a5,a5,1022 # ffffffffc020a040 <swap_manager_lru>
     pgfault_num=0;
ffffffffc0202c4a:	0000fd97          	auipc	s11,0xf
ffffffffc0202c4e:	862d8d93          	addi	s11,s11,-1950 # ffffffffc02114ac <pgfault_num>
     if (sm == &swap_manager_lru){
ffffffffc0202c52:	1cf70163          	beq	a4,a5,ffffffffc0202e14 <swap_init+0x3b6>
          *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202c56:	6705                	lui	a4,0x1
ffffffffc0202c58:	46a9                	li	a3,10
ffffffffc0202c5a:	00d70023          	sb	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
          assert(pgfault_num==1);
ffffffffc0202c5e:	000da783          	lw	a5,0(s11)
ffffffffc0202c62:	4605                	li	a2,1
ffffffffc0202c64:	2781                	sext.w	a5,a5
ffffffffc0202c66:	48c79c63          	bne	a5,a2,ffffffffc02030fe <swap_init+0x6a0>
          *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202c6a:	00d70823          	sb	a3,16(a4)
          assert(pgfault_num==1);
ffffffffc0202c6e:	000da703          	lw	a4,0(s11)
ffffffffc0202c72:	2701                	sext.w	a4,a4
ffffffffc0202c74:	4af71563          	bne	a4,a5,ffffffffc020311e <swap_init+0x6c0>
          *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202c78:	6709                	lui	a4,0x2
ffffffffc0202c7a:	46ad                	li	a3,11
ffffffffc0202c7c:	00d70023          	sb	a3,0(a4) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
          assert(pgfault_num==2);
ffffffffc0202c80:	000da783          	lw	a5,0(s11)
ffffffffc0202c84:	4609                	li	a2,2
ffffffffc0202c86:	2781                	sext.w	a5,a5
ffffffffc0202c88:	4ac79b63          	bne	a5,a2,ffffffffc020313e <swap_init+0x6e0>
          *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202c8c:	00d70823          	sb	a3,16(a4)
          assert(pgfault_num==2);
ffffffffc0202c90:	000da703          	lw	a4,0(s11)
ffffffffc0202c94:	2701                	sext.w	a4,a4
ffffffffc0202c96:	4cf71463          	bne	a4,a5,ffffffffc020315e <swap_init+0x700>
          *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202c9a:	670d                	lui	a4,0x3
ffffffffc0202c9c:	46b1                	li	a3,12
ffffffffc0202c9e:	00d70023          	sb	a3,0(a4) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
          assert(pgfault_num==3);
ffffffffc0202ca2:	000da783          	lw	a5,0(s11)
ffffffffc0202ca6:	460d                	li	a2,3
ffffffffc0202ca8:	2781                	sext.w	a5,a5
ffffffffc0202caa:	4cc79a63          	bne	a5,a2,ffffffffc020317e <swap_init+0x720>
          *(unsigned char *)0x3010 = 0x0c;
ffffffffc0202cae:	00d70823          	sb	a3,16(a4)
          assert(pgfault_num==3);
ffffffffc0202cb2:	000da703          	lw	a4,0(s11)
ffffffffc0202cb6:	2701                	sext.w	a4,a4
ffffffffc0202cb8:	4ef71363          	bne	a4,a5,ffffffffc020319e <swap_init+0x740>
          *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202cbc:	6791                	lui	a5,0x4
ffffffffc0202cbe:	4735                	li	a4,13
ffffffffc0202cc0:	00e78023          	sb	a4,0(a5) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
          assert(pgfault_num==4);
ffffffffc0202cc4:	000da783          	lw	a5,0(s11)
ffffffffc0202cc8:	2781                	sext.w	a5,a5
ffffffffc0202cca:	4fa79a63          	bne	a5,s10,ffffffffc02031be <swap_init+0x760>
          *(unsigned char *)0x4010 = 0x0d;
ffffffffc0202cce:	6791                	lui	a5,0x4
ffffffffc0202cd0:	4735                	li	a4,13
ffffffffc0202cd2:	00e78823          	sb	a4,16(a5) # 4010 <BASE_ADDRESS-0xffffffffc01fbff0>
          assert(pgfault_num==4);
ffffffffc0202cd6:	000da783          	lw	a5,0(s11)
ffffffffc0202cda:	4711                	li	a4,4
ffffffffc0202cdc:	2781                	sext.w	a5,a5
ffffffffc0202cde:	50e79063          	bne	a5,a4,ffffffffc02031de <swap_init+0x780>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0202ce2:	481c                	lw	a5,16(s0)
ffffffffc0202ce4:	3a079d63          	bnez	a5,ffffffffc020309e <swap_init+0x640>
ffffffffc0202ce8:	0000f797          	auipc	a5,0xf
ffffffffc0202cec:	82878793          	addi	a5,a5,-2008 # ffffffffc0211510 <swap_in_seq_no>
ffffffffc0202cf0:	0000f717          	auipc	a4,0xf
ffffffffc0202cf4:	84870713          	addi	a4,a4,-1976 # ffffffffc0211538 <swap_out_seq_no>
ffffffffc0202cf8:	0000f617          	auipc	a2,0xf
ffffffffc0202cfc:	84060613          	addi	a2,a2,-1984 # ffffffffc0211538 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0202d00:	56fd                	li	a3,-1
ffffffffc0202d02:	c394                	sw	a3,0(a5)
ffffffffc0202d04:	c314                	sw	a3,0(a4)
ffffffffc0202d06:	0791                	addi	a5,a5,4
ffffffffc0202d08:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0202d0a:	fec79ce3          	bne	a5,a2,ffffffffc0202d02 <swap_init+0x2a4>
ffffffffc0202d0e:	0000f697          	auipc	a3,0xf
ffffffffc0202d12:	88a68693          	addi	a3,a3,-1910 # ffffffffc0211598 <check_ptep>
ffffffffc0202d16:	0000e817          	auipc	a6,0xe
ffffffffc0202d1a:	7da80813          	addi	a6,a6,2010 # ffffffffc02114f0 <check_rp>
ffffffffc0202d1e:	6705                	lui	a4,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202d20:	0000ec17          	auipc	s8,0xe
ffffffffc0202d24:	778c0c13          	addi	s8,s8,1912 # ffffffffc0211498 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d28:	0000ed97          	auipc	s11,0xe
ffffffffc0202d2c:	7c0d8d93          	addi	s11,s11,1984 # ffffffffc02114e8 <pages>
ffffffffc0202d30:	00004d17          	auipc	s10,0x4
ffffffffc0202d34:	cf0d0d13          	addi	s10,s10,-784 # ffffffffc0206a20 <nbase>

     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202d38:	6562                	ld	a0,24(sp)
ffffffffc0202d3a:	85ba                	mv	a1,a4
         check_ptep[i]=0;
ffffffffc0202d3c:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202d40:	4601                	li	a2,0
ffffffffc0202d42:	e842                	sd	a6,16(sp)
ffffffffc0202d44:	e43a                	sd	a4,8(sp)
         check_ptep[i]=0;
ffffffffc0202d46:	e036                	sd	a3,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202d48:	a25fe0ef          	jal	ra,ffffffffc020176c <get_pte>
ffffffffc0202d4c:	6682                	ld	a3,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0202d4e:	6722                	ld	a4,8(sp)
ffffffffc0202d50:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202d52:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc0202d54:	24050163          	beqz	a0,ffffffffc0202f96 <swap_init+0x538>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202d58:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202d5a:	0017f613          	andi	a2,a5,1
ffffffffc0202d5e:	24060c63          	beqz	a2,ffffffffc0202fb6 <swap_init+0x558>
    if (PPN(pa) >= npage) {
ffffffffc0202d62:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202d66:	078a                	slli	a5,a5,0x2
ffffffffc0202d68:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202d6a:	26c7f263          	bleu	a2,a5,ffffffffc0202fce <swap_init+0x570>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d6e:	000d3603          	ld	a2,0(s10)
ffffffffc0202d72:	000db583          	ld	a1,0(s11)
ffffffffc0202d76:	00083503          	ld	a0,0(a6)
ffffffffc0202d7a:	8f91                	sub	a5,a5,a2
ffffffffc0202d7c:	00379613          	slli	a2,a5,0x3
ffffffffc0202d80:	97b2                	add	a5,a5,a2
ffffffffc0202d82:	078e                	slli	a5,a5,0x3
ffffffffc0202d84:	97ae                	add	a5,a5,a1
ffffffffc0202d86:	1cf51863          	bne	a0,a5,ffffffffc0202f56 <swap_init+0x4f8>
ffffffffc0202d8a:	6785                	lui	a5,0x1
ffffffffc0202d8c:	973e                	add	a4,a4,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202d8e:	6795                	lui	a5,0x5
ffffffffc0202d90:	06a1                	addi	a3,a3,8
ffffffffc0202d92:	0821                	addi	a6,a6,8
ffffffffc0202d94:	faf712e3          	bne	a4,a5,ffffffffc0202d38 <swap_init+0x2da>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0202d98:	00003517          	auipc	a0,0x3
ffffffffc0202d9c:	34850513          	addi	a0,a0,840 # ffffffffc02060e0 <default_pmm_manager+0x970>
ffffffffc0202da0:	b1efd0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = sm->check_swap();
ffffffffc0202da4:	000cb783          	ld	a5,0(s9)
ffffffffc0202da8:	7f9c                	ld	a5,56(a5)
ffffffffc0202daa:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0202dac:	30051963          	bnez	a0,ffffffffc02030be <swap_init+0x660>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0202db0:	000a3503          	ld	a0,0(s4)
ffffffffc0202db4:	4585                	li	a1,1
ffffffffc0202db6:	0a21                	addi	s4,s4,8
ffffffffc0202db8:	92ffe0ef          	jal	ra,ffffffffc02016e6 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202dbc:	ff5a1ae3          	bne	s4,s5,ffffffffc0202db0 <swap_init+0x352>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0202dc0:	855e                	mv	a0,s7
ffffffffc0202dc2:	735000ef          	jal	ra,ffffffffc0203cf6 <mm_destroy>
         
     nr_free = nr_free_store;
ffffffffc0202dc6:	77a2                	ld	a5,40(sp)
ffffffffc0202dc8:	0000e717          	auipc	a4,0xe
ffffffffc0202dcc:	70f72023          	sw	a5,1792(a4) # ffffffffc02114c8 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0202dd0:	7782                	ld	a5,32(sp)
ffffffffc0202dd2:	0000e717          	auipc	a4,0xe
ffffffffc0202dd6:	6ef73323          	sd	a5,1766(a4) # ffffffffc02114b8 <free_area>
ffffffffc0202dda:	0000e797          	auipc	a5,0xe
ffffffffc0202dde:	6f37b323          	sd	s3,1766(a5) # ffffffffc02114c0 <free_area+0x8>

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202de2:	00898a63          	beq	s3,s0,ffffffffc0202df6 <swap_init+0x398>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202de6:	ff89a783          	lw	a5,-8(s3)
    return listelm->next;
ffffffffc0202dea:	0089b983          	ld	s3,8(s3)
ffffffffc0202dee:	397d                	addiw	s2,s2,-1
ffffffffc0202df0:	9c9d                	subw	s1,s1,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202df2:	fe899ae3          	bne	s3,s0,ffffffffc0202de6 <swap_init+0x388>
     }
     cprintf("count is %d, total is %d\n",count,total);
ffffffffc0202df6:	8626                	mv	a2,s1
ffffffffc0202df8:	85ca                	mv	a1,s2
ffffffffc0202dfa:	00003517          	auipc	a0,0x3
ffffffffc0202dfe:	31650513          	addi	a0,a0,790 # ffffffffc0206110 <default_pmm_manager+0x9a0>
ffffffffc0202e02:	abcfd0ef          	jal	ra,ffffffffc02000be <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
ffffffffc0202e06:	00003517          	auipc	a0,0x3
ffffffffc0202e0a:	32a50513          	addi	a0,a0,810 # ffffffffc0206130 <default_pmm_manager+0x9c0>
ffffffffc0202e0e:	ab0fd0ef          	jal	ra,ffffffffc02000be <cprintf>
ffffffffc0202e12:	b155                	j	ffffffffc0202ab6 <swap_init+0x58>
    *(unsigned char *)addr = value;
ffffffffc0202e14:	46a9                	li	a3,10
ffffffffc0202e16:	6705                	lui	a4,0x1
ffffffffc0202e18:	00d70023          	sb	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    lru_update(addr);
ffffffffc0202e1c:	6505                	lui	a0,0x1
    *(unsigned char *)addr = value;
ffffffffc0202e1e:	e036                	sd	a3,0(sp)
    lru_update(addr);
ffffffffc0202e20:	bcbff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==1);
ffffffffc0202e24:	000da783          	lw	a5,0(s11)
ffffffffc0202e28:	4605                	li	a2,1
ffffffffc0202e2a:	6705                	lui	a4,0x1
ffffffffc0202e2c:	00078c1b          	sext.w	s8,a5
ffffffffc0202e30:	6682                	ld	a3,0(sp)
ffffffffc0202e32:	3ecc1663          	bne	s8,a2,ffffffffc020321e <swap_init+0x7c0>
    *(unsigned char *)addr = value;
ffffffffc0202e36:	00d70823          	sb	a3,16(a4) # 1010 <BASE_ADDRESS-0xffffffffc01feff0>
    lru_update(addr);
ffffffffc0202e3a:	01070513          	addi	a0,a4,16
ffffffffc0202e3e:	badff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==1);
ffffffffc0202e42:	000da703          	lw	a4,0(s11)
ffffffffc0202e46:	2701                	sext.w	a4,a4
ffffffffc0202e48:	41871b63          	bne	a4,s8,ffffffffc020325e <swap_init+0x800>
    *(unsigned char *)addr = value;
ffffffffc0202e4c:	46ad                	li	a3,11
ffffffffc0202e4e:	6709                	lui	a4,0x2
ffffffffc0202e50:	00d70023          	sb	a3,0(a4) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    lru_update(addr);
ffffffffc0202e54:	6509                	lui	a0,0x2
    *(unsigned char *)addr = value;
ffffffffc0202e56:	e036                	sd	a3,0(sp)
    lru_update(addr);
ffffffffc0202e58:	b93ff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==2);
ffffffffc0202e5c:	000da783          	lw	a5,0(s11)
ffffffffc0202e60:	4609                	li	a2,2
ffffffffc0202e62:	6709                	lui	a4,0x2
ffffffffc0202e64:	00078c1b          	sext.w	s8,a5
ffffffffc0202e68:	6682                	ld	a3,0(sp)
ffffffffc0202e6a:	3ccc1a63          	bne	s8,a2,ffffffffc020323e <swap_init+0x7e0>
    *(unsigned char *)addr = value;
ffffffffc0202e6e:	00d70823          	sb	a3,16(a4) # 2010 <BASE_ADDRESS-0xffffffffc01fdff0>
    lru_update(addr);
ffffffffc0202e72:	01070513          	addi	a0,a4,16
ffffffffc0202e76:	b75ff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==2);
ffffffffc0202e7a:	000da703          	lw	a4,0(s11)
ffffffffc0202e7e:	2701                	sext.w	a4,a4
ffffffffc0202e80:	45871f63          	bne	a4,s8,ffffffffc02032de <swap_init+0x880>
    *(unsigned char *)addr = value;
ffffffffc0202e84:	46b1                	li	a3,12
ffffffffc0202e86:	670d                	lui	a4,0x3
ffffffffc0202e88:	00d70023          	sb	a3,0(a4) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    lru_update(addr);
ffffffffc0202e8c:	650d                	lui	a0,0x3
    *(unsigned char *)addr = value;
ffffffffc0202e8e:	e036                	sd	a3,0(sp)
    lru_update(addr);
ffffffffc0202e90:	b5bff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==3);
ffffffffc0202e94:	000da783          	lw	a5,0(s11)
ffffffffc0202e98:	460d                	li	a2,3
ffffffffc0202e9a:	670d                	lui	a4,0x3
ffffffffc0202e9c:	00078c1b          	sext.w	s8,a5
ffffffffc0202ea0:	6682                	ld	a3,0(sp)
ffffffffc0202ea2:	40cc1e63          	bne	s8,a2,ffffffffc02032be <swap_init+0x860>
    *(unsigned char *)addr = value;
ffffffffc0202ea6:	00d70823          	sb	a3,16(a4) # 3010 <BASE_ADDRESS-0xffffffffc01fcff0>
    lru_update(addr);
ffffffffc0202eaa:	01070513          	addi	a0,a4,16
ffffffffc0202eae:	b3dff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==3);
ffffffffc0202eb2:	000da703          	lw	a4,0(s11)
ffffffffc0202eb6:	2701                	sext.w	a4,a4
ffffffffc0202eb8:	3f871363          	bne	a4,s8,ffffffffc020329e <swap_init+0x840>
    *(unsigned char *)addr = value;
ffffffffc0202ebc:	6791                	lui	a5,0x4
ffffffffc0202ebe:	4735                	li	a4,13
ffffffffc0202ec0:	00e78023          	sb	a4,0(a5) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    lru_update(addr);
ffffffffc0202ec4:	6511                	lui	a0,0x4
ffffffffc0202ec6:	b25ff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==4);
ffffffffc0202eca:	000da783          	lw	a5,0(s11)
ffffffffc0202ece:	2781                	sext.w	a5,a5
ffffffffc0202ed0:	3ba79763          	bne	a5,s10,ffffffffc020327e <swap_init+0x820>
    *(unsigned char *)addr = value;
ffffffffc0202ed4:	47b5                	li	a5,13
ffffffffc0202ed6:	6511                	lui	a0,0x4
ffffffffc0202ed8:	00f50823          	sb	a5,16(a0) # 4010 <BASE_ADDRESS-0xffffffffc01fbff0>
    lru_update(addr);
ffffffffc0202edc:	0541                	addi	a0,a0,16
ffffffffc0202ede:	b0dff0ef          	jal	ra,ffffffffc02029ea <lru_update>
          assert(pgfault_num==4);
ffffffffc0202ee2:	000da783          	lw	a5,0(s11)
ffffffffc0202ee6:	4711                	li	a4,4
ffffffffc0202ee8:	2781                	sext.w	a5,a5
ffffffffc0202eea:	dee78ce3          	beq	a5,a4,ffffffffc0202ce2 <swap_init+0x284>
ffffffffc0202eee:	00003697          	auipc	a3,0x3
ffffffffc0202ef2:	1a268693          	addi	a3,a3,418 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc0202ef6:	00002617          	auipc	a2,0x2
ffffffffc0202efa:	4e260613          	addi	a2,a2,1250 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202efe:	0b900593          	li	a1,185
ffffffffc0202f02:	00003517          	auipc	a0,0x3
ffffffffc0202f06:	29650513          	addi	a0,a0,662 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202f0a:	c6afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     int ret, count = 0, total = 0, i;
ffffffffc0202f0e:	4481                	li	s1,0
ffffffffc0202f10:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202f12:	4981                	li	s3,0
ffffffffc0202f14:	b921                	j	ffffffffc0202b2c <swap_init+0xce>
        assert(PageProperty(p));
ffffffffc0202f16:	00002697          	auipc	a3,0x2
ffffffffc0202f1a:	4b268693          	addi	a3,a3,1202 # ffffffffc02053c8 <commands+0x860>
ffffffffc0202f1e:	00002617          	auipc	a2,0x2
ffffffffc0202f22:	4ba60613          	addi	a2,a2,1210 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202f26:	0e700593          	li	a1,231
ffffffffc0202f2a:	00003517          	auipc	a0,0x3
ffffffffc0202f2e:	26e50513          	addi	a0,a0,622 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202f32:	c42fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202f36:	00003697          	auipc	a3,0x3
ffffffffc0202f3a:	0a268693          	addi	a3,a3,162 # ffffffffc0205fd8 <default_pmm_manager+0x868>
ffffffffc0202f3e:	00002617          	auipc	a2,0x2
ffffffffc0202f42:	49a60613          	addi	a2,a2,1178 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202f46:	10700593          	li	a1,263
ffffffffc0202f4a:	00003517          	auipc	a0,0x3
ffffffffc0202f4e:	24e50513          	addi	a0,a0,590 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202f52:	c22fd0ef          	jal	ra,ffffffffc0200374 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202f56:	00003697          	auipc	a3,0x3
ffffffffc0202f5a:	16268693          	addi	a3,a3,354 # ffffffffc02060b8 <default_pmm_manager+0x948>
ffffffffc0202f5e:	00002617          	auipc	a2,0x2
ffffffffc0202f62:	47a60613          	addi	a2,a2,1146 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202f66:	12700593          	li	a1,295
ffffffffc0202f6a:	00003517          	auipc	a0,0x3
ffffffffc0202f6e:	22e50513          	addi	a0,a0,558 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202f72:	c02fd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202f76:	00003697          	auipc	a3,0x3
ffffffffc0202f7a:	07a68693          	addi	a3,a3,122 # ffffffffc0205ff0 <default_pmm_manager+0x880>
ffffffffc0202f7e:	00002617          	auipc	a2,0x2
ffffffffc0202f82:	45a60613          	addi	a2,a2,1114 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202f86:	10800593          	li	a1,264
ffffffffc0202f8a:	00003517          	auipc	a0,0x3
ffffffffc0202f8e:	20e50513          	addi	a0,a0,526 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202f92:	be2fd0ef          	jal	ra,ffffffffc0200374 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202f96:	00003697          	auipc	a3,0x3
ffffffffc0202f9a:	10a68693          	addi	a3,a3,266 # ffffffffc02060a0 <default_pmm_manager+0x930>
ffffffffc0202f9e:	00002617          	auipc	a2,0x2
ffffffffc0202fa2:	43a60613          	addi	a2,a2,1082 # ffffffffc02053d8 <commands+0x870>
ffffffffc0202fa6:	12600593          	li	a1,294
ffffffffc0202faa:	00003517          	auipc	a0,0x3
ffffffffc0202fae:	1ee50513          	addi	a0,a0,494 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202fb2:	bc2fd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202fb6:	00003617          	auipc	a2,0x3
ffffffffc0202fba:	a7a60613          	addi	a2,a2,-1414 # ffffffffc0205a30 <default_pmm_manager+0x2c0>
ffffffffc0202fbe:	07000593          	li	a1,112
ffffffffc0202fc2:	00003517          	auipc	a0,0x3
ffffffffc0202fc6:	89650513          	addi	a0,a0,-1898 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc0202fca:	baafd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0202fce:	00003617          	auipc	a2,0x3
ffffffffc0202fd2:	86a60613          	addi	a2,a2,-1942 # ffffffffc0205838 <default_pmm_manager+0xc8>
ffffffffc0202fd6:	06500593          	li	a1,101
ffffffffc0202fda:	00003517          	auipc	a0,0x3
ffffffffc0202fde:	87e50513          	addi	a0,a0,-1922 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc0202fe2:	b92fd0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202fe6:	00003617          	auipc	a2,0x3
ffffffffc0202fea:	ed260613          	addi	a2,a2,-302 # ffffffffc0205eb8 <default_pmm_manager+0x748>
ffffffffc0202fee:	02800593          	li	a1,40
ffffffffc0202ff2:	00003517          	auipc	a0,0x3
ffffffffc0202ff6:	1a650513          	addi	a0,a0,422 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc0202ffa:	b7afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202ffe:	00003697          	auipc	a3,0x3
ffffffffc0203002:	f9a68693          	addi	a3,a3,-102 # ffffffffc0205f98 <default_pmm_manager+0x828>
ffffffffc0203006:	00002617          	auipc	a2,0x2
ffffffffc020300a:	3d260613          	addi	a2,a2,978 # ffffffffc02053d8 <commands+0x870>
ffffffffc020300e:	10200593          	li	a1,258
ffffffffc0203012:	00003517          	auipc	a0,0x3
ffffffffc0203016:	18650513          	addi	a0,a0,390 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020301a:	b5afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(pgdir[0] == 0);
ffffffffc020301e:	00003697          	auipc	a3,0x3
ffffffffc0203022:	f2268693          	addi	a3,a3,-222 # ffffffffc0205f40 <default_pmm_manager+0x7d0>
ffffffffc0203026:	00002617          	auipc	a2,0x2
ffffffffc020302a:	3b260613          	addi	a2,a2,946 # ffffffffc02053d8 <commands+0x870>
ffffffffc020302e:	0f700593          	li	a1,247
ffffffffc0203032:	00003517          	auipc	a0,0x3
ffffffffc0203036:	16650513          	addi	a0,a0,358 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020303a:	b3afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(vma != NULL);
ffffffffc020303e:	00003697          	auipc	a3,0x3
ffffffffc0203042:	f1268693          	addi	a3,a3,-238 # ffffffffc0205f50 <default_pmm_manager+0x7e0>
ffffffffc0203046:	00002617          	auipc	a2,0x2
ffffffffc020304a:	39260613          	addi	a2,a2,914 # ffffffffc02053d8 <commands+0x870>
ffffffffc020304e:	0fa00593          	li	a1,250
ffffffffc0203052:	00003517          	auipc	a0,0x3
ffffffffc0203056:	14650513          	addi	a0,a0,326 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020305a:	b1afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(mm != NULL);
ffffffffc020305e:	00003697          	auipc	a3,0x3
ffffffffc0203062:	eba68693          	addi	a3,a3,-326 # ffffffffc0205f18 <default_pmm_manager+0x7a8>
ffffffffc0203066:	00002617          	auipc	a2,0x2
ffffffffc020306a:	37260613          	addi	a2,a2,882 # ffffffffc02053d8 <commands+0x870>
ffffffffc020306e:	0ef00593          	li	a1,239
ffffffffc0203072:	00003517          	auipc	a0,0x3
ffffffffc0203076:	12650513          	addi	a0,a0,294 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020307a:	afafd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc020307e:	00003697          	auipc	a3,0x3
ffffffffc0203082:	eaa68693          	addi	a3,a3,-342 # ffffffffc0205f28 <default_pmm_manager+0x7b8>
ffffffffc0203086:	00002617          	auipc	a2,0x2
ffffffffc020308a:	35260613          	addi	a2,a2,850 # ffffffffc02053d8 <commands+0x870>
ffffffffc020308e:	0f200593          	li	a1,242
ffffffffc0203092:	00003517          	auipc	a0,0x3
ffffffffc0203096:	10650513          	addi	a0,a0,262 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020309a:	adafd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert( nr_free == 0);         
ffffffffc020309e:	00002697          	auipc	a3,0x2
ffffffffc02030a2:	51268693          	addi	a3,a3,1298 # ffffffffc02055b0 <commands+0xa48>
ffffffffc02030a6:	00002617          	auipc	a2,0x2
ffffffffc02030aa:	33260613          	addi	a2,a2,818 # ffffffffc02053d8 <commands+0x870>
ffffffffc02030ae:	11e00593          	li	a1,286
ffffffffc02030b2:	00003517          	auipc	a0,0x3
ffffffffc02030b6:	0e650513          	addi	a0,a0,230 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02030ba:	abafd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(ret==0);
ffffffffc02030be:	00003697          	auipc	a3,0x3
ffffffffc02030c2:	04a68693          	addi	a3,a3,74 # ffffffffc0206108 <default_pmm_manager+0x998>
ffffffffc02030c6:	00002617          	auipc	a2,0x2
ffffffffc02030ca:	31260613          	addi	a2,a2,786 # ffffffffc02053d8 <commands+0x870>
ffffffffc02030ce:	12d00593          	li	a1,301
ffffffffc02030d2:	00003517          	auipc	a0,0x3
ffffffffc02030d6:	0c650513          	addi	a0,a0,198 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02030da:	a9afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(total == nr_free_pages());
ffffffffc02030de:	00002697          	auipc	a3,0x2
ffffffffc02030e2:	32a68693          	addi	a3,a3,810 # ffffffffc0205408 <commands+0x8a0>
ffffffffc02030e6:	00002617          	auipc	a2,0x2
ffffffffc02030ea:	2f260613          	addi	a2,a2,754 # ffffffffc02053d8 <commands+0x870>
ffffffffc02030ee:	0ea00593          	li	a1,234
ffffffffc02030f2:	00003517          	auipc	a0,0x3
ffffffffc02030f6:	0a650513          	addi	a0,a0,166 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02030fa:	a7afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==1);
ffffffffc02030fe:	00003697          	auipc	a3,0x3
ffffffffc0203102:	f6268693          	addi	a3,a3,-158 # ffffffffc0206060 <default_pmm_manager+0x8f0>
ffffffffc0203106:	00002617          	auipc	a2,0x2
ffffffffc020310a:	2d260613          	addi	a2,a2,722 # ffffffffc02053d8 <commands+0x870>
ffffffffc020310e:	0bd00593          	li	a1,189
ffffffffc0203112:	00003517          	auipc	a0,0x3
ffffffffc0203116:	08650513          	addi	a0,a0,134 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020311a:	a5afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==1);
ffffffffc020311e:	00003697          	auipc	a3,0x3
ffffffffc0203122:	f4268693          	addi	a3,a3,-190 # ffffffffc0206060 <default_pmm_manager+0x8f0>
ffffffffc0203126:	00002617          	auipc	a2,0x2
ffffffffc020312a:	2b260613          	addi	a2,a2,690 # ffffffffc02053d8 <commands+0x870>
ffffffffc020312e:	0bf00593          	li	a1,191
ffffffffc0203132:	00003517          	auipc	a0,0x3
ffffffffc0203136:	06650513          	addi	a0,a0,102 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020313a:	a3afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==2);
ffffffffc020313e:	00003697          	auipc	a3,0x3
ffffffffc0203142:	f3268693          	addi	a3,a3,-206 # ffffffffc0206070 <default_pmm_manager+0x900>
ffffffffc0203146:	00002617          	auipc	a2,0x2
ffffffffc020314a:	29260613          	addi	a2,a2,658 # ffffffffc02053d8 <commands+0x870>
ffffffffc020314e:	0c100593          	li	a1,193
ffffffffc0203152:	00003517          	auipc	a0,0x3
ffffffffc0203156:	04650513          	addi	a0,a0,70 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020315a:	a1afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==2);
ffffffffc020315e:	00003697          	auipc	a3,0x3
ffffffffc0203162:	f1268693          	addi	a3,a3,-238 # ffffffffc0206070 <default_pmm_manager+0x900>
ffffffffc0203166:	00002617          	auipc	a2,0x2
ffffffffc020316a:	27260613          	addi	a2,a2,626 # ffffffffc02053d8 <commands+0x870>
ffffffffc020316e:	0c300593          	li	a1,195
ffffffffc0203172:	00003517          	auipc	a0,0x3
ffffffffc0203176:	02650513          	addi	a0,a0,38 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020317a:	9fafd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==3);
ffffffffc020317e:	00003697          	auipc	a3,0x3
ffffffffc0203182:	f0268693          	addi	a3,a3,-254 # ffffffffc0206080 <default_pmm_manager+0x910>
ffffffffc0203186:	00002617          	auipc	a2,0x2
ffffffffc020318a:	25260613          	addi	a2,a2,594 # ffffffffc02053d8 <commands+0x870>
ffffffffc020318e:	0c500593          	li	a1,197
ffffffffc0203192:	00003517          	auipc	a0,0x3
ffffffffc0203196:	00650513          	addi	a0,a0,6 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020319a:	9dafd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==3);
ffffffffc020319e:	00003697          	auipc	a3,0x3
ffffffffc02031a2:	ee268693          	addi	a3,a3,-286 # ffffffffc0206080 <default_pmm_manager+0x910>
ffffffffc02031a6:	00002617          	auipc	a2,0x2
ffffffffc02031aa:	23260613          	addi	a2,a2,562 # ffffffffc02053d8 <commands+0x870>
ffffffffc02031ae:	0c700593          	li	a1,199
ffffffffc02031b2:	00003517          	auipc	a0,0x3
ffffffffc02031b6:	fe650513          	addi	a0,a0,-26 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02031ba:	9bafd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==4);
ffffffffc02031be:	00003697          	auipc	a3,0x3
ffffffffc02031c2:	ed268693          	addi	a3,a3,-302 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc02031c6:	00002617          	auipc	a2,0x2
ffffffffc02031ca:	21260613          	addi	a2,a2,530 # ffffffffc02053d8 <commands+0x870>
ffffffffc02031ce:	0c900593          	li	a1,201
ffffffffc02031d2:	00003517          	auipc	a0,0x3
ffffffffc02031d6:	fc650513          	addi	a0,a0,-58 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02031da:	99afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==4);
ffffffffc02031de:	00003697          	auipc	a3,0x3
ffffffffc02031e2:	eb268693          	addi	a3,a3,-334 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc02031e6:	00002617          	auipc	a2,0x2
ffffffffc02031ea:	1f260613          	addi	a2,a2,498 # ffffffffc02053d8 <commands+0x870>
ffffffffc02031ee:	0cb00593          	li	a1,203
ffffffffc02031f2:	00003517          	auipc	a0,0x3
ffffffffc02031f6:	fa650513          	addi	a0,a0,-90 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02031fa:	97afd0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02031fe:	00003697          	auipc	a3,0x3
ffffffffc0203202:	e1268693          	addi	a3,a3,-494 # ffffffffc0206010 <default_pmm_manager+0x8a0>
ffffffffc0203206:	00002617          	auipc	a2,0x2
ffffffffc020320a:	1d260613          	addi	a2,a2,466 # ffffffffc02053d8 <commands+0x870>
ffffffffc020320e:	11500593          	li	a1,277
ffffffffc0203212:	00003517          	auipc	a0,0x3
ffffffffc0203216:	f8650513          	addi	a0,a0,-122 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020321a:	95afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==1);
ffffffffc020321e:	00003697          	auipc	a3,0x3
ffffffffc0203222:	e4268693          	addi	a3,a3,-446 # ffffffffc0206060 <default_pmm_manager+0x8f0>
ffffffffc0203226:	00002617          	auipc	a2,0x2
ffffffffc020322a:	1b260613          	addi	a2,a2,434 # ffffffffc02053d8 <commands+0x870>
ffffffffc020322e:	0ab00593          	li	a1,171
ffffffffc0203232:	00003517          	auipc	a0,0x3
ffffffffc0203236:	f6650513          	addi	a0,a0,-154 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020323a:	93afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==2);
ffffffffc020323e:	00003697          	auipc	a3,0x3
ffffffffc0203242:	e3268693          	addi	a3,a3,-462 # ffffffffc0206070 <default_pmm_manager+0x900>
ffffffffc0203246:	00002617          	auipc	a2,0x2
ffffffffc020324a:	19260613          	addi	a2,a2,402 # ffffffffc02053d8 <commands+0x870>
ffffffffc020324e:	0af00593          	li	a1,175
ffffffffc0203252:	00003517          	auipc	a0,0x3
ffffffffc0203256:	f4650513          	addi	a0,a0,-186 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020325a:	91afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==1);
ffffffffc020325e:	00003697          	auipc	a3,0x3
ffffffffc0203262:	e0268693          	addi	a3,a3,-510 # ffffffffc0206060 <default_pmm_manager+0x8f0>
ffffffffc0203266:	00002617          	auipc	a2,0x2
ffffffffc020326a:	17260613          	addi	a2,a2,370 # ffffffffc02053d8 <commands+0x870>
ffffffffc020326e:	0ad00593          	li	a1,173
ffffffffc0203272:	00003517          	auipc	a0,0x3
ffffffffc0203276:	f2650513          	addi	a0,a0,-218 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020327a:	8fafd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==4);
ffffffffc020327e:	00003697          	auipc	a3,0x3
ffffffffc0203282:	e1268693          	addi	a3,a3,-494 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc0203286:	00002617          	auipc	a2,0x2
ffffffffc020328a:	15260613          	addi	a2,a2,338 # ffffffffc02053d8 <commands+0x870>
ffffffffc020328e:	0b700593          	li	a1,183
ffffffffc0203292:	00003517          	auipc	a0,0x3
ffffffffc0203296:	f0650513          	addi	a0,a0,-250 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc020329a:	8dafd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==3);
ffffffffc020329e:	00003697          	auipc	a3,0x3
ffffffffc02032a2:	de268693          	addi	a3,a3,-542 # ffffffffc0206080 <default_pmm_manager+0x910>
ffffffffc02032a6:	00002617          	auipc	a2,0x2
ffffffffc02032aa:	13260613          	addi	a2,a2,306 # ffffffffc02053d8 <commands+0x870>
ffffffffc02032ae:	0b500593          	li	a1,181
ffffffffc02032b2:	00003517          	auipc	a0,0x3
ffffffffc02032b6:	ee650513          	addi	a0,a0,-282 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02032ba:	8bafd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==3);
ffffffffc02032be:	00003697          	auipc	a3,0x3
ffffffffc02032c2:	dc268693          	addi	a3,a3,-574 # ffffffffc0206080 <default_pmm_manager+0x910>
ffffffffc02032c6:	00002617          	auipc	a2,0x2
ffffffffc02032ca:	11260613          	addi	a2,a2,274 # ffffffffc02053d8 <commands+0x870>
ffffffffc02032ce:	0b300593          	li	a1,179
ffffffffc02032d2:	00003517          	auipc	a0,0x3
ffffffffc02032d6:	ec650513          	addi	a0,a0,-314 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02032da:	89afd0ef          	jal	ra,ffffffffc0200374 <__panic>
          assert(pgfault_num==2);
ffffffffc02032de:	00003697          	auipc	a3,0x3
ffffffffc02032e2:	d9268693          	addi	a3,a3,-622 # ffffffffc0206070 <default_pmm_manager+0x900>
ffffffffc02032e6:	00002617          	auipc	a2,0x2
ffffffffc02032ea:	0f260613          	addi	a2,a2,242 # ffffffffc02053d8 <commands+0x870>
ffffffffc02032ee:	0b100593          	li	a1,177
ffffffffc02032f2:	00003517          	auipc	a0,0x3
ffffffffc02032f6:	ea650513          	addi	a0,a0,-346 # ffffffffc0206198 <default_pmm_manager+0xa28>
ffffffffc02032fa:	87afd0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02032fe <lru_write_memory>:
    *(unsigned char *)addr = value;
ffffffffc02032fe:	00b50023          	sb	a1,0(a0)
    lru_update(addr);
ffffffffc0203302:	ee8ff06f          	j	ffffffffc02029ea <lru_update>

ffffffffc0203306 <_clock_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203306:	0000e797          	auipc	a5,0xe
ffffffffc020330a:	2b278793          	addi	a5,a5,690 # ffffffffc02115b8 <pra_list_head>
     // 初始化pra_list_head为空链表
     list_init(&pra_list_head);
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     curr_ptr = &pra_list_head;
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     mm->sm_priv = &pra_list_head;
ffffffffc020330e:	f51c                	sd	a5,40(a0)
ffffffffc0203310:	e79c                	sd	a5,8(a5)
ffffffffc0203312:	e39c                	sd	a5,0(a5)
     curr_ptr = &pra_list_head;
ffffffffc0203314:	0000e717          	auipc	a4,0xe
ffffffffc0203318:	2af73a23          	sd	a5,692(a4) # ffffffffc02115c8 <curr_ptr>
    //  cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc020331c:	4501                	li	a0,0
ffffffffc020331e:	8082                	ret

ffffffffc0203320 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc0203320:	4501                	li	a0,0
ffffffffc0203322:	8082                	ret

ffffffffc0203324 <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203324:	4501                	li	a0,0
ffffffffc0203326:	8082                	ret

ffffffffc0203328 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203328:	4501                	li	a0,0
ffffffffc020332a:	8082                	ret

ffffffffc020332c <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc020332c:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020332e:	678d                	lui	a5,0x3
ffffffffc0203330:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc0203332:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203334:	00e78023          	sb	a4,0(a5) # 3000 <BASE_ADDRESS-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0203338:	0000e797          	auipc	a5,0xe
ffffffffc020333c:	17478793          	addi	a5,a5,372 # ffffffffc02114ac <pgfault_num>
ffffffffc0203340:	4398                	lw	a4,0(a5)
ffffffffc0203342:	4691                	li	a3,4
ffffffffc0203344:	2701                	sext.w	a4,a4
ffffffffc0203346:	08d71f63          	bne	a4,a3,ffffffffc02033e4 <_clock_check_swap+0xb8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020334a:	6685                	lui	a3,0x1
ffffffffc020334c:	4629                	li	a2,10
ffffffffc020334e:	00c68023          	sb	a2,0(a3) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc0203352:	4394                	lw	a3,0(a5)
ffffffffc0203354:	2681                	sext.w	a3,a3
ffffffffc0203356:	20e69763          	bne	a3,a4,ffffffffc0203564 <_clock_check_swap+0x238>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020335a:	6711                	lui	a4,0x4
ffffffffc020335c:	4635                	li	a2,13
ffffffffc020335e:	00c70023          	sb	a2,0(a4) # 4000 <BASE_ADDRESS-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc0203362:	4398                	lw	a4,0(a5)
ffffffffc0203364:	2701                	sext.w	a4,a4
ffffffffc0203366:	1cd71f63          	bne	a4,a3,ffffffffc0203544 <_clock_check_swap+0x218>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020336a:	6689                	lui	a3,0x2
ffffffffc020336c:	462d                	li	a2,11
ffffffffc020336e:	00c68023          	sb	a2,0(a3) # 2000 <BASE_ADDRESS-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc0203372:	4394                	lw	a3,0(a5)
ffffffffc0203374:	2681                	sext.w	a3,a3
ffffffffc0203376:	1ae69763          	bne	a3,a4,ffffffffc0203524 <_clock_check_swap+0x1f8>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc020337a:	6715                	lui	a4,0x5
ffffffffc020337c:	46b9                	li	a3,14
ffffffffc020337e:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc0203382:	4398                	lw	a4,0(a5)
ffffffffc0203384:	4695                	li	a3,5
ffffffffc0203386:	2701                	sext.w	a4,a4
ffffffffc0203388:	16d71e63          	bne	a4,a3,ffffffffc0203504 <_clock_check_swap+0x1d8>
    assert(pgfault_num==5);
ffffffffc020338c:	4394                	lw	a3,0(a5)
ffffffffc020338e:	2681                	sext.w	a3,a3
ffffffffc0203390:	14e69a63          	bne	a3,a4,ffffffffc02034e4 <_clock_check_swap+0x1b8>
    assert(pgfault_num==5);
ffffffffc0203394:	4398                	lw	a4,0(a5)
ffffffffc0203396:	2701                	sext.w	a4,a4
ffffffffc0203398:	12d71663          	bne	a4,a3,ffffffffc02034c4 <_clock_check_swap+0x198>
    assert(pgfault_num==5);
ffffffffc020339c:	4394                	lw	a3,0(a5)
ffffffffc020339e:	2681                	sext.w	a3,a3
ffffffffc02033a0:	10e69263          	bne	a3,a4,ffffffffc02034a4 <_clock_check_swap+0x178>
    assert(pgfault_num==5);
ffffffffc02033a4:	4398                	lw	a4,0(a5)
ffffffffc02033a6:	2701                	sext.w	a4,a4
ffffffffc02033a8:	0cd71e63          	bne	a4,a3,ffffffffc0203484 <_clock_check_swap+0x158>
    assert(pgfault_num==5);
ffffffffc02033ac:	4394                	lw	a3,0(a5)
ffffffffc02033ae:	2681                	sext.w	a3,a3
ffffffffc02033b0:	0ae69a63          	bne	a3,a4,ffffffffc0203464 <_clock_check_swap+0x138>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02033b4:	6715                	lui	a4,0x5
ffffffffc02033b6:	46b9                	li	a3,14
ffffffffc02033b8:	00d70023          	sb	a3,0(a4) # 5000 <BASE_ADDRESS-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02033bc:	4398                	lw	a4,0(a5)
ffffffffc02033be:	4695                	li	a3,5
ffffffffc02033c0:	2701                	sext.w	a4,a4
ffffffffc02033c2:	08d71163          	bne	a4,a3,ffffffffc0203444 <_clock_check_swap+0x118>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02033c6:	6705                	lui	a4,0x1
ffffffffc02033c8:	00074683          	lbu	a3,0(a4) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc02033cc:	4729                	li	a4,10
ffffffffc02033ce:	04e69b63          	bne	a3,a4,ffffffffc0203424 <_clock_check_swap+0xf8>
    assert(pgfault_num==6);
ffffffffc02033d2:	439c                	lw	a5,0(a5)
ffffffffc02033d4:	4719                	li	a4,6
ffffffffc02033d6:	2781                	sext.w	a5,a5
ffffffffc02033d8:	02e79663          	bne	a5,a4,ffffffffc0203404 <_clock_check_swap+0xd8>
}
ffffffffc02033dc:	60a2                	ld	ra,8(sp)
ffffffffc02033de:	4501                	li	a0,0
ffffffffc02033e0:	0141                	addi	sp,sp,16
ffffffffc02033e2:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02033e4:	00003697          	auipc	a3,0x3
ffffffffc02033e8:	cac68693          	addi	a3,a3,-852 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc02033ec:	00002617          	auipc	a2,0x2
ffffffffc02033f0:	fec60613          	addi	a2,a2,-20 # ffffffffc02053d8 <commands+0x870>
ffffffffc02033f4:	08700593          	li	a1,135
ffffffffc02033f8:	00003517          	auipc	a0,0x3
ffffffffc02033fc:	e0850513          	addi	a0,a0,-504 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203400:	f75fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==6);
ffffffffc0203404:	00003697          	auipc	a3,0x3
ffffffffc0203408:	e4c68693          	addi	a3,a3,-436 # ffffffffc0206250 <default_pmm_manager+0xae0>
ffffffffc020340c:	00002617          	auipc	a2,0x2
ffffffffc0203410:	fcc60613          	addi	a2,a2,-52 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203414:	09e00593          	li	a1,158
ffffffffc0203418:	00003517          	auipc	a0,0x3
ffffffffc020341c:	de850513          	addi	a0,a0,-536 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203420:	f55fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203424:	00003697          	auipc	a3,0x3
ffffffffc0203428:	e0468693          	addi	a3,a3,-508 # ffffffffc0206228 <default_pmm_manager+0xab8>
ffffffffc020342c:	00002617          	auipc	a2,0x2
ffffffffc0203430:	fac60613          	addi	a2,a2,-84 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203434:	09c00593          	li	a1,156
ffffffffc0203438:	00003517          	auipc	a0,0x3
ffffffffc020343c:	dc850513          	addi	a0,a0,-568 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203440:	f35fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203444:	00003697          	auipc	a3,0x3
ffffffffc0203448:	dd468693          	addi	a3,a3,-556 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020344c:	00002617          	auipc	a2,0x2
ffffffffc0203450:	f8c60613          	addi	a2,a2,-116 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203454:	09b00593          	li	a1,155
ffffffffc0203458:	00003517          	auipc	a0,0x3
ffffffffc020345c:	da850513          	addi	a0,a0,-600 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203460:	f15fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203464:	00003697          	auipc	a3,0x3
ffffffffc0203468:	db468693          	addi	a3,a3,-588 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020346c:	00002617          	auipc	a2,0x2
ffffffffc0203470:	f6c60613          	addi	a2,a2,-148 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203474:	09900593          	li	a1,153
ffffffffc0203478:	00003517          	auipc	a0,0x3
ffffffffc020347c:	d8850513          	addi	a0,a0,-632 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203480:	ef5fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203484:	00003697          	auipc	a3,0x3
ffffffffc0203488:	d9468693          	addi	a3,a3,-620 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020348c:	00002617          	auipc	a2,0x2
ffffffffc0203490:	f4c60613          	addi	a2,a2,-180 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203494:	09700593          	li	a1,151
ffffffffc0203498:	00003517          	auipc	a0,0x3
ffffffffc020349c:	d6850513          	addi	a0,a0,-664 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc02034a0:	ed5fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc02034a4:	00003697          	auipc	a3,0x3
ffffffffc02034a8:	d7468693          	addi	a3,a3,-652 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc02034ac:	00002617          	auipc	a2,0x2
ffffffffc02034b0:	f2c60613          	addi	a2,a2,-212 # ffffffffc02053d8 <commands+0x870>
ffffffffc02034b4:	09500593          	li	a1,149
ffffffffc02034b8:	00003517          	auipc	a0,0x3
ffffffffc02034bc:	d4850513          	addi	a0,a0,-696 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc02034c0:	eb5fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc02034c4:	00003697          	auipc	a3,0x3
ffffffffc02034c8:	d5468693          	addi	a3,a3,-684 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc02034cc:	00002617          	auipc	a2,0x2
ffffffffc02034d0:	f0c60613          	addi	a2,a2,-244 # ffffffffc02053d8 <commands+0x870>
ffffffffc02034d4:	09300593          	li	a1,147
ffffffffc02034d8:	00003517          	auipc	a0,0x3
ffffffffc02034dc:	d2850513          	addi	a0,a0,-728 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc02034e0:	e95fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc02034e4:	00003697          	auipc	a3,0x3
ffffffffc02034e8:	d3468693          	addi	a3,a3,-716 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc02034ec:	00002617          	auipc	a2,0x2
ffffffffc02034f0:	eec60613          	addi	a2,a2,-276 # ffffffffc02053d8 <commands+0x870>
ffffffffc02034f4:	09100593          	li	a1,145
ffffffffc02034f8:	00003517          	auipc	a0,0x3
ffffffffc02034fc:	d0850513          	addi	a0,a0,-760 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203500:	e75fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203504:	00003697          	auipc	a3,0x3
ffffffffc0203508:	d1468693          	addi	a3,a3,-748 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020350c:	00002617          	auipc	a2,0x2
ffffffffc0203510:	ecc60613          	addi	a2,a2,-308 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203514:	08f00593          	li	a1,143
ffffffffc0203518:	00003517          	auipc	a0,0x3
ffffffffc020351c:	ce850513          	addi	a0,a0,-792 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203520:	e55fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==4);
ffffffffc0203524:	00003697          	auipc	a3,0x3
ffffffffc0203528:	b6c68693          	addi	a3,a3,-1172 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc020352c:	00002617          	auipc	a2,0x2
ffffffffc0203530:	eac60613          	addi	a2,a2,-340 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203534:	08d00593          	li	a1,141
ffffffffc0203538:	00003517          	auipc	a0,0x3
ffffffffc020353c:	cc850513          	addi	a0,a0,-824 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203540:	e35fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==4);
ffffffffc0203544:	00003697          	auipc	a3,0x3
ffffffffc0203548:	b4c68693          	addi	a3,a3,-1204 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc020354c:	00002617          	auipc	a2,0x2
ffffffffc0203550:	e8c60613          	addi	a2,a2,-372 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203554:	08b00593          	li	a1,139
ffffffffc0203558:	00003517          	auipc	a0,0x3
ffffffffc020355c:	ca850513          	addi	a0,a0,-856 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203560:	e15fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==4);
ffffffffc0203564:	00003697          	auipc	a3,0x3
ffffffffc0203568:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc020356c:	00002617          	auipc	a2,0x2
ffffffffc0203570:	e6c60613          	addi	a2,a2,-404 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203574:	08900593          	li	a1,137
ffffffffc0203578:	00003517          	auipc	a0,0x3
ffffffffc020357c:	c8850513          	addi	a0,a0,-888 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc0203580:	df5fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203584 <_clock_map_swappable>:
    list_entry_t *entry = &(page->pra_page_link);
ffffffffc0203584:	03060793          	addi	a5,a2,48
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0203588:	c79d                	beqz	a5,ffffffffc02035b6 <_clock_map_swappable+0x32>
ffffffffc020358a:	0000e717          	auipc	a4,0xe
ffffffffc020358e:	03e70713          	addi	a4,a4,62 # ffffffffc02115c8 <curr_ptr>
ffffffffc0203592:	6318                	ld	a4,0(a4)
ffffffffc0203594:	c30d                	beqz	a4,ffffffffc02035b6 <_clock_map_swappable+0x32>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203596:	0000e697          	auipc	a3,0xe
ffffffffc020359a:	02268693          	addi	a3,a3,34 # ffffffffc02115b8 <pra_list_head>
ffffffffc020359e:	6298                	ld	a4,0(a3)
    prev->next = next->prev = elm;
ffffffffc02035a0:	0000e597          	auipc	a1,0xe
ffffffffc02035a4:	00f5bc23          	sd	a5,24(a1) # ffffffffc02115b8 <pra_list_head>
}
ffffffffc02035a8:	4501                	li	a0,0
ffffffffc02035aa:	e71c                	sd	a5,8(a4)
    page->visited = 1;
ffffffffc02035ac:	4785                	li	a5,1
    elm->next = next;
ffffffffc02035ae:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc02035b0:	fa18                	sd	a4,48(a2)
ffffffffc02035b2:	ea1c                	sd	a5,16(a2)
}
ffffffffc02035b4:	8082                	ret
{
ffffffffc02035b6:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02035b8:	00003697          	auipc	a3,0x3
ffffffffc02035bc:	ca868693          	addi	a3,a3,-856 # ffffffffc0206260 <default_pmm_manager+0xaf0>
ffffffffc02035c0:	00002617          	auipc	a2,0x2
ffffffffc02035c4:	e1860613          	addi	a2,a2,-488 # ffffffffc02053d8 <commands+0x870>
ffffffffc02035c8:	03600593          	li	a1,54
ffffffffc02035cc:	00003517          	auipc	a0,0x3
ffffffffc02035d0:	c3450513          	addi	a0,a0,-972 # ffffffffc0206200 <default_pmm_manager+0xa90>
{
ffffffffc02035d4:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc02035d6:	d9ffc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02035da <_clock_swap_out_victim>:
    assert(head != NULL);
ffffffffc02035da:	751c                	ld	a5,40(a0)
{
ffffffffc02035dc:	1101                	addi	sp,sp,-32
ffffffffc02035de:	ec06                	sd	ra,24(sp)
ffffffffc02035e0:	e822                	sd	s0,16(sp)
ffffffffc02035e2:	e426                	sd	s1,8(sp)
ffffffffc02035e4:	e04a                	sd	s2,0(sp)
    assert(head != NULL);
ffffffffc02035e6:	c7ad                	beqz	a5,ffffffffc0203650 <_clock_swap_out_victim+0x76>
    assert(in_tick==0);
ffffffffc02035e8:	e641                	bnez	a2,ffffffffc0203670 <_clock_swap_out_victim+0x96>
ffffffffc02035ea:	0000e497          	auipc	s1,0xe
ffffffffc02035ee:	fde48493          	addi	s1,s1,-34 # ffffffffc02115c8 <curr_ptr>
    return listelm->next;
ffffffffc02035f2:	0000e717          	auipc	a4,0xe
ffffffffc02035f6:	fc670713          	addi	a4,a4,-58 # ffffffffc02115b8 <pra_list_head>
ffffffffc02035fa:	892e                	mv	s2,a1
ffffffffc02035fc:	6080                	ld	s0,0(s1)
ffffffffc02035fe:	6714                	ld	a3,8(a4)
ffffffffc0203600:	a031                	j	ffffffffc020360c <_clock_swap_out_victim+0x32>
        if(!page->visited){
ffffffffc0203602:	fe043783          	ld	a5,-32(s0)
ffffffffc0203606:	cb91                	beqz	a5,ffffffffc020361a <_clock_swap_out_victim+0x40>
        page->visited = 0;
ffffffffc0203608:	fe043023          	sd	zero,-32(s0)
ffffffffc020360c:	6400                	ld	s0,8(s0)
        if(curr_ptr == &pra_list_head)
ffffffffc020360e:	fee41ae3          	bne	s0,a4,ffffffffc0203602 <_clock_swap_out_victim+0x28>
            curr_ptr = list_next(curr_ptr);
ffffffffc0203612:	8436                	mv	s0,a3
        if(!page->visited){
ffffffffc0203614:	fe043783          	ld	a5,-32(s0)
ffffffffc0203618:	fbe5                	bnez	a5,ffffffffc0203608 <_clock_swap_out_victim+0x2e>
            cprintf("curr_ptr 0xffffffff%x",curr_ptr);                
ffffffffc020361a:	85a2                	mv	a1,s0
ffffffffc020361c:	00003517          	auipc	a0,0x3
ffffffffc0203620:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206298 <default_pmm_manager+0xb28>
ffffffffc0203624:	0000e797          	auipc	a5,0xe
ffffffffc0203628:	fa87b223          	sd	s0,-92(a5) # ffffffffc02115c8 <curr_ptr>
ffffffffc020362c:	a93fc0ef          	jal	ra,ffffffffc02000be <cprintf>
            list_del(curr_ptr);
ffffffffc0203630:	609c                	ld	a5,0(s1)
        struct Page* page = le2page(curr_ptr,pra_page_link);
ffffffffc0203632:	fd040413          	addi	s0,s0,-48
}
ffffffffc0203636:	60e2                	ld	ra,24(sp)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203638:	6398                	ld	a4,0(a5)
ffffffffc020363a:	679c                	ld	a5,8(a5)
ffffffffc020363c:	64a2                	ld	s1,8(sp)
ffffffffc020363e:	4501                	li	a0,0
    prev->next = next;
ffffffffc0203640:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203642:	e398                	sd	a4,0(a5)
            *ptr_page = page;
ffffffffc0203644:	00893023          	sd	s0,0(s2)
}
ffffffffc0203648:	6442                	ld	s0,16(sp)
ffffffffc020364a:	6902                	ld	s2,0(sp)
ffffffffc020364c:	6105                	addi	sp,sp,32
ffffffffc020364e:	8082                	ret
    assert(head != NULL);
ffffffffc0203650:	00002697          	auipc	a3,0x2
ffffffffc0203654:	7c068693          	addi	a3,a3,1984 # ffffffffc0205e10 <default_pmm_manager+0x6a0>
ffffffffc0203658:	00002617          	auipc	a2,0x2
ffffffffc020365c:	d8060613          	addi	a2,a2,-640 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203660:	04800593          	li	a1,72
ffffffffc0203664:	00003517          	auipc	a0,0x3
ffffffffc0203668:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc020366c:	d09fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(in_tick==0);
ffffffffc0203670:	00003697          	auipc	a3,0x3
ffffffffc0203674:	c1868693          	addi	a3,a3,-1000 # ffffffffc0206288 <default_pmm_manager+0xb18>
ffffffffc0203678:	00002617          	auipc	a2,0x2
ffffffffc020367c:	d6060613          	addi	a2,a2,-672 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203680:	04900593          	li	a1,73
ffffffffc0203684:	00003517          	auipc	a0,0x3
ffffffffc0203688:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206200 <default_pmm_manager+0xa90>
ffffffffc020368c:	ce9fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203690 <_lru_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203690:	0000e797          	auipc	a5,0xe
ffffffffc0203694:	f2878793          	addi	a5,a5,-216 # ffffffffc02115b8 <pra_list_head>
 */
static int
_lru_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203698:	f51c                	sd	a5,40(a0)
ffffffffc020369a:	e79c                	sd	a5,8(a5)
ffffffffc020369c:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    curr_ptr = &pra_list_head;
ffffffffc020369e:	0000e717          	auipc	a4,0xe
ffffffffc02036a2:	f2f73523          	sd	a5,-214(a4) # ffffffffc02115c8 <curr_ptr>
     return 0;
}
ffffffffc02036a6:	4501                	li	a0,0
ffffffffc02036a8:	8082                	ret

ffffffffc02036aa <_lru_init>:

static int
_lru_init(void)
{
    return 0;
}
ffffffffc02036aa:	4501                	li	a0,0
ffffffffc02036ac:	8082                	ret

ffffffffc02036ae <_lru_set_unswappable>:

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc02036ae:	4501                	li	a0,0
ffffffffc02036b0:	8082                	ret

ffffffffc02036b2 <_lru_tick_event>:

static int
_lru_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc02036b2:	4501                	li	a0,0
ffffffffc02036b4:	8082                	ret

ffffffffc02036b6 <_lru_check_swap>:
_lru_check_swap(void) {
ffffffffc02036b6:	1101                	addi	sp,sp,-32
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc02036b8:	00003517          	auipc	a0,0x3
ffffffffc02036bc:	c1050513          	addi	a0,a0,-1008 # ffffffffc02062c8 <default_pmm_manager+0xb58>
_lru_check_swap(void) {
ffffffffc02036c0:	ec06                	sd	ra,24(sp)
ffffffffc02036c2:	e822                	sd	s0,16(sp)
ffffffffc02036c4:	e426                	sd	s1,8(sp)
ffffffffc02036c6:	e04a                	sd	s2,0(sp)
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc02036c8:	9f7fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x3000,0x0c);
ffffffffc02036cc:	45b1                	li	a1,12
ffffffffc02036ce:	650d                	lui	a0,0x3
    assert(pgfault_num==4);
ffffffffc02036d0:	0000e417          	auipc	s0,0xe
ffffffffc02036d4:	ddc40413          	addi	s0,s0,-548 # ffffffffc02114ac <pgfault_num>
    lru_write_memory(0x3000,0x0c);
ffffffffc02036d8:	c27ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==4);
ffffffffc02036dc:	4004                	lw	s1,0(s0)
ffffffffc02036de:	4791                	li	a5,4
ffffffffc02036e0:	2481                	sext.w	s1,s1
ffffffffc02036e2:	16f49063          	bne	s1,a5,ffffffffc0203842 <_lru_check_swap+0x18c>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc02036e6:	00003517          	auipc	a0,0x3
ffffffffc02036ea:	c2250513          	addi	a0,a0,-990 # ffffffffc0206308 <default_pmm_manager+0xb98>
ffffffffc02036ee:	9d1fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x1000,0x0a);
ffffffffc02036f2:	45a9                	li	a1,10
ffffffffc02036f4:	6505                	lui	a0,0x1
ffffffffc02036f6:	c09ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==4);
ffffffffc02036fa:	00042903          	lw	s2,0(s0)
ffffffffc02036fe:	2901                	sext.w	s2,s2
ffffffffc0203700:	2c991163          	bne	s2,s1,ffffffffc02039c2 <_lru_check_swap+0x30c>
    cprintf("write Virt Page d in lru_check_swap\n");
ffffffffc0203704:	00003517          	auipc	a0,0x3
ffffffffc0203708:	c2c50513          	addi	a0,a0,-980 # ffffffffc0206330 <default_pmm_manager+0xbc0>
ffffffffc020370c:	9b3fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x4000 ,0x0d);
ffffffffc0203710:	45b5                	li	a1,13
ffffffffc0203712:	6511                	lui	a0,0x4
ffffffffc0203714:	bebff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==4);
ffffffffc0203718:	4004                	lw	s1,0(s0)
ffffffffc020371a:	2481                	sext.w	s1,s1
ffffffffc020371c:	29249363          	bne	s1,s2,ffffffffc02039a2 <_lru_check_swap+0x2ec>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0203720:	00003517          	auipc	a0,0x3
ffffffffc0203724:	c3850513          	addi	a0,a0,-968 # ffffffffc0206358 <default_pmm_manager+0xbe8>
ffffffffc0203728:	997fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x2000 ,0x0b);
ffffffffc020372c:	45ad                	li	a1,11
ffffffffc020372e:	6509                	lui	a0,0x2
ffffffffc0203730:	bcfff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==4);
ffffffffc0203734:	401c                	lw	a5,0(s0)
ffffffffc0203736:	2781                	sext.w	a5,a5
ffffffffc0203738:	24979563          	bne	a5,s1,ffffffffc0203982 <_lru_check_swap+0x2cc>
    cprintf("write Virt Page e in lru_check_swap\n");
ffffffffc020373c:	00003517          	auipc	a0,0x3
ffffffffc0203740:	c4450513          	addi	a0,a0,-956 # ffffffffc0206380 <default_pmm_manager+0xc10>
ffffffffc0203744:	97bfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x5000 ,0x0e);
ffffffffc0203748:	45b9                	li	a1,14
ffffffffc020374a:	6515                	lui	a0,0x5
ffffffffc020374c:	bb3ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==5);
ffffffffc0203750:	4004                	lw	s1,0(s0)
ffffffffc0203752:	4795                	li	a5,5
ffffffffc0203754:	2481                	sext.w	s1,s1
ffffffffc0203756:	20f49663          	bne	s1,a5,ffffffffc0203962 <_lru_check_swap+0x2ac>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc020375a:	00003517          	auipc	a0,0x3
ffffffffc020375e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0206358 <default_pmm_manager+0xbe8>
ffffffffc0203762:	95dfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x2000 ,0x0b);
ffffffffc0203766:	45ad                	li	a1,11
ffffffffc0203768:	6509                	lui	a0,0x2
ffffffffc020376a:	b95ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==5);
ffffffffc020376e:	00042903          	lw	s2,0(s0)
ffffffffc0203772:	2901                	sext.w	s2,s2
ffffffffc0203774:	1c991763          	bne	s2,s1,ffffffffc0203942 <_lru_check_swap+0x28c>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc0203778:	00003517          	auipc	a0,0x3
ffffffffc020377c:	b9050513          	addi	a0,a0,-1136 # ffffffffc0206308 <default_pmm_manager+0xb98>
ffffffffc0203780:	93ffc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x1000 ,0x0a);
ffffffffc0203784:	45a9                	li	a1,10
ffffffffc0203786:	6505                	lui	a0,0x1
ffffffffc0203788:	b77ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==5);
ffffffffc020378c:	4004                	lw	s1,0(s0)
ffffffffc020378e:	2481                	sext.w	s1,s1
ffffffffc0203790:	19249963          	bne	s1,s2,ffffffffc0203922 <_lru_check_swap+0x26c>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0203794:	00003517          	auipc	a0,0x3
ffffffffc0203798:	bc450513          	addi	a0,a0,-1084 # ffffffffc0206358 <default_pmm_manager+0xbe8>
ffffffffc020379c:	923fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x2000 ,0x0b);
ffffffffc02037a0:	45ad                	li	a1,11
ffffffffc02037a2:	6509                	lui	a0,0x2
ffffffffc02037a4:	b5bff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==5);
ffffffffc02037a8:	401c                	lw	a5,0(s0)
ffffffffc02037aa:	2781                	sext.w	a5,a5
ffffffffc02037ac:	14979b63          	bne	a5,s1,ffffffffc0203902 <_lru_check_swap+0x24c>
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc02037b0:	00003517          	auipc	a0,0x3
ffffffffc02037b4:	b1850513          	addi	a0,a0,-1256 # ffffffffc02062c8 <default_pmm_manager+0xb58>
ffffffffc02037b8:	907fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x3000 ,0x0c);
ffffffffc02037bc:	45b1                	li	a1,12
ffffffffc02037be:	650d                	lui	a0,0x3
ffffffffc02037c0:	b3fff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==6);
ffffffffc02037c4:	401c                	lw	a5,0(s0)
ffffffffc02037c6:	4719                	li	a4,6
ffffffffc02037c8:	2781                	sext.w	a5,a5
ffffffffc02037ca:	10e79c63          	bne	a5,a4,ffffffffc02038e2 <_lru_check_swap+0x22c>
    cprintf("write Virt Page d in lru_check_swap\n");
ffffffffc02037ce:	00003517          	auipc	a0,0x3
ffffffffc02037d2:	b6250513          	addi	a0,a0,-1182 # ffffffffc0206330 <default_pmm_manager+0xbc0>
ffffffffc02037d6:	8e9fc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x4000 ,0x0d);
ffffffffc02037da:	45b5                	li	a1,13
ffffffffc02037dc:	6511                	lui	a0,0x4
ffffffffc02037de:	b21ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==7);
ffffffffc02037e2:	401c                	lw	a5,0(s0)
ffffffffc02037e4:	471d                	li	a4,7
ffffffffc02037e6:	2781                	sext.w	a5,a5
ffffffffc02037e8:	0ce79d63          	bne	a5,a4,ffffffffc02038c2 <_lru_check_swap+0x20c>
    cprintf("write Virt Page e in lru_check_swap\n");
ffffffffc02037ec:	00003517          	auipc	a0,0x3
ffffffffc02037f0:	b9450513          	addi	a0,a0,-1132 # ffffffffc0206380 <default_pmm_manager+0xc10>
ffffffffc02037f4:	8cbfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    lru_write_memory(0x5000 ,0x0e);
ffffffffc02037f8:	45b9                	li	a1,14
ffffffffc02037fa:	6515                	lui	a0,0x5
ffffffffc02037fc:	b03ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==8);
ffffffffc0203800:	401c                	lw	a5,0(s0)
ffffffffc0203802:	4721                	li	a4,8
ffffffffc0203804:	2781                	sext.w	a5,a5
ffffffffc0203806:	08e79e63          	bne	a5,a4,ffffffffc02038a2 <_lru_check_swap+0x1ec>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc020380a:	00003517          	auipc	a0,0x3
ffffffffc020380e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0206308 <default_pmm_manager+0xb98>
ffffffffc0203812:	8adfc0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203816:	6785                	lui	a5,0x1
ffffffffc0203818:	0007c703          	lbu	a4,0(a5) # 1000 <BASE_ADDRESS-0xffffffffc01ff000>
ffffffffc020381c:	47a9                	li	a5,10
ffffffffc020381e:	06f71263          	bne	a4,a5,ffffffffc0203882 <_lru_check_swap+0x1cc>
    lru_write_memory(0x1000 ,0x0a);
ffffffffc0203822:	45a9                	li	a1,10
ffffffffc0203824:	6505                	lui	a0,0x1
ffffffffc0203826:	ad9ff0ef          	jal	ra,ffffffffc02032fe <lru_write_memory>
    assert(pgfault_num==9);
ffffffffc020382a:	401c                	lw	a5,0(s0)
ffffffffc020382c:	4725                	li	a4,9
ffffffffc020382e:	2781                	sext.w	a5,a5
ffffffffc0203830:	02e79963          	bne	a5,a4,ffffffffc0203862 <_lru_check_swap+0x1ac>
}
ffffffffc0203834:	60e2                	ld	ra,24(sp)
ffffffffc0203836:	6442                	ld	s0,16(sp)
ffffffffc0203838:	64a2                	ld	s1,8(sp)
ffffffffc020383a:	6902                	ld	s2,0(sp)
ffffffffc020383c:	4501                	li	a0,0
ffffffffc020383e:	6105                	addi	sp,sp,32
ffffffffc0203840:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203842:	00003697          	auipc	a3,0x3
ffffffffc0203846:	84e68693          	addi	a3,a3,-1970 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc020384a:	00002617          	auipc	a2,0x2
ffffffffc020384e:	b8e60613          	addi	a2,a2,-1138 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203852:	06300593          	li	a1,99
ffffffffc0203856:	00003517          	auipc	a0,0x3
ffffffffc020385a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020385e:	b17fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==9);
ffffffffc0203862:	00003697          	auipc	a3,0x3
ffffffffc0203866:	b6668693          	addi	a3,a3,-1178 # ffffffffc02063c8 <default_pmm_manager+0xc58>
ffffffffc020386a:	00002617          	auipc	a2,0x2
ffffffffc020386e:	b6e60613          	addi	a2,a2,-1170 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203872:	08500593          	li	a1,133
ffffffffc0203876:	00003517          	auipc	a0,0x3
ffffffffc020387a:	a7a50513          	addi	a0,a0,-1414 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020387e:	af7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203882:	00003697          	auipc	a3,0x3
ffffffffc0203886:	9a668693          	addi	a3,a3,-1626 # ffffffffc0206228 <default_pmm_manager+0xab8>
ffffffffc020388a:	00002617          	auipc	a2,0x2
ffffffffc020388e:	b4e60613          	addi	a2,a2,-1202 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203892:	08300593          	li	a1,131
ffffffffc0203896:	00003517          	auipc	a0,0x3
ffffffffc020389a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020389e:	ad7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==8);
ffffffffc02038a2:	00003697          	auipc	a3,0x3
ffffffffc02038a6:	b1668693          	addi	a3,a3,-1258 # ffffffffc02063b8 <default_pmm_manager+0xc48>
ffffffffc02038aa:	00002617          	auipc	a2,0x2
ffffffffc02038ae:	b2e60613          	addi	a2,a2,-1234 # ffffffffc02053d8 <commands+0x870>
ffffffffc02038b2:	08100593          	li	a1,129
ffffffffc02038b6:	00003517          	auipc	a0,0x3
ffffffffc02038ba:	a3a50513          	addi	a0,a0,-1478 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc02038be:	ab7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==7);
ffffffffc02038c2:	00003697          	auipc	a3,0x3
ffffffffc02038c6:	ae668693          	addi	a3,a3,-1306 # ffffffffc02063a8 <default_pmm_manager+0xc38>
ffffffffc02038ca:	00002617          	auipc	a2,0x2
ffffffffc02038ce:	b0e60613          	addi	a2,a2,-1266 # ffffffffc02053d8 <commands+0x870>
ffffffffc02038d2:	07e00593          	li	a1,126
ffffffffc02038d6:	00003517          	auipc	a0,0x3
ffffffffc02038da:	a1a50513          	addi	a0,a0,-1510 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc02038de:	a97fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==6);
ffffffffc02038e2:	00003697          	auipc	a3,0x3
ffffffffc02038e6:	96e68693          	addi	a3,a3,-1682 # ffffffffc0206250 <default_pmm_manager+0xae0>
ffffffffc02038ea:	00002617          	auipc	a2,0x2
ffffffffc02038ee:	aee60613          	addi	a2,a2,-1298 # ffffffffc02053d8 <commands+0x870>
ffffffffc02038f2:	07b00593          	li	a1,123
ffffffffc02038f6:	00003517          	auipc	a0,0x3
ffffffffc02038fa:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc02038fe:	a77fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203902:	00003697          	auipc	a3,0x3
ffffffffc0203906:	91668693          	addi	a3,a3,-1770 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020390a:	00002617          	auipc	a2,0x2
ffffffffc020390e:	ace60613          	addi	a2,a2,-1330 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203912:	07800593          	li	a1,120
ffffffffc0203916:	00003517          	auipc	a0,0x3
ffffffffc020391a:	9da50513          	addi	a0,a0,-1574 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020391e:	a57fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203922:	00003697          	auipc	a3,0x3
ffffffffc0203926:	8f668693          	addi	a3,a3,-1802 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020392a:	00002617          	auipc	a2,0x2
ffffffffc020392e:	aae60613          	addi	a2,a2,-1362 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203932:	07500593          	li	a1,117
ffffffffc0203936:	00003517          	auipc	a0,0x3
ffffffffc020393a:	9ba50513          	addi	a0,a0,-1606 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020393e:	a37fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203942:	00003697          	auipc	a3,0x3
ffffffffc0203946:	8d668693          	addi	a3,a3,-1834 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020394a:	00002617          	auipc	a2,0x2
ffffffffc020394e:	a8e60613          	addi	a2,a2,-1394 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203952:	07200593          	li	a1,114
ffffffffc0203956:	00003517          	auipc	a0,0x3
ffffffffc020395a:	99a50513          	addi	a0,a0,-1638 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020395e:	a17fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==5);
ffffffffc0203962:	00003697          	auipc	a3,0x3
ffffffffc0203966:	8b668693          	addi	a3,a3,-1866 # ffffffffc0206218 <default_pmm_manager+0xaa8>
ffffffffc020396a:	00002617          	auipc	a2,0x2
ffffffffc020396e:	a6e60613          	addi	a2,a2,-1426 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203972:	06f00593          	li	a1,111
ffffffffc0203976:	00003517          	auipc	a0,0x3
ffffffffc020397a:	97a50513          	addi	a0,a0,-1670 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020397e:	9f7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==4);
ffffffffc0203982:	00002697          	auipc	a3,0x2
ffffffffc0203986:	70e68693          	addi	a3,a3,1806 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc020398a:	00002617          	auipc	a2,0x2
ffffffffc020398e:	a4e60613          	addi	a2,a2,-1458 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203992:	06c00593          	li	a1,108
ffffffffc0203996:	00003517          	auipc	a0,0x3
ffffffffc020399a:	95a50513          	addi	a0,a0,-1702 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc020399e:	9d7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==4);
ffffffffc02039a2:	00002697          	auipc	a3,0x2
ffffffffc02039a6:	6ee68693          	addi	a3,a3,1774 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc02039aa:	00002617          	auipc	a2,0x2
ffffffffc02039ae:	a2e60613          	addi	a2,a2,-1490 # ffffffffc02053d8 <commands+0x870>
ffffffffc02039b2:	06900593          	li	a1,105
ffffffffc02039b6:	00003517          	auipc	a0,0x3
ffffffffc02039ba:	93a50513          	addi	a0,a0,-1734 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc02039be:	9b7fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgfault_num==4);
ffffffffc02039c2:	00002697          	auipc	a3,0x2
ffffffffc02039c6:	6ce68693          	addi	a3,a3,1742 # ffffffffc0206090 <default_pmm_manager+0x920>
ffffffffc02039ca:	00002617          	auipc	a2,0x2
ffffffffc02039ce:	a0e60613          	addi	a2,a2,-1522 # ffffffffc02053d8 <commands+0x870>
ffffffffc02039d2:	06600593          	li	a1,102
ffffffffc02039d6:	00003517          	auipc	a0,0x3
ffffffffc02039da:	91a50513          	addi	a0,a0,-1766 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc02039de:	997fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02039e2 <_lru_swap_out_victim>:
{
ffffffffc02039e2:	715d                	addi	sp,sp,-80
ffffffffc02039e4:	f84a                	sd	s2,48(sp)
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02039e6:	02853903          	ld	s2,40(a0)
{
ffffffffc02039ea:	e486                	sd	ra,72(sp)
ffffffffc02039ec:	e0a2                	sd	s0,64(sp)
ffffffffc02039ee:	fc26                	sd	s1,56(sp)
ffffffffc02039f0:	f44e                	sd	s3,40(sp)
ffffffffc02039f2:	f052                	sd	s4,32(sp)
ffffffffc02039f4:	ec56                	sd	s5,24(sp)
ffffffffc02039f6:	e85a                	sd	s6,16(sp)
ffffffffc02039f8:	e45e                	sd	s7,8(sp)
ffffffffc02039fa:	e062                	sd	s8,0(sp)
         assert(head != NULL);
ffffffffc02039fc:	0c090863          	beqz	s2,ffffffffc0203acc <_lru_swap_out_victim+0xea>
     assert(in_tick==0);
ffffffffc0203a00:	e675                	bnez	a2,ffffffffc0203aec <_lru_swap_out_victim+0x10a>
    list_entry_t *le = head->next;
ffffffffc0203a02:	00893403          	ld	s0,8(s2)
    cprintf("\nPage swap out begin\n");
ffffffffc0203a06:	00003517          	auipc	a0,0x3
ffffffffc0203a0a:	9f250513          	addi	a0,a0,-1550 # ffffffffc02063f8 <default_pmm_manager+0xc88>
ffffffffc0203a0e:	8bae                	mv	s7,a1
ffffffffc0203a10:	eaefc0ef          	jal	ra,ffffffffc02000be <cprintf>
    while (le!=head) {
ffffffffc0203a14:	00003797          	auipc	a5,0x3
ffffffffc0203a18:	00c78793          	addi	a5,a5,12 # ffffffffc0206a20 <nbase>
ffffffffc0203a1c:	0007b983          	ld	s3,0(a5)
    uint_t max = 0;
ffffffffc0203a20:	4481                	li	s1,0
ffffffffc0203a22:	0000ec17          	auipc	s8,0xe
ffffffffc0203a26:	ac6c0c13          	addi	s8,s8,-1338 # ffffffffc02114e8 <pages>
ffffffffc0203a2a:	00002b17          	auipc	s6,0x2
ffffffffc0203a2e:	996b0b13          	addi	s6,s6,-1642 # ffffffffc02053c0 <commands+0x858>
    while (le!=head) {
ffffffffc0203a32:	04890063          	beq	s2,s0,ffffffffc0203a72 <_lru_swap_out_victim+0x90>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0203a36:	000b3a83          	ld	s5,0(s6)
        cprintf("Page:%x,Page.visited:%d\n",page2ppn(page),page->visited);
ffffffffc0203a3a:	00003a17          	auipc	s4,0x3
ffffffffc0203a3e:	9f6a0a13          	addi	s4,s4,-1546 # ffffffffc0206430 <default_pmm_manager+0xcc0>
        if(page->visited >= max){
ffffffffc0203a42:	fe043603          	ld	a2,-32(s0)
        struct Page* page = le2page(le,pra_page_link);
ffffffffc0203a46:	fd040593          	addi	a1,s0,-48
        if(page->visited >= max){
ffffffffc0203a4a:	00966763          	bltu	a2,s1,ffffffffc0203a58 <_lru_swap_out_victim+0x76>
            curr_ptr = le;
ffffffffc0203a4e:	0000e797          	auipc	a5,0xe
ffffffffc0203a52:	b687bd23          	sd	s0,-1158(a5) # ffffffffc02115c8 <curr_ptr>
ffffffffc0203a56:	84b2                	mv	s1,a2
ffffffffc0203a58:	000c3783          	ld	a5,0(s8)
        cprintf("Page:%x,Page.visited:%d\n",page2ppn(page),page->visited);
ffffffffc0203a5c:	8552                	mv	a0,s4
ffffffffc0203a5e:	8d9d                	sub	a1,a1,a5
ffffffffc0203a60:	858d                	srai	a1,a1,0x3
ffffffffc0203a62:	035585b3          	mul	a1,a1,s5
ffffffffc0203a66:	95ce                	add	a1,a1,s3
ffffffffc0203a68:	e56fc0ef          	jal	ra,ffffffffc02000be <cprintf>
        le = le->next;
ffffffffc0203a6c:	6400                	ld	s0,8(s0)
    while (le!=head) {
ffffffffc0203a6e:	fc891ae3          	bne	s2,s0,ffffffffc0203a42 <_lru_swap_out_victim+0x60>
    *ptr_page = le2page(curr_ptr,pra_page_link);
ffffffffc0203a72:	0000e417          	auipc	s0,0xe
ffffffffc0203a76:	b5640413          	addi	s0,s0,-1194 # ffffffffc02115c8 <curr_ptr>
ffffffffc0203a7a:	6018                	ld	a4,0(s0)
ffffffffc0203a7c:	000b3683          	ld	a3,0(s6)
    cprintf("vitim Page:%x,Page.visited:%d\n\n",page2ppn(*ptr_page),(*ptr_page)->visited);
ffffffffc0203a80:	00003517          	auipc	a0,0x3
ffffffffc0203a84:	99050513          	addi	a0,a0,-1648 # ffffffffc0206410 <default_pmm_manager+0xca0>
    *ptr_page = le2page(curr_ptr,pra_page_link);
ffffffffc0203a88:	fd070793          	addi	a5,a4,-48
ffffffffc0203a8c:	00fbb023          	sd	a5,0(s7)
ffffffffc0203a90:	000c3583          	ld	a1,0(s8)
    cprintf("vitim Page:%x,Page.visited:%d\n\n",page2ppn(*ptr_page),(*ptr_page)->visited);
ffffffffc0203a94:	fe073603          	ld	a2,-32(a4)
ffffffffc0203a98:	40b785b3          	sub	a1,a5,a1
ffffffffc0203a9c:	858d                	srai	a1,a1,0x3
ffffffffc0203a9e:	02d585b3          	mul	a1,a1,a3
ffffffffc0203aa2:	95ce                	add	a1,a1,s3
ffffffffc0203aa4:	e1afc0ef          	jal	ra,ffffffffc02000be <cprintf>
    list_del(curr_ptr);
ffffffffc0203aa8:	601c                	ld	a5,0(s0)
}
ffffffffc0203aaa:	60a6                	ld	ra,72(sp)
ffffffffc0203aac:	6406                	ld	s0,64(sp)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203aae:	6398                	ld	a4,0(a5)
ffffffffc0203ab0:	679c                	ld	a5,8(a5)
ffffffffc0203ab2:	74e2                	ld	s1,56(sp)
ffffffffc0203ab4:	7942                	ld	s2,48(sp)
    prev->next = next;
ffffffffc0203ab6:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203ab8:	e398                	sd	a4,0(a5)
ffffffffc0203aba:	79a2                	ld	s3,40(sp)
ffffffffc0203abc:	7a02                	ld	s4,32(sp)
ffffffffc0203abe:	6ae2                	ld	s5,24(sp)
ffffffffc0203ac0:	6b42                	ld	s6,16(sp)
ffffffffc0203ac2:	6ba2                	ld	s7,8(sp)
ffffffffc0203ac4:	6c02                	ld	s8,0(sp)
ffffffffc0203ac6:	4501                	li	a0,0
ffffffffc0203ac8:	6161                	addi	sp,sp,80
ffffffffc0203aca:	8082                	ret
         assert(head != NULL);
ffffffffc0203acc:	00002697          	auipc	a3,0x2
ffffffffc0203ad0:	34468693          	addi	a3,a3,836 # ffffffffc0205e10 <default_pmm_manager+0x6a0>
ffffffffc0203ad4:	00002617          	auipc	a2,0x2
ffffffffc0203ad8:	90460613          	addi	a2,a2,-1788 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203adc:	04500593          	li	a1,69
ffffffffc0203ae0:	00003517          	auipc	a0,0x3
ffffffffc0203ae4:	81050513          	addi	a0,a0,-2032 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc0203ae8:	88dfc0ef          	jal	ra,ffffffffc0200374 <__panic>
     assert(in_tick==0);
ffffffffc0203aec:	00002697          	auipc	a3,0x2
ffffffffc0203af0:	79c68693          	addi	a3,a3,1948 # ffffffffc0206288 <default_pmm_manager+0xb18>
ffffffffc0203af4:	00002617          	auipc	a2,0x2
ffffffffc0203af8:	8e460613          	addi	a2,a2,-1820 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203afc:	04600593          	li	a1,70
ffffffffc0203b00:	00002517          	auipc	a0,0x2
ffffffffc0203b04:	7f050513          	addi	a0,a0,2032 # ffffffffc02062f0 <default_pmm_manager+0xb80>
ffffffffc0203b08:	86dfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203b0c <_lru_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc0203b0c:	03060713          	addi	a4,a2,48
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203b10:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0203b12:	cb19                	beqz	a4,ffffffffc0203b28 <_lru_map_swappable+0x1c>
ffffffffc0203b14:	cb91                	beqz	a5,ffffffffc0203b28 <_lru_map_swappable+0x1c>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203b16:	6794                	ld	a3,8(a5)
}
ffffffffc0203b18:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0203b1a:	e298                	sd	a4,0(a3)
ffffffffc0203b1c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0203b1e:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc0203b20:	fa1c                	sd	a5,48(a2)
    page->visited = 0;
ffffffffc0203b22:	00063823          	sd	zero,16(a2)
}
ffffffffc0203b26:	8082                	ret
{
ffffffffc0203b28:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0203b2a:	00003697          	auipc	a3,0x3
ffffffffc0203b2e:	8ae68693          	addi	a3,a3,-1874 # ffffffffc02063d8 <default_pmm_manager+0xc68>
ffffffffc0203b32:	00002617          	auipc	a2,0x2
ffffffffc0203b36:	8a660613          	addi	a2,a2,-1882 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203b3a:	03400593          	li	a1,52
ffffffffc0203b3e:	00002517          	auipc	a0,0x2
ffffffffc0203b42:	7b250513          	addi	a0,a0,1970 # ffffffffc02062f0 <default_pmm_manager+0xb80>
{
ffffffffc0203b46:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0203b48:	82dfc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203b4c <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203b4c:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203b4e:	00003697          	auipc	a3,0x3
ffffffffc0203b52:	91a68693          	addi	a3,a3,-1766 # ffffffffc0206468 <default_pmm_manager+0xcf8>
ffffffffc0203b56:	00002617          	auipc	a2,0x2
ffffffffc0203b5a:	88260613          	addi	a2,a2,-1918 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203b5e:	07d00593          	li	a1,125
ffffffffc0203b62:	00003517          	auipc	a0,0x3
ffffffffc0203b66:	92650513          	addi	a0,a0,-1754 # ffffffffc0206488 <default_pmm_manager+0xd18>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203b6a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203b6c:	809fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203b70 <mm_create>:
mm_create(void) {
ffffffffc0203b70:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203b72:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0203b76:	e022                	sd	s0,0(sp)
ffffffffc0203b78:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203b7a:	b11fe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc0203b7e:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0203b80:	c115                	beqz	a0,ffffffffc0203ba4 <mm_create+0x34>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203b82:	0000e797          	auipc	a5,0xe
ffffffffc0203b86:	92678793          	addi	a5,a5,-1754 # ffffffffc02114a8 <swap_init_ok>
ffffffffc0203b8a:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0203b8c:	e408                	sd	a0,8(s0)
ffffffffc0203b8e:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0203b90:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203b94:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203b98:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203b9c:	2781                	sext.w	a5,a5
ffffffffc0203b9e:	eb81                	bnez	a5,ffffffffc0203bae <mm_create+0x3e>
        else mm->sm_priv = NULL;
ffffffffc0203ba0:	02053423          	sd	zero,40(a0)
}
ffffffffc0203ba4:	8522                	mv	a0,s0
ffffffffc0203ba6:	60a2                	ld	ra,8(sp)
ffffffffc0203ba8:	6402                	ld	s0,0(sp)
ffffffffc0203baa:	0141                	addi	sp,sp,16
ffffffffc0203bac:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0203bae:	c5ffe0ef          	jal	ra,ffffffffc020280c <swap_init_mm>
}
ffffffffc0203bb2:	8522                	mv	a0,s0
ffffffffc0203bb4:	60a2                	ld	ra,8(sp)
ffffffffc0203bb6:	6402                	ld	s0,0(sp)
ffffffffc0203bb8:	0141                	addi	sp,sp,16
ffffffffc0203bba:	8082                	ret

ffffffffc0203bbc <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0203bbc:	1101                	addi	sp,sp,-32
ffffffffc0203bbe:	e04a                	sd	s2,0(sp)
ffffffffc0203bc0:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bc2:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0203bc6:	e822                	sd	s0,16(sp)
ffffffffc0203bc8:	e426                	sd	s1,8(sp)
ffffffffc0203bca:	ec06                	sd	ra,24(sp)
ffffffffc0203bcc:	84ae                	mv	s1,a1
ffffffffc0203bce:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203bd0:	abbfe0ef          	jal	ra,ffffffffc020268a <kmalloc>
    if (vma != NULL) {
ffffffffc0203bd4:	c509                	beqz	a0,ffffffffc0203bde <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0203bd6:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203bda:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203bdc:	ed00                	sd	s0,24(a0)
}
ffffffffc0203bde:	60e2                	ld	ra,24(sp)
ffffffffc0203be0:	6442                	ld	s0,16(sp)
ffffffffc0203be2:	64a2                	ld	s1,8(sp)
ffffffffc0203be4:	6902                	ld	s2,0(sp)
ffffffffc0203be6:	6105                	addi	sp,sp,32
ffffffffc0203be8:	8082                	ret

ffffffffc0203bea <find_vma>:
    if (mm != NULL) {
ffffffffc0203bea:	c51d                	beqz	a0,ffffffffc0203c18 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0203bec:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203bee:	c781                	beqz	a5,ffffffffc0203bf6 <find_vma+0xc>
ffffffffc0203bf0:	6798                	ld	a4,8(a5)
ffffffffc0203bf2:	02e5f663          	bleu	a4,a1,ffffffffc0203c1e <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0203bf6:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0203bf8:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0203bfa:	00f50f63          	beq	a0,a5,ffffffffc0203c18 <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0203bfe:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203c02:	fee5ebe3          	bltu	a1,a4,ffffffffc0203bf8 <find_vma+0xe>
ffffffffc0203c06:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203c0a:	fee5f7e3          	bleu	a4,a1,ffffffffc0203bf8 <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0203c0e:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc0203c10:	c781                	beqz	a5,ffffffffc0203c18 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc0203c12:	e91c                	sd	a5,16(a0)
}
ffffffffc0203c14:	853e                	mv	a0,a5
ffffffffc0203c16:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0203c18:	4781                	li	a5,0
}
ffffffffc0203c1a:	853e                	mv	a0,a5
ffffffffc0203c1c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0203c1e:	6b98                	ld	a4,16(a5)
ffffffffc0203c20:	fce5fbe3          	bleu	a4,a1,ffffffffc0203bf6 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0203c24:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0203c26:	b7fd                	j	ffffffffc0203c14 <find_vma+0x2a>

ffffffffc0203c28 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203c28:	6590                	ld	a2,8(a1)
ffffffffc0203c2a:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0203c2e:	1141                	addi	sp,sp,-16
ffffffffc0203c30:	e406                	sd	ra,8(sp)
ffffffffc0203c32:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203c34:	01066863          	bltu	a2,a6,ffffffffc0203c44 <insert_vma_struct+0x1c>
ffffffffc0203c38:	a8b9                	j	ffffffffc0203c96 <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0203c3a:	fe87b683          	ld	a3,-24(a5)
ffffffffc0203c3e:	04d66763          	bltu	a2,a3,ffffffffc0203c8c <insert_vma_struct+0x64>
ffffffffc0203c42:	873e                	mv	a4,a5
ffffffffc0203c44:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc0203c46:	fef51ae3          	bne	a0,a5,ffffffffc0203c3a <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0203c4a:	02a70463          	beq	a4,a0,ffffffffc0203c72 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203c4e:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203c52:	fe873883          	ld	a7,-24(a4)
ffffffffc0203c56:	08d8f063          	bleu	a3,a7,ffffffffc0203cd6 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203c5a:	04d66e63          	bltu	a2,a3,ffffffffc0203cb6 <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc0203c5e:	00f50a63          	beq	a0,a5,ffffffffc0203c72 <insert_vma_struct+0x4a>
ffffffffc0203c62:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203c66:	0506e863          	bltu	a3,a6,ffffffffc0203cb6 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0203c6a:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203c6e:	02c6f263          	bleu	a2,a3,ffffffffc0203c92 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0203c72:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc0203c74:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203c76:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203c7a:	e390                	sd	a2,0(a5)
ffffffffc0203c7c:	e710                	sd	a2,8(a4)
}
ffffffffc0203c7e:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203c80:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203c82:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc0203c84:	2685                	addiw	a3,a3,1
ffffffffc0203c86:	d114                	sw	a3,32(a0)
}
ffffffffc0203c88:	0141                	addi	sp,sp,16
ffffffffc0203c8a:	8082                	ret
    if (le_prev != list) {
ffffffffc0203c8c:	fca711e3          	bne	a4,a0,ffffffffc0203c4e <insert_vma_struct+0x26>
ffffffffc0203c90:	bfd9                	j	ffffffffc0203c66 <insert_vma_struct+0x3e>
ffffffffc0203c92:	ebbff0ef          	jal	ra,ffffffffc0203b4c <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203c96:	00003697          	auipc	a3,0x3
ffffffffc0203c9a:	88268693          	addi	a3,a3,-1918 # ffffffffc0206518 <default_pmm_manager+0xda8>
ffffffffc0203c9e:	00001617          	auipc	a2,0x1
ffffffffc0203ca2:	73a60613          	addi	a2,a2,1850 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203ca6:	08400593          	li	a1,132
ffffffffc0203caa:	00002517          	auipc	a0,0x2
ffffffffc0203cae:	7de50513          	addi	a0,a0,2014 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0203cb2:	ec2fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203cb6:	00003697          	auipc	a3,0x3
ffffffffc0203cba:	8a268693          	addi	a3,a3,-1886 # ffffffffc0206558 <default_pmm_manager+0xde8>
ffffffffc0203cbe:	00001617          	auipc	a2,0x1
ffffffffc0203cc2:	71a60613          	addi	a2,a2,1818 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203cc6:	07c00593          	li	a1,124
ffffffffc0203cca:	00002517          	auipc	a0,0x2
ffffffffc0203cce:	7be50513          	addi	a0,a0,1982 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0203cd2:	ea2fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203cd6:	00003697          	auipc	a3,0x3
ffffffffc0203cda:	86268693          	addi	a3,a3,-1950 # ffffffffc0206538 <default_pmm_manager+0xdc8>
ffffffffc0203cde:	00001617          	auipc	a2,0x1
ffffffffc0203ce2:	6fa60613          	addi	a2,a2,1786 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203ce6:	07b00593          	li	a1,123
ffffffffc0203cea:	00002517          	auipc	a0,0x2
ffffffffc0203cee:	79e50513          	addi	a0,a0,1950 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0203cf2:	e82fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0203cf6 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0203cf6:	1141                	addi	sp,sp,-16
ffffffffc0203cf8:	e022                	sd	s0,0(sp)
ffffffffc0203cfa:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203cfc:	6508                	ld	a0,8(a0)
ffffffffc0203cfe:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0203d00:	00a40e63          	beq	s0,a0,ffffffffc0203d1c <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203d04:	6118                	ld	a4,0(a0)
ffffffffc0203d06:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  //kfree vma        
ffffffffc0203d08:	03000593          	li	a1,48
ffffffffc0203d0c:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203d0e:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203d10:	e398                	sd	a4,0(a5)
ffffffffc0203d12:	a3bfe0ef          	jal	ra,ffffffffc020274c <kfree>
    return listelm->next;
ffffffffc0203d16:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0203d18:	fea416e3          	bne	s0,a0,ffffffffc0203d04 <mm_destroy+0xe>
    }
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203d1c:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0203d1e:	6402                	ld	s0,0(sp)
ffffffffc0203d20:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203d22:	03000593          	li	a1,48
}
ffffffffc0203d26:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); //kfree mm
ffffffffc0203d28:	a25fe06f          	j	ffffffffc020274c <kfree>

ffffffffc0203d2c <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0203d2c:	715d                	addi	sp,sp,-80
ffffffffc0203d2e:	e486                	sd	ra,72(sp)
ffffffffc0203d30:	e0a2                	sd	s0,64(sp)
ffffffffc0203d32:	fc26                	sd	s1,56(sp)
ffffffffc0203d34:	f84a                	sd	s2,48(sp)
ffffffffc0203d36:	f052                	sd	s4,32(sp)
ffffffffc0203d38:	f44e                	sd	s3,40(sp)
ffffffffc0203d3a:	ec56                	sd	s5,24(sp)
ffffffffc0203d3c:	e85a                	sd	s6,16(sp)
ffffffffc0203d3e:	e45e                	sd	s7,8(sp)
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203d40:	9edfd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203d44:	892a                	mv	s2,a0
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203d46:	9e7fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203d4a:	8a2a                	mv	s4,a0

    struct mm_struct *mm = mm_create();
ffffffffc0203d4c:	e25ff0ef          	jal	ra,ffffffffc0203b70 <mm_create>
    assert(mm != NULL);
ffffffffc0203d50:	842a                	mv	s0,a0
ffffffffc0203d52:	03200493          	li	s1,50
ffffffffc0203d56:	e919                	bnez	a0,ffffffffc0203d6c <vmm_init+0x40>
ffffffffc0203d58:	aeed                	j	ffffffffc0204152 <vmm_init+0x426>
        vma->vm_start = vm_start;
ffffffffc0203d5a:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203d5c:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203d5e:	00053c23          	sd	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203d62:	14ed                	addi	s1,s1,-5
ffffffffc0203d64:	8522                	mv	a0,s0
ffffffffc0203d66:	ec3ff0ef          	jal	ra,ffffffffc0203c28 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0203d6a:	c88d                	beqz	s1,ffffffffc0203d9c <vmm_init+0x70>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203d6c:	03000513          	li	a0,48
ffffffffc0203d70:	91bfe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc0203d74:	85aa                	mv	a1,a0
ffffffffc0203d76:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0203d7a:	f165                	bnez	a0,ffffffffc0203d5a <vmm_init+0x2e>
        assert(vma != NULL);
ffffffffc0203d7c:	00002697          	auipc	a3,0x2
ffffffffc0203d80:	1d468693          	addi	a3,a3,468 # ffffffffc0205f50 <default_pmm_manager+0x7e0>
ffffffffc0203d84:	00001617          	auipc	a2,0x1
ffffffffc0203d88:	65460613          	addi	a2,a2,1620 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203d8c:	0ce00593          	li	a1,206
ffffffffc0203d90:	00002517          	auipc	a0,0x2
ffffffffc0203d94:	6f850513          	addi	a0,a0,1784 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0203d98:	ddcfc0ef          	jal	ra,ffffffffc0200374 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc0203d9c:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203da0:	1f900993          	li	s3,505
ffffffffc0203da4:	a819                	j	ffffffffc0203dba <vmm_init+0x8e>
        vma->vm_start = vm_start;
ffffffffc0203da6:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203da8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203daa:	00053c23          	sd	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203dae:	0495                	addi	s1,s1,5
ffffffffc0203db0:	8522                	mv	a0,s0
ffffffffc0203db2:	e77ff0ef          	jal	ra,ffffffffc0203c28 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0203db6:	03348a63          	beq	s1,s3,ffffffffc0203dea <vmm_init+0xbe>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203dba:	03000513          	li	a0,48
ffffffffc0203dbe:	8cdfe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc0203dc2:	85aa                	mv	a1,a0
ffffffffc0203dc4:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0203dc8:	fd79                	bnez	a0,ffffffffc0203da6 <vmm_init+0x7a>
        assert(vma != NULL);
ffffffffc0203dca:	00002697          	auipc	a3,0x2
ffffffffc0203dce:	18668693          	addi	a3,a3,390 # ffffffffc0205f50 <default_pmm_manager+0x7e0>
ffffffffc0203dd2:	00001617          	auipc	a2,0x1
ffffffffc0203dd6:	60660613          	addi	a2,a2,1542 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203dda:	0d400593          	li	a1,212
ffffffffc0203dde:	00002517          	auipc	a0,0x2
ffffffffc0203de2:	6aa50513          	addi	a0,a0,1706 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0203de6:	d8efc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203dea:	6418                	ld	a4,8(s0)
ffffffffc0203dec:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0203dee:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0203df2:	2ae40063          	beq	s0,a4,ffffffffc0204092 <vmm_init+0x366>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203df6:	fe873603          	ld	a2,-24(a4)
ffffffffc0203dfa:	ffe78693          	addi	a3,a5,-2
ffffffffc0203dfe:	20d61a63          	bne	a2,a3,ffffffffc0204012 <vmm_init+0x2e6>
ffffffffc0203e02:	ff073683          	ld	a3,-16(a4)
ffffffffc0203e06:	20d79663          	bne	a5,a3,ffffffffc0204012 <vmm_init+0x2e6>
ffffffffc0203e0a:	0795                	addi	a5,a5,5
ffffffffc0203e0c:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0203e0e:	feb792e3          	bne	a5,a1,ffffffffc0203df2 <vmm_init+0xc6>
ffffffffc0203e12:	499d                	li	s3,7
ffffffffc0203e14:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203e16:	1f900b93          	li	s7,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203e1a:	85a6                	mv	a1,s1
ffffffffc0203e1c:	8522                	mv	a0,s0
ffffffffc0203e1e:	dcdff0ef          	jal	ra,ffffffffc0203bea <find_vma>
ffffffffc0203e22:	8b2a                	mv	s6,a0
        assert(vma1 != NULL);
ffffffffc0203e24:	2e050763          	beqz	a0,ffffffffc0204112 <vmm_init+0x3e6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0203e28:	00148593          	addi	a1,s1,1
ffffffffc0203e2c:	8522                	mv	a0,s0
ffffffffc0203e2e:	dbdff0ef          	jal	ra,ffffffffc0203bea <find_vma>
ffffffffc0203e32:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc0203e34:	2a050f63          	beqz	a0,ffffffffc02040f2 <vmm_init+0x3c6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0203e38:	85ce                	mv	a1,s3
ffffffffc0203e3a:	8522                	mv	a0,s0
ffffffffc0203e3c:	dafff0ef          	jal	ra,ffffffffc0203bea <find_vma>
        assert(vma3 == NULL);
ffffffffc0203e40:	28051963          	bnez	a0,ffffffffc02040d2 <vmm_init+0x3a6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0203e44:	00348593          	addi	a1,s1,3
ffffffffc0203e48:	8522                	mv	a0,s0
ffffffffc0203e4a:	da1ff0ef          	jal	ra,ffffffffc0203bea <find_vma>
        assert(vma4 == NULL);
ffffffffc0203e4e:	26051263          	bnez	a0,ffffffffc02040b2 <vmm_init+0x386>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0203e52:	00448593          	addi	a1,s1,4
ffffffffc0203e56:	8522                	mv	a0,s0
ffffffffc0203e58:	d93ff0ef          	jal	ra,ffffffffc0203bea <find_vma>
        assert(vma5 == NULL);
ffffffffc0203e5c:	2c051b63          	bnez	a0,ffffffffc0204132 <vmm_init+0x406>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0203e60:	008b3783          	ld	a5,8(s6)
ffffffffc0203e64:	1c979763          	bne	a5,s1,ffffffffc0204032 <vmm_init+0x306>
ffffffffc0203e68:	010b3783          	ld	a5,16(s6)
ffffffffc0203e6c:	1d379363          	bne	a5,s3,ffffffffc0204032 <vmm_init+0x306>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0203e70:	008ab783          	ld	a5,8(s5)
ffffffffc0203e74:	1c979f63          	bne	a5,s1,ffffffffc0204052 <vmm_init+0x326>
ffffffffc0203e78:	010ab783          	ld	a5,16(s5)
ffffffffc0203e7c:	1d379b63          	bne	a5,s3,ffffffffc0204052 <vmm_init+0x326>
ffffffffc0203e80:	0495                	addi	s1,s1,5
ffffffffc0203e82:	0995                	addi	s3,s3,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0203e84:	f9749be3          	bne	s1,s7,ffffffffc0203e1a <vmm_init+0xee>
ffffffffc0203e88:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0203e8a:	59fd                	li	s3,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0203e8c:	85a6                	mv	a1,s1
ffffffffc0203e8e:	8522                	mv	a0,s0
ffffffffc0203e90:	d5bff0ef          	jal	ra,ffffffffc0203bea <find_vma>
ffffffffc0203e94:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc0203e98:	c90d                	beqz	a0,ffffffffc0203eca <vmm_init+0x19e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0203e9a:	6914                	ld	a3,16(a0)
ffffffffc0203e9c:	6510                	ld	a2,8(a0)
ffffffffc0203e9e:	00002517          	auipc	a0,0x2
ffffffffc0203ea2:	7da50513          	addi	a0,a0,2010 # ffffffffc0206678 <default_pmm_manager+0xf08>
ffffffffc0203ea6:	a18fc0ef          	jal	ra,ffffffffc02000be <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203eaa:	00002697          	auipc	a3,0x2
ffffffffc0203eae:	7f668693          	addi	a3,a3,2038 # ffffffffc02066a0 <default_pmm_manager+0xf30>
ffffffffc0203eb2:	00001617          	auipc	a2,0x1
ffffffffc0203eb6:	52660613          	addi	a2,a2,1318 # ffffffffc02053d8 <commands+0x870>
ffffffffc0203eba:	0f600593          	li	a1,246
ffffffffc0203ebe:	00002517          	auipc	a0,0x2
ffffffffc0203ec2:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0203ec6:	caefc0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0203eca:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0203ecc:	fd3490e3          	bne	s1,s3,ffffffffc0203e8c <vmm_init+0x160>
    }

    mm_destroy(mm);
ffffffffc0203ed0:	8522                	mv	a0,s0
ffffffffc0203ed2:	e25ff0ef          	jal	ra,ffffffffc0203cf6 <mm_destroy>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203ed6:	857fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203eda:	28aa1c63          	bne	s4,a0,ffffffffc0204172 <vmm_init+0x446>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203ede:	00003517          	auipc	a0,0x3
ffffffffc0203ee2:	80250513          	addi	a0,a0,-2046 # ffffffffc02066e0 <default_pmm_manager+0xf70>
ffffffffc0203ee6:	9d8fc0ef          	jal	ra,ffffffffc02000be <cprintf>

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
	// char *name = "check_pgfault";
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0203eea:	843fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203eee:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0203ef0:	c81ff0ef          	jal	ra,ffffffffc0203b70 <mm_create>
ffffffffc0203ef4:	0000d797          	auipc	a5,0xd
ffffffffc0203ef8:	6ca7be23          	sd	a0,1756(a5) # ffffffffc02115d0 <check_mm_struct>
ffffffffc0203efc:	842a                	mv	s0,a0

    assert(check_mm_struct != NULL);
ffffffffc0203efe:	2a050a63          	beqz	a0,ffffffffc02041b2 <vmm_init+0x486>
    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203f02:	0000d797          	auipc	a5,0xd
ffffffffc0203f06:	58e78793          	addi	a5,a5,1422 # ffffffffc0211490 <boot_pgdir>
ffffffffc0203f0a:	6384                	ld	s1,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0203f0c:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203f0e:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0203f10:	32079d63          	bnez	a5,ffffffffc020424a <vmm_init+0x51e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203f14:	03000513          	li	a0,48
ffffffffc0203f18:	f72fe0ef          	jal	ra,ffffffffc020268a <kmalloc>
ffffffffc0203f1c:	8a2a                	mv	s4,a0
    if (vma != NULL) {
ffffffffc0203f1e:	14050a63          	beqz	a0,ffffffffc0204072 <vmm_init+0x346>
        vma->vm_end = vm_end;
ffffffffc0203f22:	002007b7          	lui	a5,0x200
ffffffffc0203f26:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags;
ffffffffc0203f2a:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);

    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0203f2c:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0203f2e:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0203f32:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0203f34:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc0203f38:	cf1ff0ef          	jal	ra,ffffffffc0203c28 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0203f3c:	10000593          	li	a1,256
ffffffffc0203f40:	8522                	mv	a0,s0
ffffffffc0203f42:	ca9ff0ef          	jal	ra,ffffffffc0203bea <find_vma>
ffffffffc0203f46:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0203f4a:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0203f4e:	2aaa1263          	bne	s4,a0,ffffffffc02041f2 <vmm_init+0x4c6>
        *(char *)(addr + i) = i;
ffffffffc0203f52:	00f78023          	sb	a5,0(a5) # 200000 <BASE_ADDRESS-0xffffffffc0000000>
        sum += i;
ffffffffc0203f56:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc0203f58:	fee79de3          	bne	a5,a4,ffffffffc0203f52 <vmm_init+0x226>
        sum += i;
ffffffffc0203f5c:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc0203f5e:	10000793          	li	a5,256
        sum += i;
ffffffffc0203f62:	35670713          	addi	a4,a4,854 # 1356 <BASE_ADDRESS-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0203f66:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0203f6a:	0007c683          	lbu	a3,0(a5)
ffffffffc0203f6e:	0785                	addi	a5,a5,1
ffffffffc0203f70:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0203f72:	fec79ce3          	bne	a5,a2,ffffffffc0203f6a <vmm_init+0x23e>
    }
    assert(sum == 0);
ffffffffc0203f76:	2a071a63          	bnez	a4,ffffffffc020422a <vmm_init+0x4fe>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0203f7a:	4581                	li	a1,0
ffffffffc0203f7c:	8526                	mv	a0,s1
ffffffffc0203f7e:	a55fd0ef          	jal	ra,ffffffffc02019d2 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203f82:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0203f84:	0000d717          	auipc	a4,0xd
ffffffffc0203f88:	51470713          	addi	a4,a4,1300 # ffffffffc0211498 <npage>
ffffffffc0203f8c:	6318                	ld	a4,0(a4)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203f8e:	078a                	slli	a5,a5,0x2
ffffffffc0203f90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203f92:	28e7f063          	bleu	a4,a5,ffffffffc0204212 <vmm_init+0x4e6>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f96:	00003717          	auipc	a4,0x3
ffffffffc0203f9a:	a8a70713          	addi	a4,a4,-1398 # ffffffffc0206a20 <nbase>
ffffffffc0203f9e:	6318                	ld	a4,0(a4)
ffffffffc0203fa0:	0000d697          	auipc	a3,0xd
ffffffffc0203fa4:	54868693          	addi	a3,a3,1352 # ffffffffc02114e8 <pages>
ffffffffc0203fa8:	6288                	ld	a0,0(a3)
ffffffffc0203faa:	8f99                	sub	a5,a5,a4
ffffffffc0203fac:	00379713          	slli	a4,a5,0x3
ffffffffc0203fb0:	97ba                	add	a5,a5,a4
ffffffffc0203fb2:	078e                	slli	a5,a5,0x3

    free_page(pde2page(pgdir[0]));
ffffffffc0203fb4:	953e                	add	a0,a0,a5
ffffffffc0203fb6:	4585                	li	a1,1
ffffffffc0203fb8:	f2efd0ef          	jal	ra,ffffffffc02016e6 <free_pages>

    pgdir[0] = 0;
ffffffffc0203fbc:	0004b023          	sd	zero,0(s1)

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc0203fc0:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc0203fc2:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc0203fc6:	d31ff0ef          	jal	ra,ffffffffc0203cf6 <mm_destroy>

    check_mm_struct = NULL;
    nr_free_pages_store--;	// szx : Sv39第二级页表多占了一个内存页，所以执行此操作
ffffffffc0203fca:	19fd                	addi	s3,s3,-1
    check_mm_struct = NULL;
ffffffffc0203fcc:	0000d797          	auipc	a5,0xd
ffffffffc0203fd0:	6007b223          	sd	zero,1540(a5) # ffffffffc02115d0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203fd4:	f58fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
ffffffffc0203fd8:	1aa99d63          	bne	s3,a0,ffffffffc0204192 <vmm_init+0x466>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0203fdc:	00002517          	auipc	a0,0x2
ffffffffc0203fe0:	76c50513          	addi	a0,a0,1900 # ffffffffc0206748 <default_pmm_manager+0xfd8>
ffffffffc0203fe4:	8dafc0ef          	jal	ra,ffffffffc02000be <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203fe8:	f44fd0ef          	jal	ra,ffffffffc020172c <nr_free_pages>
    nr_free_pages_store--;	// szx : Sv39三级页表多占一个内存页，所以执行此操作
ffffffffc0203fec:	197d                	addi	s2,s2,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0203fee:	1ea91263          	bne	s2,a0,ffffffffc02041d2 <vmm_init+0x4a6>
}
ffffffffc0203ff2:	6406                	ld	s0,64(sp)
ffffffffc0203ff4:	60a6                	ld	ra,72(sp)
ffffffffc0203ff6:	74e2                	ld	s1,56(sp)
ffffffffc0203ff8:	7942                	ld	s2,48(sp)
ffffffffc0203ffa:	79a2                	ld	s3,40(sp)
ffffffffc0203ffc:	7a02                	ld	s4,32(sp)
ffffffffc0203ffe:	6ae2                	ld	s5,24(sp)
ffffffffc0204000:	6b42                	ld	s6,16(sp)
ffffffffc0204002:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204004:	00002517          	auipc	a0,0x2
ffffffffc0204008:	76450513          	addi	a0,a0,1892 # ffffffffc0206768 <default_pmm_manager+0xff8>
}
ffffffffc020400c:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc020400e:	8b0fc06f          	j	ffffffffc02000be <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204012:	00002697          	auipc	a3,0x2
ffffffffc0204016:	57e68693          	addi	a3,a3,1406 # ffffffffc0206590 <default_pmm_manager+0xe20>
ffffffffc020401a:	00001617          	auipc	a2,0x1
ffffffffc020401e:	3be60613          	addi	a2,a2,958 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204022:	0dd00593          	li	a1,221
ffffffffc0204026:	00002517          	auipc	a0,0x2
ffffffffc020402a:	46250513          	addi	a0,a0,1122 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020402e:	b46fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0204032:	00002697          	auipc	a3,0x2
ffffffffc0204036:	5e668693          	addi	a3,a3,1510 # ffffffffc0206618 <default_pmm_manager+0xea8>
ffffffffc020403a:	00001617          	auipc	a2,0x1
ffffffffc020403e:	39e60613          	addi	a2,a2,926 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204042:	0ed00593          	li	a1,237
ffffffffc0204046:	00002517          	auipc	a0,0x2
ffffffffc020404a:	44250513          	addi	a0,a0,1090 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020404e:	b26fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0204052:	00002697          	auipc	a3,0x2
ffffffffc0204056:	5f668693          	addi	a3,a3,1526 # ffffffffc0206648 <default_pmm_manager+0xed8>
ffffffffc020405a:	00001617          	auipc	a2,0x1
ffffffffc020405e:	37e60613          	addi	a2,a2,894 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204062:	0ee00593          	li	a1,238
ffffffffc0204066:	00002517          	auipc	a0,0x2
ffffffffc020406a:	42250513          	addi	a0,a0,1058 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020406e:	b06fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(vma != NULL);
ffffffffc0204072:	00002697          	auipc	a3,0x2
ffffffffc0204076:	ede68693          	addi	a3,a3,-290 # ffffffffc0205f50 <default_pmm_manager+0x7e0>
ffffffffc020407a:	00001617          	auipc	a2,0x1
ffffffffc020407e:	35e60613          	addi	a2,a2,862 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204082:	11100593          	li	a1,273
ffffffffc0204086:	00002517          	auipc	a0,0x2
ffffffffc020408a:	40250513          	addi	a0,a0,1026 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020408e:	ae6fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0204092:	00002697          	auipc	a3,0x2
ffffffffc0204096:	4e668693          	addi	a3,a3,1254 # ffffffffc0206578 <default_pmm_manager+0xe08>
ffffffffc020409a:	00001617          	auipc	a2,0x1
ffffffffc020409e:	33e60613          	addi	a2,a2,830 # ffffffffc02053d8 <commands+0x870>
ffffffffc02040a2:	0db00593          	li	a1,219
ffffffffc02040a6:	00002517          	auipc	a0,0x2
ffffffffc02040aa:	3e250513          	addi	a0,a0,994 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc02040ae:	ac6fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma4 == NULL);
ffffffffc02040b2:	00002697          	auipc	a3,0x2
ffffffffc02040b6:	54668693          	addi	a3,a3,1350 # ffffffffc02065f8 <default_pmm_manager+0xe88>
ffffffffc02040ba:	00001617          	auipc	a2,0x1
ffffffffc02040be:	31e60613          	addi	a2,a2,798 # ffffffffc02053d8 <commands+0x870>
ffffffffc02040c2:	0e900593          	li	a1,233
ffffffffc02040c6:	00002517          	auipc	a0,0x2
ffffffffc02040ca:	3c250513          	addi	a0,a0,962 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc02040ce:	aa6fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma3 == NULL);
ffffffffc02040d2:	00002697          	auipc	a3,0x2
ffffffffc02040d6:	51668693          	addi	a3,a3,1302 # ffffffffc02065e8 <default_pmm_manager+0xe78>
ffffffffc02040da:	00001617          	auipc	a2,0x1
ffffffffc02040de:	2fe60613          	addi	a2,a2,766 # ffffffffc02053d8 <commands+0x870>
ffffffffc02040e2:	0e700593          	li	a1,231
ffffffffc02040e6:	00002517          	auipc	a0,0x2
ffffffffc02040ea:	3a250513          	addi	a0,a0,930 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc02040ee:	a86fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma2 != NULL);
ffffffffc02040f2:	00002697          	auipc	a3,0x2
ffffffffc02040f6:	4e668693          	addi	a3,a3,1254 # ffffffffc02065d8 <default_pmm_manager+0xe68>
ffffffffc02040fa:	00001617          	auipc	a2,0x1
ffffffffc02040fe:	2de60613          	addi	a2,a2,734 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204102:	0e500593          	li	a1,229
ffffffffc0204106:	00002517          	auipc	a0,0x2
ffffffffc020410a:	38250513          	addi	a0,a0,898 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020410e:	a66fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma1 != NULL);
ffffffffc0204112:	00002697          	auipc	a3,0x2
ffffffffc0204116:	4b668693          	addi	a3,a3,1206 # ffffffffc02065c8 <default_pmm_manager+0xe58>
ffffffffc020411a:	00001617          	auipc	a2,0x1
ffffffffc020411e:	2be60613          	addi	a2,a2,702 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204122:	0e300593          	li	a1,227
ffffffffc0204126:	00002517          	auipc	a0,0x2
ffffffffc020412a:	36250513          	addi	a0,a0,866 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020412e:	a46fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        assert(vma5 == NULL);
ffffffffc0204132:	00002697          	auipc	a3,0x2
ffffffffc0204136:	4d668693          	addi	a3,a3,1238 # ffffffffc0206608 <default_pmm_manager+0xe98>
ffffffffc020413a:	00001617          	auipc	a2,0x1
ffffffffc020413e:	29e60613          	addi	a2,a2,670 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204142:	0eb00593          	li	a1,235
ffffffffc0204146:	00002517          	auipc	a0,0x2
ffffffffc020414a:	34250513          	addi	a0,a0,834 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020414e:	a26fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(mm != NULL);
ffffffffc0204152:	00002697          	auipc	a3,0x2
ffffffffc0204156:	dc668693          	addi	a3,a3,-570 # ffffffffc0205f18 <default_pmm_manager+0x7a8>
ffffffffc020415a:	00001617          	auipc	a2,0x1
ffffffffc020415e:	27e60613          	addi	a2,a2,638 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204162:	0c700593          	li	a1,199
ffffffffc0204166:	00002517          	auipc	a0,0x2
ffffffffc020416a:	32250513          	addi	a0,a0,802 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020416e:	a06fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204172:	00002697          	auipc	a3,0x2
ffffffffc0204176:	54668693          	addi	a3,a3,1350 # ffffffffc02066b8 <default_pmm_manager+0xf48>
ffffffffc020417a:	00001617          	auipc	a2,0x1
ffffffffc020417e:	25e60613          	addi	a2,a2,606 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204182:	0fb00593          	li	a1,251
ffffffffc0204186:	00002517          	auipc	a0,0x2
ffffffffc020418a:	30250513          	addi	a0,a0,770 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020418e:	9e6fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204192:	00002697          	auipc	a3,0x2
ffffffffc0204196:	52668693          	addi	a3,a3,1318 # ffffffffc02066b8 <default_pmm_manager+0xf48>
ffffffffc020419a:	00001617          	auipc	a2,0x1
ffffffffc020419e:	23e60613          	addi	a2,a2,574 # ffffffffc02053d8 <commands+0x870>
ffffffffc02041a2:	12e00593          	li	a1,302
ffffffffc02041a6:	00002517          	auipc	a0,0x2
ffffffffc02041aa:	2e250513          	addi	a0,a0,738 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc02041ae:	9c6fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02041b2:	00002697          	auipc	a3,0x2
ffffffffc02041b6:	54e68693          	addi	a3,a3,1358 # ffffffffc0206700 <default_pmm_manager+0xf90>
ffffffffc02041ba:	00001617          	auipc	a2,0x1
ffffffffc02041be:	21e60613          	addi	a2,a2,542 # ffffffffc02053d8 <commands+0x870>
ffffffffc02041c2:	10a00593          	li	a1,266
ffffffffc02041c6:	00002517          	auipc	a0,0x2
ffffffffc02041ca:	2c250513          	addi	a0,a0,706 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc02041ce:	9a6fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02041d2:	00002697          	auipc	a3,0x2
ffffffffc02041d6:	4e668693          	addi	a3,a3,1254 # ffffffffc02066b8 <default_pmm_manager+0xf48>
ffffffffc02041da:	00001617          	auipc	a2,0x1
ffffffffc02041de:	1fe60613          	addi	a2,a2,510 # ffffffffc02053d8 <commands+0x870>
ffffffffc02041e2:	0bd00593          	li	a1,189
ffffffffc02041e6:	00002517          	auipc	a0,0x2
ffffffffc02041ea:	2a250513          	addi	a0,a0,674 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc02041ee:	986fc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02041f2:	00002697          	auipc	a3,0x2
ffffffffc02041f6:	52668693          	addi	a3,a3,1318 # ffffffffc0206718 <default_pmm_manager+0xfa8>
ffffffffc02041fa:	00001617          	auipc	a2,0x1
ffffffffc02041fe:	1de60613          	addi	a2,a2,478 # ffffffffc02053d8 <commands+0x870>
ffffffffc0204202:	11600593          	li	a1,278
ffffffffc0204206:	00002517          	auipc	a0,0x2
ffffffffc020420a:	28250513          	addi	a0,a0,642 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc020420e:	966fc0ef          	jal	ra,ffffffffc0200374 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204212:	00001617          	auipc	a2,0x1
ffffffffc0204216:	62660613          	addi	a2,a2,1574 # ffffffffc0205838 <default_pmm_manager+0xc8>
ffffffffc020421a:	06500593          	li	a1,101
ffffffffc020421e:	00001517          	auipc	a0,0x1
ffffffffc0204222:	63a50513          	addi	a0,a0,1594 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc0204226:	94efc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(sum == 0);
ffffffffc020422a:	00002697          	auipc	a3,0x2
ffffffffc020422e:	50e68693          	addi	a3,a3,1294 # ffffffffc0206738 <default_pmm_manager+0xfc8>
ffffffffc0204232:	00001617          	auipc	a2,0x1
ffffffffc0204236:	1a660613          	addi	a2,a2,422 # ffffffffc02053d8 <commands+0x870>
ffffffffc020423a:	12000593          	li	a1,288
ffffffffc020423e:	00002517          	auipc	a0,0x2
ffffffffc0204242:	24a50513          	addi	a0,a0,586 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0204246:	92efc0ef          	jal	ra,ffffffffc0200374 <__panic>
    assert(pgdir[0] == 0);
ffffffffc020424a:	00002697          	auipc	a3,0x2
ffffffffc020424e:	cf668693          	addi	a3,a3,-778 # ffffffffc0205f40 <default_pmm_manager+0x7d0>
ffffffffc0204252:	00001617          	auipc	a2,0x1
ffffffffc0204256:	18660613          	addi	a2,a2,390 # ffffffffc02053d8 <commands+0x870>
ffffffffc020425a:	10d00593          	li	a1,269
ffffffffc020425e:	00002517          	auipc	a0,0x2
ffffffffc0204262:	22a50513          	addi	a0,a0,554 # ffffffffc0206488 <default_pmm_manager+0xd18>
ffffffffc0204266:	90efc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020426a <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020426a:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020426c:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020426e:	f022                	sd	s0,32(sp)
ffffffffc0204270:	ec26                	sd	s1,24(sp)
ffffffffc0204272:	f406                	sd	ra,40(sp)
ffffffffc0204274:	e84a                	sd	s2,16(sp)
ffffffffc0204276:	8432                	mv	s0,a2
ffffffffc0204278:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020427a:	971ff0ef          	jal	ra,ffffffffc0203bea <find_vma>

    pgfault_num++;
ffffffffc020427e:	0000d797          	auipc	a5,0xd
ffffffffc0204282:	22e78793          	addi	a5,a5,558 # ffffffffc02114ac <pgfault_num>
ffffffffc0204286:	439c                	lw	a5,0(a5)
ffffffffc0204288:	2785                	addiw	a5,a5,1
ffffffffc020428a:	0000d717          	auipc	a4,0xd
ffffffffc020428e:	22f72123          	sw	a5,546(a4) # ffffffffc02114ac <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0204292:	c549                	beqz	a0,ffffffffc020431c <do_pgfault+0xb2>
ffffffffc0204294:	651c                	ld	a5,8(a0)
ffffffffc0204296:	08f46363          	bltu	s0,a5,ffffffffc020431c <do_pgfault+0xb2>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020429a:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc020429c:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020429e:	8b89                	andi	a5,a5,2
ffffffffc02042a0:	efa9                	bnez	a5,ffffffffc02042fa <do_pgfault+0x90>
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02042a2:	767d                	lui	a2,0xfffff
    *   mm->pgdir : the PDT of these vma
    *
    */


    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc02042a4:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02042a6:	8c71                	and	s0,s0,a2
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
ffffffffc02042a8:	85a2                	mv	a1,s0
ffffffffc02042aa:	4605                	li	a2,1
ffffffffc02042ac:	cc0fd0ef          	jal	ra,ffffffffc020176c <get_pte>
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) {
ffffffffc02042b0:	610c                	ld	a1,0(a0)
ffffffffc02042b2:	c5b1                	beqz	a1,ffffffffc02042fe <do_pgfault+0x94>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc02042b4:	0000d797          	auipc	a5,0xd
ffffffffc02042b8:	1f478793          	addi	a5,a5,500 # ffffffffc02114a8 <swap_init_ok>
ffffffffc02042bc:	439c                	lw	a5,0(a5)
ffffffffc02042be:	2781                	sext.w	a5,a5
ffffffffc02042c0:	c7bd                	beqz	a5,ffffffffc020432e <do_pgfault+0xc4>
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            swap_in(mm,addr,&page);
ffffffffc02042c2:	85a2                	mv	a1,s0
ffffffffc02042c4:	0030                	addi	a2,sp,8
ffffffffc02042c6:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02042c8:	e402                	sd	zero,8(sp)
            swap_in(mm,addr,&page);
ffffffffc02042ca:	e76fe0ef          	jal	ra,ffffffffc0202940 <swap_in>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc02042ce:	65a2                	ld	a1,8(sp)
ffffffffc02042d0:	6c88                	ld	a0,24(s1)
ffffffffc02042d2:	86ca                	mv	a3,s2
ffffffffc02042d4:	8622                	mv	a2,s0
ffffffffc02042d6:	f6efd0ef          	jal	ra,ffffffffc0201a44 <page_insert>
            //(3) make the page swappable.
            swap_map_swappable(mm,addr,page,1);
ffffffffc02042da:	6622                	ld	a2,8(sp)
ffffffffc02042dc:	4685                	li	a3,1
ffffffffc02042de:	85a2                	mv	a1,s0
ffffffffc02042e0:	8526                	mv	a0,s1
ffffffffc02042e2:	d3afe0ef          	jal	ra,ffffffffc020281c <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc02042e6:	6722                	ld	a4,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc02042e8:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc02042ea:	e320                	sd	s0,64(a4)
failed:
    return ret;
}
ffffffffc02042ec:	70a2                	ld	ra,40(sp)
ffffffffc02042ee:	7402                	ld	s0,32(sp)
ffffffffc02042f0:	64e2                	ld	s1,24(sp)
ffffffffc02042f2:	6942                	ld	s2,16(sp)
ffffffffc02042f4:	853e                	mv	a0,a5
ffffffffc02042f6:	6145                	addi	sp,sp,48
ffffffffc02042f8:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc02042fa:	4959                	li	s2,22
ffffffffc02042fc:	b75d                	j	ffffffffc02042a2 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02042fe:	6c88                	ld	a0,24(s1)
ffffffffc0204300:	864a                	mv	a2,s2
ffffffffc0204302:	85a2                	mv	a1,s0
ffffffffc0204304:	af4fe0ef          	jal	ra,ffffffffc02025f8 <pgdir_alloc_page>
   ret = 0;
ffffffffc0204308:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020430a:	f16d                	bnez	a0,ffffffffc02042ec <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc020430c:	00002517          	auipc	a0,0x2
ffffffffc0204310:	1bc50513          	addi	a0,a0,444 # ffffffffc02064c8 <default_pmm_manager+0xd58>
ffffffffc0204314:	dabfb0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204318:	57f1                	li	a5,-4
            goto failed;
ffffffffc020431a:	bfc9                	j	ffffffffc02042ec <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020431c:	85a2                	mv	a1,s0
ffffffffc020431e:	00002517          	auipc	a0,0x2
ffffffffc0204322:	17a50513          	addi	a0,a0,378 # ffffffffc0206498 <default_pmm_manager+0xd28>
ffffffffc0204326:	d99fb0ef          	jal	ra,ffffffffc02000be <cprintf>
    int ret = -E_INVAL;
ffffffffc020432a:	57f5                	li	a5,-3
        goto failed;
ffffffffc020432c:	b7c1                	j	ffffffffc02042ec <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc020432e:	00002517          	auipc	a0,0x2
ffffffffc0204332:	1c250513          	addi	a0,a0,450 # ffffffffc02064f0 <default_pmm_manager+0xd80>
ffffffffc0204336:	d89fb0ef          	jal	ra,ffffffffc02000be <cprintf>
    ret = -E_NO_MEM;
ffffffffc020433a:	57f1                	li	a5,-4
            goto failed;
ffffffffc020433c:	bf45                	j	ffffffffc02042ec <do_pgfault+0x82>

ffffffffc020433e <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc020433e:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204340:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204342:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204344:	95afc0ef          	jal	ra,ffffffffc020049e <ide_device_valid>
ffffffffc0204348:	cd01                	beqz	a0,ffffffffc0204360 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc020434a:	4505                	li	a0,1
ffffffffc020434c:	958fc0ef          	jal	ra,ffffffffc02004a4 <ide_device_size>
}
ffffffffc0204350:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204352:	810d                	srli	a0,a0,0x3
ffffffffc0204354:	0000d797          	auipc	a5,0xd
ffffffffc0204358:	22a7b223          	sd	a0,548(a5) # ffffffffc0211578 <max_swap_offset>
}
ffffffffc020435c:	0141                	addi	sp,sp,16
ffffffffc020435e:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204360:	00002617          	auipc	a2,0x2
ffffffffc0204364:	42060613          	addi	a2,a2,1056 # ffffffffc0206780 <default_pmm_manager+0x1010>
ffffffffc0204368:	45b5                	li	a1,13
ffffffffc020436a:	00002517          	auipc	a0,0x2
ffffffffc020436e:	43650513          	addi	a0,a0,1078 # ffffffffc02067a0 <default_pmm_manager+0x1030>
ffffffffc0204372:	802fc0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc0204376 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204376:	1141                	addi	sp,sp,-16
ffffffffc0204378:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020437a:	00855793          	srli	a5,a0,0x8
ffffffffc020437e:	c7b5                	beqz	a5,ffffffffc02043ea <swapfs_read+0x74>
ffffffffc0204380:	0000d717          	auipc	a4,0xd
ffffffffc0204384:	1f870713          	addi	a4,a4,504 # ffffffffc0211578 <max_swap_offset>
ffffffffc0204388:	6318                	ld	a4,0(a4)
ffffffffc020438a:	06e7f063          	bleu	a4,a5,ffffffffc02043ea <swapfs_read+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020438e:	0000d717          	auipc	a4,0xd
ffffffffc0204392:	15a70713          	addi	a4,a4,346 # ffffffffc02114e8 <pages>
ffffffffc0204396:	6310                	ld	a2,0(a4)
ffffffffc0204398:	00001717          	auipc	a4,0x1
ffffffffc020439c:	02870713          	addi	a4,a4,40 # ffffffffc02053c0 <commands+0x858>
ffffffffc02043a0:	00002697          	auipc	a3,0x2
ffffffffc02043a4:	68068693          	addi	a3,a3,1664 # ffffffffc0206a20 <nbase>
ffffffffc02043a8:	40c58633          	sub	a2,a1,a2
ffffffffc02043ac:	630c                	ld	a1,0(a4)
ffffffffc02043ae:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02043b0:	0000d717          	auipc	a4,0xd
ffffffffc02043b4:	0e870713          	addi	a4,a4,232 # ffffffffc0211498 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02043b8:	02b60633          	mul	a2,a2,a1
ffffffffc02043bc:	0037959b          	slliw	a1,a5,0x3
ffffffffc02043c0:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02043c2:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02043c4:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02043c6:	57fd                	li	a5,-1
ffffffffc02043c8:	83b1                	srli	a5,a5,0xc
ffffffffc02043ca:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02043cc:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc02043ce:	02e7fa63          	bleu	a4,a5,ffffffffc0204402 <swapfs_read+0x8c>
ffffffffc02043d2:	0000d797          	auipc	a5,0xd
ffffffffc02043d6:	10678793          	addi	a5,a5,262 # ffffffffc02114d8 <va_pa_offset>
ffffffffc02043da:	639c                	ld	a5,0(a5)
}
ffffffffc02043dc:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02043de:	46a1                	li	a3,8
ffffffffc02043e0:	963e                	add	a2,a2,a5
ffffffffc02043e2:	4505                	li	a0,1
}
ffffffffc02043e4:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02043e6:	8c4fc06f          	j	ffffffffc02004aa <ide_read_secs>
ffffffffc02043ea:	86aa                	mv	a3,a0
ffffffffc02043ec:	00002617          	auipc	a2,0x2
ffffffffc02043f0:	3cc60613          	addi	a2,a2,972 # ffffffffc02067b8 <default_pmm_manager+0x1048>
ffffffffc02043f4:	45d1                	li	a1,20
ffffffffc02043f6:	00002517          	auipc	a0,0x2
ffffffffc02043fa:	3aa50513          	addi	a0,a0,938 # ffffffffc02067a0 <default_pmm_manager+0x1030>
ffffffffc02043fe:	f77fb0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc0204402:	86b2                	mv	a3,a2
ffffffffc0204404:	06a00593          	li	a1,106
ffffffffc0204408:	00001617          	auipc	a2,0x1
ffffffffc020440c:	3b860613          	addi	a2,a2,952 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc0204410:	00001517          	auipc	a0,0x1
ffffffffc0204414:	44850513          	addi	a0,a0,1096 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc0204418:	f5dfb0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc020441c <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc020441c:	1141                	addi	sp,sp,-16
ffffffffc020441e:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204420:	00855793          	srli	a5,a0,0x8
ffffffffc0204424:	c7b5                	beqz	a5,ffffffffc0204490 <swapfs_write+0x74>
ffffffffc0204426:	0000d717          	auipc	a4,0xd
ffffffffc020442a:	15270713          	addi	a4,a4,338 # ffffffffc0211578 <max_swap_offset>
ffffffffc020442e:	6318                	ld	a4,0(a4)
ffffffffc0204430:	06e7f063          	bleu	a4,a5,ffffffffc0204490 <swapfs_write+0x74>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0204434:	0000d717          	auipc	a4,0xd
ffffffffc0204438:	0b470713          	addi	a4,a4,180 # ffffffffc02114e8 <pages>
ffffffffc020443c:	6310                	ld	a2,0(a4)
ffffffffc020443e:	00001717          	auipc	a4,0x1
ffffffffc0204442:	f8270713          	addi	a4,a4,-126 # ffffffffc02053c0 <commands+0x858>
ffffffffc0204446:	00002697          	auipc	a3,0x2
ffffffffc020444a:	5da68693          	addi	a3,a3,1498 # ffffffffc0206a20 <nbase>
ffffffffc020444e:	40c58633          	sub	a2,a1,a2
ffffffffc0204452:	630c                	ld	a1,0(a4)
ffffffffc0204454:	860d                	srai	a2,a2,0x3
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0204456:	0000d717          	auipc	a4,0xd
ffffffffc020445a:	04270713          	addi	a4,a4,66 # ffffffffc0211498 <npage>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020445e:	02b60633          	mul	a2,a2,a1
ffffffffc0204462:	0037959b          	slliw	a1,a5,0x3
ffffffffc0204466:	629c                	ld	a5,0(a3)
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0204468:	6318                	ld	a4,0(a4)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020446a:	963e                	add	a2,a2,a5
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc020446c:	57fd                	li	a5,-1
ffffffffc020446e:	83b1                	srli	a5,a5,0xc
ffffffffc0204470:	8ff1                	and	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0204472:	0632                	slli	a2,a2,0xc
static inline void *page2kva(struct Page *page) { return KADDR(page2pa(page)); }
ffffffffc0204474:	02e7fa63          	bleu	a4,a5,ffffffffc02044a8 <swapfs_write+0x8c>
ffffffffc0204478:	0000d797          	auipc	a5,0xd
ffffffffc020447c:	06078793          	addi	a5,a5,96 # ffffffffc02114d8 <va_pa_offset>
ffffffffc0204480:	639c                	ld	a5,0(a5)
}
ffffffffc0204482:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204484:	46a1                	li	a3,8
ffffffffc0204486:	963e                	add	a2,a2,a5
ffffffffc0204488:	4505                	li	a0,1
}
ffffffffc020448a:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020448c:	842fc06f          	j	ffffffffc02004ce <ide_write_secs>
ffffffffc0204490:	86aa                	mv	a3,a0
ffffffffc0204492:	00002617          	auipc	a2,0x2
ffffffffc0204496:	32660613          	addi	a2,a2,806 # ffffffffc02067b8 <default_pmm_manager+0x1048>
ffffffffc020449a:	45e5                	li	a1,25
ffffffffc020449c:	00002517          	auipc	a0,0x2
ffffffffc02044a0:	30450513          	addi	a0,a0,772 # ffffffffc02067a0 <default_pmm_manager+0x1030>
ffffffffc02044a4:	ed1fb0ef          	jal	ra,ffffffffc0200374 <__panic>
ffffffffc02044a8:	86b2                	mv	a3,a2
ffffffffc02044aa:	06a00593          	li	a1,106
ffffffffc02044ae:	00001617          	auipc	a2,0x1
ffffffffc02044b2:	31260613          	addi	a2,a2,786 # ffffffffc02057c0 <default_pmm_manager+0x50>
ffffffffc02044b6:	00001517          	auipc	a0,0x1
ffffffffc02044ba:	3a250513          	addi	a0,a0,930 # ffffffffc0205858 <default_pmm_manager+0xe8>
ffffffffc02044be:	eb7fb0ef          	jal	ra,ffffffffc0200374 <__panic>

ffffffffc02044c2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02044c2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02044c6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02044c8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02044cc:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02044ce:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02044d2:	f022                	sd	s0,32(sp)
ffffffffc02044d4:	ec26                	sd	s1,24(sp)
ffffffffc02044d6:	e84a                	sd	s2,16(sp)
ffffffffc02044d8:	f406                	sd	ra,40(sp)
ffffffffc02044da:	e44e                	sd	s3,8(sp)
ffffffffc02044dc:	84aa                	mv	s1,a0
ffffffffc02044de:	892e                	mv	s2,a1
ffffffffc02044e0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02044e4:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02044e6:	03067e63          	bleu	a6,a2,ffffffffc0204522 <printnum+0x60>
ffffffffc02044ea:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02044ec:	00805763          	blez	s0,ffffffffc02044fa <printnum+0x38>
ffffffffc02044f0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02044f2:	85ca                	mv	a1,s2
ffffffffc02044f4:	854e                	mv	a0,s3
ffffffffc02044f6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02044f8:	fc65                	bnez	s0,ffffffffc02044f0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02044fa:	1a02                	slli	s4,s4,0x20
ffffffffc02044fc:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204500:	00002797          	auipc	a5,0x2
ffffffffc0204504:	46878793          	addi	a5,a5,1128 # ffffffffc0206968 <error_string+0x38>
ffffffffc0204508:	9a3e                	add	s4,s4,a5
}
ffffffffc020450a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020450c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204510:	70a2                	ld	ra,40(sp)
ffffffffc0204512:	69a2                	ld	s3,8(sp)
ffffffffc0204514:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204516:	85ca                	mv	a1,s2
ffffffffc0204518:	8326                	mv	t1,s1
}
ffffffffc020451a:	6942                	ld	s2,16(sp)
ffffffffc020451c:	64e2                	ld	s1,24(sp)
ffffffffc020451e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204520:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204522:	03065633          	divu	a2,a2,a6
ffffffffc0204526:	8722                	mv	a4,s0
ffffffffc0204528:	f9bff0ef          	jal	ra,ffffffffc02044c2 <printnum>
ffffffffc020452c:	b7f9                	j	ffffffffc02044fa <printnum+0x38>

ffffffffc020452e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020452e:	7119                	addi	sp,sp,-128
ffffffffc0204530:	f4a6                	sd	s1,104(sp)
ffffffffc0204532:	f0ca                	sd	s2,96(sp)
ffffffffc0204534:	e8d2                	sd	s4,80(sp)
ffffffffc0204536:	e4d6                	sd	s5,72(sp)
ffffffffc0204538:	e0da                	sd	s6,64(sp)
ffffffffc020453a:	fc5e                	sd	s7,56(sp)
ffffffffc020453c:	f862                	sd	s8,48(sp)
ffffffffc020453e:	f06a                	sd	s10,32(sp)
ffffffffc0204540:	fc86                	sd	ra,120(sp)
ffffffffc0204542:	f8a2                	sd	s0,112(sp)
ffffffffc0204544:	ecce                	sd	s3,88(sp)
ffffffffc0204546:	f466                	sd	s9,40(sp)
ffffffffc0204548:	ec6e                	sd	s11,24(sp)
ffffffffc020454a:	892a                	mv	s2,a0
ffffffffc020454c:	84ae                	mv	s1,a1
ffffffffc020454e:	8d32                	mv	s10,a2
ffffffffc0204550:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204552:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204554:	00002a17          	auipc	s4,0x2
ffffffffc0204558:	284a0a13          	addi	s4,s4,644 # ffffffffc02067d8 <default_pmm_manager+0x1068>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020455c:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204560:	00002c17          	auipc	s8,0x2
ffffffffc0204564:	3d0c0c13          	addi	s8,s8,976 # ffffffffc0206930 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204568:	000d4503          	lbu	a0,0(s10)
ffffffffc020456c:	02500793          	li	a5,37
ffffffffc0204570:	001d0413          	addi	s0,s10,1
ffffffffc0204574:	00f50e63          	beq	a0,a5,ffffffffc0204590 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0204578:	c521                	beqz	a0,ffffffffc02045c0 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020457a:	02500993          	li	s3,37
ffffffffc020457e:	a011                	j	ffffffffc0204582 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0204580:	c121                	beqz	a0,ffffffffc02045c0 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0204582:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204584:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204586:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204588:	fff44503          	lbu	a0,-1(s0)
ffffffffc020458c:	ff351ae3          	bne	a0,s3,ffffffffc0204580 <vprintfmt+0x52>
ffffffffc0204590:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204594:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204598:	4981                	li	s3,0
ffffffffc020459a:	4801                	li	a6,0
        width = precision = -1;
ffffffffc020459c:	5cfd                	li	s9,-1
ffffffffc020459e:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02045a0:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02045a4:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02045a6:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02045aa:	0ff6f693          	andi	a3,a3,255
ffffffffc02045ae:	00140d13          	addi	s10,s0,1
ffffffffc02045b2:	20d5e563          	bltu	a1,a3,ffffffffc02047bc <vprintfmt+0x28e>
ffffffffc02045b6:	068a                	slli	a3,a3,0x2
ffffffffc02045b8:	96d2                	add	a3,a3,s4
ffffffffc02045ba:	4294                	lw	a3,0(a3)
ffffffffc02045bc:	96d2                	add	a3,a3,s4
ffffffffc02045be:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02045c0:	70e6                	ld	ra,120(sp)
ffffffffc02045c2:	7446                	ld	s0,112(sp)
ffffffffc02045c4:	74a6                	ld	s1,104(sp)
ffffffffc02045c6:	7906                	ld	s2,96(sp)
ffffffffc02045c8:	69e6                	ld	s3,88(sp)
ffffffffc02045ca:	6a46                	ld	s4,80(sp)
ffffffffc02045cc:	6aa6                	ld	s5,72(sp)
ffffffffc02045ce:	6b06                	ld	s6,64(sp)
ffffffffc02045d0:	7be2                	ld	s7,56(sp)
ffffffffc02045d2:	7c42                	ld	s8,48(sp)
ffffffffc02045d4:	7ca2                	ld	s9,40(sp)
ffffffffc02045d6:	7d02                	ld	s10,32(sp)
ffffffffc02045d8:	6de2                	ld	s11,24(sp)
ffffffffc02045da:	6109                	addi	sp,sp,128
ffffffffc02045dc:	8082                	ret
    if (lflag >= 2) {
ffffffffc02045de:	4705                	li	a4,1
ffffffffc02045e0:	008a8593          	addi	a1,s5,8
ffffffffc02045e4:	01074463          	blt	a4,a6,ffffffffc02045ec <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02045e8:	26080363          	beqz	a6,ffffffffc020484e <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02045ec:	000ab603          	ld	a2,0(s5)
ffffffffc02045f0:	46c1                	li	a3,16
ffffffffc02045f2:	8aae                	mv	s5,a1
ffffffffc02045f4:	a06d                	j	ffffffffc020469e <vprintfmt+0x170>
            goto reswitch;
ffffffffc02045f6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02045fa:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02045fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02045fe:	b765                	j	ffffffffc02045a6 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0204600:	000aa503          	lw	a0,0(s5)
ffffffffc0204604:	85a6                	mv	a1,s1
ffffffffc0204606:	0aa1                	addi	s5,s5,8
ffffffffc0204608:	9902                	jalr	s2
            break;
ffffffffc020460a:	bfb9                	j	ffffffffc0204568 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020460c:	4705                	li	a4,1
ffffffffc020460e:	008a8993          	addi	s3,s5,8
ffffffffc0204612:	01074463          	blt	a4,a6,ffffffffc020461a <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0204616:	22080463          	beqz	a6,ffffffffc020483e <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020461a:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc020461e:	24044463          	bltz	s0,ffffffffc0204866 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0204622:	8622                	mv	a2,s0
ffffffffc0204624:	8ace                	mv	s5,s3
ffffffffc0204626:	46a9                	li	a3,10
ffffffffc0204628:	a89d                	j	ffffffffc020469e <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020462a:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020462e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204630:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0204632:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204636:	8fb5                	xor	a5,a5,a3
ffffffffc0204638:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020463c:	1ad74363          	blt	a4,a3,ffffffffc02047e2 <vprintfmt+0x2b4>
ffffffffc0204640:	00369793          	slli	a5,a3,0x3
ffffffffc0204644:	97e2                	add	a5,a5,s8
ffffffffc0204646:	639c                	ld	a5,0(a5)
ffffffffc0204648:	18078d63          	beqz	a5,ffffffffc02047e2 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc020464c:	86be                	mv	a3,a5
ffffffffc020464e:	00002617          	auipc	a2,0x2
ffffffffc0204652:	3ca60613          	addi	a2,a2,970 # ffffffffc0206a18 <error_string+0xe8>
ffffffffc0204656:	85a6                	mv	a1,s1
ffffffffc0204658:	854a                	mv	a0,s2
ffffffffc020465a:	240000ef          	jal	ra,ffffffffc020489a <printfmt>
ffffffffc020465e:	b729                	j	ffffffffc0204568 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0204660:	00144603          	lbu	a2,1(s0)
ffffffffc0204664:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204666:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204668:	bf3d                	j	ffffffffc02045a6 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020466a:	4705                	li	a4,1
ffffffffc020466c:	008a8593          	addi	a1,s5,8
ffffffffc0204670:	01074463          	blt	a4,a6,ffffffffc0204678 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0204674:	1e080263          	beqz	a6,ffffffffc0204858 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0204678:	000ab603          	ld	a2,0(s5)
ffffffffc020467c:	46a1                	li	a3,8
ffffffffc020467e:	8aae                	mv	s5,a1
ffffffffc0204680:	a839                	j	ffffffffc020469e <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0204682:	03000513          	li	a0,48
ffffffffc0204686:	85a6                	mv	a1,s1
ffffffffc0204688:	e03e                	sd	a5,0(sp)
ffffffffc020468a:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020468c:	85a6                	mv	a1,s1
ffffffffc020468e:	07800513          	li	a0,120
ffffffffc0204692:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204694:	0aa1                	addi	s5,s5,8
ffffffffc0204696:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc020469a:	6782                	ld	a5,0(sp)
ffffffffc020469c:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020469e:	876e                	mv	a4,s11
ffffffffc02046a0:	85a6                	mv	a1,s1
ffffffffc02046a2:	854a                	mv	a0,s2
ffffffffc02046a4:	e1fff0ef          	jal	ra,ffffffffc02044c2 <printnum>
            break;
ffffffffc02046a8:	b5c1                	j	ffffffffc0204568 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02046aa:	000ab603          	ld	a2,0(s5)
ffffffffc02046ae:	0aa1                	addi	s5,s5,8
ffffffffc02046b0:	1c060663          	beqz	a2,ffffffffc020487c <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc02046b4:	00160413          	addi	s0,a2,1
ffffffffc02046b8:	17b05c63          	blez	s11,ffffffffc0204830 <vprintfmt+0x302>
ffffffffc02046bc:	02d00593          	li	a1,45
ffffffffc02046c0:	14b79263          	bne	a5,a1,ffffffffc0204804 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02046c4:	00064783          	lbu	a5,0(a2)
ffffffffc02046c8:	0007851b          	sext.w	a0,a5
ffffffffc02046cc:	c905                	beqz	a0,ffffffffc02046fc <vprintfmt+0x1ce>
ffffffffc02046ce:	000cc563          	bltz	s9,ffffffffc02046d8 <vprintfmt+0x1aa>
ffffffffc02046d2:	3cfd                	addiw	s9,s9,-1
ffffffffc02046d4:	036c8263          	beq	s9,s6,ffffffffc02046f8 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02046d8:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02046da:	18098463          	beqz	s3,ffffffffc0204862 <vprintfmt+0x334>
ffffffffc02046de:	3781                	addiw	a5,a5,-32
ffffffffc02046e0:	18fbf163          	bleu	a5,s7,ffffffffc0204862 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02046e4:	03f00513          	li	a0,63
ffffffffc02046e8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02046ea:	0405                	addi	s0,s0,1
ffffffffc02046ec:	fff44783          	lbu	a5,-1(s0)
ffffffffc02046f0:	3dfd                	addiw	s11,s11,-1
ffffffffc02046f2:	0007851b          	sext.w	a0,a5
ffffffffc02046f6:	fd61                	bnez	a0,ffffffffc02046ce <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc02046f8:	e7b058e3          	blez	s11,ffffffffc0204568 <vprintfmt+0x3a>
ffffffffc02046fc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02046fe:	85a6                	mv	a1,s1
ffffffffc0204700:	02000513          	li	a0,32
ffffffffc0204704:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204706:	e60d81e3          	beqz	s11,ffffffffc0204568 <vprintfmt+0x3a>
ffffffffc020470a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020470c:	85a6                	mv	a1,s1
ffffffffc020470e:	02000513          	li	a0,32
ffffffffc0204712:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204714:	fe0d94e3          	bnez	s11,ffffffffc02046fc <vprintfmt+0x1ce>
ffffffffc0204718:	bd81                	j	ffffffffc0204568 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020471a:	4705                	li	a4,1
ffffffffc020471c:	008a8593          	addi	a1,s5,8
ffffffffc0204720:	01074463          	blt	a4,a6,ffffffffc0204728 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0204724:	12080063          	beqz	a6,ffffffffc0204844 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0204728:	000ab603          	ld	a2,0(s5)
ffffffffc020472c:	46a9                	li	a3,10
ffffffffc020472e:	8aae                	mv	s5,a1
ffffffffc0204730:	b7bd                	j	ffffffffc020469e <vprintfmt+0x170>
ffffffffc0204732:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0204736:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020473a:	846a                	mv	s0,s10
ffffffffc020473c:	b5ad                	j	ffffffffc02045a6 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020473e:	85a6                	mv	a1,s1
ffffffffc0204740:	02500513          	li	a0,37
ffffffffc0204744:	9902                	jalr	s2
            break;
ffffffffc0204746:	b50d                	j	ffffffffc0204568 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0204748:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc020474c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204750:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204752:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0204754:	e40dd9e3          	bgez	s11,ffffffffc02045a6 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0204758:	8de6                	mv	s11,s9
ffffffffc020475a:	5cfd                	li	s9,-1
ffffffffc020475c:	b5a9                	j	ffffffffc02045a6 <vprintfmt+0x78>
            goto reswitch;
ffffffffc020475e:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0204762:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204766:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204768:	bd3d                	j	ffffffffc02045a6 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc020476a:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc020476e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204772:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204774:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204778:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020477c:	fcd56ce3          	bltu	a0,a3,ffffffffc0204754 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0204780:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204782:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0204786:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020478a:	0196873b          	addw	a4,a3,s9
ffffffffc020478e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204792:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0204796:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc020479a:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020479e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02047a2:	fcd57fe3          	bleu	a3,a0,ffffffffc0204780 <vprintfmt+0x252>
ffffffffc02047a6:	b77d                	j	ffffffffc0204754 <vprintfmt+0x226>
            if (width < 0)
ffffffffc02047a8:	fffdc693          	not	a3,s11
ffffffffc02047ac:	96fd                	srai	a3,a3,0x3f
ffffffffc02047ae:	00ddfdb3          	and	s11,s11,a3
ffffffffc02047b2:	00144603          	lbu	a2,1(s0)
ffffffffc02047b6:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02047b8:	846a                	mv	s0,s10
ffffffffc02047ba:	b3f5                	j	ffffffffc02045a6 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02047bc:	85a6                	mv	a1,s1
ffffffffc02047be:	02500513          	li	a0,37
ffffffffc02047c2:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02047c4:	fff44703          	lbu	a4,-1(s0)
ffffffffc02047c8:	02500793          	li	a5,37
ffffffffc02047cc:	8d22                	mv	s10,s0
ffffffffc02047ce:	d8f70de3          	beq	a4,a5,ffffffffc0204568 <vprintfmt+0x3a>
ffffffffc02047d2:	02500713          	li	a4,37
ffffffffc02047d6:	1d7d                	addi	s10,s10,-1
ffffffffc02047d8:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02047dc:	fee79de3          	bne	a5,a4,ffffffffc02047d6 <vprintfmt+0x2a8>
ffffffffc02047e0:	b361                	j	ffffffffc0204568 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02047e2:	00002617          	auipc	a2,0x2
ffffffffc02047e6:	22660613          	addi	a2,a2,550 # ffffffffc0206a08 <error_string+0xd8>
ffffffffc02047ea:	85a6                	mv	a1,s1
ffffffffc02047ec:	854a                	mv	a0,s2
ffffffffc02047ee:	0ac000ef          	jal	ra,ffffffffc020489a <printfmt>
ffffffffc02047f2:	bb9d                	j	ffffffffc0204568 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02047f4:	00002617          	auipc	a2,0x2
ffffffffc02047f8:	20c60613          	addi	a2,a2,524 # ffffffffc0206a00 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02047fc:	00002417          	auipc	s0,0x2
ffffffffc0204800:	20540413          	addi	s0,s0,517 # ffffffffc0206a01 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204804:	8532                	mv	a0,a2
ffffffffc0204806:	85e6                	mv	a1,s9
ffffffffc0204808:	e032                	sd	a2,0(sp)
ffffffffc020480a:	e43e                	sd	a5,8(sp)
ffffffffc020480c:	18a000ef          	jal	ra,ffffffffc0204996 <strnlen>
ffffffffc0204810:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204814:	6602                	ld	a2,0(sp)
ffffffffc0204816:	01b05d63          	blez	s11,ffffffffc0204830 <vprintfmt+0x302>
ffffffffc020481a:	67a2                	ld	a5,8(sp)
ffffffffc020481c:	2781                	sext.w	a5,a5
ffffffffc020481e:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0204820:	6522                	ld	a0,8(sp)
ffffffffc0204822:	85a6                	mv	a1,s1
ffffffffc0204824:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204826:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204828:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020482a:	6602                	ld	a2,0(sp)
ffffffffc020482c:	fe0d9ae3          	bnez	s11,ffffffffc0204820 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204830:	00064783          	lbu	a5,0(a2)
ffffffffc0204834:	0007851b          	sext.w	a0,a5
ffffffffc0204838:	e8051be3          	bnez	a0,ffffffffc02046ce <vprintfmt+0x1a0>
ffffffffc020483c:	b335                	j	ffffffffc0204568 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc020483e:	000aa403          	lw	s0,0(s5)
ffffffffc0204842:	bbf1                	j	ffffffffc020461e <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0204844:	000ae603          	lwu	a2,0(s5)
ffffffffc0204848:	46a9                	li	a3,10
ffffffffc020484a:	8aae                	mv	s5,a1
ffffffffc020484c:	bd89                	j	ffffffffc020469e <vprintfmt+0x170>
ffffffffc020484e:	000ae603          	lwu	a2,0(s5)
ffffffffc0204852:	46c1                	li	a3,16
ffffffffc0204854:	8aae                	mv	s5,a1
ffffffffc0204856:	b5a1                	j	ffffffffc020469e <vprintfmt+0x170>
ffffffffc0204858:	000ae603          	lwu	a2,0(s5)
ffffffffc020485c:	46a1                	li	a3,8
ffffffffc020485e:	8aae                	mv	s5,a1
ffffffffc0204860:	bd3d                	j	ffffffffc020469e <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0204862:	9902                	jalr	s2
ffffffffc0204864:	b559                	j	ffffffffc02046ea <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0204866:	85a6                	mv	a1,s1
ffffffffc0204868:	02d00513          	li	a0,45
ffffffffc020486c:	e03e                	sd	a5,0(sp)
ffffffffc020486e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204870:	8ace                	mv	s5,s3
ffffffffc0204872:	40800633          	neg	a2,s0
ffffffffc0204876:	46a9                	li	a3,10
ffffffffc0204878:	6782                	ld	a5,0(sp)
ffffffffc020487a:	b515                	j	ffffffffc020469e <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc020487c:	01b05663          	blez	s11,ffffffffc0204888 <vprintfmt+0x35a>
ffffffffc0204880:	02d00693          	li	a3,45
ffffffffc0204884:	f6d798e3          	bne	a5,a3,ffffffffc02047f4 <vprintfmt+0x2c6>
ffffffffc0204888:	00002417          	auipc	s0,0x2
ffffffffc020488c:	17940413          	addi	s0,s0,377 # ffffffffc0206a01 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204890:	02800513          	li	a0,40
ffffffffc0204894:	02800793          	li	a5,40
ffffffffc0204898:	bd1d                	j	ffffffffc02046ce <vprintfmt+0x1a0>

ffffffffc020489a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020489a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020489c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02048a0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02048a2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02048a4:	ec06                	sd	ra,24(sp)
ffffffffc02048a6:	f83a                	sd	a4,48(sp)
ffffffffc02048a8:	fc3e                	sd	a5,56(sp)
ffffffffc02048aa:	e0c2                	sd	a6,64(sp)
ffffffffc02048ac:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02048ae:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02048b0:	c7fff0ef          	jal	ra,ffffffffc020452e <vprintfmt>
}
ffffffffc02048b4:	60e2                	ld	ra,24(sp)
ffffffffc02048b6:	6161                	addi	sp,sp,80
ffffffffc02048b8:	8082                	ret

ffffffffc02048ba <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02048ba:	715d                	addi	sp,sp,-80
ffffffffc02048bc:	e486                	sd	ra,72(sp)
ffffffffc02048be:	e0a2                	sd	s0,64(sp)
ffffffffc02048c0:	fc26                	sd	s1,56(sp)
ffffffffc02048c2:	f84a                	sd	s2,48(sp)
ffffffffc02048c4:	f44e                	sd	s3,40(sp)
ffffffffc02048c6:	f052                	sd	s4,32(sp)
ffffffffc02048c8:	ec56                	sd	s5,24(sp)
ffffffffc02048ca:	e85a                	sd	s6,16(sp)
ffffffffc02048cc:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02048ce:	c901                	beqz	a0,ffffffffc02048de <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02048d0:	85aa                	mv	a1,a0
ffffffffc02048d2:	00002517          	auipc	a0,0x2
ffffffffc02048d6:	14650513          	addi	a0,a0,326 # ffffffffc0206a18 <error_string+0xe8>
ffffffffc02048da:	fe4fb0ef          	jal	ra,ffffffffc02000be <cprintf>
readline(const char *prompt) {
ffffffffc02048de:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02048e0:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02048e2:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02048e4:	4aa9                	li	s5,10
ffffffffc02048e6:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02048e8:	0000cb97          	auipc	s7,0xc
ffffffffc02048ec:	798b8b93          	addi	s7,s7,1944 # ffffffffc0211080 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02048f0:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02048f4:	803fb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc02048f8:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02048fa:	00054b63          	bltz	a0,ffffffffc0204910 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02048fe:	00a95b63          	ble	a0,s2,ffffffffc0204914 <readline+0x5a>
ffffffffc0204902:	029a5463          	ble	s1,s4,ffffffffc020492a <readline+0x70>
        c = getchar();
ffffffffc0204906:	ff0fb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc020490a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc020490c:	fe0559e3          	bgez	a0,ffffffffc02048fe <readline+0x44>
            return NULL;
ffffffffc0204910:	4501                	li	a0,0
ffffffffc0204912:	a099                	j	ffffffffc0204958 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0204914:	03341463          	bne	s0,s3,ffffffffc020493c <readline+0x82>
ffffffffc0204918:	e8b9                	bnez	s1,ffffffffc020496e <readline+0xb4>
        c = getchar();
ffffffffc020491a:	fdcfb0ef          	jal	ra,ffffffffc02000f6 <getchar>
ffffffffc020491e:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0204920:	fe0548e3          	bltz	a0,ffffffffc0204910 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204924:	fea958e3          	ble	a0,s2,ffffffffc0204914 <readline+0x5a>
ffffffffc0204928:	4481                	li	s1,0
            cputchar(c);
ffffffffc020492a:	8522                	mv	a0,s0
ffffffffc020492c:	fc6fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i ++] = c;
ffffffffc0204930:	009b87b3          	add	a5,s7,s1
ffffffffc0204934:	00878023          	sb	s0,0(a5)
ffffffffc0204938:	2485                	addiw	s1,s1,1
ffffffffc020493a:	bf6d                	j	ffffffffc02048f4 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc020493c:	01540463          	beq	s0,s5,ffffffffc0204944 <readline+0x8a>
ffffffffc0204940:	fb641ae3          	bne	s0,s6,ffffffffc02048f4 <readline+0x3a>
            cputchar(c);
ffffffffc0204944:	8522                	mv	a0,s0
ffffffffc0204946:	facfb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            buf[i] = '\0';
ffffffffc020494a:	0000c517          	auipc	a0,0xc
ffffffffc020494e:	73650513          	addi	a0,a0,1846 # ffffffffc0211080 <buf>
ffffffffc0204952:	94aa                	add	s1,s1,a0
ffffffffc0204954:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0204958:	60a6                	ld	ra,72(sp)
ffffffffc020495a:	6406                	ld	s0,64(sp)
ffffffffc020495c:	74e2                	ld	s1,56(sp)
ffffffffc020495e:	7942                	ld	s2,48(sp)
ffffffffc0204960:	79a2                	ld	s3,40(sp)
ffffffffc0204962:	7a02                	ld	s4,32(sp)
ffffffffc0204964:	6ae2                	ld	s5,24(sp)
ffffffffc0204966:	6b42                	ld	s6,16(sp)
ffffffffc0204968:	6ba2                	ld	s7,8(sp)
ffffffffc020496a:	6161                	addi	sp,sp,80
ffffffffc020496c:	8082                	ret
            cputchar(c);
ffffffffc020496e:	4521                	li	a0,8
ffffffffc0204970:	f82fb0ef          	jal	ra,ffffffffc02000f2 <cputchar>
            i --;
ffffffffc0204974:	34fd                	addiw	s1,s1,-1
ffffffffc0204976:	bfbd                	j	ffffffffc02048f4 <readline+0x3a>

ffffffffc0204978 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204978:	00054783          	lbu	a5,0(a0)
ffffffffc020497c:	cb91                	beqz	a5,ffffffffc0204990 <strlen+0x18>
    size_t cnt = 0;
ffffffffc020497e:	4781                	li	a5,0
        cnt ++;
ffffffffc0204980:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0204982:	00f50733          	add	a4,a0,a5
ffffffffc0204986:	00074703          	lbu	a4,0(a4)
ffffffffc020498a:	fb7d                	bnez	a4,ffffffffc0204980 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020498c:	853e                	mv	a0,a5
ffffffffc020498e:	8082                	ret
    size_t cnt = 0;
ffffffffc0204990:	4781                	li	a5,0
}
ffffffffc0204992:	853e                	mv	a0,a5
ffffffffc0204994:	8082                	ret

ffffffffc0204996 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204996:	c185                	beqz	a1,ffffffffc02049b6 <strnlen+0x20>
ffffffffc0204998:	00054783          	lbu	a5,0(a0)
ffffffffc020499c:	cf89                	beqz	a5,ffffffffc02049b6 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc020499e:	4781                	li	a5,0
ffffffffc02049a0:	a021                	j	ffffffffc02049a8 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02049a2:	00074703          	lbu	a4,0(a4)
ffffffffc02049a6:	c711                	beqz	a4,ffffffffc02049b2 <strnlen+0x1c>
        cnt ++;
ffffffffc02049a8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02049aa:	00f50733          	add	a4,a0,a5
ffffffffc02049ae:	fef59ae3          	bne	a1,a5,ffffffffc02049a2 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02049b2:	853e                	mv	a0,a5
ffffffffc02049b4:	8082                	ret
    size_t cnt = 0;
ffffffffc02049b6:	4781                	li	a5,0
}
ffffffffc02049b8:	853e                	mv	a0,a5
ffffffffc02049ba:	8082                	ret

ffffffffc02049bc <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02049bc:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02049be:	0585                	addi	a1,a1,1
ffffffffc02049c0:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02049c4:	0785                	addi	a5,a5,1
ffffffffc02049c6:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02049ca:	fb75                	bnez	a4,ffffffffc02049be <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02049cc:	8082                	ret

ffffffffc02049ce <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02049ce:	00054783          	lbu	a5,0(a0)
ffffffffc02049d2:	0005c703          	lbu	a4,0(a1)
ffffffffc02049d6:	cb91                	beqz	a5,ffffffffc02049ea <strcmp+0x1c>
ffffffffc02049d8:	00e79c63          	bne	a5,a4,ffffffffc02049f0 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02049dc:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02049de:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02049e2:	0585                	addi	a1,a1,1
ffffffffc02049e4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02049e8:	fbe5                	bnez	a5,ffffffffc02049d8 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02049ea:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02049ec:	9d19                	subw	a0,a0,a4
ffffffffc02049ee:	8082                	ret
ffffffffc02049f0:	0007851b          	sext.w	a0,a5
ffffffffc02049f4:	9d19                	subw	a0,a0,a4
ffffffffc02049f6:	8082                	ret

ffffffffc02049f8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02049f8:	00054783          	lbu	a5,0(a0)
ffffffffc02049fc:	cb91                	beqz	a5,ffffffffc0204a10 <strchr+0x18>
        if (*s == c) {
ffffffffc02049fe:	00b79563          	bne	a5,a1,ffffffffc0204a08 <strchr+0x10>
ffffffffc0204a02:	a809                	j	ffffffffc0204a14 <strchr+0x1c>
ffffffffc0204a04:	00b78763          	beq	a5,a1,ffffffffc0204a12 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0204a08:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204a0a:	00054783          	lbu	a5,0(a0)
ffffffffc0204a0e:	fbfd                	bnez	a5,ffffffffc0204a04 <strchr+0xc>
    }
    return NULL;
ffffffffc0204a10:	4501                	li	a0,0
}
ffffffffc0204a12:	8082                	ret
ffffffffc0204a14:	8082                	ret

ffffffffc0204a16 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204a16:	ca01                	beqz	a2,ffffffffc0204a26 <memset+0x10>
ffffffffc0204a18:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204a1a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204a1c:	0785                	addi	a5,a5,1
ffffffffc0204a1e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204a22:	fec79de3          	bne	a5,a2,ffffffffc0204a1c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204a26:	8082                	ret

ffffffffc0204a28 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204a28:	ca19                	beqz	a2,ffffffffc0204a3e <memcpy+0x16>
ffffffffc0204a2a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204a2c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204a2e:	0585                	addi	a1,a1,1
ffffffffc0204a30:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0204a34:	0785                	addi	a5,a5,1
ffffffffc0204a36:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204a3a:	fec59ae3          	bne	a1,a2,ffffffffc0204a2e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204a3e:	8082                	ret
