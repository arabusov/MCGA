%include "fat12.inc"
;FAT1
        times   NBYTEPSEC*FATSIZE db 0
;FAT2
        times   NBYTEPSEC*FATSIZE db 0
;ROOT dir
        times   NBYTEPSEC*ROOTSIZE db 0
