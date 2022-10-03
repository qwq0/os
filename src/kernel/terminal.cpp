#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

namespace terminal
{

    /* Hardware text mode color constants. */
    enum vga_color
    {
        VGA_COLOR_BLACK = 0,
        VGA_COLOR_BLUE = 1,
        VGA_COLOR_GREEN = 2,
        VGA_COLOR_CYAN = 3,
        VGA_COLOR_RED = 4,
        VGA_COLOR_MAGENTA = 5,
        VGA_COLOR_BROWN = 6,
        VGA_COLOR_LIGHT_GREY = 7,
        VGA_COLOR_DARK_GREY = 8,
        VGA_COLOR_LIGHT_BLUE = 9,
        VGA_COLOR_LIGHT_GREEN = 10,
        VGA_COLOR_LIGHT_CYAN = 11,
        VGA_COLOR_LIGHT_RED = 12,
        VGA_COLOR_LIGHT_MAGENTA = 13,
        VGA_COLOR_LIGHT_BROWN = 14,
        VGA_COLOR_WHITE = 15,
    };

    /**
     * 获取颜色编码
     * @param fg 字符颜色
     * @param bg 背景颜色
     * @return 颜色编码
     */
    static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg)
    {
        return fg | bg << 4;
    }

    /**
     * 获取显示字符编码
     * @param uc 字符
     * @param color 颜色编码
     * @return 显示字符编码
     */
    static inline uint16_t vga_entry(unsigned char uc, uint8_t color)
    {
        return (uint16_t)uc | (uint16_t)color << 8;
    }

    /**
     * 获取字符串长度
     * @param str 字符串
     * @return 长度
     */
    size_t strlen(const char *str)
    {
        size_t len = 0;
        while (str[len])
            len++;
        return len;
    }

    static const size_t VGA_WIDTH = 80;
    static const size_t VGA_HEIGHT = 25;

    size_t terminal_row;
    size_t terminal_column;
    uint8_t terminal_color;
    uint16_t *terminal_buffer;

    /**
     * 初始化终端
     */
    void terminal_initialize(void)
    {
        terminal_row = 0;
        terminal_column = 0;
        terminal_color = vga_entry_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
        terminal_buffer = (uint16_t *)0xB8000;
        for (size_t y = 0; y < VGA_HEIGHT; y++)
        {
            for (size_t x = 0; x < VGA_WIDTH; x++)
            {
                const size_t index = y * VGA_WIDTH + x;
                terminal_buffer[index] = vga_entry(' ', terminal_color);
            }
        }
    }

    /**
     * 切换打印终端颜色
     * @param color 颜色
     */
    void terminal_setcolor(uint8_t color)
    {
        terminal_color = color;
    }

    /**
     * 打印字符到指定位置
     * @param c 字符
     * @param color 颜色
     * @param x 横坐标
     * @param y 纵坐标
     */
    void terminal_putentryat(char c, uint8_t color, size_t x, size_t y)
    {
        const size_t index = y * VGA_WIDTH + x;
        terminal_buffer[index] = vga_entry(c, color);
    }

    /**
     * 打印单个字符
     * @param c 字符
     */
    void terminal_putchar(char c)
    {
        if (c == '\n')
        {
            terminal_column = 0;
            terminal_row++;
        }
        else
        {
            terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
            terminal_column++;
        }

        if (terminal_column >= VGA_WIDTH)
        {
            terminal_column = 0;
            terminal_row++;
            if (terminal_row >= VGA_HEIGHT)
                terminal_row = 0;
        }
    }

    /**
     * 打印字符串到终端
     * @param data 字符串
     */
    void terminal_write_string(const char *data)
    {
        size_t size = strlen(data);
        for (size_t i = 0; i < size; i++)
            terminal_putchar(data[i]);
    }

    /**
     * 打印字符串到终端
     * @param data 字符串
     */
    void terminal_write_int(int num)
    {
        if (num < 0)
        {
            num = -num;
            terminal_putchar('-');
        }
        char str[21];
        size_t ind = 0;
        while (num)
        {
            str[ind] = (num % 10) + '0';
            ind++;
            num /= 10;
        }
        while (ind)
        {
            ind--;
            terminal_putchar(str[ind]);
        }
    }

}