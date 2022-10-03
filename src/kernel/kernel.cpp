#include "terminal.cpp"

#if defined(__linux__)
#error "This needs to be compiled with a cross-compiler"
#endif
#if !defined(__i386__)
#error "This needs to be compiled with a ix86-elf compiler"
#endif

extern "C"
{
	/**
	 * 核心入口
	 */
	void kernel_main(void)
	{
		terminal::terminal_initialize();

		terminal::terminal_write_string("Hello, kernel World!\n");

		terminal::terminal_write_string("test print number");
		terminal::terminal_write_int(-12345);
		terminal::terminal_write_string("\n");
	}
}