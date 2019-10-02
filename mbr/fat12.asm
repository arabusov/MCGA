%include "fat12.inc"
%include "bl.inc"
%define     NBLCLU  BLNSEC/NSECPCLU 
;FAT1
fat1:       db      FAT_ID, 0xff, 0xff
%assign i 3
%rep    (NBLCLU-1)/2
        db      i % 0x100
        db      ((i+1) % 0x10)*0x10 + (i/0x100)
        db      (i+1) / 0x10
%assign i i+2
%endrep
%if NBLCLU % 2 == 0
        db  (NBLCLU+1) % 0x100
        db  (NBLCLU+1)/0x100 + 0xf0
        db  0xff
%else
        db  0xff, 0x0f, 0x00
%endif

actual_fat_size equ $ - fat1
        times   NBYTEPSEC*FATSIZE-actual_fat_size db 0
;FAT2 -- just a copy of FAT1
fat2:       db      FAT_ID, 0xff, 0xff
%assign i 3
%rep    (NBLCLU-1)/2
        db      i % 0x100
        db      ((i+1) % 0x10)*0x10 + (i/0x100)
        db      (i+1) / 0x10
%assign i i+2
%endrep
%if NBLCLU % 2 == 0
        db  (NBLCLU+1) % 0x100
        db  (NBLCLU+1)/0x100 + 0xf0
        db  0xff
%else
        db  0xff, 0x0f, 0x00
%endif

actual_fat2_size equ $ - fat2
        times   NBYTEPSEC*FATSIZE-actual_fat2_size db 0
;ROOT dir
dir:
        db  "BL      "
        db  "COM"
        db  0x5 ; read only, hidden and system
        db  0   ; reserved
        db  199 ; create time for dos 7.0
        db  0xa*0x8, 0x0 ; 12h
        db  0x27*2+1, 0x2 ; create date
        db  0x27*2+1, 0x2 ; last access date
        db  0xff; rights
        db  0xa*0x8, 0x0 ; 12h last modified time
        db  0x27*2+1, 0x2 ; last modified date
        dw  0x0002  ; first cluster
        dd  BLNSEC*NBYTEPSEC ; BL size in bytes
actual_dir_size equ $ - dir
        times   NBYTEPSEC*ROOTSIZE-actual_dir_size db 0
; reserved cluster
        times   NBYTEPSEC*NSECPCLU db 0
