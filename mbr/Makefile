floppy_type=360
diskette=fda${floppy_type}.img
INCLUDE=inc
AS=nasm
CAT=cat
AFLAGS=-f bin -dFLOPPY_TYPE=${floppy_type} -I${INCLUDE}
OBJ_DIR=obj
KRN_SRC=kernel
BL_SRC=bl
OBJ=$(patsubst $(BL_SRC)/%.asm,$(OBJ_DIR)/%.bin, $(wildcard $(BL_SRC)/*.asm))
OBJ+=$(patsubst $(KRN_SRC)/%.asm,$(OBJ_DIR)/%.bin, $(wildcard $(KRN_SRC)/*.asm))

all: build
	@echo Done.


build: $(OBJ)
	$(CAT) $(OBJ_DIR)/mbr.bin > ${diskette}
	$(CAT) $(OBJ_DIR)/fat12.bin >> ${diskette}
	$(CAT) $(OBJ_DIR)/bl.bin >> ${diskette}
	$(CAT) $(OBJ_DIR)/cfg.bin >> ${diskette}
	$(CAT) $(OBJ_DIR)/atix.bin >> ${diskette}
	$(CAT) $(OBJ_DIR)/floppy.bin >> ${diskette}


$(OBJ_DIR)/%.bin : $(KRN_SRC)/%.asm $(OBJ_DIR)
	${AS} ${AFLAGS} $< -o $@

$(OBJ_DIR)/%.bin : $(BL_SRC)/%.asm $(OBJ_DIR)
	${AS} ${AFLAGS} $< -o $@

$(OBJ_DIR):
	mkdir -p ${OBJ_DIR}
fda1200:
	make clean
	make build floppy_type=1200
fda360:
	make clean
	make build floppy_type=360
qemu: fda1200
	qemu-system-i386 -drive format=raw,if=floppy,file=fda1200.img
debug: fda1200
	qemu-system-i386 -s -S -drive format=raw,if=floppy,file=fda1200.img
pcem: fda360
	pcem --config config/ibmpc_at_cga.cfg

clean:
	rm -rf ${OBJ_DIR}

cleanall: clean
	rm -rf fda*.img
