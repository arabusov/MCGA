%include "fat12.inc"
%include "bl.inc"
%include "cfg.inc"
%define     NBLCLU  BLNSEC/NSECPCLU 
%define     NCFGCLU CFG_NSEC/NSECPCLU
%define     CFG_1CLU    NBLCLU+2
%macro  MAKE_FILE_BASE 4
%if %3 >=2

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
        %if %3 >= 2
        db  0xff, 0x0f+((%4+1) % 0x10)*0x10, ((%4+1) / 0x10)
    %elif %3 == 1
        db  0xff, 0xff, 0xff
    %else
        db  0xff, 0x0f, 0x00
    %endif
%endif
%endmacro

%macro  PAIR 2
    db %1 % 0x100, %1 / 0x100 + (%2 % 0x10)*0x10, %2 / 0x10
%endmacro

%macro  MAKE_FILE 1-*
%assign i 1
%assign c 0x002
%assign s 0
%assign o 0
    %rep %0
        %if o == 0
            %assign s s+%[i]
            dw  %(
            %rep ((%[i] - 1)/ 2)
                PAIR (c+1), (c+2)
                %assign c c+2
            %endrep
            %if c == (2 + s - 1)
                %if i <= %0
                    %if %[(i+1)] >= 2
                        PAIR 0xfff, (c+2)
                    %else
                        PAIR 0xfff, 0xfff
                        %assign s s+1
                        %assign o 1
                    %endif
                %else
                    PAIR 0xfff, 0x000
                %endif
            %else 
                PAIR (c+1), 0xfff
            %endif
            %assign c c+2
        %else
            %assign o 0
        %endif
        %assign i i+1
    %endrep
%endmacro
;FAT12 macro
%macro      MAKE_FAT12 1
fat%1:       db      FAT_ID, 0xff, 0xff
%if FLOPPY_TYPE == 360
            db  0x03, 0x40, 0x00, 0x05, 0x60, 0x00,
            db  0xff, 0xff, 0xff
%else
db 0x3
db 0x40
db 0x0
db 0x5
db 0x60
db 0x0
db 0x7
db 0x80
db 0x0
db 0x9
db 0xa0
db 0x0
db 0xb
db 0xf0
db 0xff
db 0xff
db 0xf
%endif
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
