%include "mbr.inc"
%include "fat12.inc"
%include "bl.inc"
%ifndef FLOPPY_TYPE
    %define FLOPPY_TYPE 1200
%endif
        times FLOPPY_TYPE*1024 - NBYTEPSEC*(1+2*FATSIZE+ROOTSIZE+BLNSEC) db 0
