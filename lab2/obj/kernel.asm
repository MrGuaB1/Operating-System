
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    #修改链接脚本的起始地址，由于CPU目前还处于Bare模式，会将地址都当成物理地址处理
    #跳不过去：构建一个合适的页表，让satp指向这个页表，然后使用地址的时候都要经过这个页表的翻译，
    #使得虚拟地址0xFFFFFFFFC0200000经过页表的翻译恰好变成0x80200000

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
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
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:


int kern_init(void) { // 调用pmm_init函数完成物理内存的管理
                      // 内存状态：free，used，reserved
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	00277617          	auipc	a2,0x277
ffffffffc0200042:	43a60613          	addi	a2,a2,1082 # ffffffffc0477478 <end>
int kern_init(void) { // 调用pmm_init函数完成物理内存的管理
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) { // 调用pmm_init函数完成物理内存的管理
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	7aa010ef          	jal	ra,ffffffffc02017f8 <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fe000ef          	jal	ra,ffffffffc0200450 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00001517          	auipc	a0,0x1
ffffffffc020005a:	7ba50513          	addi	a0,a0,1978 # ffffffffc0201810 <etext+0x6>
ffffffffc020005e:	090000ef          	jal	ra,ffffffffc02000ee <cputs>

    print_kerninfo();
ffffffffc0200062:	0dc000ef          	jal	ra,ffffffffc020013e <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	404000ef          	jal	ra,ffffffffc020046a <idt_init>

    //主要用来负责初始化物理内存管理
    pmm_init();  // init physical memory management
ffffffffc020006a:	066010ef          	jal	ra,ffffffffc02010d0 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006e:	3fc000ef          	jal	ra,ffffffffc020046a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200072:	39a000ef          	jal	ra,ffffffffc020040c <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200076:	3e8000ef          	jal	ra,ffffffffc020045e <intr_enable>



    /* do nothing */
    while (1)
        ;
ffffffffc020007a:	a001                	j	ffffffffc020007a <kern_init+0x44>

ffffffffc020007c <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020007c:	1141                	addi	sp,sp,-16
ffffffffc020007e:	e022                	sd	s0,0(sp)
ffffffffc0200080:	e406                	sd	ra,8(sp)
ffffffffc0200082:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200084:	3ce000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200088:	401c                	lw	a5,0(s0)
}
ffffffffc020008a:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc020008c:	2785                	addiw	a5,a5,1
ffffffffc020008e:	c01c                	sw	a5,0(s0)
}
ffffffffc0200090:	6402                	ld	s0,0(sp)
ffffffffc0200092:	0141                	addi	sp,sp,16
ffffffffc0200094:	8082                	ret

ffffffffc0200096 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200096:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	86ae                	mv	a3,a1
ffffffffc020009a:	862a                	mv	a2,a0
ffffffffc020009c:	006c                	addi	a1,sp,12
ffffffffc020009e:	00000517          	auipc	a0,0x0
ffffffffc02000a2:	fde50513          	addi	a0,a0,-34 # ffffffffc020007c <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a6:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a8:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000aa:	240010ef          	jal	ra,ffffffffc02012ea <vprintfmt>
    return cnt;
}
ffffffffc02000ae:	60e2                	ld	ra,24(sp)
ffffffffc02000b0:	4532                	lw	a0,12(sp)
ffffffffc02000b2:	6105                	addi	sp,sp,32
ffffffffc02000b4:	8082                	ret

ffffffffc02000b6 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b6:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b8:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000bc:	f42e                	sd	a1,40(sp)
ffffffffc02000be:	f832                	sd	a2,48(sp)
ffffffffc02000c0:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c2:	862a                	mv	a2,a0
ffffffffc02000c4:	004c                	addi	a1,sp,4
ffffffffc02000c6:	00000517          	auipc	a0,0x0
ffffffffc02000ca:	fb650513          	addi	a0,a0,-74 # ffffffffc020007c <cputch>
ffffffffc02000ce:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000d0:	ec06                	sd	ra,24(sp)
ffffffffc02000d2:	e0ba                	sd	a4,64(sp)
ffffffffc02000d4:	e4be                	sd	a5,72(sp)
ffffffffc02000d6:	e8c2                	sd	a6,80(sp)
ffffffffc02000d8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000da:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000dc:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000de:	20c010ef          	jal	ra,ffffffffc02012ea <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e2:	60e2                	ld	ra,24(sp)
ffffffffc02000e4:	4512                	lw	a0,4(sp)
ffffffffc02000e6:	6125                	addi	sp,sp,96
ffffffffc02000e8:	8082                	ret

ffffffffc02000ea <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000ea:	3680006f          	j	ffffffffc0200452 <cons_putc>

ffffffffc02000ee <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	e822                	sd	s0,16(sp)
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e426                	sd	s1,8(sp)
ffffffffc02000f6:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f8:	00054503          	lbu	a0,0(a0)
ffffffffc02000fc:	c51d                	beqz	a0,ffffffffc020012a <cputs+0x3c>
ffffffffc02000fe:	0405                	addi	s0,s0,1
ffffffffc0200100:	4485                	li	s1,1
ffffffffc0200102:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200104:	34e000ef          	jal	ra,ffffffffc0200452 <cons_putc>
    (*cnt) ++;
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200112:	f96d                	bnez	a0,ffffffffc0200104 <cputs+0x16>
ffffffffc0200114:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200118:	4529                	li	a0,10
ffffffffc020011a:	338000ef          	jal	ra,ffffffffc0200452 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011e:	8522                	mv	a0,s0
ffffffffc0200120:	60e2                	ld	ra,24(sp)
ffffffffc0200122:	6442                	ld	s0,16(sp)
ffffffffc0200124:	64a2                	ld	s1,8(sp)
ffffffffc0200126:	6105                	addi	sp,sp,32
ffffffffc0200128:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	4405                	li	s0,1
ffffffffc020012c:	b7f5                	j	ffffffffc0200118 <cputs+0x2a>

ffffffffc020012e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012e:	1141                	addi	sp,sp,-16
ffffffffc0200130:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200132:	328000ef          	jal	ra,ffffffffc020045a <cons_getc>
ffffffffc0200136:	dd75                	beqz	a0,ffffffffc0200132 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200138:	60a2                	ld	ra,8(sp)
ffffffffc020013a:	0141                	addi	sp,sp,16
ffffffffc020013c:	8082                	ret

ffffffffc020013e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200140:	00001517          	auipc	a0,0x1
ffffffffc0200144:	72050513          	addi	a0,a0,1824 # ffffffffc0201860 <etext+0x56>
void print_kerninfo(void) {
ffffffffc0200148:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020014a:	f6dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014e:	00000597          	auipc	a1,0x0
ffffffffc0200152:	ee858593          	addi	a1,a1,-280 # ffffffffc0200036 <kern_init>
ffffffffc0200156:	00001517          	auipc	a0,0x1
ffffffffc020015a:	72a50513          	addi	a0,a0,1834 # ffffffffc0201880 <etext+0x76>
ffffffffc020015e:	f59ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200162:	00001597          	auipc	a1,0x1
ffffffffc0200166:	6a858593          	addi	a1,a1,1704 # ffffffffc020180a <etext>
ffffffffc020016a:	00001517          	auipc	a0,0x1
ffffffffc020016e:	73650513          	addi	a0,a0,1846 # ffffffffc02018a0 <etext+0x96>
ffffffffc0200172:	f45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200176:	00006597          	auipc	a1,0x6
ffffffffc020017a:	e9a58593          	addi	a1,a1,-358 # ffffffffc0206010 <edata>
ffffffffc020017e:	00001517          	auipc	a0,0x1
ffffffffc0200182:	74250513          	addi	a0,a0,1858 # ffffffffc02018c0 <etext+0xb6>
ffffffffc0200186:	f31ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020018a:	00277597          	auipc	a1,0x277
ffffffffc020018e:	2ee58593          	addi	a1,a1,750 # ffffffffc0477478 <end>
ffffffffc0200192:	00001517          	auipc	a0,0x1
ffffffffc0200196:	74e50513          	addi	a0,a0,1870 # ffffffffc02018e0 <etext+0xd6>
ffffffffc020019a:	f1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019e:	00277597          	auipc	a1,0x277
ffffffffc02001a2:	6d958593          	addi	a1,a1,1753 # ffffffffc0477877 <end+0x3ff>
ffffffffc02001a6:	00000797          	auipc	a5,0x0
ffffffffc02001aa:	e9078793          	addi	a5,a5,-368 # ffffffffc0200036 <kern_init>
ffffffffc02001ae:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001bc:	95be                	add	a1,a1,a5
ffffffffc02001be:	85a9                	srai	a1,a1,0xa
ffffffffc02001c0:	00001517          	auipc	a0,0x1
ffffffffc02001c4:	74050513          	addi	a0,a0,1856 # ffffffffc0201900 <etext+0xf6>
}
ffffffffc02001c8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ca:	eedff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02001ce <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ce:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001d0:	00001617          	auipc	a2,0x1
ffffffffc02001d4:	66060613          	addi	a2,a2,1632 # ffffffffc0201830 <etext+0x26>
ffffffffc02001d8:	04e00593          	li	a1,78
ffffffffc02001dc:	00001517          	auipc	a0,0x1
ffffffffc02001e0:	66c50513          	addi	a0,a0,1644 # ffffffffc0201848 <etext+0x3e>
void print_stackframe(void) {
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e6:	1c6000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001ea <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001ea:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001ec:	00002617          	auipc	a2,0x2
ffffffffc02001f0:	82460613          	addi	a2,a2,-2012 # ffffffffc0201a10 <commands+0xe0>
ffffffffc02001f4:	00002597          	auipc	a1,0x2
ffffffffc02001f8:	83c58593          	addi	a1,a1,-1988 # ffffffffc0201a30 <commands+0x100>
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	83c50513          	addi	a0,a0,-1988 # ffffffffc0201a38 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200206:	eb1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	83e60613          	addi	a2,a2,-1986 # ffffffffc0201a48 <commands+0x118>
ffffffffc0200212:	00002597          	auipc	a1,0x2
ffffffffc0200216:	85e58593          	addi	a1,a1,-1954 # ffffffffc0201a70 <commands+0x140>
ffffffffc020021a:	00002517          	auipc	a0,0x2
ffffffffc020021e:	81e50513          	addi	a0,a0,-2018 # ffffffffc0201a38 <commands+0x108>
ffffffffc0200222:	e95ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	85a60613          	addi	a2,a2,-1958 # ffffffffc0201a80 <commands+0x150>
ffffffffc020022e:	00002597          	auipc	a1,0x2
ffffffffc0200232:	87258593          	addi	a1,a1,-1934 # ffffffffc0201aa0 <commands+0x170>
ffffffffc0200236:	00002517          	auipc	a0,0x2
ffffffffc020023a:	80250513          	addi	a0,a0,-2046 # ffffffffc0201a38 <commands+0x108>
ffffffffc020023e:	e79ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    }
    return 0;
}
ffffffffc0200242:	60a2                	ld	ra,8(sp)
ffffffffc0200244:	4501                	li	a0,0
ffffffffc0200246:	0141                	addi	sp,sp,16
ffffffffc0200248:	8082                	ret

ffffffffc020024a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020024a:	1141                	addi	sp,sp,-16
ffffffffc020024c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024e:	ef1ff0ef          	jal	ra,ffffffffc020013e <print_kerninfo>
    return 0;
}
ffffffffc0200252:	60a2                	ld	ra,8(sp)
ffffffffc0200254:	4501                	li	a0,0
ffffffffc0200256:	0141                	addi	sp,sp,16
ffffffffc0200258:	8082                	ret

