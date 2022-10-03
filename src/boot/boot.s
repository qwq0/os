/*
    声明多引导标头的常量
    Declare constants for the multiboot header.
*/
.set ALIGN,    1<<0             /* 在页面边界对齐加载的模块 align loaded modules on page boundaries */
.set MEMINFO,  1<<1             /* 提供内存映射 provide memory map */
.set FLAGS,    ALIGN | MEMINFO  /* 这是 Multiboot 'flag' 字段 this is the Multiboot 'flag' field */
.set MAGIC,    0x1BADB002       /* 'magic number' 让引导加载程序找到头 'magic number' lets bootloader find the header */
.set CHECKSUM, -(MAGIC + FLAGS) /* 上面的校验和，证明我们是多重引导 checksum of above, to prove we are multiboot */
 
/* 
    声明一个将程序标记为内核的多重引导标头。这些是魔术
    多引导标准中记录的值。引导加载程序将
    在内核文件的前 8 KiB 中搜索此签名，对齐在
    32 位边界。签名位于其自己的部分中，因此标题可以是
    强制在内核文件的前 8 KiB 内。
    Declare a multiboot header that marks the program as a kernel. These are magic
    values that are documented in the multiboot standard. The bootloader will
    search for this signature in the first 8 KiB of the kernel file, aligned at a
    32-bit boundary. The signature is in its own section so the header can be
    forced to be within the first 8 KiB of the kernel file.
*/
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM
 
/*
    多重引导标准没有定义堆栈指针寄存器的值
    (esp) 并由内核提供堆栈。这为一个
    通过在其底部创建一个符号，然后分配 16384
    字节，最后在顶部创建一个符号。堆栈增长
    在 x86 上向下。堆栈位于其自己的部分中，因此可以标记为 nobits，
    这意味着内核文件更小，因为它不包含
    未初始化的堆栈。 x86 上的堆栈必须按照 16 字节对齐
    System V ABI 标准和事实上的扩展。编译器将假定
    堆栈正确对齐，未能对齐堆栈将导致
    未定义的行为。
    The multiboot standard does not define the value of the stack pointer register
    (esp) and it is up to the kernel to provide a stack. This allocates room for a
    small stack by creating a symbol at the bottom of it, then allocating 16384
    bytes for it, and finally creating a symbol at the top. The stack grows
    downwards on x86. The stack is in its own section so it can be marked nobits,
    which means the kernel file is smaller because it does not contain an
    uninitialized stack. The stack on x86 must be 16-byte aligned according to the
    System V ABI standard and de-facto extensions. The compiler will assume the
    stack is properly aligned and failure to align the stack will result in
    undefined behavior.
*/
.section .bss
.align 16
stack_bottom:
.skip 2 * 1024 * 1024 /* 2MB 栈空间 */
stack_top:
 
