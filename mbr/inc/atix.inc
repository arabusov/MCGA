%ifndef ATIX_INC
    %include "fat12.inc"
    %define ATIX_INC
    %define SCRSEG      0xb800
    %define SCRNRW      25
    %define SCRNCL      80

    %define ATIX_NSEC    32

    %define ATIX_SEG    0x0040
    %define ATIX_OFFSET 0x0100

    %define ATIX_STACK_OFFSET 0xfffd

;-----------------------------------------------;
;               PROTECTED MODE STUFF            ;
;-----------------------------------------------;

    %define PM_BIT  1
    ; descriptor macro args: base low 16 bits,
    ; base high 8 bits, limit 16 bits,
    ; and the access rights byte
    %macro DESCRIPTOR 4
            dw      %3
            dw      %1
            db      %2
            db      %4
            dw      0 ; reserved
    %endmacro

    %define DESC_SIZE 2+2+1+1+2

    %define PRESENT 0x80
    %define SEGMENT_DESCRIPTOR 0x10
    %define EXECUTABLE  0x08
    %define NON_EXECUTABLE_MASK 0xf7
    %define RW_BIT  0x02
    %define PRIVELEGES (x) (x % 4)*32
    %define ACCESSED 0x01
    %define CONFORMING 0x04
    %define EXPAND_DOWN 0x04
    %define EXPAND_UP_MASK 0xfb
    
    %define CODE_ACC_BYTE PRESENT | SEGMENT_DESCRIPTOR | EXECUTABLE | \
        CONFORMING | RW_BIT | ACCESSED
    %define DATA_ACC_BYTE PRESENT | SEGMENT_DESCRIPTOR |      0     | \
            0      | RW_BIT | ACCESSED
    %define STACK_ACC_BYTE PRESENT| SEGMENT_DESCRIPTOR |      0     | \
       EXPAND_DOWN | RW_BIT | ACCESSED

    %define ATIX_CODE_BASE ATIX_SEG*0x10+ATIX_OFFSET
    %define ATIX_STACK_BASE ATIX_SEG*0x10+ATIX_STACK_OFFSET
%endif
