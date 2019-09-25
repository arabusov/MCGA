

build:
	nasm -f bin mbr.asm -o mbr.bin

run: build
	qemu-system-i386 -fda mbr.bin

clean:
	rm mbr.bin