/*
    链接描述文件指定 _start 作为内核的入口点，
    加载内核后，引导加载程序将跳转到该位置。它
    由于引导加载程序消失了，因此从此函数返回没有意义。
    The linker script specifies _start as the entry point to the kernel and the
    bootloader will jump to this position once the kernel has been loaded. It
    doesn't make sense to return from this function as the bootloader is gone.
*/
.section .text
.global _start
.type _start, @function
_start:
	/*
        引导加载程序已将我们加载到 x86 上的 32 位保护模式
        机器。中断被禁用。分页被禁用。处理器
        状态如多重引导标准中所定义。内核已完全
        CPU的控制。内核只能利用硬件特性
        以及它作为自身一部分提供的任何代码。没有 printf
        函数，除非内核提供自己的 <stdio.h> 头文件和
        printf 实现。没有安全限制，没有
        安全措施，没有调试机制，只有内核提供的
        本身。它拥有绝对和完全的权力
        机器。
        The bootloader has loaded us into 32-bit protected mode on a x86
        machine. Interrupts are disabled. Paging is disabled. The processor
        state is as defined in the multiboot standard. The kernel has full
        control of the CPU. The kernel can only make use of hardware features
        and any code it provides as part of itself. There's no printf
        function, unless the kernel provides its own <stdio.h> header and a
        printf implementation. There are no security restrictions, no
        safeguards, no debugging mechanisms, only what the kernel provides
        itself. It has absolute and complete power over the
        machine.
	*/
 
	/*
        要设置堆栈，我们将 esp 寄存器设置为指向堆栈的顶部
        堆栈（因为它在 x86 系统上向下增长）。这是必须做的
        在汇编中，像 C 这样的语言在没有堆栈的情况下无法运行。
        To set up a stack, we set the esp register to point to the top of the
        stack (as it grows downwards on x86 systems). This is necessarily done
        in assembly as languages such as C cannot function without a stack.
	*/
	mov $stack_top, %esp
 
	/*
        这是在启动之前初始化关键处理器状态的好地方
        进入高级内核。最好尽量减少早期
        关键功能离线的环境。请注意，
        处理器尚未完全初始化：浮动等功能
        点指令和指令集扩展未初始化
        然而。 GDT 应该在这里加载。应在此处启用分页。
        全局构造函数和异常等 C++ 特性将需要
        运行时支持也能正常工作。
        This is a good place to initialize crucial processor state before the
        high-level kernel is entered. It's best to minimize the early
        environment where crucial features are offline. Note that the
        processor is not fully initialized yet: Features such as floating
        point instructions and instruction set extensions are not initialized
        yet. The GDT should be loaded here. Paging should be enabled here.
        C++ features such as global constructors and exceptions will require
        runtime support to work as well.
	*/
 
	/*
        进入高级内核。 ABI 要求堆栈为 16 字节
        在调用指令时对齐（随后推送
        大小为 4 字节的返回指针）。堆栈最初是 16 字节
        上面对齐，我们已经将 16 个字节的倍数推送到
        堆栈以来（到目前为止已推送 0 个字节），因此对齐已
        保留并且调用定义明确。
        Enter the high-level kernel. The ABI requires the stack is 16-byte
        aligned at the time of the call instruction (which afterwards pushes
        the return pointer of size 4 bytes). The stack was originally 16-byte
        aligned above and we've pushed a multiple of 16 bytes to the
        stack since (pushed 0 bytes so far), so the alignment has thus been
        preserved and the call is well defined.
	*/
	call kernel_main
 
	/*
        如果系统无事可做，请将计算机放入
        无限循环。要做到这一点：
        1) 使用 cli 禁用中断（在 eflags 中清除中断启用）。
        它们已被引导加载程序禁用，因此不需要。
        请注意，您以后可能会启用中断并从
        kernel_main （这有点荒谬）。
        2) 用hlt（停止指令）等待下一个中断到来。
        由于它们被禁用，这将锁定计算机。
        3) 如果 hlt 指令由于
        不可屏蔽中断发生或由于系统管理模式。
        If the system has nothing more to do, put the computer into an
        infinite loop. To do that:
        1) Disable interrupts with cli (clear interrupt enable in eflags).
        They are already disabled by the bootloader, so this is not needed.
        Mind that you might later enable interrupts and return from
        kernel_main (which is sort of nonsensical to do).
        2) Wait for the next interrupt to arrive with hlt (halt instruction).
        Since they are disabled, this will lock up the computer.
        3) Jump to the hlt instruction if it ever wakes up due to a
        non-maskable interrupt occurring or due to system management mode.
	*/
	cli
1:	hlt
	jmp 1b
 
/*
    将 _start 符号的大小设置为 当前位置'.' 减去它的开始。
    这在调试或实现调用跟踪时很有用。
    Set the size of the _start symbol to the current location '.' minus its start.
    This is useful when debugging or when you implement call tracing.
*/
.size _start, . - _start
