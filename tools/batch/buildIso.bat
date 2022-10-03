mkdir .\bin\tmp\isodir\boot\grub
copy .\bin\os.bin .\bin\tmp\isodir\boot\os.bin
copy .\src\grub\grub.cfg .\bin\tmp\isodir\boot\grub\grub.cfg
echo 将bin/isodir/文件夹复制到linux中使用grub构建iso
echo 构建命令 grub-mkrescue -o os.iso isodir