ffffffffc020025a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	1141                	addi	sp,sp,-16
ffffffffc020025c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025e:	f71ff0ef          	jal	ra,ffffffffc02001ce <print_stackframe>
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020026a:	7115                	addi	sp,sp,-224
ffffffffc020026c:	e962                	sd	s8,144(sp)
ffffffffc020026e:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200270:	00001517          	auipc	a0,0x1
ffffffffc0200274:	70850513          	addi	a0,a0,1800 # ffffffffc0201978 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200278:	ed86                	sd	ra,216(sp)
ffffffffc020027a:	e9a2                	sd	s0,208(sp)
ffffffffc020027c:	e5a6                	sd	s1,200(sp)
ffffffffc020027e:	e1ca                	sd	s2,192(sp)
ffffffffc0200280:	fd4e                	sd	s3,184(sp)
ffffffffc0200282:	f952                	sd	s4,176(sp)
ffffffffc0200284:	f556                	sd	s5,168(sp)
ffffffffc0200286:	f15a                	sd	s6,160(sp)
ffffffffc0200288:	ed5e                	sd	s7,152(sp)
ffffffffc020028a:	e566                	sd	s9,136(sp)
ffffffffc020028c:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	e29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200292:	00001517          	auipc	a0,0x1
ffffffffc0200296:	70e50513          	addi	a0,a0,1806 # ffffffffc02019a0 <commands+0x70>
ffffffffc020029a:	e1dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    if (tf != NULL) {
ffffffffc020029e:	000c0563          	beqz	s8,ffffffffc02002a8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002a2:	8562                	mv	a0,s8
ffffffffc02002a4:	3a6000ef          	jal	ra,ffffffffc020064a <print_trapframe>
ffffffffc02002a8:	00001c97          	auipc	s9,0x1
ffffffffc02002ac:	688c8c93          	addi	s9,s9,1672 # ffffffffc0201930 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002b0:	00001997          	auipc	s3,0x1
ffffffffc02002b4:	71898993          	addi	s3,s3,1816 # ffffffffc02019c8 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b8:	00001917          	auipc	s2,0x1
ffffffffc02002bc:	71890913          	addi	s2,s2,1816 # ffffffffc02019d0 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002c0:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002c2:	00001b17          	auipc	s6,0x1
ffffffffc02002c6:	716b0b13          	addi	s6,s6,1814 # ffffffffc02019d8 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ca:	00001a97          	auipc	s5,0x1
ffffffffc02002ce:	766a8a93          	addi	s5,s5,1894 # ffffffffc0201a30 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002d2:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d4:	854e                	mv	a0,s3
ffffffffc02002d6:	3a0010ef          	jal	ra,ffffffffc0201676 <readline>
ffffffffc02002da:	842a                	mv	s0,a0
ffffffffc02002dc:	dd65                	beqz	a0,ffffffffc02002d4 <kmonitor+0x6a>
ffffffffc02002de:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002e2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e4:	c999                	beqz	a1,ffffffffc02002fa <kmonitor+0x90>
ffffffffc02002e6:	854a                	mv	a0,s2
ffffffffc02002e8:	4f2010ef          	jal	ra,ffffffffc02017da <strchr>
ffffffffc02002ec:	c925                	beqz	a0,ffffffffc020035c <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ee:	00144583          	lbu	a1,1(s0)
ffffffffc02002f2:	00040023          	sb	zero,0(s0)
ffffffffc02002f6:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f8:	f5fd                	bnez	a1,ffffffffc02002e6 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002fa:	dce9                	beqz	s1,ffffffffc02002d4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002fc:	6582                	ld	a1,0(sp)
ffffffffc02002fe:	00001d17          	auipc	s10,0x1
ffffffffc0200302:	632d0d13          	addi	s10,s10,1586 # ffffffffc0201930 <commands>
    if (argc == 0) {
ffffffffc0200306:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200308:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	0d61                	addi	s10,s10,24
ffffffffc020030c:	4a4010ef          	jal	ra,ffffffffc02017b0 <strcmp>
ffffffffc0200310:	c919                	beqz	a0,ffffffffc0200326 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200312:	2405                	addiw	s0,s0,1
ffffffffc0200314:	09740463          	beq	s0,s7,ffffffffc020039c <kmonitor+0x132>
ffffffffc0200318:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031c:	6582                	ld	a1,0(sp)
ffffffffc020031e:	0d61                	addi	s10,s10,24
ffffffffc0200320:	490010ef          	jal	ra,ffffffffc02017b0 <strcmp>
ffffffffc0200324:	f57d                	bnez	a0,ffffffffc0200312 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200326:	00141793          	slli	a5,s0,0x1
ffffffffc020032a:	97a2                	add	a5,a5,s0
ffffffffc020032c:	078e                	slli	a5,a5,0x3
ffffffffc020032e:	97e6                	add	a5,a5,s9
ffffffffc0200330:	6b9c                	ld	a5,16(a5)
ffffffffc0200332:	8662                	mv	a2,s8
ffffffffc0200334:	002c                	addi	a1,sp,8
ffffffffc0200336:	fff4851b          	addiw	a0,s1,-1
ffffffffc020033a:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020033c:	f8055ce3          	bgez	a0,ffffffffc02002d4 <kmonitor+0x6a>
}
ffffffffc0200340:	60ee                	ld	ra,216(sp)
ffffffffc0200342:	644e                	ld	s0,208(sp)
ffffffffc0200344:	64ae                	ld	s1,200(sp)
ffffffffc0200346:	690e                	ld	s2,192(sp)
ffffffffc0200348:	79ea                	ld	s3,184(sp)
ffffffffc020034a:	7a4a                	ld	s4,176(sp)
ffffffffc020034c:	7aaa                	ld	s5,168(sp)
ffffffffc020034e:	7b0a                	ld	s6,160(sp)
ffffffffc0200350:	6bea                	ld	s7,152(sp)
ffffffffc0200352:	6c4a                	ld	s8,144(sp)
ffffffffc0200354:	6caa                	ld	s9,136(sp)
ffffffffc0200356:	6d0a                	ld	s10,128(sp)
ffffffffc0200358:	612d                	addi	sp,sp,224
ffffffffc020035a:	8082                	ret
        if (*buf == '\0') {
ffffffffc020035c:	00044783          	lbu	a5,0(s0)
ffffffffc0200360:	dfc9                	beqz	a5,ffffffffc02002fa <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200362:	03448863          	beq	s1,s4,ffffffffc0200392 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200366:	00349793          	slli	a5,s1,0x3
ffffffffc020036a:	0118                	addi	a4,sp,128
ffffffffc020036c:	97ba                	add	a5,a5,a4
ffffffffc020036e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200372:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200376:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200378:	e591                	bnez	a1,ffffffffc0200384 <kmonitor+0x11a>
ffffffffc020037a:	b749                	j	ffffffffc02002fc <kmonitor+0x92>
            buf ++;
ffffffffc020037c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037e:	00044583          	lbu	a1,0(s0)
ffffffffc0200382:	ddad                	beqz	a1,ffffffffc02002fc <kmonitor+0x92>
ffffffffc0200384:	854a                	mv	a0,s2
ffffffffc0200386:	454010ef          	jal	ra,ffffffffc02017da <strchr>
ffffffffc020038a:	d96d                	beqz	a0,ffffffffc020037c <kmonitor+0x112>
ffffffffc020038c:	00044583          	lbu	a1,0(s0)
ffffffffc0200390:	bf91                	j	ffffffffc02002e4 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d21ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
ffffffffc020039a:	b7f1                	j	ffffffffc0200366 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	65a50513          	addi	a0,a0,1626 # ffffffffc02019f8 <commands+0xc8>
ffffffffc02003a6:	d11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    return 0;
ffffffffc02003aa:	b72d                	j	ffffffffc02002d4 <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06430313          	addi	t1,t1,100 # ffffffffc0206410 <is_panic>
ffffffffc02003b4:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	02031c63          	bnez	t1,ffffffffc0200400 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	8432                	mv	s0,a2
ffffffffc02003d0:	00006717          	auipc	a4,0x6
ffffffffc02003d4:	04f72023          	sw	a5,64(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003da:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003dc:	85aa                	mv	a1,a0
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	6d250513          	addi	a0,a0,1746 # ffffffffc0201ab0 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e6:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e8:	ccfff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003ec:	65a2                	ld	a1,8(sp)
ffffffffc02003ee:	8522                	mv	a0,s0
ffffffffc02003f0:	ca7ff0ef          	jal	ra,ffffffffc0200096 <vcprintf>
    cprintf("\n");
ffffffffc02003f4:	00001517          	auipc	a0,0x1
ffffffffc02003f8:	53450513          	addi	a0,a0,1332 # ffffffffc0201928 <etext+0x11e>
ffffffffc02003fc:	cbbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200400:	064000ef          	jal	ra,ffffffffc0200464 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200404:	4501                	li	a0,0
ffffffffc0200406:	e65ff0ef          	jal	ra,ffffffffc020026a <kmonitor>
ffffffffc020040a:	bfed                	j	ffffffffc0200404 <__panic+0x58>

ffffffffc020040c <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020040c:	1141                	addi	sp,sp,-16
ffffffffc020040e:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200410:	02000793          	li	a5,32
ffffffffc0200414:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200418:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020041c:	67e1                	lui	a5,0x18
ffffffffc020041e:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200422:	953e                	add	a0,a0,a5
ffffffffc0200424:	32c010ef          	jal	ra,ffffffffc0201750 <sbi_set_timer>
}
ffffffffc0200428:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020042a:	00006797          	auipc	a5,0x6
ffffffffc020042e:	0007b323          	sd	zero,6(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200432:	00001517          	auipc	a0,0x1
ffffffffc0200436:	69e50513          	addi	a0,a0,1694 # ffffffffc0201ad0 <commands+0x1a0>
}
ffffffffc020043a:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020043c:	c7bff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc0200440 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200440:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200444:	67e1                	lui	a5,0x18
ffffffffc0200446:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020044a:	953e                	add	a0,a0,a5
ffffffffc020044c:	3040106f          	j	ffffffffc0201750 <sbi_set_timer>

ffffffffc0200450 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200450:	8082                	ret

ffffffffc0200452 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200452:	0ff57513          	andi	a0,a0,255
ffffffffc0200456:	2de0106f          	j	ffffffffc0201734 <sbi_console_putchar>

ffffffffc020045a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020045a:	3120106f          	j	ffffffffc020176c <sbi_console_getchar>

ffffffffc020045e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200464:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200468:	8082                	ret

ffffffffc020046a <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020046a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046e:	00000797          	auipc	a5,0x0
ffffffffc0200472:	30678793          	addi	a5,a5,774 # ffffffffc0200774 <__alltraps>
ffffffffc0200476:	10579073          	csrw	stvec,a5
}
ffffffffc020047a:	8082                	ret

ffffffffc020047c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020047e:	1141                	addi	sp,sp,-16
ffffffffc0200480:	e022                	sd	s0,0(sp)
ffffffffc0200482:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200484:	00001517          	auipc	a0,0x1
ffffffffc0200488:	76450513          	addi	a0,a0,1892 # ffffffffc0201be8 <commands+0x2b8>
void print_regs(struct pushregs *gpr) {
ffffffffc020048c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048e:	c29ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200492:	640c                	ld	a1,8(s0)
ffffffffc0200494:	00001517          	auipc	a0,0x1
ffffffffc0200498:	76c50513          	addi	a0,a0,1900 # ffffffffc0201c00 <commands+0x2d0>
ffffffffc020049c:	c1bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004a0:	680c                	ld	a1,16(s0)
ffffffffc02004a2:	00001517          	auipc	a0,0x1
ffffffffc02004a6:	77650513          	addi	a0,a0,1910 # ffffffffc0201c18 <commands+0x2e8>
ffffffffc02004aa:	c0dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004ae:	6c0c                	ld	a1,24(s0)
ffffffffc02004b0:	00001517          	auipc	a0,0x1
ffffffffc02004b4:	78050513          	addi	a0,a0,1920 # ffffffffc0201c30 <commands+0x300>
ffffffffc02004b8:	bffff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004bc:	700c                	ld	a1,32(s0)
ffffffffc02004be:	00001517          	auipc	a0,0x1
ffffffffc02004c2:	78a50513          	addi	a0,a0,1930 # ffffffffc0201c48 <commands+0x318>
ffffffffc02004c6:	bf1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004ca:	740c                	ld	a1,40(s0)
ffffffffc02004cc:	00001517          	auipc	a0,0x1
ffffffffc02004d0:	79450513          	addi	a0,a0,1940 # ffffffffc0201c60 <commands+0x330>
ffffffffc02004d4:	be3ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d8:	780c                	ld	a1,48(s0)
ffffffffc02004da:	00001517          	auipc	a0,0x1
ffffffffc02004de:	79e50513          	addi	a0,a0,1950 # ffffffffc0201c78 <commands+0x348>
ffffffffc02004e2:	bd5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e6:	7c0c                	ld	a1,56(s0)
ffffffffc02004e8:	00001517          	auipc	a0,0x1
ffffffffc02004ec:	7a850513          	addi	a0,a0,1960 # ffffffffc0201c90 <commands+0x360>
ffffffffc02004f0:	bc7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f4:	602c                	ld	a1,64(s0)
ffffffffc02004f6:	00001517          	auipc	a0,0x1
ffffffffc02004fa:	7b250513          	addi	a0,a0,1970 # ffffffffc0201ca8 <commands+0x378>
ffffffffc02004fe:	bb9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200502:	642c                	ld	a1,72(s0)
ffffffffc0200504:	00001517          	auipc	a0,0x1
ffffffffc0200508:	7bc50513          	addi	a0,a0,1980 # ffffffffc0201cc0 <commands+0x390>
ffffffffc020050c:	babff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200510:	682c                	ld	a1,80(s0)
ffffffffc0200512:	00001517          	auipc	a0,0x1
ffffffffc0200516:	7c650513          	addi	a0,a0,1990 # ffffffffc0201cd8 <commands+0x3a8>
ffffffffc020051a:	b9dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051e:	6c2c                	ld	a1,88(s0)
ffffffffc0200520:	00001517          	auipc	a0,0x1
ffffffffc0200524:	7d050513          	addi	a0,a0,2000 # ffffffffc0201cf0 <commands+0x3c0>
ffffffffc0200528:	b8fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020052c:	702c                	ld	a1,96(s0)
ffffffffc020052e:	00001517          	auipc	a0,0x1
ffffffffc0200532:	7da50513          	addi	a0,a0,2010 # ffffffffc0201d08 <commands+0x3d8>
ffffffffc0200536:	b81ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020053a:	742c                	ld	a1,104(s0)
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	7e450513          	addi	a0,a0,2020 # ffffffffc0201d20 <commands+0x3f0>
ffffffffc0200544:	b73ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200548:	782c                	ld	a1,112(s0)
ffffffffc020054a:	00001517          	auipc	a0,0x1
ffffffffc020054e:	7ee50513          	addi	a0,a0,2030 # ffffffffc0201d38 <commands+0x408>
ffffffffc0200552:	b65ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200556:	7c2c                	ld	a1,120(s0)
ffffffffc0200558:	00001517          	auipc	a0,0x1
ffffffffc020055c:	7f850513          	addi	a0,a0,2040 # ffffffffc0201d50 <commands+0x420>
ffffffffc0200560:	b57ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200564:	604c                	ld	a1,128(s0)
ffffffffc0200566:	00002517          	auipc	a0,0x2
ffffffffc020056a:	80250513          	addi	a0,a0,-2046 # ffffffffc0201d68 <commands+0x438>
ffffffffc020056e:	b49ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200572:	644c                	ld	a1,136(s0)
ffffffffc0200574:	00002517          	auipc	a0,0x2
ffffffffc0200578:	80c50513          	addi	a0,a0,-2036 # ffffffffc0201d80 <commands+0x450>
ffffffffc020057c:	b3bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200580:	684c                	ld	a1,144(s0)
ffffffffc0200582:	00002517          	auipc	a0,0x2
ffffffffc0200586:	81650513          	addi	a0,a0,-2026 # ffffffffc0201d98 <commands+0x468>
ffffffffc020058a:	b2dff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058e:	6c4c                	ld	a1,152(s0)
ffffffffc0200590:	00002517          	auipc	a0,0x2
ffffffffc0200594:	82050513          	addi	a0,a0,-2016 # ffffffffc0201db0 <commands+0x480>
ffffffffc0200598:	b1fff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020059c:	704c                	ld	a1,160(s0)
ffffffffc020059e:	00002517          	auipc	a0,0x2
ffffffffc02005a2:	82a50513          	addi	a0,a0,-2006 # ffffffffc0201dc8 <commands+0x498>
ffffffffc02005a6:	b11ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005aa:	744c                	ld	a1,168(s0)
ffffffffc02005ac:	00002517          	auipc	a0,0x2
ffffffffc02005b0:	83450513          	addi	a0,a0,-1996 # ffffffffc0201de0 <commands+0x4b0>
ffffffffc02005b4:	b03ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b8:	784c                	ld	a1,176(s0)
ffffffffc02005ba:	00002517          	auipc	a0,0x2
ffffffffc02005be:	83e50513          	addi	a0,a0,-1986 # ffffffffc0201df8 <commands+0x4c8>
ffffffffc02005c2:	af5ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c6:	7c4c                	ld	a1,184(s0)
ffffffffc02005c8:	00002517          	auipc	a0,0x2
ffffffffc02005cc:	84850513          	addi	a0,a0,-1976 # ffffffffc0201e10 <commands+0x4e0>
ffffffffc02005d0:	ae7ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d4:	606c                	ld	a1,192(s0)
ffffffffc02005d6:	00002517          	auipc	a0,0x2
ffffffffc02005da:	85250513          	addi	a0,a0,-1966 # ffffffffc0201e28 <commands+0x4f8>
ffffffffc02005de:	ad9ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005e2:	646c                	ld	a1,200(s0)
ffffffffc02005e4:	00002517          	auipc	a0,0x2
ffffffffc02005e8:	85c50513          	addi	a0,a0,-1956 # ffffffffc0201e40 <commands+0x510>
ffffffffc02005ec:	acbff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005f0:	686c                	ld	a1,208(s0)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	86650513          	addi	a0,a0,-1946 # ffffffffc0201e58 <commands+0x528>
ffffffffc02005fa:	abdff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200600:	00002517          	auipc	a0,0x2
ffffffffc0200604:	87050513          	addi	a0,a0,-1936 # ffffffffc0201e70 <commands+0x540>
ffffffffc0200608:	aafff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020060c:	706c                	ld	a1,224(s0)
ffffffffc020060e:	00002517          	auipc	a0,0x2
ffffffffc0200612:	87a50513          	addi	a0,a0,-1926 # ffffffffc0201e88 <commands+0x558>
ffffffffc0200616:	aa1ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020061a:	746c                	ld	a1,232(s0)
ffffffffc020061c:	00002517          	auipc	a0,0x2
ffffffffc0200620:	88450513          	addi	a0,a0,-1916 # ffffffffc0201ea0 <commands+0x570>
ffffffffc0200624:	a93ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200628:	786c                	ld	a1,240(s0)
ffffffffc020062a:	00002517          	auipc	a0,0x2
ffffffffc020062e:	88e50513          	addi	a0,a0,-1906 # ffffffffc0201eb8 <commands+0x588>
ffffffffc0200632:	a85ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200638:	6402                	ld	s0,0(sp)
ffffffffc020063a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	89450513          	addi	a0,a0,-1900 # ffffffffc0201ed0 <commands+0x5a0>
}
ffffffffc0200644:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200646:	a71ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020064a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020064a:	1141                	addi	sp,sp,-16
ffffffffc020064c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200650:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200652:	00002517          	auipc	a0,0x2
ffffffffc0200656:	89650513          	addi	a0,a0,-1898 # ffffffffc0201ee8 <commands+0x5b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020065a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020065c:	a5bff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200660:	8522                	mv	a0,s0
ffffffffc0200662:	e1bff0ef          	jal	ra,ffffffffc020047c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200666:	10043583          	ld	a1,256(s0)
ffffffffc020066a:	00002517          	auipc	a0,0x2
ffffffffc020066e:	89650513          	addi	a0,a0,-1898 # ffffffffc0201f00 <commands+0x5d0>
ffffffffc0200672:	a45ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200676:	10843583          	ld	a1,264(s0)
ffffffffc020067a:	00002517          	auipc	a0,0x2
ffffffffc020067e:	89e50513          	addi	a0,a0,-1890 # ffffffffc0201f18 <commands+0x5e8>
ffffffffc0200682:	a35ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200686:	11043583          	ld	a1,272(s0)
ffffffffc020068a:	00002517          	auipc	a0,0x2
ffffffffc020068e:	8a650513          	addi	a0,a0,-1882 # ffffffffc0201f30 <commands+0x600>
ffffffffc0200692:	a25ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	11843583          	ld	a1,280(s0)
}
ffffffffc020069a:	6402                	ld	s0,0(sp)
ffffffffc020069c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069e:	00002517          	auipc	a0,0x2
ffffffffc02006a2:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0201f48 <commands+0x618>
}
ffffffffc02006a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a8:	a0fff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc02006ac <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006ac:	11853783          	ld	a5,280(a0)
ffffffffc02006b0:	577d                	li	a4,-1
ffffffffc02006b2:	8305                	srli	a4,a4,0x1
ffffffffc02006b4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006b6:	472d                	li	a4,11
ffffffffc02006b8:	08f76563          	bltu	a4,a5,ffffffffc0200742 <interrupt_handler+0x96>
ffffffffc02006bc:	00001717          	auipc	a4,0x1
ffffffffc02006c0:	43070713          	addi	a4,a4,1072 # ffffffffc0201aec <commands+0x1bc>
ffffffffc02006c4:	078a                	slli	a5,a5,0x2
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	439c                	lw	a5,0(a5)
ffffffffc02006ca:	97ba                	add	a5,a5,a4
ffffffffc02006cc:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ce:	00001517          	auipc	a0,0x1
ffffffffc02006d2:	4b250513          	addi	a0,a0,1202 # ffffffffc0201b80 <commands+0x250>
ffffffffc02006d6:	9e1ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006da:	00001517          	auipc	a0,0x1
ffffffffc02006de:	48650513          	addi	a0,a0,1158 # ffffffffc0201b60 <commands+0x230>
ffffffffc02006e2:	9d5ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e6:	00001517          	auipc	a0,0x1
ffffffffc02006ea:	43a50513          	addi	a0,a0,1082 # ffffffffc0201b20 <commands+0x1f0>
ffffffffc02006ee:	9c9ff06f          	j	ffffffffc02000b6 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006f2:	00001517          	auipc	a0,0x1
ffffffffc02006f6:	4ae50513          	addi	a0,a0,1198 # ffffffffc0201ba0 <commands+0x270>
ffffffffc02006fa:	9bdff06f          	j	ffffffffc02000b6 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006fe:	1141                	addi	sp,sp,-16
ffffffffc0200700:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200702:	d3fff0ef          	jal	ra,ffffffffc0200440 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200706:	00006797          	auipc	a5,0x6
ffffffffc020070a:	d2a78793          	addi	a5,a5,-726 # ffffffffc0206430 <ticks>
ffffffffc020070e:	639c                	ld	a5,0(a5)
ffffffffc0200710:	06400713          	li	a4,100
ffffffffc0200714:	0785                	addi	a5,a5,1
ffffffffc0200716:	02e7f733          	remu	a4,a5,a4
ffffffffc020071a:	00006697          	auipc	a3,0x6
ffffffffc020071e:	d0f6bb23          	sd	a5,-746(a3) # ffffffffc0206430 <ticks>
ffffffffc0200722:	c315                	beqz	a4,ffffffffc0200746 <interrupt_handler+0x9a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200724:	60a2                	ld	ra,8(sp)
ffffffffc0200726:	0141                	addi	sp,sp,16
ffffffffc0200728:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc020072a:	00001517          	auipc	a0,0x1
ffffffffc020072e:	49e50513          	addi	a0,a0,1182 # ffffffffc0201bc8 <commands+0x298>
ffffffffc0200732:	985ff06f          	j	ffffffffc02000b6 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200736:	00001517          	auipc	a0,0x1
ffffffffc020073a:	40a50513          	addi	a0,a0,1034 # ffffffffc0201b40 <commands+0x210>
ffffffffc020073e:	979ff06f          	j	ffffffffc02000b6 <cprintf>
            print_trapframe(tf);
ffffffffc0200742:	f09ff06f          	j	ffffffffc020064a <print_trapframe>
}
ffffffffc0200746:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200748:	06400593          	li	a1,100
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	46c50513          	addi	a0,a0,1132 # ffffffffc0201bb8 <commands+0x288>
}
ffffffffc0200754:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200756:	961ff06f          	j	ffffffffc02000b6 <cprintf>

