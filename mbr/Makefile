
build: mbr bl
	cat mbr.bin > img.bin
	cat bl.bin >> img.bin

mbr:
	nasm -f bin mbr.asm -o mbr.bin
bl:
	nasm -f bin bl.asm -o bl.bin

run: build
	qemu-system-i386 -drive format=raw,file=img.bin

clean:
	rm -f *.bin
