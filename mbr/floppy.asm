%include "mbr.inc"
%include "fat12.inc"
%include "bl.inc"
%include "cfg.inc"
%include "floppy.inc"
%define FLOPPY_NSEC FLOPPY_TYPE*1024/NBYTEPSEC 
%define MBRFATBL_NSEC (1+2*FATSIZE+ROOTSIZE+BLNSEC) - CFG_NSEC
%define REMINDER_FLOPPY FLOPPY_NSEC - MBRFATBL_NSEC
%assign i 0
%rep    REMINDER_FLOPPY
        dw      i
        times       NBYTEPSEC - 2 db 0
%assign i i+1
%endrep