ffffffffc020075a <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc020075a:	11853783          	ld	a5,280(a0)
ffffffffc020075e:	0007c863          	bltz	a5,ffffffffc020076e <trap+0x14>
    switch (tf->cause) {
ffffffffc0200762:	472d                	li	a4,11
ffffffffc0200764:	00f76363          	bltu	a4,a5,ffffffffc020076a <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200768:	8082                	ret
            print_trapframe(tf);
ffffffffc020076a:	ee1ff06f          	j	ffffffffc020064a <print_trapframe>
        interrupt_handler(tf);
ffffffffc020076e:	f3fff06f          	j	ffffffffc02006ac <interrupt_handler>
	...

ffffffffc0200774 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200774:	14011073          	csrw	sscratch,sp
ffffffffc0200778:	712d                	addi	sp,sp,-288
ffffffffc020077a:	e002                	sd	zero,0(sp)
ffffffffc020077c:	e406                	sd	ra,8(sp)
ffffffffc020077e:	ec0e                	sd	gp,24(sp)
ffffffffc0200780:	f012                	sd	tp,32(sp)
ffffffffc0200782:	f416                	sd	t0,40(sp)
ffffffffc0200784:	f81a                	sd	t1,48(sp)
ffffffffc0200786:	fc1e                	sd	t2,56(sp)
ffffffffc0200788:	e0a2                	sd	s0,64(sp)
ffffffffc020078a:	e4a6                	sd	s1,72(sp)
ffffffffc020078c:	e8aa                	sd	a0,80(sp)
ffffffffc020078e:	ecae                	sd	a1,88(sp)
ffffffffc0200790:	f0b2                	sd	a2,96(sp)
ffffffffc0200792:	f4b6                	sd	a3,104(sp)
ffffffffc0200794:	f8ba                	sd	a4,112(sp)
ffffffffc0200796:	fcbe                	sd	a5,120(sp)
ffffffffc0200798:	e142                	sd	a6,128(sp)
ffffffffc020079a:	e546                	sd	a7,136(sp)
ffffffffc020079c:	e94a                	sd	s2,144(sp)
ffffffffc020079e:	ed4e                	sd	s3,152(sp)
ffffffffc02007a0:	f152                	sd	s4,160(sp)
ffffffffc02007a2:	f556                	sd	s5,168(sp)
ffffffffc02007a4:	f95a                	sd	s6,176(sp)
ffffffffc02007a6:	fd5e                	sd	s7,184(sp)
ffffffffc02007a8:	e1e2                	sd	s8,192(sp)
ffffffffc02007aa:	e5e6                	sd	s9,200(sp)
ffffffffc02007ac:	e9ea                	sd	s10,208(sp)
ffffffffc02007ae:	edee                	sd	s11,216(sp)
ffffffffc02007b0:	f1f2                	sd	t3,224(sp)
ffffffffc02007b2:	f5f6                	sd	t4,232(sp)
ffffffffc02007b4:	f9fa                	sd	t5,240(sp)
ffffffffc02007b6:	fdfe                	sd	t6,248(sp)
ffffffffc02007b8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007bc:	100024f3          	csrr	s1,sstatus
ffffffffc02007c0:	14102973          	csrr	s2,sepc
ffffffffc02007c4:	143029f3          	csrr	s3,stval
ffffffffc02007c8:	14202a73          	csrr	s4,scause
ffffffffc02007cc:	e822                	sd	s0,16(sp)
ffffffffc02007ce:	e226                	sd	s1,256(sp)
ffffffffc02007d0:	e64a                	sd	s2,264(sp)
ffffffffc02007d2:	ea4e                	sd	s3,272(sp)
ffffffffc02007d4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007d6:	850a                	mv	a0,sp
    jal trap
ffffffffc02007d8:	f83ff0ef          	jal	ra,ffffffffc020075a <trap>

ffffffffc02007dc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007dc:	6492                	ld	s1,256(sp)
ffffffffc02007de:	6932                	ld	s2,264(sp)
ffffffffc02007e0:	10049073          	csrw	sstatus,s1
ffffffffc02007e4:	14191073          	csrw	sepc,s2
ffffffffc02007e8:	60a2                	ld	ra,8(sp)
ffffffffc02007ea:	61e2                	ld	gp,24(sp)
ffffffffc02007ec:	7202                	ld	tp,32(sp)
ffffffffc02007ee:	72a2                	ld	t0,40(sp)
ffffffffc02007f0:	7342                	ld	t1,48(sp)
ffffffffc02007f2:	73e2                	ld	t2,56(sp)
ffffffffc02007f4:	6406                	ld	s0,64(sp)
ffffffffc02007f6:	64a6                	ld	s1,72(sp)
ffffffffc02007f8:	6546                	ld	a0,80(sp)
ffffffffc02007fa:	65e6                	ld	a1,88(sp)
ffffffffc02007fc:	7606                	ld	a2,96(sp)
ffffffffc02007fe:	76a6                	ld	a3,104(sp)
ffffffffc0200800:	7746                	ld	a4,112(sp)
ffffffffc0200802:	77e6                	ld	a5,120(sp)
ffffffffc0200804:	680a                	ld	a6,128(sp)
ffffffffc0200806:	68aa                	ld	a7,136(sp)
ffffffffc0200808:	694a                	ld	s2,144(sp)
ffffffffc020080a:	69ea                	ld	s3,152(sp)
ffffffffc020080c:	7a0a                	ld	s4,160(sp)
ffffffffc020080e:	7aaa                	ld	s5,168(sp)
ffffffffc0200810:	7b4a                	ld	s6,176(sp)
ffffffffc0200812:	7bea                	ld	s7,184(sp)
ffffffffc0200814:	6c0e                	ld	s8,192(sp)
ffffffffc0200816:	6cae                	ld	s9,200(sp)
ffffffffc0200818:	6d4e                	ld	s10,208(sp)
ffffffffc020081a:	6dee                	ld	s11,216(sp)
ffffffffc020081c:	7e0e                	ld	t3,224(sp)
ffffffffc020081e:	7eae                	ld	t4,232(sp)
ffffffffc0200820:	7f4e                	ld	t5,240(sp)
ffffffffc0200822:	7fee                	ld	t6,248(sp)
ffffffffc0200824:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200826:	10200073          	sret

ffffffffc020082a <buddy_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020082a:	00006797          	auipc	a5,0x6
ffffffffc020082e:	c0e78793          	addi	a5,a5,-1010 # ffffffffc0206438 <free_area>
ffffffffc0200832:	e79c                	sd	a5,8(a5)
ffffffffc0200834:	e39c                	sd	a5,0(a5)
int nr_block;//已分配的块数

static void buddy_init()
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200836:	0007a823          	sw	zero,16(a5)
}
ffffffffc020083a:	8082                	ret

ffffffffc020083c <buddy_free_pages>:
    unsigned left_longest, right_longest;
    struct buddy2* self = root;

    list_entry_t* le = list_next(&free_list);
    int i = 0;
    for (i = 0; i < nr_block; i++)//找到块
ffffffffc020083c:	00006897          	auipc	a7,0x6
ffffffffc0200840:	c1488893          	addi	a7,a7,-1004 # ffffffffc0206450 <nr_block>
ffffffffc0200844:	0008a803          	lw	a6,0(a7)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200848:	00006e17          	auipc	t3,0x6
ffffffffc020084c:	bf0e0e13          	addi	t3,t3,-1040 # ffffffffc0206438 <free_area>
ffffffffc0200850:	008e3703          	ld	a4,8(t3)
ffffffffc0200854:	17005f63          	blez	a6,ffffffffc02009d2 <buddy_free_pages+0x196>
        if (rec[i].base == base)
ffffffffc0200858:	000a2617          	auipc	a2,0xa2
ffffffffc020085c:	00060613          	mv	a2,a2
ffffffffc0200860:	621c                	ld	a5,0(a2)
ffffffffc0200862:	16f50e63          	beq	a0,a5,ffffffffc02009de <buddy_free_pages+0x1a2>
ffffffffc0200866:	000a2697          	auipc	a3,0xa2
ffffffffc020086a:	00a68693          	addi	a3,a3,10 # ffffffffc02a2870 <rec+0x18>
    for (i = 0; i < nr_block; i++)//找到块
ffffffffc020086e:	4781                	li	a5,0
ffffffffc0200870:	a029                	j	ffffffffc020087a <buddy_free_pages+0x3e>
        if (rec[i].base == base)
ffffffffc0200872:	fe86b303          	ld	t1,-24(a3)
ffffffffc0200876:	14a30c63          	beq	t1,a0,ffffffffc02009ce <buddy_free_pages+0x192>
    for (i = 0; i < nr_block; i++)//找到块
ffffffffc020087a:	2785                	addiw	a5,a5,1
ffffffffc020087c:	06e1                	addi	a3,a3,24
ffffffffc020087e:	ff079ae3          	bne	a5,a6,ffffffffc0200872 <buddy_free_pages+0x36>
            break;
    int offset = rec[i].offset; //找到偏移量
ffffffffc0200882:	00181313          	slli	t1,a6,0x1
ffffffffc0200886:	010307b3          	add	a5,t1,a6
ffffffffc020088a:	078e                	slli	a5,a5,0x3
ffffffffc020088c:	97b2                	add	a5,a5,a2
ffffffffc020088e:	0087ae83          	lw	t4,8(a5)
    int pos = i; //暂存i
    i = 0;
    while (i++ < offset)
ffffffffc0200892:	01d05963          	blez	t4,ffffffffc02008a4 <buddy_free_pages+0x68>
ffffffffc0200896:	001e851b          	addiw	a0,t4,1
ffffffffc020089a:	4685                	li	a3,1
ffffffffc020089c:	2685                	addiw	a3,a3,1
ffffffffc020089e:	6718                	ld	a4,8(a4)
ffffffffc02008a0:	fea69ee3          	bne	a3,a0,ffffffffc020089c <buddy_free_pages+0x60>
        le = list_next(le);
    int allocpages = fixsize(n);
ffffffffc02008a4:	2581                	sext.w	a1,a1
    size |= size >> 1;
ffffffffc02008a6:	0015d69b          	srliw	a3,a1,0x1
ffffffffc02008aa:	8ecd                	or	a3,a3,a1
ffffffffc02008ac:	2681                	sext.w	a3,a3
    size |= size >> 2;
ffffffffc02008ae:	0026d79b          	srliw	a5,a3,0x2
ffffffffc02008b2:	8edd                	or	a3,a3,a5
ffffffffc02008b4:	2681                	sext.w	a3,a3
    size |= size >> 4;
ffffffffc02008b6:	0046d79b          	srliw	a5,a3,0x4

    node_size = 1;
    index = offset + self->size - 1;
ffffffffc02008ba:	00006517          	auipc	a0,0x6
ffffffffc02008be:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0206458 <root>
    size |= size >> 4;
ffffffffc02008c2:	8edd                	or	a3,a3,a5
    index = offset + self->size - 1;
ffffffffc02008c4:	411c                	lw	a5,0(a0)
    size |= size >> 4;
ffffffffc02008c6:	2681                	sext.w	a3,a3
    size |= size >> 8;
ffffffffc02008c8:	0086d59b          	srliw	a1,a3,0x8
ffffffffc02008cc:	8ecd                	or	a3,a3,a1
    index = offset + self->size - 1;
ffffffffc02008ce:	37fd                	addiw	a5,a5,-1
    size |= size >> 8;
ffffffffc02008d0:	2681                	sext.w	a3,a3
    index = offset + self->size - 1;
ffffffffc02008d2:	01d787bb          	addw	a5,a5,t4
    size |= size >> 16;
ffffffffc02008d6:	0106d59b          	srliw	a1,a3,0x10
    nr_free += allocpages;//更新空闲页的数量
ffffffffc02008da:	010e2e83          	lw	t4,16(t3)
    struct Page* p;
    self[index].longest = allocpages; //恢复longest字段
ffffffffc02008de:	02079e13          	slli	t3,a5,0x20
    size |= size >> 16;
ffffffffc02008e2:	8ecd                	or	a3,a3,a1
    self[index].longest = allocpages; //恢复longest字段
ffffffffc02008e4:	020e5e13          	srli	t3,t3,0x20
    return size + 1; //得到2的幂次方
ffffffffc02008e8:	0016859b          	addiw	a1,a3,1
    self[index].longest = allocpages; //恢复longest字段
ffffffffc02008ec:	0e0e                	slli	t3,t3,0x3
    nr_free += allocpages;//更新空闲页的数量
ffffffffc02008ee:	00be8ebb          	addw	t4,t4,a1
    self[index].longest = allocpages; //恢复longest字段
ffffffffc02008f2:	9e2a                	add	t3,t3,a0
    nr_free += allocpages;//更新空闲页的数量
ffffffffc02008f4:	00006f17          	auipc	t5,0x6
ffffffffc02008f8:	b5df2a23          	sw	t4,-1196(t5) # ffffffffc0206448 <free_area+0x10>
    self[index].longest = allocpages; //恢复longest字段
ffffffffc02008fc:	00be2223          	sw	a1,4(t3)

    for (i = 0; i < allocpages; i++)//回收已分配的页
ffffffffc0200900:	4681                	li	a3,0
    {
        p = le2page(le, page_link);
        p->flags = 0;
        p->property = 1;
ffffffffc0200902:	4e85                	li	t4,1
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200904:	4e09                	li	t3,2
    for (i = 0; i < allocpages; i++)//回收已分配的页
ffffffffc0200906:	00b05e63          	blez	a1,ffffffffc0200922 <buddy_free_pages+0xe6>
        p->flags = 0;
ffffffffc020090a:	fe073823          	sd	zero,-16(a4)
        p->property = 1;
ffffffffc020090e:	ffd72c23          	sw	t4,-8(a4)
ffffffffc0200912:	ff070f13          	addi	t5,a4,-16
ffffffffc0200916:	41cf302f          	amoor.d	zero,t3,(t5)
    for (i = 0; i < allocpages; i++)//回收已分配的页
ffffffffc020091a:	2685                	addiw	a3,a3,1
ffffffffc020091c:	6718                	ld	a4,8(a4)
ffffffffc020091e:	fed596e3          	bne	a1,a3,ffffffffc020090a <buddy_free_pages+0xce>
    node_size = 1;
ffffffffc0200922:	4e05                	li	t3,1
        SetPageProperty(p);
        le = list_next(le);
    }
    while (index) { //向上合并，修改祖先节点的记录值
ffffffffc0200924:	c7b9                	beqz	a5,ffffffffc0200972 <buddy_free_pages+0x136>
        index = PARENT(index);
ffffffffc0200926:	2785                	addiw	a5,a5,1
ffffffffc0200928:	0017d59b          	srliw	a1,a5,0x1
ffffffffc020092c:	35fd                	addiw	a1,a1,-1
        node_size *= 2;

        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc020092e:	0015969b          	slliw	a3,a1,0x1
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc0200932:	ffe7f713          	andi	a4,a5,-2
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc0200936:	2685                	addiw	a3,a3,1
ffffffffc0200938:	1682                	slli	a3,a3,0x20
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc020093a:	1702                	slli	a4,a4,0x20
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc020093c:	9281                	srli	a3,a3,0x20
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc020093e:	9301                	srli	a4,a4,0x20
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc0200940:	068e                	slli	a3,a3,0x3
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc0200942:	070e                	slli	a4,a4,0x3
ffffffffc0200944:	972a                	add	a4,a4,a0
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc0200946:	96aa                	add	a3,a3,a0
        right_longest = self[RIGHT_LEAF(index)].longest;
ffffffffc0200948:	00472e83          	lw	t4,4(a4)
        left_longest = self[LEFT_LEAF(index)].longest;
ffffffffc020094c:	42d4                	lw	a3,4(a3)
ffffffffc020094e:	02059713          	slli	a4,a1,0x20
ffffffffc0200952:	8375                	srli	a4,a4,0x1d
        node_size *= 2;
ffffffffc0200954:	001e1e1b          	slliw	t3,t3,0x1

        if (left_longest + right_longest == node_size)
ffffffffc0200958:	01d68fbb          	addw	t6,a3,t4
ffffffffc020095c:	972a                	add	a4,a4,a0
        index = PARENT(index);
ffffffffc020095e:	0005879b          	sext.w	a5,a1
        if (left_longest + right_longest == node_size)
ffffffffc0200962:	07cf8263          	beq	t6,t3,ffffffffc02009c6 <buddy_free_pages+0x18a>
            self[index].longest = node_size;
        else
            self[index].longest = MAX(left_longest, right_longest);
ffffffffc0200966:	85b6                	mv	a1,a3
ffffffffc0200968:	01d6f363          	bleu	t4,a3,ffffffffc020096e <buddy_free_pages+0x132>
ffffffffc020096c:	85f6                	mv	a1,t4
ffffffffc020096e:	c34c                	sw	a1,4(a4)
    while (index) { //向上合并，修改祖先节点的记录值
ffffffffc0200970:	fbdd                	bnez	a5,ffffffffc0200926 <buddy_free_pages+0xea>
    }

    // 恢复结构体
    for (i = pos; i < nr_block - 1; i++)
ffffffffc0200972:	0008a783          	lw	a5,0(a7)
ffffffffc0200976:	fff7871b          	addiw	a4,a5,-1
ffffffffc020097a:	853a                	mv	a0,a4
ffffffffc020097c:	04e85063          	ble	a4,a6,ffffffffc02009bc <buddy_free_pages+0x180>
ffffffffc0200980:	ffe7859b          	addiw	a1,a5,-2
ffffffffc0200984:	410585bb          	subw	a1,a1,a6
ffffffffc0200988:	1582                	slli	a1,a1,0x20
ffffffffc020098a:	9181                	srli	a1,a1,0x20
ffffffffc020098c:	01058733          	add	a4,a1,a6
ffffffffc0200990:	00171593          	slli	a1,a4,0x1
ffffffffc0200994:	95ba                	add	a1,a1,a4
ffffffffc0200996:	010307b3          	add	a5,t1,a6
ffffffffc020099a:	078e                	slli	a5,a5,0x3
ffffffffc020099c:	058e                	slli	a1,a1,0x3
ffffffffc020099e:	000a2717          	auipc	a4,0xa2
ffffffffc02009a2:	ed270713          	addi	a4,a4,-302 # ffffffffc02a2870 <rec+0x18>
ffffffffc02009a6:	97b2                	add	a5,a5,a2
ffffffffc02009a8:	95ba                	add	a1,a1,a4
        rec[i] = rec[i + 1];
ffffffffc02009aa:	6f90                	ld	a2,24(a5)
ffffffffc02009ac:	7394                	ld	a3,32(a5)
ffffffffc02009ae:	7798                	ld	a4,40(a5)
ffffffffc02009b0:	e390                	sd	a2,0(a5)
ffffffffc02009b2:	e794                	sd	a3,8(a5)
ffffffffc02009b4:	eb98                	sd	a4,16(a5)
ffffffffc02009b6:	07e1                	addi	a5,a5,24
    for (i = pos; i < nr_block - 1; i++)
ffffffffc02009b8:	fef599e3          	bne	a1,a5,ffffffffc02009aa <buddy_free_pages+0x16e>
    nr_block--; //更新分配块数的值
ffffffffc02009bc:	00006797          	auipc	a5,0x6
ffffffffc02009c0:	a8a7aa23          	sw	a0,-1388(a5) # ffffffffc0206450 <nr_block>
}
ffffffffc02009c4:	8082                	ret
            self[index].longest = node_size;
