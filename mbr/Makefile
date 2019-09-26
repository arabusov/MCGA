
build: mbr bl fat12
	cat mbr.bin > img.bin
	cat fat12.bin >> img.bin
	cat bl.bin >> img.bin

mbr:
	nasm -f bin mbr.asm -o mbr.bin
bl:
	nasm -f bin bl.asm -o bl.bin
fat12:
	nasm -f bin fat12.asm -o fat12.bin

run: build
	qemu-system-i386 -drive format=raw,if=floppy,file=img.bin

clean:
	rm -f *.bin
