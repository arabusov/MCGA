floppy_type=360
diskette=fda${floppy_type}.img

AS=nasm
AFLAGS=-f bin -dFLOPPY_TYPE=${floppy_type}
build: mbr.bin bl.bin fat12.bin cfg.bin atix.com floppy.bin 
	cat mbr.bin > ${diskette}
	cat fat12.bin >> ${diskette}
	cat bl.bin >> ${diskette}
	cat cfg.bin >> ${diskette}
	cat	atix.com >> ${diskette}
	cat floppy.bin >> ${diskette}


%.bin : %.asm
	${AS} ${AFLAGS} $< -o $@

%.com : %.asm
	${AS} ${AFLAGS} $< -o $@

run:
	make clean
	make floppy_type=1200
	qemu-system-i386 -drive format=raw,if=floppy,file=fda1200.img
pcem:
	make clean
	make floppy_type=360
	pcem --config ibmpc_at_cga.cfg

clean:
	rm -f *.bin
	rm -rf *.com