ffffffffc02009c6:	01c72223          	sw	t3,4(a4)
    while (index) { //向上合并，修改祖先节点的记录值
ffffffffc02009ca:	ffb1                	bnez	a5,ffffffffc0200926 <buddy_free_pages+0xea>
ffffffffc02009cc:	b75d                	j	ffffffffc0200972 <buddy_free_pages+0x136>
    for (i = 0; i < nr_block; i++)//找到块
ffffffffc02009ce:	883e                	mv	a6,a5
ffffffffc02009d0:	bd4d                	j	ffffffffc0200882 <buddy_free_pages+0x46>
ffffffffc02009d2:	4801                	li	a6,0
ffffffffc02009d4:	000a2617          	auipc	a2,0xa2
ffffffffc02009d8:	e8460613          	addi	a2,a2,-380 # ffffffffc02a2858 <rec>
ffffffffc02009dc:	b55d                	j	ffffffffc0200882 <buddy_free_pages+0x46>
ffffffffc02009de:	4801                	li	a6,0
ffffffffc02009e0:	b54d                	j	ffffffffc0200882 <buddy_free_pages+0x46>

ffffffffc02009e2 <buddy_nr_free_pages>:

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02009e2:	00006517          	auipc	a0,0x6
ffffffffc02009e6:	a6656503          	lwu	a0,-1434(a0) # ffffffffc0206448 <free_area+0x10>
ffffffffc02009ea:	8082                	ret

ffffffffc02009ec <buddy_check>:

static void
buddy_check(void) {
ffffffffc02009ec:	7179                	addi	sp,sp,-48
    struct Page* p0, * A, * B, * C, * D;
    p0 = A = B = C = D = NULL;

    // 检验是否分配成功
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009ee:	4505                	li	a0,1
buddy_check(void) {
ffffffffc02009f0:	f406                	sd	ra,40(sp)
ffffffffc02009f2:	f022                	sd	s0,32(sp)
ffffffffc02009f4:	ec26                	sd	s1,24(sp)
ffffffffc02009f6:	e84a                	sd	s2,16(sp)
ffffffffc02009f8:	e44e                	sd	s3,8(sp)
ffffffffc02009fa:	e052                	sd	s4,0(sp)
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009fc:	64a000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200a00:	28050c63          	beqz	a0,ffffffffc0200c98 <buddy_check+0x2ac>
ffffffffc0200a04:	842a                	mv	s0,a0
    assert((A = alloc_page()) != NULL);
ffffffffc0200a06:	4505                	li	a0,1
ffffffffc0200a08:	63e000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200a0c:	84aa                	mv	s1,a0
ffffffffc0200a0e:	26050563          	beqz	a0,ffffffffc0200c78 <buddy_check+0x28c>
    assert((B = alloc_page()) != NULL);
ffffffffc0200a12:	4505                	li	a0,1
ffffffffc0200a14:	632000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200a18:	892a                	mv	s2,a0
ffffffffc0200a1a:	22050f63          	beqz	a0,ffffffffc0200c58 <buddy_check+0x26c>

    //检验分配是否不重复
    assert(p0 != A && p0 != B && A != B);
ffffffffc0200a1e:	18940d63          	beq	s0,s1,ffffffffc0200bb8 <buddy_check+0x1cc>
ffffffffc0200a22:	18a40b63          	beq	s0,a0,ffffffffc0200bb8 <buddy_check+0x1cc>
ffffffffc0200a26:	18a48963          	beq	s1,a0,ffffffffc0200bb8 <buddy_check+0x1cc>

    // 多重合并检验，最终的效果是A和P0都指向含1024页的块的首地址
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
ffffffffc0200a2a:	401c                	lw	a5,0(s0)
ffffffffc0200a2c:	1a079663          	bnez	a5,ffffffffc0200bd8 <buddy_check+0x1ec>
ffffffffc0200a30:	409c                	lw	a5,0(s1)
ffffffffc0200a32:	1a079363          	bnez	a5,ffffffffc0200bd8 <buddy_check+0x1ec>
ffffffffc0200a36:	411c                	lw	a5,0(a0)
ffffffffc0200a38:	1a079063          	bnez	a5,ffffffffc0200bd8 <buddy_check+0x1ec>
    free_page(p0);
ffffffffc0200a3c:	8522                	mv	a0,s0
ffffffffc0200a3e:	4585                	li	a1,1
ffffffffc0200a40:	64a000ef          	jal	ra,ffffffffc020108a <free_pages>
    free_page(A);
ffffffffc0200a44:	8526                	mv	a0,s1
ffffffffc0200a46:	4585                	li	a1,1
ffffffffc0200a48:	642000ef          	jal	ra,ffffffffc020108a <free_pages>
    free_page(B);
ffffffffc0200a4c:	4585                	li	a1,1
ffffffffc0200a4e:	854a                	mv	a0,s2
ffffffffc0200a50:	63a000ef          	jal	ra,ffffffffc020108a <free_pages>
    A = alloc_pages(500);
ffffffffc0200a54:	1f400513          	li	a0,500
ffffffffc0200a58:	5ee000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200a5c:	842a                	mv	s0,a0
    B = alloc_pages(500);
ffffffffc0200a5e:	1f400513          	li	a0,500
ffffffffc0200a62:	5e4000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200a66:	84aa                	mv	s1,a0
    cprintf("A %p\n", A);
ffffffffc0200a68:	85a2                	mv	a1,s0
ffffffffc0200a6a:	00001517          	auipc	a0,0x1
ffffffffc0200a6e:	5e650513          	addi	a0,a0,1510 # ffffffffc0202050 <commands+0x720>
ffffffffc0200a72:	e44ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("B %p\n", B);
ffffffffc0200a76:	85a6                	mv	a1,s1
ffffffffc0200a78:	00001517          	auipc	a0,0x1
ffffffffc0200a7c:	5e050513          	addi	a0,a0,1504 # ffffffffc0202058 <commands+0x728>
ffffffffc0200a80:	e36ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(A, 250);
ffffffffc0200a84:	0fa00593          	li	a1,250
ffffffffc0200a88:	8522                	mv	a0,s0
ffffffffc0200a8a:	600000ef          	jal	ra,ffffffffc020108a <free_pages>
    free_pages(B, 500);
ffffffffc0200a8e:	1f400593          	li	a1,500
ffffffffc0200a92:	8526                	mv	a0,s1
ffffffffc0200a94:	5f6000ef          	jal	ra,ffffffffc020108a <free_pages>
    free_pages(A + 250, 250);
ffffffffc0200a98:	6509                	lui	a0,0x2
ffffffffc0200a9a:	71050513          	addi	a0,a0,1808 # 2710 <BASE_ADDRESS-0xffffffffc01fd8f0>
ffffffffc0200a9e:	0fa00593          	li	a1,250
ffffffffc0200aa2:	9522                	add	a0,a0,s0
ffffffffc0200aa4:	5e6000ef          	jal	ra,ffffffffc020108a <free_pages>
    p0 = alloc_pages(1024);
ffffffffc0200aa8:	40000513          	li	a0,1024
ffffffffc0200aac:	59a000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200ab0:	892a                	mv	s2,a0
    cprintf("p0 %p\n", p0);
ffffffffc0200ab2:	85aa                	mv	a1,a0
ffffffffc0200ab4:	00001517          	auipc	a0,0x1
ffffffffc0200ab8:	5ac50513          	addi	a0,a0,1452 # ffffffffc0202060 <commands+0x730>
ffffffffc0200abc:	dfaff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    assert(p0 == A);
ffffffffc0200ac0:	21241c63          	bne	s0,s2,ffffffffc0200cd8 <buddy_check+0x2ec>
    assert(p0 + 512 == B);
ffffffffc0200ac4:	6795                	lui	a5,0x5
ffffffffc0200ac6:	97ca                	add	a5,a5,s2
ffffffffc0200ac8:	12f49863          	bne	s1,a5,ffffffffc0200bf8 <buddy_check+0x20c>

    //检验buddy分配规则
    A = alloc_pages(70);
ffffffffc0200acc:	04600513          	li	a0,70
ffffffffc0200ad0:	576000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
ffffffffc0200ad4:	89aa                	mv	s3,a0
    B = alloc_pages(35);
ffffffffc0200ad6:	02300513          	li	a0,35
ffffffffc0200ada:	56c000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
    assert(A + 128 == B);
ffffffffc0200ade:	6405                	lui	s0,0x1
ffffffffc0200ae0:	40040793          	addi	a5,s0,1024 # 1400 <BASE_ADDRESS-0xffffffffc01fec00>
ffffffffc0200ae4:	97ce                	add	a5,a5,s3
    B = alloc_pages(35);
ffffffffc0200ae6:	84aa                	mv	s1,a0
    assert(A + 128 == B);
ffffffffc0200ae8:	14f51863          	bne	a0,a5,ffffffffc0200c38 <buddy_check+0x24c>
    cprintf("A %p\n", A);
ffffffffc0200aec:	85ce                	mv	a1,s3
ffffffffc0200aee:	00001517          	auipc	a0,0x1
ffffffffc0200af2:	56250513          	addi	a0,a0,1378 # ffffffffc0202050 <commands+0x720>
ffffffffc0200af6:	dc0ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("B %p\n", B);
ffffffffc0200afa:	85a6                	mv	a1,s1
ffffffffc0200afc:	00001517          	auipc	a0,0x1
ffffffffc0200b00:	55c50513          	addi	a0,a0,1372 # ffffffffc0202058 <commands+0x728>
ffffffffc0200b04:	db2ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    C = alloc_pages(80);
ffffffffc0200b08:	05000513          	li	a0,80
ffffffffc0200b0c:	53a000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
    assert(A + 256 == C);
ffffffffc0200b10:	678d                	lui	a5,0x3
ffffffffc0200b12:	80078793          	addi	a5,a5,-2048 # 2800 <BASE_ADDRESS-0xffffffffc01fd800>
ffffffffc0200b16:	97ce                	add	a5,a5,s3
    C = alloc_pages(80);
ffffffffc0200b18:	8a2a                	mv	s4,a0
    assert(A + 256 == C);
ffffffffc0200b1a:	0ef51f63          	bne	a0,a5,ffffffffc0200c18 <buddy_check+0x22c>
    cprintf("C %p\n", C);
ffffffffc0200b1e:	85aa                	mv	a1,a0
ffffffffc0200b20:	00001517          	auipc	a0,0x1
ffffffffc0200b24:	58050513          	addi	a0,a0,1408 # ffffffffc02020a0 <commands+0x770>
ffffffffc0200b28:	d8eff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(A, 70);
ffffffffc0200b2c:	854e                	mv	a0,s3
ffffffffc0200b2e:	04600593          	li	a1,70
ffffffffc0200b32:	558000ef          	jal	ra,ffffffffc020108a <free_pages>
    cprintf("B %p\n", B);
ffffffffc0200b36:	85a6                	mv	a1,s1
ffffffffc0200b38:	00001517          	auipc	a0,0x1
ffffffffc0200b3c:	52050513          	addi	a0,a0,1312 # ffffffffc0202058 <commands+0x728>
ffffffffc0200b40:	d76ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    D = alloc_pages(60);
ffffffffc0200b44:	03c00513          	li	a0,60
ffffffffc0200b48:	4fe000ef          	jal	ra,ffffffffc0201046 <alloc_pages>
    cprintf("D %p\n", D);
    assert(B + 64 == D);
ffffffffc0200b4c:	a0040413          	addi	s0,s0,-1536
    cprintf("D %p\n", D);
ffffffffc0200b50:	85aa                	mv	a1,a0
    D = alloc_pages(60);
ffffffffc0200b52:	89aa                	mv	s3,a0
    assert(B + 64 == D);
ffffffffc0200b54:	9426                	add	s0,s0,s1
    cprintf("D %p\n", D);
ffffffffc0200b56:	00001517          	auipc	a0,0x1
ffffffffc0200b5a:	55250513          	addi	a0,a0,1362 # ffffffffc02020a8 <commands+0x778>
ffffffffc0200b5e:	d58ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    assert(B + 64 == D);
ffffffffc0200b62:	14899b63          	bne	s3,s0,ffffffffc0200cb8 <buddy_check+0x2cc>
    free_pages(B, 35);
ffffffffc0200b66:	8526                	mv	a0,s1
ffffffffc0200b68:	02300593          	li	a1,35
ffffffffc0200b6c:	51e000ef          	jal	ra,ffffffffc020108a <free_pages>
    cprintf("D %p\n", D);
ffffffffc0200b70:	85ce                	mv	a1,s3
ffffffffc0200b72:	00001517          	auipc	a0,0x1
ffffffffc0200b76:	53650513          	addi	a0,a0,1334 # ffffffffc02020a8 <commands+0x778>
ffffffffc0200b7a:	d3cff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(D, 60);
ffffffffc0200b7e:	854e                	mv	a0,s3
ffffffffc0200b80:	03c00593          	li	a1,60
ffffffffc0200b84:	506000ef          	jal	ra,ffffffffc020108a <free_pages>
    cprintf("C %p\n", C);
ffffffffc0200b88:	85d2                	mv	a1,s4
ffffffffc0200b8a:	00001517          	auipc	a0,0x1
ffffffffc0200b8e:	51650513          	addi	a0,a0,1302 # ffffffffc02020a0 <commands+0x770>
ffffffffc0200b92:	d24ff0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    free_pages(C, 80);
ffffffffc0200b96:	8552                	mv	a0,s4
ffffffffc0200b98:	05000593          	li	a1,80
ffffffffc0200b9c:	4ee000ef          	jal	ra,ffffffffc020108a <free_pages>
    free_pages(p0, 1000);
}
ffffffffc0200ba0:	7402                	ld	s0,32(sp)
ffffffffc0200ba2:	70a2                	ld	ra,40(sp)
ffffffffc0200ba4:	64e2                	ld	s1,24(sp)
ffffffffc0200ba6:	69a2                	ld	s3,8(sp)
ffffffffc0200ba8:	6a02                	ld	s4,0(sp)
    free_pages(p0, 1000);
ffffffffc0200baa:	854a                	mv	a0,s2
}
ffffffffc0200bac:	6942                	ld	s2,16(sp)
    free_pages(p0, 1000);
ffffffffc0200bae:	3e800593          	li	a1,1000
}
ffffffffc0200bb2:	6145                	addi	sp,sp,48
    free_pages(p0, 1000);
ffffffffc0200bb4:	4d60006f          	j	ffffffffc020108a <free_pages>
    assert(p0 != A && p0 != B && A != B);
