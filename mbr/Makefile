diskette=fda1200.img
build: mbr bl fat12
	cat mbr.bin > ${diskette}
	cat fat12.bin >> ${diskette}
	cat bl.bin >> ${diskette}

mbr:
	nasm -f bin mbr.asm -o mbr.bin
bl:
	nasm -f bin bl.asm -o bl.bin
fat12:
	nasm -f bin fat12.asm -o fat12.bin

run: build
	qemu-system-i386 -drive format=raw,if=floppy,file=${diskette}
pcem: build
	pcem --config ibmpc_at_cga.cfg

clean:
	rm -f *.bin
