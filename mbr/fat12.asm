%include "fat12.inc"
%include "bl.inc"
;FAT1
fat1:       db      FAT_ID, 0xff, 0xff
actual_fat_size equ $ - fat1
        times   NBYTEPSEC*FATSIZE-actual_fat_size db 0
;FAT2
        times   NBYTEPSEC*FATSIZE db 0
;ROOT dir
        times   NBYTEPSEC*ROOTSIZE db 0
; reserved cluster
        times   NBYTEPSEC*NSECPCLU db 0