ffffffffc0200bb8:	00001697          	auipc	a3,0x1
ffffffffc0200bbc:	43868693          	addi	a3,a3,1080 # ffffffffc0201ff0 <commands+0x6c0>
ffffffffc0200bc0:	00001617          	auipc	a2,0x1
ffffffffc0200bc4:	3c060613          	addi	a2,a2,960 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200bc8:	0d200593          	li	a1,210
ffffffffc0200bcc:	00001517          	auipc	a0,0x1
ffffffffc0200bd0:	3cc50513          	addi	a0,a0,972 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200bd4:	fd8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
ffffffffc0200bd8:	00001697          	auipc	a3,0x1
ffffffffc0200bdc:	43868693          	addi	a3,a3,1080 # ffffffffc0202010 <commands+0x6e0>
ffffffffc0200be0:	00001617          	auipc	a2,0x1
ffffffffc0200be4:	3a060613          	addi	a2,a2,928 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200be8:	0d500593          	li	a1,213
ffffffffc0200bec:	00001517          	auipc	a0,0x1
ffffffffc0200bf0:	3ac50513          	addi	a0,a0,940 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200bf4:	fb8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 + 512 == B);
ffffffffc0200bf8:	00001697          	auipc	a3,0x1
ffffffffc0200bfc:	47868693          	addi	a3,a3,1144 # ffffffffc0202070 <commands+0x740>
ffffffffc0200c00:	00001617          	auipc	a2,0x1
ffffffffc0200c04:	38060613          	addi	a2,a2,896 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200c08:	0e300593          	li	a1,227
ffffffffc0200c0c:	00001517          	auipc	a0,0x1
ffffffffc0200c10:	38c50513          	addi	a0,a0,908 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200c14:	f98ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(A + 256 == C);
ffffffffc0200c18:	00001697          	auipc	a3,0x1
ffffffffc0200c1c:	47868693          	addi	a3,a3,1144 # ffffffffc0202090 <commands+0x760>
ffffffffc0200c20:	00001617          	auipc	a2,0x1
ffffffffc0200c24:	36060613          	addi	a2,a2,864 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200c28:	0ec00593          	li	a1,236
ffffffffc0200c2c:	00001517          	auipc	a0,0x1
ffffffffc0200c30:	36c50513          	addi	a0,a0,876 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200c34:	f78ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(A + 128 == B);
ffffffffc0200c38:	00001697          	auipc	a3,0x1
ffffffffc0200c3c:	44868693          	addi	a3,a3,1096 # ffffffffc0202080 <commands+0x750>
ffffffffc0200c40:	00001617          	auipc	a2,0x1
ffffffffc0200c44:	34060613          	addi	a2,a2,832 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200c48:	0e800593          	li	a1,232
ffffffffc0200c4c:	00001517          	auipc	a0,0x1
ffffffffc0200c50:	34c50513          	addi	a0,a0,844 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200c54:	f58ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((B = alloc_page()) != NULL);
ffffffffc0200c58:	00001697          	auipc	a3,0x1
ffffffffc0200c5c:	37868693          	addi	a3,a3,888 # ffffffffc0201fd0 <commands+0x6a0>
ffffffffc0200c60:	00001617          	auipc	a2,0x1
ffffffffc0200c64:	32060613          	addi	a2,a2,800 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200c68:	0cf00593          	li	a1,207
ffffffffc0200c6c:	00001517          	auipc	a0,0x1
ffffffffc0200c70:	32c50513          	addi	a0,a0,812 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200c74:	f38ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((A = alloc_page()) != NULL);
ffffffffc0200c78:	00001697          	auipc	a3,0x1
ffffffffc0200c7c:	33868693          	addi	a3,a3,824 # ffffffffc0201fb0 <commands+0x680>
ffffffffc0200c80:	00001617          	auipc	a2,0x1
ffffffffc0200c84:	30060613          	addi	a2,a2,768 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200c88:	0ce00593          	li	a1,206
ffffffffc0200c8c:	00001517          	auipc	a0,0x1
ffffffffc0200c90:	30c50513          	addi	a0,a0,780 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200c94:	f18ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c98:	00001697          	auipc	a3,0x1
ffffffffc0200c9c:	2c868693          	addi	a3,a3,712 # ffffffffc0201f60 <commands+0x630>
ffffffffc0200ca0:	00001617          	auipc	a2,0x1
ffffffffc0200ca4:	2e060613          	addi	a2,a2,736 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200ca8:	0cd00593          	li	a1,205
ffffffffc0200cac:	00001517          	auipc	a0,0x1
ffffffffc0200cb0:	2ec50513          	addi	a0,a0,748 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200cb4:	ef8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(B + 64 == D);
ffffffffc0200cb8:	00001697          	auipc	a3,0x1
ffffffffc0200cbc:	3f868693          	addi	a3,a3,1016 # ffffffffc02020b0 <commands+0x780>
ffffffffc0200cc0:	00001617          	auipc	a2,0x1
ffffffffc0200cc4:	2c060613          	addi	a2,a2,704 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200cc8:	0f200593          	li	a1,242
ffffffffc0200ccc:	00001517          	auipc	a0,0x1
ffffffffc0200cd0:	2cc50513          	addi	a0,a0,716 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200cd4:	ed8ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 == A);
ffffffffc0200cd8:	00001697          	auipc	a3,0x1
ffffffffc0200cdc:	39068693          	addi	a3,a3,912 # ffffffffc0202068 <commands+0x738>
ffffffffc0200ce0:	00001617          	auipc	a2,0x1
ffffffffc0200ce4:	2a060613          	addi	a2,a2,672 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200ce8:	0e200593          	li	a1,226
ffffffffc0200cec:	00001517          	auipc	a0,0x1
ffffffffc0200cf0:	2ac50513          	addi	a0,a0,684 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200cf4:	eb8ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200cf8 <buddy_init_memmap>:
{
ffffffffc0200cf8:	1141                	addi	sp,sp,-16
ffffffffc0200cfa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200cfc:	10058a63          	beqz	a1,ffffffffc0200e10 <buddy_init_memmap+0x118>
    for (; p != base + n; p++)
ffffffffc0200d00:	00259613          	slli	a2,a1,0x2
ffffffffc0200d04:	962e                	add	a2,a2,a1
ffffffffc0200d06:	060e                	slli	a2,a2,0x3
ffffffffc0200d08:	962a                	add	a2,a2,a0
ffffffffc0200d0a:	0ca60e63          	beq	a2,a0,ffffffffc0200de6 <buddy_init_memmap+0xee>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d0e:	651c                	ld	a5,8(a0)
ffffffffc0200d10:	00005697          	auipc	a3,0x5
ffffffffc0200d14:	72868693          	addi	a3,a3,1832 # ffffffffc0206438 <free_area>
        p->property = 1;
ffffffffc0200d18:	4885                	li	a7,1
        assert(PageReserved(p));
ffffffffc0200d1a:	8b85                	andi	a5,a5,1
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d1c:	4809                	li	a6,2
ffffffffc0200d1e:	e789                	bnez	a5,ffffffffc0200d28 <buddy_init_memmap+0x30>
ffffffffc0200d20:	a8c1                	j	ffffffffc0200df0 <buddy_init_memmap+0xf8>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d22:	651c                	ld	a5,8(a0)
ffffffffc0200d24:	8b85                	andi	a5,a5,1
ffffffffc0200d26:	c7e9                	beqz	a5,ffffffffc0200df0 <buddy_init_memmap+0xf8>
        p->flags = 0;
ffffffffc0200d28:	00053423          	sd	zero,8(a0)
        p->property = 1;
ffffffffc0200d2c:	01152823          	sw	a7,16(a0)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d30:	00052023          	sw	zero,0(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200d34:	00850793          	addi	a5,a0,8
ffffffffc0200d38:	4107b02f          	amoor.d	zero,a6,(a5)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200d3c:	629c                	ld	a5,0(a3)
ffffffffc0200d3e:	01850713          	addi	a4,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200d42:	00005317          	auipc	t1,0x5
ffffffffc0200d46:	6ee33b23          	sd	a4,1782(t1) # ffffffffc0206438 <free_area>
ffffffffc0200d4a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200d4c:	f114                	sd	a3,32(a0)
    elm->prev = prev;
ffffffffc0200d4e:	ed1c                	sd	a5,24(a0)
    for (; p != base + n; p++)
ffffffffc0200d50:	02850513          	addi	a0,a0,40
ffffffffc0200d54:	fca617e3          	bne	a2,a0,ffffffffc0200d22 <buddy_init_memmap+0x2a>
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200d58:	0015d793          	srli	a5,a1,0x1
ffffffffc0200d5c:	8fcd                	or	a5,a5,a1
ffffffffc0200d5e:	0027d713          	srli	a4,a5,0x2
ffffffffc0200d62:	8fd9                	or	a5,a5,a4
ffffffffc0200d64:	0047d713          	srli	a4,a5,0x4
ffffffffc0200d68:	8f5d                	or	a4,a4,a5
ffffffffc0200d6a:	00875793          	srli	a5,a4,0x8
    nr_free += n;
ffffffffc0200d6e:	4a90                	lw	a2,16(a3)
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200d70:	00e7e6b3          	or	a3,a5,a4
ffffffffc0200d74:	0106d793          	srli	a5,a3,0x10
    nr_free += n;
ffffffffc0200d78:	0005871b          	sext.w	a4,a1
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200d7c:	8fd5                	or	a5,a5,a3
ffffffffc0200d7e:	8385                	srli	a5,a5,0x1
    nr_free += n;
ffffffffc0200d80:	00e606bb          	addw	a3,a2,a4
ffffffffc0200d84:	00005617          	auipc	a2,0x5
ffffffffc0200d88:	6cd62223          	sw	a3,1732(a2) # ffffffffc0206448 <free_area+0x10>
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200d8c:	8dfd                	and	a1,a1,a5
ffffffffc0200d8e:	e5a1                	bnez	a1,ffffffffc0200dd6 <buddy_init_memmap+0xde>
ffffffffc0200d90:	85ba                	mv	a1,a4
    nr_block = 0; //初始化已分配的块数为0
ffffffffc0200d92:	00005797          	auipc	a5,0x5
ffffffffc0200d96:	6a07af23          	sw	zero,1726(a5) # ffffffffc0206450 <nr_block>
    root[0].size = size;
ffffffffc0200d9a:	00005797          	auipc	a5,0x5
ffffffffc0200d9e:	6ae7af23          	sw	a4,1726(a5) # ffffffffc0206458 <root>
    unsigned node_size = size * 2;
ffffffffc0200da2:	0015961b          	slliw	a2,a1,0x1
    for (int i = 0; i < 2 * size - 1; i++) {
ffffffffc0200da6:	4785                	li	a5,1
ffffffffc0200da8:	02c7d463          	ble	a2,a5,ffffffffc0200dd0 <buddy_init_memmap+0xd8>
ffffffffc0200dac:	00005717          	auipc	a4,0x5
ffffffffc0200db0:	6b070713          	addi	a4,a4,1712 # ffffffffc020645c <root+0x4>
ffffffffc0200db4:	fff6059b          	addiw	a1,a2,-1
ffffffffc0200db8:	4781                	li	a5,0
        if (IS_POWER_OF_2(i + 1))
ffffffffc0200dba:	0017869b          	addiw	a3,a5,1
ffffffffc0200dbe:	8ff5                	and	a5,a5,a3
ffffffffc0200dc0:	e399                	bnez	a5,ffffffffc0200dc6 <buddy_init_memmap+0xce>
            node_size /= 2;
ffffffffc0200dc2:	0016561b          	srliw	a2,a2,0x1
        root[i].longest = node_size;
ffffffffc0200dc6:	c310                	sw	a2,0(a4)
ffffffffc0200dc8:	87b6                	mv	a5,a3
ffffffffc0200dca:	0721                	addi	a4,a4,8
    for (int i = 0; i < 2 * size - 1; i++) {
ffffffffc0200dcc:	fed597e3          	bne	a1,a3,ffffffffc0200dba <buddy_init_memmap+0xc2>
}
ffffffffc0200dd0:	60a2                	ld	ra,8(sp)
ffffffffc0200dd2:	0141                	addi	sp,sp,16
ffffffffc0200dd4:	8082                	ret
    int allocpages = UINT32_ROUND_DOWN(n);
ffffffffc0200dd6:	fff7c793          	not	a5,a5
ffffffffc0200dda:	8ff9                	and	a5,a5,a4
ffffffffc0200ddc:	0007871b          	sext.w	a4,a5
ffffffffc0200de0:	0007059b          	sext.w	a1,a4
ffffffffc0200de4:	b77d                	j	ffffffffc0200d92 <buddy_init_memmap+0x9a>
ffffffffc0200de6:	00005697          	auipc	a3,0x5
ffffffffc0200dea:	65268693          	addi	a3,a3,1618 # ffffffffc0206438 <free_area>
ffffffffc0200dee:	b7ad                	j	ffffffffc0200d58 <buddy_init_memmap+0x60>
        assert(PageReserved(p));
ffffffffc0200df0:	00001697          	auipc	a3,0x1
ffffffffc0200df4:	2d068693          	addi	a3,a3,720 # ffffffffc02020c0 <commands+0x790>
ffffffffc0200df8:	00001617          	auipc	a2,0x1
ffffffffc0200dfc:	18860613          	addi	a2,a2,392 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200e00:	04200593          	li	a1,66
ffffffffc0200e04:	00001517          	auipc	a0,0x1
ffffffffc0200e08:	19450513          	addi	a0,a0,404 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200e0c:	da0ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200e10:	00001697          	auipc	a3,0x1
ffffffffc0200e14:	2c068693          	addi	a3,a3,704 # ffffffffc02020d0 <commands+0x7a0>
ffffffffc0200e18:	00001617          	auipc	a2,0x1
ffffffffc0200e1c:	16860613          	addi	a2,a2,360 # ffffffffc0201f80 <commands+0x650>
ffffffffc0200e20:	03e00593          	li	a1,62
ffffffffc0200e24:	00001517          	auipc	a0,0x1
ffffffffc0200e28:	17450513          	addi	a0,a0,372 # ffffffffc0201f98 <commands+0x668>
ffffffffc0200e2c:	d80ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200e30 <buddy2_alloc>:
int buddy2_alloc(struct buddy2* self, int size) {
ffffffffc0200e30:	882a                	mv	a6,a0
    if (size <= 0) 
ffffffffc0200e32:	4605                	li	a2,1
ffffffffc0200e34:	00b05963          	blez	a1,ffffffffc0200e46 <buddy2_alloc+0x16>
    else if (!IS_POWER_OF_2(size)) //不为2的幂时，取比size大的，最接近的2的n次幂
ffffffffc0200e38:	fff5879b          	addiw	a5,a1,-1
ffffffffc0200e3c:	8fed                	and	a5,a5,a1
ffffffffc0200e3e:	2781                	sext.w	a5,a5
ffffffffc0200e40:	0005861b          	sext.w	a2,a1
ffffffffc0200e44:	ebcd                	bnez	a5,ffffffffc0200ef6 <buddy2_alloc+0xc6>
    if (self[index].longest < size) //可分配内存不足
ffffffffc0200e46:	00482783          	lw	a5,4(a6)
ffffffffc0200e4a:	0ac7e463          	bltu	a5,a2,ffffffffc0200ef2 <buddy2_alloc+0xc2>
    for (node_size = self->size; node_size != size; node_size /= 2) {
ffffffffc0200e4e:	00082503          	lw	a0,0(a6)
ffffffffc0200e52:	0cc50763          	beq	a0,a2,ffffffffc0200f20 <buddy2_alloc+0xf0>
ffffffffc0200e56:	85aa                	mv	a1,a0
    unsigned index = 0;//节点的标号
ffffffffc0200e58:	4781                	li	a5,0
        if (self[LEFT_LEAF(index)].longest >= size)
ffffffffc0200e5a:	0017989b          	slliw	a7,a5,0x1
ffffffffc0200e5e:	0018879b          	addiw	a5,a7,1
ffffffffc0200e62:	02079713          	slli	a4,a5,0x20
ffffffffc0200e66:	8375                	srli	a4,a4,0x1d
ffffffffc0200e68:	9742                	add	a4,a4,a6
ffffffffc0200e6a:	00472303          	lw	t1,4(a4)
ffffffffc0200e6e:	0028869b          	addiw	a3,a7,2
            if (self[RIGHT_LEAF(index)].longest >= size)
ffffffffc0200e72:	02069713          	slli	a4,a3,0x20
ffffffffc0200e76:	8375                	srli	a4,a4,0x1d
ffffffffc0200e78:	9742                	add	a4,a4,a6
        if (self[LEFT_LEAF(index)].longest >= size)
ffffffffc0200e7a:	00c36763          	bltu	t1,a2,ffffffffc0200e88 <buddy2_alloc+0x58>
            if (self[RIGHT_LEAF(index)].longest >= size)
ffffffffc0200e7e:	4358                	lw	a4,4(a4)
ffffffffc0200e80:	00c76763          	bltu	a4,a2,ffffffffc0200e8e <buddy2_alloc+0x5e>
                index = self[LEFT_LEAF(index)].longest <= self[RIGHT_LEAF(index)].longest ? LEFT_LEAF(index) : RIGHT_LEAF(index);            
ffffffffc0200e84:	00677563          	bleu	t1,a4,ffffffffc0200e8e <buddy2_alloc+0x5e>
            index = RIGHT_LEAF(index);
ffffffffc0200e88:	87b6                	mv	a5,a3
        if (self[LEFT_LEAF(index)].longest >= size)
ffffffffc0200e8a:	0038869b          	addiw	a3,a7,3
    for (node_size = self->size; node_size != size; node_size /= 2) {
ffffffffc0200e8e:	0015d59b          	srliw	a1,a1,0x1
ffffffffc0200e92:	fcc594e3          	bne	a1,a2,ffffffffc0200e5a <buddy2_alloc+0x2a>
    offset = (index + 1) * node_size - self->size;
ffffffffc0200e96:	02d586bb          	mulw	a3,a1,a3
    self[index].longest = 0;//标记节点为已使用
ffffffffc0200e9a:	02079713          	slli	a4,a5,0x20
ffffffffc0200e9e:	8375                	srli	a4,a4,0x1d
ffffffffc0200ea0:	9742                	add	a4,a4,a6
ffffffffc0200ea2:	00072223          	sw	zero,4(a4)
    while (index) {
ffffffffc0200ea6:	40a6853b          	subw	a0,a3,a0
ffffffffc0200eaa:	c7a9                	beqz	a5,ffffffffc0200ef4 <buddy2_alloc+0xc4>
        index = PARENT(index);
ffffffffc0200eac:	2785                	addiw	a5,a5,1
ffffffffc0200eae:	0017d61b          	srliw	a2,a5,0x1
ffffffffc0200eb2:	367d                	addiw	a2,a2,-1
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
ffffffffc0200eb4:	0016169b          	slliw	a3,a2,0x1
ffffffffc0200eb8:	ffe7f713          	andi	a4,a5,-2
ffffffffc0200ebc:	2685                	addiw	a3,a3,1
ffffffffc0200ebe:	1682                	slli	a3,a3,0x20
ffffffffc0200ec0:	1702                	slli	a4,a4,0x20
ffffffffc0200ec2:	9281                	srli	a3,a3,0x20
ffffffffc0200ec4:	9301                	srli	a4,a4,0x20
ffffffffc0200ec6:	068e                	slli	a3,a3,0x3
ffffffffc0200ec8:	070e                	slli	a4,a4,0x3
ffffffffc0200eca:	9742                	add	a4,a4,a6
ffffffffc0200ecc:	96c2                	add	a3,a3,a6
ffffffffc0200ece:	434c                	lw	a1,4(a4)
ffffffffc0200ed0:	42d4                	lw	a3,4(a3)
        self[index].longest =
ffffffffc0200ed2:	02061713          	slli	a4,a2,0x20
ffffffffc0200ed6:	8375                	srli	a4,a4,0x1d
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
ffffffffc0200ed8:	0006831b          	sext.w	t1,a3
ffffffffc0200edc:	0005889b          	sext.w	a7,a1
        index = PARENT(index);
ffffffffc0200ee0:	0006079b          	sext.w	a5,a2
        self[index].longest =
ffffffffc0200ee4:	9742                	add	a4,a4,a6
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
ffffffffc0200ee6:	01137363          	bleu	a7,t1,ffffffffc0200eec <buddy2_alloc+0xbc>
ffffffffc0200eea:	86ae                	mv	a3,a1
        self[index].longest =
ffffffffc0200eec:	c354                	sw	a3,4(a4)
    while (index) {
ffffffffc0200eee:	ffdd                	bnez	a5,ffffffffc0200eac <buddy2_alloc+0x7c>
ffffffffc0200ef0:	8082                	ret
        return -1;
ffffffffc0200ef2:	557d                	li	a0,-1
}
ffffffffc0200ef4:	8082                	ret
    size |= size >> 1;
ffffffffc0200ef6:	0016579b          	srliw	a5,a2,0x1
ffffffffc0200efa:	8e5d                	or	a2,a2,a5
ffffffffc0200efc:	2601                	sext.w	a2,a2
    size |= size >> 2;
ffffffffc0200efe:	0026579b          	srliw	a5,a2,0x2
ffffffffc0200f02:	8e5d                	or	a2,a2,a5
ffffffffc0200f04:	2601                	sext.w	a2,a2
    size |= size >> 4;
ffffffffc0200f06:	0046579b          	srliw	a5,a2,0x4
ffffffffc0200f0a:	8e5d                	or	a2,a2,a5
ffffffffc0200f0c:	2601                	sext.w	a2,a2
    size |= size >> 8;
ffffffffc0200f0e:	0086579b          	srliw	a5,a2,0x8
ffffffffc0200f12:	8e5d                	or	a2,a2,a5
ffffffffc0200f14:	2601                	sext.w	a2,a2
    size |= size >> 16;
ffffffffc0200f16:	0106579b          	srliw	a5,a2,0x10
ffffffffc0200f1a:	8e5d                	or	a2,a2,a5
    return size + 1; //得到2的幂次方
ffffffffc0200f1c:	2605                	addiw	a2,a2,1
ffffffffc0200f1e:	b725                	j	ffffffffc0200e46 <buddy2_alloc+0x16>
    self[index].longest = 0;//标记节点为已使用
ffffffffc0200f20:	00082223          	sw	zero,4(a6)
ffffffffc0200f24:	4501                	li	a0,0
ffffffffc0200f26:	8082                	ret

ffffffffc0200f28 <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc0200f28:	7179                	addi	sp,sp,-48
ffffffffc0200f2a:	f406                	sd	ra,40(sp)
ffffffffc0200f2c:	f022                	sd	s0,32(sp)
ffffffffc0200f2e:	ec26                	sd	s1,24(sp)
ffffffffc0200f30:	e84a                	sd	s2,16(sp)
ffffffffc0200f32:	e44e                	sd	s3,8(sp)
    assert(n > 0);
ffffffffc0200f34:	c96d                	beqz	a0,ffffffffc0201026 <buddy_alloc_pages+0xfe>
ffffffffc0200f36:	842a                	mv	s0,a0
    if (n > nr_free)
ffffffffc0200f38:	00005797          	auipc	a5,0x5
ffffffffc0200f3c:	5107e783          	lwu	a5,1296(a5) # ffffffffc0206448 <free_area+0x10>
ffffffffc0200f40:	00005497          	auipc	s1,0x5
ffffffffc0200f44:	4f848493          	addi	s1,s1,1272 # ffffffffc0206438 <free_area>
        return NULL;
ffffffffc0200f48:	4501                	li	a0,0
    if (n > nr_free)
ffffffffc0200f4a:	0c87e563          	bltu	a5,s0,ffffffffc0201014 <buddy_alloc_pages+0xec>
    rec[nr_block].offset = buddy2_alloc(root, n); //记录偏移量
ffffffffc0200f4e:	2401                	sext.w	s0,s0
ffffffffc0200f50:	00005997          	auipc	s3,0x5
ffffffffc0200f54:	50098993          	addi	s3,s3,1280 # ffffffffc0206450 <nr_block>
ffffffffc0200f58:	85a2                	mv	a1,s0
ffffffffc0200f5a:	00005517          	auipc	a0,0x5
ffffffffc0200f5e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0206458 <root>
ffffffffc0200f62:	0009a903          	lw	s2,0(s3)
ffffffffc0200f66:	ecbff0ef          	jal	ra,ffffffffc0200e30 <buddy2_alloc>
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200f6a:	0009a683          	lw	a3,0(s3)
    rec[nr_block].offset = buddy2_alloc(root, n); //记录偏移量
ffffffffc0200f6e:	00191793          	slli	a5,s2,0x1
ffffffffc0200f72:	97ca                	add	a5,a5,s2
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200f74:	00169813          	slli	a6,a3,0x1
    rec[nr_block].offset = buddy2_alloc(root, n); //记录偏移量
ffffffffc0200f78:	000a2597          	auipc	a1,0xa2
ffffffffc0200f7c:	8e058593          	addi	a1,a1,-1824 # ffffffffc02a2858 <rec>
ffffffffc0200f80:	078e                	slli	a5,a5,0x3
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200f82:	00d80733          	add	a4,a6,a3
    rec[nr_block].offset = buddy2_alloc(root, n); //记录偏移量
ffffffffc0200f86:	97ae                	add	a5,a5,a1
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200f88:	070e                	slli	a4,a4,0x3
    rec[nr_block].offset = buddy2_alloc(root, n); //记录偏移量
ffffffffc0200f8a:	c788                	sw	a0,8(a5)
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200f8c:	972e                	add	a4,a4,a1
ffffffffc0200f8e:	4718                	lw	a4,8(a4)
ffffffffc0200f90:	08074963          	bltz	a4,ffffffffc0201022 <buddy_alloc_pages+0xfa>
ffffffffc0200f94:	2705                	addiw	a4,a4,1
ffffffffc0200f96:	4781                	li	a5,0
    list_entry_t* le = &free_list, * len;
ffffffffc0200f98:	8626                	mv	a2,s1
    for (int i = 0; i < rec[nr_block].offset + 1; i++)
ffffffffc0200f9a:	2785                	addiw	a5,a5,1
    return listelm->next;
ffffffffc0200f9c:	6610                	ld	a2,8(a2)
ffffffffc0200f9e:	fee79ee3          	bne	a5,a4,ffffffffc0200f9a <buddy_alloc_pages+0x72>
    size |= size >> 1;
ffffffffc0200fa2:	0014571b          	srliw	a4,s0,0x1
ffffffffc0200fa6:	8f41                	or	a4,a4,s0
ffffffffc0200fa8:	2701                	sext.w	a4,a4
    size |= size >> 2;
ffffffffc0200faa:	0027579b          	srliw	a5,a4,0x2
ffffffffc0200fae:	8f5d                	or	a4,a4,a5
ffffffffc0200fb0:	2701                	sext.w	a4,a4
    size |= size >> 4;
ffffffffc0200fb2:	0047579b          	srliw	a5,a4,0x4
ffffffffc0200fb6:	8f5d                	or	a4,a4,a5
ffffffffc0200fb8:	2701                	sext.w	a4,a4
    size |= size >> 8;
ffffffffc0200fba:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200fbe:	8f5d                	or	a4,a4,a5
ffffffffc0200fc0:	2701                	sext.w	a4,a4
    size |= size >> 16;
ffffffffc0200fc2:	0107579b          	srliw	a5,a4,0x10
ffffffffc0200fc6:	8f5d                	or	a4,a4,a5
    rec[nr_block].base = page;//记录分配块首页
ffffffffc0200fc8:	9836                	add	a6,a6,a3
ffffffffc0200fca:	080e                	slli	a6,a6,0x3
    return size + 1; //得到2的幂次方
ffffffffc0200fcc:	2705                	addiw	a4,a4,1
    rec[nr_block].base = page;//记录分配块首页
ffffffffc0200fce:	95c2                	add	a1,a1,a6
    page = le2page(le, page_link);
ffffffffc0200fd0:	fe860513          	addi	a0,a2,-24
    int allocpages = fixsize(n); //根据需求n得到块大小
ffffffffc0200fd4:	0007081b          	sext.w	a6,a4
    nr_block++;
ffffffffc0200fd8:	2685                	addiw	a3,a3,1
    rec[nr_block].base = page;//记录分配块首页
ffffffffc0200fda:	e188                	sd	a0,0(a1)
    rec[nr_block].nr = allocpages;//记录分配的页数
ffffffffc0200fdc:	0105b823          	sd	a6,16(a1)
    nr_block++;
ffffffffc0200fe0:	00005797          	auipc	a5,0x5
ffffffffc0200fe4:	46d7a823          	sw	a3,1136(a5) # ffffffffc0206450 <nr_block>
    for (int i = 0; i < allocpages; i++)
ffffffffc0200fe8:	01005d63          	blez	a6,ffffffffc0201002 <buddy_alloc_pages+0xda>
ffffffffc0200fec:	87b2                	mv	a5,a2
ffffffffc0200fee:	4681                	li	a3,0
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200ff0:	58f5                	li	a7,-3
ffffffffc0200ff2:	678c                	ld	a1,8(a5)
ffffffffc0200ff4:	17c1                	addi	a5,a5,-16
ffffffffc0200ff6:	6117b02f          	amoand.d	zero,a7,(a5)
ffffffffc0200ffa:	2685                	addiw	a3,a3,1
        le = len;
ffffffffc0200ffc:	87ae                	mv	a5,a1
    for (int i = 0; i < allocpages; i++)
ffffffffc0200ffe:	fed81ae3          	bne	a6,a3,ffffffffc0200ff2 <buddy_alloc_pages+0xca>
    nr_free -= allocpages;//减去已被分配的页数
ffffffffc0201002:	489c                	lw	a5,16(s1)
ffffffffc0201004:	40e7873b          	subw	a4,a5,a4
ffffffffc0201008:	00005797          	auipc	a5,0x5
ffffffffc020100c:	44e7a023          	sw	a4,1088(a5) # ffffffffc0206448 <free_area+0x10>
    page->property = n;
ffffffffc0201010:	fe862c23          	sw	s0,-8(a2)
}
ffffffffc0201014:	70a2                	ld	ra,40(sp)
ffffffffc0201016:	7402                	ld	s0,32(sp)
ffffffffc0201018:	64e2                	ld	s1,24(sp)
ffffffffc020101a:	6942                	ld	s2,16(sp)
ffffffffc020101c:	69a2                	ld	s3,8(sp)
ffffffffc020101e:	6145                	addi	sp,sp,48
ffffffffc0201020:	8082                	ret
    list_entry_t* le = &free_list, * len;
ffffffffc0201022:	8626                	mv	a2,s1
ffffffffc0201024:	bfbd                	j	ffffffffc0200fa2 <buddy_alloc_pages+0x7a>
    assert(n > 0);
ffffffffc0201026:	00001697          	auipc	a3,0x1
ffffffffc020102a:	0aa68693          	addi	a3,a3,170 # ffffffffc02020d0 <commands+0x7a0>
ffffffffc020102e:	00001617          	auipc	a2,0x1
ffffffffc0201032:	f5260613          	addi	a2,a2,-174 # ffffffffc0201f80 <commands+0x650>
ffffffffc0201036:	07500593          	li	a1,117
ffffffffc020103a:	00001517          	auipc	a0,0x1
ffffffffc020103e:	f5e50513          	addi	a0,a0,-162 # ffffffffc0201f98 <commands+0x668>
ffffffffc0201042:	b6aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201046 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201046:	100027f3          	csrr	a5,sstatus
ffffffffc020104a:	8b89                	andi	a5,a5,2
ffffffffc020104c:	eb89                	bnez	a5,ffffffffc020105e <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020104e:	00276797          	auipc	a5,0x276
ffffffffc0201052:	41278793          	addi	a5,a5,1042 # ffffffffc0477460 <pmm_manager>
ffffffffc0201056:	639c                	ld	a5,0(a5)
ffffffffc0201058:	0187b303          	ld	t1,24(a5)
ffffffffc020105c:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc020105e:	1141                	addi	sp,sp,-16
ffffffffc0201060:	e406                	sd	ra,8(sp)
ffffffffc0201062:	e022                	sd	s0,0(sp)
ffffffffc0201064:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201066:	bfeff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020106a:	00276797          	auipc	a5,0x276
ffffffffc020106e:	3f678793          	addi	a5,a5,1014 # ffffffffc0477460 <pmm_manager>
ffffffffc0201072:	639c                	ld	a5,0(a5)
ffffffffc0201074:	8522                	mv	a0,s0
ffffffffc0201076:	6f9c                	ld	a5,24(a5)
ffffffffc0201078:	9782                	jalr	a5
ffffffffc020107a:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020107c:	be2ff0ef          	jal	ra,ffffffffc020045e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201080:	8522                	mv	a0,s0
ffffffffc0201082:	60a2                	ld	ra,8(sp)
ffffffffc0201084:	6402                	ld	s0,0(sp)
ffffffffc0201086:	0141                	addi	sp,sp,16
ffffffffc0201088:	8082                	ret

ffffffffc020108a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020108a:	100027f3          	csrr	a5,sstatus
ffffffffc020108e:	8b89                	andi	a5,a5,2
ffffffffc0201090:	eb89                	bnez	a5,ffffffffc02010a2 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201092:	00276797          	auipc	a5,0x276
ffffffffc0201096:	3ce78793          	addi	a5,a5,974 # ffffffffc0477460 <pmm_manager>
ffffffffc020109a:	639c                	ld	a5,0(a5)
ffffffffc020109c:	0207b303          	ld	t1,32(a5)
ffffffffc02010a0:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc02010a2:	1101                	addi	sp,sp,-32
ffffffffc02010a4:	ec06                	sd	ra,24(sp)
ffffffffc02010a6:	e822                	sd	s0,16(sp)
ffffffffc02010a8:	e426                	sd	s1,8(sp)
ffffffffc02010aa:	842a                	mv	s0,a0
ffffffffc02010ac:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02010ae:	bb6ff0ef          	jal	ra,ffffffffc0200464 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02010b2:	00276797          	auipc	a5,0x276
ffffffffc02010b6:	3ae78793          	addi	a5,a5,942 # ffffffffc0477460 <pmm_manager>
ffffffffc02010ba:	639c                	ld	a5,0(a5)
ffffffffc02010bc:	85a6                	mv	a1,s1
ffffffffc02010be:	8522                	mv	a0,s0
ffffffffc02010c0:	739c                	ld	a5,32(a5)
ffffffffc02010c2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02010c4:	6442                	ld	s0,16(sp)
ffffffffc02010c6:	60e2                	ld	ra,24(sp)
ffffffffc02010c8:	64a2                	ld	s1,8(sp)
ffffffffc02010ca:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02010cc:	b92ff06f          	j	ffffffffc020045e <intr_enable>

ffffffffc02010d0 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc02010d0:	00001797          	auipc	a5,0x1
ffffffffc02010d4:	00878793          	addi	a5,a5,8 # ffffffffc02020d8 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010d8:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02010da:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010dc:	00001517          	auipc	a0,0x1
ffffffffc02010e0:	05c50513          	addi	a0,a0,92 # ffffffffc0202138 <buddy_pmm_manager+0x60>
void pmm_init(void) {
ffffffffc02010e4:	ec06                	sd	ra,24(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc02010e6:	00276717          	auipc	a4,0x276
ffffffffc02010ea:	36f73d23          	sd	a5,890(a4) # ffffffffc0477460 <pmm_manager>
void pmm_init(void) {
ffffffffc02010ee:	e822                	sd	s0,16(sp)
ffffffffc02010f0:	e426                	sd	s1,8(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc02010f2:	00276417          	auipc	s0,0x276
ffffffffc02010f6:	36e40413          	addi	s0,s0,878 # ffffffffc0477460 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010fa:	fbdfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pmm_manager->init();
ffffffffc02010fe:	601c                	ld	a5,0(s0)
ffffffffc0201100:	679c                	ld	a5,8(a5)
ffffffffc0201102:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201104:	57f5                	li	a5,-3
ffffffffc0201106:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201108:	00001517          	auipc	a0,0x1
ffffffffc020110c:	04850513          	addi	a0,a0,72 # ffffffffc0202150 <buddy_pmm_manager+0x78>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201110:	00276717          	auipc	a4,0x276
ffffffffc0201114:	34f73c23          	sd	a5,856(a4) # ffffffffc0477468 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc0201118:	f9ffe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020111c:	46c5                	li	a3,17
ffffffffc020111e:	06ee                	slli	a3,a3,0x1b
ffffffffc0201120:	40100613          	li	a2,1025
ffffffffc0201124:	16fd                	addi	a3,a3,-1
ffffffffc0201126:	0656                	slli	a2,a2,0x15
ffffffffc0201128:	07e005b7          	lui	a1,0x7e00
ffffffffc020112c:	00001517          	auipc	a0,0x1
ffffffffc0201130:	03c50513          	addi	a0,a0,60 # ffffffffc0202168 <buddy_pmm_manager+0x90>
ffffffffc0201134:	f83fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201138:	777d                	lui	a4,0xfffff
ffffffffc020113a:	00277797          	auipc	a5,0x277
ffffffffc020113e:	33d78793          	addi	a5,a5,829 # ffffffffc0478477 <end+0xfff>
ffffffffc0201142:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0201144:	00088737          	lui	a4,0x88
ffffffffc0201148:	00005697          	auipc	a3,0x5
ffffffffc020114c:	2ce6b823          	sd	a4,720(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201150:	4601                	li	a2,0
ffffffffc0201152:	00276717          	auipc	a4,0x276
ffffffffc0201156:	30f73f23          	sd	a5,798(a4) # ffffffffc0477470 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020115a:	4681                	li	a3,0
ffffffffc020115c:	00005897          	auipc	a7,0x5
ffffffffc0201160:	2bc88893          	addi	a7,a7,700 # ffffffffc0206418 <npage>
ffffffffc0201164:	00276597          	auipc	a1,0x276
ffffffffc0201168:	30c58593          	addi	a1,a1,780 # ffffffffc0477470 <pages>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020116c:	4805                	li	a6,1
ffffffffc020116e:	fff80537          	lui	a0,0xfff80
ffffffffc0201172:	a011                	j	ffffffffc0201176 <pmm_init+0xa6>
ffffffffc0201174:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc0201176:	97b2                	add	a5,a5,a2
ffffffffc0201178:	07a1                	addi	a5,a5,8
ffffffffc020117a:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020117e:	0008b703          	ld	a4,0(a7)
ffffffffc0201182:	0685                	addi	a3,a3,1
ffffffffc0201184:	02860613          	addi	a2,a2,40
ffffffffc0201188:	00a707b3          	add	a5,a4,a0
ffffffffc020118c:	fef6e4e3          	bltu	a3,a5,ffffffffc0201174 <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201190:	6190                	ld	a2,0(a1)
ffffffffc0201192:	00271793          	slli	a5,a4,0x2
ffffffffc0201196:	97ba                	add	a5,a5,a4
ffffffffc0201198:	fec006b7          	lui	a3,0xfec00
ffffffffc020119c:	078e                	slli	a5,a5,0x3
ffffffffc020119e:	96b2                	add	a3,a3,a2
ffffffffc02011a0:	96be                	add	a3,a3,a5
ffffffffc02011a2:	c02007b7          	lui	a5,0xc0200
ffffffffc02011a6:	08f6e863          	bltu	a3,a5,ffffffffc0201236 <pmm_init+0x166>
ffffffffc02011aa:	00276497          	auipc	s1,0x276
ffffffffc02011ae:	2be48493          	addi	s1,s1,702 # ffffffffc0477468 <va_pa_offset>
ffffffffc02011b2:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc02011b4:	45c5                	li	a1,17
ffffffffc02011b6:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011b8:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc02011ba:	04b6e963          	bltu	a3,a1,ffffffffc020120c <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02011be:	601c                	ld	a5,0(s0)
ffffffffc02011c0:	63bc                	ld	a5,64(a5)
ffffffffc02011c2:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	03c50513          	addi	a0,a0,60 # ffffffffc0202200 <buddy_pmm_manager+0x128>
ffffffffc02011cc:	eebfe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02011d0:	00004697          	auipc	a3,0x4
ffffffffc02011d4:	e3068693          	addi	a3,a3,-464 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02011d8:	00005797          	auipc	a5,0x5
ffffffffc02011dc:	24d7b423          	sd	a3,584(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011e0:	c02007b7          	lui	a5,0xc0200
ffffffffc02011e4:	06f6e563          	bltu	a3,a5,ffffffffc020124e <pmm_init+0x17e>
ffffffffc02011e8:	609c                	ld	a5,0(s1)
}
ffffffffc02011ea:	6442                	ld	s0,16(sp)
ffffffffc02011ec:	60e2                	ld	ra,24(sp)
ffffffffc02011ee:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011f0:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02011f2:	8e9d                	sub	a3,a3,a5
ffffffffc02011f4:	00276797          	auipc	a5,0x276
ffffffffc02011f8:	26d7b223          	sd	a3,612(a5) # ffffffffc0477458 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011fc:	00001517          	auipc	a0,0x1
ffffffffc0201200:	02450513          	addi	a0,a0,36 # ffffffffc0202220 <buddy_pmm_manager+0x148>
ffffffffc0201204:	8636                	mv	a2,a3
}
ffffffffc0201206:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201208:	eaffe06f          	j	ffffffffc02000b6 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020120c:	6785                	lui	a5,0x1
ffffffffc020120e:	17fd                	addi	a5,a5,-1
ffffffffc0201210:	96be                	add	a3,a3,a5
ffffffffc0201212:	77fd                	lui	a5,0xfffff
ffffffffc0201214:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201216:	00c6d793          	srli	a5,a3,0xc
ffffffffc020121a:	04e7f663          	bleu	a4,a5,ffffffffc0201266 <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc020121e:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201220:	97aa                	add	a5,a5,a0
ffffffffc0201222:	00279513          	slli	a0,a5,0x2
ffffffffc0201226:	953e                	add	a0,a0,a5
ffffffffc0201228:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020122a:	8d95                	sub	a1,a1,a3
ffffffffc020122c:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020122e:	81b1                	srli	a1,a1,0xc
ffffffffc0201230:	9532                	add	a0,a0,a2
ffffffffc0201232:	9782                	jalr	a5
ffffffffc0201234:	b769                	j	ffffffffc02011be <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201236:	00001617          	auipc	a2,0x1
ffffffffc020123a:	f6260613          	addi	a2,a2,-158 # ffffffffc0202198 <buddy_pmm_manager+0xc0>
ffffffffc020123e:	07300593          	li	a1,115
ffffffffc0201242:	00001517          	auipc	a0,0x1
ffffffffc0201246:	f7e50513          	addi	a0,a0,-130 # ffffffffc02021c0 <buddy_pmm_manager+0xe8>
ffffffffc020124a:	962ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020124e:	00001617          	auipc	a2,0x1
ffffffffc0201252:	f4a60613          	addi	a2,a2,-182 # ffffffffc0202198 <buddy_pmm_manager+0xc0>
ffffffffc0201256:	08e00593          	li	a1,142
ffffffffc020125a:	00001517          	auipc	a0,0x1
ffffffffc020125e:	f6650513          	addi	a0,a0,-154 # ffffffffc02021c0 <buddy_pmm_manager+0xe8>
ffffffffc0201262:	94aff0ef          	jal	ra,ffffffffc02003ac <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201266:	00001617          	auipc	a2,0x1
ffffffffc020126a:	f6a60613          	addi	a2,a2,-150 # ffffffffc02021d0 <buddy_pmm_manager+0xf8>
ffffffffc020126e:	06f00593          	li	a1,111
ffffffffc0201272:	00001517          	auipc	a0,0x1
ffffffffc0201276:	f7e50513          	addi	a0,a0,-130 # ffffffffc02021f0 <buddy_pmm_manager+0x118>
ffffffffc020127a:	932ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc020127e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020127e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201282:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201284:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201288:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020128a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020128e:	f022                	sd	s0,32(sp)
ffffffffc0201290:	ec26                	sd	s1,24(sp)
ffffffffc0201292:	e84a                	sd	s2,16(sp)
ffffffffc0201294:	f406                	sd	ra,40(sp)
ffffffffc0201296:	e44e                	sd	s3,8(sp)
ffffffffc0201298:	84aa                	mv	s1,a0
ffffffffc020129a:	892e                	mv	s2,a1
ffffffffc020129c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02012a0:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02012a2:	03067e63          	bleu	a6,a2,ffffffffc02012de <printnum+0x60>
ffffffffc02012a6:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02012a8:	00805763          	blez	s0,ffffffffc02012b6 <printnum+0x38>
ffffffffc02012ac:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02012ae:	85ca                	mv	a1,s2
ffffffffc02012b0:	854e                	mv	a0,s3
ffffffffc02012b2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02012b4:	fc65                	bnez	s0,ffffffffc02012ac <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012b6:	1a02                	slli	s4,s4,0x20
ffffffffc02012b8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02012bc:	00001797          	auipc	a5,0x1
ffffffffc02012c0:	13478793          	addi	a5,a5,308 # ffffffffc02023f0 <error_string+0x38>
ffffffffc02012c4:	9a3e                	add	s4,s4,a5
}
ffffffffc02012c6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012c8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02012cc:	70a2                	ld	ra,40(sp)
ffffffffc02012ce:	69a2                	ld	s3,8(sp)
ffffffffc02012d0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012d2:	85ca                	mv	a1,s2
ffffffffc02012d4:	8326                	mv	t1,s1
}
ffffffffc02012d6:	6942                	ld	s2,16(sp)
ffffffffc02012d8:	64e2                	ld	s1,24(sp)
ffffffffc02012da:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012dc:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02012de:	03065633          	divu	a2,a2,a6
ffffffffc02012e2:	8722                	mv	a4,s0
ffffffffc02012e4:	f9bff0ef          	jal	ra,ffffffffc020127e <printnum>
ffffffffc02012e8:	b7f9                	j	ffffffffc02012b6 <printnum+0x38>

ffffffffc02012ea <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012ea:	7119                	addi	sp,sp,-128
ffffffffc02012ec:	f4a6                	sd	s1,104(sp)
ffffffffc02012ee:	f0ca                	sd	s2,96(sp)
ffffffffc02012f0:	e8d2                	sd	s4,80(sp)
ffffffffc02012f2:	e4d6                	sd	s5,72(sp)
ffffffffc02012f4:	e0da                	sd	s6,64(sp)
ffffffffc02012f6:	fc5e                	sd	s7,56(sp)
ffffffffc02012f8:	f862                	sd	s8,48(sp)
ffffffffc02012fa:	f06a                	sd	s10,32(sp)
ffffffffc02012fc:	fc86                	sd	ra,120(sp)
ffffffffc02012fe:	f8a2                	sd	s0,112(sp)
ffffffffc0201300:	ecce                	sd	s3,88(sp)
ffffffffc0201302:	f466                	sd	s9,40(sp)
ffffffffc0201304:	ec6e                	sd	s11,24(sp)
ffffffffc0201306:	892a                	mv	s2,a0
ffffffffc0201308:	84ae                	mv	s1,a1
ffffffffc020130a:	8d32                	mv	s10,a2
ffffffffc020130c:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020130e:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201310:	00001a17          	auipc	s4,0x1
ffffffffc0201314:	f50a0a13          	addi	s4,s4,-176 # ffffffffc0202260 <buddy_pmm_manager+0x188>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201318:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020131c:	00001c17          	auipc	s8,0x1
ffffffffc0201320:	09cc0c13          	addi	s8,s8,156 # ffffffffc02023b8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201324:	000d4503          	lbu	a0,0(s10)
ffffffffc0201328:	02500793          	li	a5,37
ffffffffc020132c:	001d0413          	addi	s0,s10,1
ffffffffc0201330:	00f50e63          	beq	a0,a5,ffffffffc020134c <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0201334:	c521                	beqz	a0,ffffffffc020137c <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201336:	02500993          	li	s3,37
ffffffffc020133a:	a011                	j	ffffffffc020133e <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc020133c:	c121                	beqz	a0,ffffffffc020137c <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc020133e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201340:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201342:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201344:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201348:	ff351ae3          	bne	a0,s3,ffffffffc020133c <vprintfmt+0x52>
ffffffffc020134c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201350:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201354:	4981                	li	s3,0
ffffffffc0201356:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201358:	5cfd                	li	s9,-1
ffffffffc020135a:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020135c:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201360:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201362:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201366:	0ff6f693          	andi	a3,a3,255
ffffffffc020136a:	00140d13          	addi	s10,s0,1
ffffffffc020136e:	20d5e563          	bltu	a1,a3,ffffffffc0201578 <vprintfmt+0x28e>
ffffffffc0201372:	068a                	slli	a3,a3,0x2
ffffffffc0201374:	96d2                	add	a3,a3,s4
ffffffffc0201376:	4294                	lw	a3,0(a3)
ffffffffc0201378:	96d2                	add	a3,a3,s4
ffffffffc020137a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020137c:	70e6                	ld	ra,120(sp)
ffffffffc020137e:	7446                	ld	s0,112(sp)
ffffffffc0201380:	74a6                	ld	s1,104(sp)
ffffffffc0201382:	7906                	ld	s2,96(sp)
ffffffffc0201384:	69e6                	ld	s3,88(sp)
ffffffffc0201386:	6a46                	ld	s4,80(sp)
ffffffffc0201388:	6aa6                	ld	s5,72(sp)
ffffffffc020138a:	6b06                	ld	s6,64(sp)
ffffffffc020138c:	7be2                	ld	s7,56(sp)
ffffffffc020138e:	7c42                	ld	s8,48(sp)
ffffffffc0201390:	7ca2                	ld	s9,40(sp)
ffffffffc0201392:	7d02                	ld	s10,32(sp)
ffffffffc0201394:	6de2                	ld	s11,24(sp)
ffffffffc0201396:	6109                	addi	sp,sp,128
ffffffffc0201398:	8082                	ret
    if (lflag >= 2) {
ffffffffc020139a:	4705                	li	a4,1
ffffffffc020139c:	008a8593          	addi	a1,s5,8
ffffffffc02013a0:	01074463          	blt	a4,a6,ffffffffc02013a8 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02013a4:	26080363          	beqz	a6,ffffffffc020160a <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02013a8:	000ab603          	ld	a2,0(s5)
ffffffffc02013ac:	46c1                	li	a3,16
ffffffffc02013ae:	8aae                	mv	s5,a1
ffffffffc02013b0:	a06d                	j	ffffffffc020145a <vprintfmt+0x170>
            goto reswitch;
ffffffffc02013b2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02013b6:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013ba:	b765                	j	ffffffffc0201362 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02013bc:	000aa503          	lw	a0,0(s5)
ffffffffc02013c0:	85a6                	mv	a1,s1
ffffffffc02013c2:	0aa1                	addi	s5,s5,8
ffffffffc02013c4:	9902                	jalr	s2
            break;
ffffffffc02013c6:	bfb9                	j	ffffffffc0201324 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013c8:	4705                	li	a4,1
ffffffffc02013ca:	008a8993          	addi	s3,s5,8
ffffffffc02013ce:	01074463          	blt	a4,a6,ffffffffc02013d6 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02013d2:	22080463          	beqz	a6,ffffffffc02015fa <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc02013d6:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02013da:	24044463          	bltz	s0,ffffffffc0201622 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02013de:	8622                	mv	a2,s0
ffffffffc02013e0:	8ace                	mv	s5,s3
ffffffffc02013e2:	46a9                	li	a3,10
ffffffffc02013e4:	a89d                	j	ffffffffc020145a <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02013e6:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013ea:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02013ec:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02013ee:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02013f2:	8fb5                	xor	a5,a5,a3
ffffffffc02013f4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013f8:	1ad74363          	blt	a4,a3,ffffffffc020159e <vprintfmt+0x2b4>
ffffffffc02013fc:	00369793          	slli	a5,a3,0x3
ffffffffc0201400:	97e2                	add	a5,a5,s8
ffffffffc0201402:	639c                	ld	a5,0(a5)
ffffffffc0201404:	18078d63          	beqz	a5,ffffffffc020159e <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201408:	86be                	mv	a3,a5
ffffffffc020140a:	00001617          	auipc	a2,0x1
ffffffffc020140e:	09660613          	addi	a2,a2,150 # ffffffffc02024a0 <error_string+0xe8>
ffffffffc0201412:	85a6                	mv	a1,s1
ffffffffc0201414:	854a                	mv	a0,s2
ffffffffc0201416:	240000ef          	jal	ra,ffffffffc0201656 <printfmt>
ffffffffc020141a:	b729                	j	ffffffffc0201324 <vprintfmt+0x3a>
            lflag ++;
ffffffffc020141c:	00144603          	lbu	a2,1(s0)
ffffffffc0201420:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201422:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201424:	bf3d                	j	ffffffffc0201362 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201426:	4705                	li	a4,1
ffffffffc0201428:	008a8593          	addi	a1,s5,8
ffffffffc020142c:	01074463          	blt	a4,a6,ffffffffc0201434 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201430:	1e080263          	beqz	a6,ffffffffc0201614 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0201434:	000ab603          	ld	a2,0(s5)
ffffffffc0201438:	46a1                	li	a3,8
ffffffffc020143a:	8aae                	mv	s5,a1
ffffffffc020143c:	a839                	j	ffffffffc020145a <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc020143e:	03000513          	li	a0,48
ffffffffc0201442:	85a6                	mv	a1,s1
ffffffffc0201444:	e03e                	sd	a5,0(sp)
ffffffffc0201446:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201448:	85a6                	mv	a1,s1
ffffffffc020144a:	07800513          	li	a0,120
ffffffffc020144e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201450:	0aa1                	addi	s5,s5,8
ffffffffc0201452:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201456:	6782                	ld	a5,0(sp)
ffffffffc0201458:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020145a:	876e                	mv	a4,s11
ffffffffc020145c:	85a6                	mv	a1,s1
ffffffffc020145e:	854a                	mv	a0,s2
ffffffffc0201460:	e1fff0ef          	jal	ra,ffffffffc020127e <printnum>
            break;
ffffffffc0201464:	b5c1                	j	ffffffffc0201324 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201466:	000ab603          	ld	a2,0(s5)
ffffffffc020146a:	0aa1                	addi	s5,s5,8
ffffffffc020146c:	1c060663          	beqz	a2,ffffffffc0201638 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0201470:	00160413          	addi	s0,a2,1
ffffffffc0201474:	17b05c63          	blez	s11,ffffffffc02015ec <vprintfmt+0x302>
ffffffffc0201478:	02d00593          	li	a1,45
ffffffffc020147c:	14b79263          	bne	a5,a1,ffffffffc02015c0 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201480:	00064783          	lbu	a5,0(a2)
ffffffffc0201484:	0007851b          	sext.w	a0,a5
ffffffffc0201488:	c905                	beqz	a0,ffffffffc02014b8 <vprintfmt+0x1ce>
ffffffffc020148a:	000cc563          	bltz	s9,ffffffffc0201494 <vprintfmt+0x1aa>
ffffffffc020148e:	3cfd                	addiw	s9,s9,-1
ffffffffc0201490:	036c8263          	beq	s9,s6,ffffffffc02014b4 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc0201494:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201496:	18098463          	beqz	s3,ffffffffc020161e <vprintfmt+0x334>
ffffffffc020149a:	3781                	addiw	a5,a5,-32
ffffffffc020149c:	18fbf163          	bleu	a5,s7,ffffffffc020161e <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02014a0:	03f00513          	li	a0,63
ffffffffc02014a4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014a6:	0405                	addi	s0,s0,1
ffffffffc02014a8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02014ac:	3dfd                	addiw	s11,s11,-1
ffffffffc02014ae:	0007851b          	sext.w	a0,a5
ffffffffc02014b2:	fd61                	bnez	a0,ffffffffc020148a <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc02014b4:	e7b058e3          	blez	s11,ffffffffc0201324 <vprintfmt+0x3a>
ffffffffc02014b8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014ba:	85a6                	mv	a1,s1
ffffffffc02014bc:	02000513          	li	a0,32
ffffffffc02014c0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014c2:	e60d81e3          	beqz	s11,ffffffffc0201324 <vprintfmt+0x3a>
ffffffffc02014c6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02014c8:	85a6                	mv	a1,s1
ffffffffc02014ca:	02000513          	li	a0,32
ffffffffc02014ce:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02014d0:	fe0d94e3          	bnez	s11,ffffffffc02014b8 <vprintfmt+0x1ce>
ffffffffc02014d4:	bd81                	j	ffffffffc0201324 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02014d6:	4705                	li	a4,1
ffffffffc02014d8:	008a8593          	addi	a1,s5,8
ffffffffc02014dc:	01074463          	blt	a4,a6,ffffffffc02014e4 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc02014e0:	12080063          	beqz	a6,ffffffffc0201600 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02014e4:	000ab603          	ld	a2,0(s5)
ffffffffc02014e8:	46a9                	li	a3,10
ffffffffc02014ea:	8aae                	mv	s5,a1
ffffffffc02014ec:	b7bd                	j	ffffffffc020145a <vprintfmt+0x170>
ffffffffc02014ee:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02014f2:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014f6:	846a                	mv	s0,s10
ffffffffc02014f8:	b5ad                	j	ffffffffc0201362 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02014fa:	85a6                	mv	a1,s1
ffffffffc02014fc:	02500513          	li	a0,37
ffffffffc0201500:	9902                	jalr	s2
            break;
ffffffffc0201502:	b50d                	j	ffffffffc0201324 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0201504:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201508:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020150c:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020150e:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201510:	e40dd9e3          	bgez	s11,ffffffffc0201362 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201514:	8de6                	mv	s11,s9
ffffffffc0201516:	5cfd                	li	s9,-1
ffffffffc0201518:	b5a9                	j	ffffffffc0201362 <vprintfmt+0x78>
            goto reswitch;
ffffffffc020151a:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc020151e:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201522:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201524:	bd3d                	j	ffffffffc0201362 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0201526:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc020152a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020152e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201530:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201534:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201538:	fcd56ce3          	bltu	a0,a3,ffffffffc0201510 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc020153c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020153e:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201542:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201546:	0196873b          	addw	a4,a3,s9
ffffffffc020154a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020154e:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201552:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201556:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020155a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020155e:	fcd57fe3          	bleu	a3,a0,ffffffffc020153c <vprintfmt+0x252>
ffffffffc0201562:	b77d                	j	ffffffffc0201510 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0201564:	fffdc693          	not	a3,s11
ffffffffc0201568:	96fd                	srai	a3,a3,0x3f
ffffffffc020156a:	00ddfdb3          	and	s11,s11,a3
ffffffffc020156e:	00144603          	lbu	a2,1(s0)
ffffffffc0201572:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201574:	846a                	mv	s0,s10
ffffffffc0201576:	b3f5                	j	ffffffffc0201362 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0201578:	85a6                	mv	a1,s1
ffffffffc020157a:	02500513          	li	a0,37
ffffffffc020157e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201580:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201584:	02500793          	li	a5,37
ffffffffc0201588:	8d22                	mv	s10,s0
ffffffffc020158a:	d8f70de3          	beq	a4,a5,ffffffffc0201324 <vprintfmt+0x3a>
ffffffffc020158e:	02500713          	li	a4,37
ffffffffc0201592:	1d7d                	addi	s10,s10,-1
ffffffffc0201594:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201598:	fee79de3          	bne	a5,a4,ffffffffc0201592 <vprintfmt+0x2a8>
ffffffffc020159c:	b361                	j	ffffffffc0201324 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020159e:	00001617          	auipc	a2,0x1
ffffffffc02015a2:	ef260613          	addi	a2,a2,-270 # ffffffffc0202490 <error_string+0xd8>
ffffffffc02015a6:	85a6                	mv	a1,s1
ffffffffc02015a8:	854a                	mv	a0,s2
ffffffffc02015aa:	0ac000ef          	jal	ra,ffffffffc0201656 <printfmt>
ffffffffc02015ae:	bb9d                	j	ffffffffc0201324 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02015b0:	00001617          	auipc	a2,0x1
ffffffffc02015b4:	ed860613          	addi	a2,a2,-296 # ffffffffc0202488 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc02015b8:	00001417          	auipc	s0,0x1
ffffffffc02015bc:	ed140413          	addi	s0,s0,-303 # ffffffffc0202489 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015c0:	8532                	mv	a0,a2
ffffffffc02015c2:	85e6                	mv	a1,s9
ffffffffc02015c4:	e032                	sd	a2,0(sp)
ffffffffc02015c6:	e43e                	sd	a5,8(sp)
ffffffffc02015c8:	1c2000ef          	jal	ra,ffffffffc020178a <strnlen>
ffffffffc02015cc:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02015d0:	6602                	ld	a2,0(sp)
ffffffffc02015d2:	01b05d63          	blez	s11,ffffffffc02015ec <vprintfmt+0x302>
ffffffffc02015d6:	67a2                	ld	a5,8(sp)
ffffffffc02015d8:	2781                	sext.w	a5,a5
ffffffffc02015da:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02015dc:	6522                	ld	a0,8(sp)
ffffffffc02015de:	85a6                	mv	a1,s1
ffffffffc02015e0:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015e2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02015e4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015e6:	6602                	ld	a2,0(sp)
ffffffffc02015e8:	fe0d9ae3          	bnez	s11,ffffffffc02015dc <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015ec:	00064783          	lbu	a5,0(a2)
ffffffffc02015f0:	0007851b          	sext.w	a0,a5
ffffffffc02015f4:	e8051be3          	bnez	a0,ffffffffc020148a <vprintfmt+0x1a0>
ffffffffc02015f8:	b335                	j	ffffffffc0201324 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02015fa:	000aa403          	lw	s0,0(s5)
ffffffffc02015fe:	bbf1                	j	ffffffffc02013da <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201600:	000ae603          	lwu	a2,0(s5)
ffffffffc0201604:	46a9                	li	a3,10
ffffffffc0201606:	8aae                	mv	s5,a1
ffffffffc0201608:	bd89                	j	ffffffffc020145a <vprintfmt+0x170>
ffffffffc020160a:	000ae603          	lwu	a2,0(s5)
ffffffffc020160e:	46c1                	li	a3,16
ffffffffc0201610:	8aae                	mv	s5,a1
ffffffffc0201612:	b5a1                	j	ffffffffc020145a <vprintfmt+0x170>
ffffffffc0201614:	000ae603          	lwu	a2,0(s5)
ffffffffc0201618:	46a1                	li	a3,8
ffffffffc020161a:	8aae                	mv	s5,a1
ffffffffc020161c:	bd3d                	j	ffffffffc020145a <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc020161e:	9902                	jalr	s2
ffffffffc0201620:	b559                	j	ffffffffc02014a6 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201622:	85a6                	mv	a1,s1
ffffffffc0201624:	02d00513          	li	a0,45
ffffffffc0201628:	e03e                	sd	a5,0(sp)
ffffffffc020162a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020162c:	8ace                	mv	s5,s3
ffffffffc020162e:	40800633          	neg	a2,s0
ffffffffc0201632:	46a9                	li	a3,10
ffffffffc0201634:	6782                	ld	a5,0(sp)
ffffffffc0201636:	b515                	j	ffffffffc020145a <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0201638:	01b05663          	blez	s11,ffffffffc0201644 <vprintfmt+0x35a>
ffffffffc020163c:	02d00693          	li	a3,45
ffffffffc0201640:	f6d798e3          	bne	a5,a3,ffffffffc02015b0 <vprintfmt+0x2c6>
ffffffffc0201644:	00001417          	auipc	s0,0x1
ffffffffc0201648:	e4540413          	addi	s0,s0,-443 # ffffffffc0202489 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020164c:	02800513          	li	a0,40
ffffffffc0201650:	02800793          	li	a5,40
ffffffffc0201654:	bd1d                	j	ffffffffc020148a <vprintfmt+0x1a0>

ffffffffc0201656 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201656:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201658:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020165c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020165e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201660:	ec06                	sd	ra,24(sp)
ffffffffc0201662:	f83a                	sd	a4,48(sp)
ffffffffc0201664:	fc3e                	sd	a5,56(sp)
ffffffffc0201666:	e0c2                	sd	a6,64(sp)
ffffffffc0201668:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020166a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020166c:	c7fff0ef          	jal	ra,ffffffffc02012ea <vprintfmt>
}
ffffffffc0201670:	60e2                	ld	ra,24(sp)
ffffffffc0201672:	6161                	addi	sp,sp,80
ffffffffc0201674:	8082                	ret

ffffffffc0201676 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201676:	715d                	addi	sp,sp,-80
ffffffffc0201678:	e486                	sd	ra,72(sp)
ffffffffc020167a:	e0a2                	sd	s0,64(sp)
ffffffffc020167c:	fc26                	sd	s1,56(sp)
ffffffffc020167e:	f84a                	sd	s2,48(sp)
ffffffffc0201680:	f44e                	sd	s3,40(sp)
ffffffffc0201682:	f052                	sd	s4,32(sp)
ffffffffc0201684:	ec56                	sd	s5,24(sp)
ffffffffc0201686:	e85a                	sd	s6,16(sp)
ffffffffc0201688:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc020168a:	c901                	beqz	a0,ffffffffc020169a <readline+0x24>
        cprintf("%s", prompt);
ffffffffc020168c:	85aa                	mv	a1,a0
ffffffffc020168e:	00001517          	auipc	a0,0x1
ffffffffc0201692:	e1250513          	addi	a0,a0,-494 # ffffffffc02024a0 <error_string+0xe8>
ffffffffc0201696:	a21fe0ef          	jal	ra,ffffffffc02000b6 <cprintf>
readline(const char *prompt) {
ffffffffc020169a:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020169c:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020169e:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02016a0:	4aa9                	li	s5,10
ffffffffc02016a2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02016a4:	00005b97          	auipc	s7,0x5
ffffffffc02016a8:	96cb8b93          	addi	s7,s7,-1684 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016ac:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02016b0:	a7ffe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02016b4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02016b6:	00054b63          	bltz	a0,ffffffffc02016cc <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016ba:	00a95b63          	ble	a0,s2,ffffffffc02016d0 <readline+0x5a>
ffffffffc02016be:	029a5463          	ble	s1,s4,ffffffffc02016e6 <readline+0x70>
        c = getchar();
ffffffffc02016c2:	a6dfe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02016c6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02016c8:	fe0559e3          	bgez	a0,ffffffffc02016ba <readline+0x44>
            return NULL;
ffffffffc02016cc:	4501                	li	a0,0
ffffffffc02016ce:	a099                	j	ffffffffc0201714 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02016d0:	03341463          	bne	s0,s3,ffffffffc02016f8 <readline+0x82>
ffffffffc02016d4:	e8b9                	bnez	s1,ffffffffc020172a <readline+0xb4>
        c = getchar();
ffffffffc02016d6:	a59fe0ef          	jal	ra,ffffffffc020012e <getchar>
ffffffffc02016da:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02016dc:	fe0548e3          	bltz	a0,ffffffffc02016cc <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02016e0:	fea958e3          	ble	a0,s2,ffffffffc02016d0 <readline+0x5a>
ffffffffc02016e4:	4481                	li	s1,0
            cputchar(c);
ffffffffc02016e6:	8522                	mv	a0,s0
ffffffffc02016e8:	a03fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i ++] = c;
ffffffffc02016ec:	009b87b3          	add	a5,s7,s1
ffffffffc02016f0:	00878023          	sb	s0,0(a5)
ffffffffc02016f4:	2485                	addiw	s1,s1,1
ffffffffc02016f6:	bf6d                	j	ffffffffc02016b0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc02016f8:	01540463          	beq	s0,s5,ffffffffc0201700 <readline+0x8a>
ffffffffc02016fc:	fb641ae3          	bne	s0,s6,ffffffffc02016b0 <readline+0x3a>
            cputchar(c);
ffffffffc0201700:	8522                	mv	a0,s0
ffffffffc0201702:	9e9fe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            buf[i] = '\0';
ffffffffc0201706:	00005517          	auipc	a0,0x5
ffffffffc020170a:	90a50513          	addi	a0,a0,-1782 # ffffffffc0206010 <edata>
ffffffffc020170e:	94aa                	add	s1,s1,a0
ffffffffc0201710:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201714:	60a6                	ld	ra,72(sp)
ffffffffc0201716:	6406                	ld	s0,64(sp)
ffffffffc0201718:	74e2                	ld	s1,56(sp)
ffffffffc020171a:	7942                	ld	s2,48(sp)
ffffffffc020171c:	79a2                	ld	s3,40(sp)
ffffffffc020171e:	7a02                	ld	s4,32(sp)
ffffffffc0201720:	6ae2                	ld	s5,24(sp)
ffffffffc0201722:	6b42                	ld	s6,16(sp)
ffffffffc0201724:	6ba2                	ld	s7,8(sp)
ffffffffc0201726:	6161                	addi	sp,sp,80
ffffffffc0201728:	8082                	ret
            cputchar(c);
ffffffffc020172a:	4521                	li	a0,8
ffffffffc020172c:	9bffe0ef          	jal	ra,ffffffffc02000ea <cputchar>
            i --;
ffffffffc0201730:	34fd                	addiw	s1,s1,-1
ffffffffc0201732:	bfbd                	j	ffffffffc02016b0 <readline+0x3a>

ffffffffc0201734 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201734:	00005797          	auipc	a5,0x5
ffffffffc0201738:	8d478793          	addi	a5,a5,-1836 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc020173c:	6398                	ld	a4,0(a5)
ffffffffc020173e:	4781                	li	a5,0
ffffffffc0201740:	88ba                	mv	a7,a4
ffffffffc0201742:	852a                	mv	a0,a0
ffffffffc0201744:	85be                	mv	a1,a5
ffffffffc0201746:	863e                	mv	a2,a5
ffffffffc0201748:	00000073          	ecall
ffffffffc020174c:	87aa                	mv	a5,a0
}
ffffffffc020174e:	8082                	ret

ffffffffc0201750 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201750:	00005797          	auipc	a5,0x5
ffffffffc0201754:	cd878793          	addi	a5,a5,-808 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201758:	6398                	ld	a4,0(a5)
ffffffffc020175a:	4781                	li	a5,0
ffffffffc020175c:	88ba                	mv	a7,a4
ffffffffc020175e:	852a                	mv	a0,a0
ffffffffc0201760:	85be                	mv	a1,a5
ffffffffc0201762:	863e                	mv	a2,a5
ffffffffc0201764:	00000073          	ecall
ffffffffc0201768:	87aa                	mv	a5,a0
}
ffffffffc020176a:	8082                	ret

ffffffffc020176c <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc020176c:	00005797          	auipc	a5,0x5
ffffffffc0201770:	89478793          	addi	a5,a5,-1900 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201774:	639c                	ld	a5,0(a5)
ffffffffc0201776:	4501                	li	a0,0
ffffffffc0201778:	88be                	mv	a7,a5
ffffffffc020177a:	852a                	mv	a0,a0
ffffffffc020177c:	85aa                	mv	a1,a0
ffffffffc020177e:	862a                	mv	a2,a0
ffffffffc0201780:	00000073          	ecall
ffffffffc0201784:	852a                	mv	a0,a0
ffffffffc0201786:	2501                	sext.w	a0,a0
ffffffffc0201788:	8082                	ret

ffffffffc020178a <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc020178a:	c185                	beqz	a1,ffffffffc02017aa <strnlen+0x20>
ffffffffc020178c:	00054783          	lbu	a5,0(a0)
ffffffffc0201790:	cf89                	beqz	a5,ffffffffc02017aa <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201792:	4781                	li	a5,0
ffffffffc0201794:	a021                	j	ffffffffc020179c <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201796:	00074703          	lbu	a4,0(a4)
ffffffffc020179a:	c711                	beqz	a4,ffffffffc02017a6 <strnlen+0x1c>
        cnt ++;
ffffffffc020179c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020179e:	00f50733          	add	a4,a0,a5
ffffffffc02017a2:	fef59ae3          	bne	a1,a5,ffffffffc0201796 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02017a6:	853e                	mv	a0,a5
ffffffffc02017a8:	8082                	ret
    size_t cnt = 0;
ffffffffc02017aa:	4781                	li	a5,0
}
ffffffffc02017ac:	853e                	mv	a0,a5
ffffffffc02017ae:	8082                	ret

ffffffffc02017b0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017b0:	00054783          	lbu	a5,0(a0)
ffffffffc02017b4:	0005c703          	lbu	a4,0(a1)
ffffffffc02017b8:	cb91                	beqz	a5,ffffffffc02017cc <strcmp+0x1c>
ffffffffc02017ba:	00e79c63          	bne	a5,a4,ffffffffc02017d2 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02017be:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017c0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02017c4:	0585                	addi	a1,a1,1
ffffffffc02017c6:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02017ca:	fbe5                	bnez	a5,ffffffffc02017ba <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02017cc:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02017ce:	9d19                	subw	a0,a0,a4
ffffffffc02017d0:	8082                	ret
ffffffffc02017d2:	0007851b          	sext.w	a0,a5
ffffffffc02017d6:	9d19                	subw	a0,a0,a4
ffffffffc02017d8:	8082                	ret

ffffffffc02017da <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02017da:	00054783          	lbu	a5,0(a0)
ffffffffc02017de:	cb91                	beqz	a5,ffffffffc02017f2 <strchr+0x18>
        if (*s == c) {
ffffffffc02017e0:	00b79563          	bne	a5,a1,ffffffffc02017ea <strchr+0x10>
ffffffffc02017e4:	a809                	j	ffffffffc02017f6 <strchr+0x1c>
ffffffffc02017e6:	00b78763          	beq	a5,a1,ffffffffc02017f4 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02017ea:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02017ec:	00054783          	lbu	a5,0(a0)
ffffffffc02017f0:	fbfd                	bnez	a5,ffffffffc02017e6 <strchr+0xc>
    }
    return NULL;
ffffffffc02017f2:	4501                	li	a0,0
}
ffffffffc02017f4:	8082                	ret
ffffffffc02017f6:	8082                	ret

ffffffffc02017f8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02017f8:	ca01                	beqz	a2,ffffffffc0201808 <memset+0x10>
ffffffffc02017fa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02017fc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02017fe:	0785                	addi	a5,a5,1
ffffffffc0201800:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201804:	fec79de3          	bne	a5,a2,ffffffffc02017fe <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201808:	8082                	ret
