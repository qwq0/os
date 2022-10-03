#pragma once

#include "terminal.cpp"

struct interrupt_frame;
 
__attribute__((interrupt)) void interrupt_handler(struct interrupt_frame* frame)
{
    terminal::terminal_write_string("get_interrupt");
}