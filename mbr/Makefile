
build: mbr bl fat12
	cat mbr.bin > fda360.img
	cat fat12.bin >> fda360.img
	cat bl.bin >> fda360.img

mbr:
	nasm -f bin mbr.asm -o mbr.bin
bl:
	nasm -f bin bl.asm -o bl.bin
fat12:
	nasm -f bin fat12.asm -o fat12.bin

run: build
	qemu-system-i386 -drive format=raw,if=floppy,file=fda360.img

clean:
	rm -f *.bin
