%include "fat12.inc"
%include "bl.inc"
%include "cfg.inc"
%define     NBLCLU  BLNSEC/NSECPCLU 
%define     NCFGCLU CFG_NSEC/NSECPCLU
%define     CFG_1CLU    NBLCLU+2
%macro  MAKE_FILE_BASE 4
%if (%3+%4) % 2 == 0
    %assign i %2+1
%elif
    %assign i %2+2
%endif
%rep    (%1-1)/2
        db      i % 0x100
        db      ((i+1) % 0x10)*0x10 + (i/0x100)
        db      (i+1) / 0x10
%assign i i+2
%endrep
%endmacro
%macro  MAKE_FILE_TAIL 4
%if %1 + %2 % 2 == 0
        db  (%1+%2-1) % 0x100
        db  (%1+%2-1)/0x100 + 0xf0
        db  0xff
%else
        db  0xff, 0x0f+((%4+1) % 0x10)*0x10, ((%4+1) / 0x10)
%endif
%endmacro
;FAT12 macro
%macro      MAKE_FAT12 1
fat%1:       db      FAT_ID, 0xff, 0xff
            ; How to create two files:
            ;MAKE_FILE_BASE NBLCLU, 2, 0, 0
            ;MAKE_FILE_TAIL NBLCLU, 2, 0, 0x851
            ;MAKE_FILE_BASE 10, 0x851, NBLCLU, 2
            ;MAKE_FILE_TAIL 10, 0x851, 0, -1
            MAKE_FILE_BASE NBLCLU, 2, 0, 0
            MAKE_FILE_TAIL NBLCLU, 2, NCFGCLU, CFG_1CLU
            MAKE_FILE_BASE NCFGCLU, CFG_1CLU, NBLCLU, 2
            MAKE_FILE_TAIL NCFGCLU, CFG_1CLU, 0, -1
actual_fat_size equ $ - fat%1
        times   NBYTEPSEC*FATSIZE-actual_fat_size db 0
%endmacro

        MAKE_FAT12 1
        MAKE_FAT12 2
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
        db  0xff, 0xff; rights
        db  0xa*0x8, 0x0 ; 12h last modified time
        db  0x27*2+1, 0x2 ; last modified date
        dw  0x0002  ; first cluster
        dd  BLNSEC*NBYTEPSEC ; BL size in bytes

        db  "CONFIG  "
        db  "INI"
        db  0x5 ; read only, hidden and system
        db  0   ; reserved
        db  199 ; create time for dos 7.0
        db  0xa*0x8, 0x0 ; 12h
        db  0x27*2+1, 0x2 ; create date
        db  0x27*2+1, 0x2 ; last access date
        db  0xff, 0xff; rights
        db  0xa*0x8, 0x0 ; 12h last modified time
        db  0x27*2+1, 0x2 ; last modified date
        dw  CFG_1CLU  ; first cluster
        dd  CFG_NSEC*NBYTEPSEC ; BL size in bytes
actual_dir_size equ $ - dir
        times   NBYTEPSEC*ROOTSIZE-actual_dir_size db 0
; reserved cluster
        times   NBYTEPSEC*NSECPCLU db 0
