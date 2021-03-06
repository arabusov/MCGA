%ifndef ATIX_INC
    %include "fat12.inc"
    %define ATIX_INC
    %define SCRSEG      0xb800
    %define SCRNRW      25
    %define SCRNCL      80

    %define ATIX_NSEC    32

    %define ATIX_SEG    0x0050
    %define ATIX_OFFSET 0x0000

    %define ATIX_STACK_OFFSET 0xfffd

    %define ATIX_ABS    ATIX_SEG*0x10+ATIX_OFFSET
    %define ATIX_STACK_ABS  ATIX_SEG*0x10+ATIX_STACK_OFFSET

;-----------------------------------------------;
;               PROTECTED MODE STUFF            ;
;-----------------------------------------------;

    %define PM_BIT  1
    ; descriptor macro args: base low 16 bits,
    ; base high 8 bits, limit 16 bits,
    ; and the access rights byte
    %macro DESCRIPTOR 3
            dw      %2
            dw      %1 % 0x10000
            db      %1 / 0x10000
            db      %3
            dw      0 ; reserved
    %endmacro

    DESC_SIZE equ 2+2+1+1+2

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
    %define EXC_GATE 0x7
    %define INT_GATE 0x6
    
    %define CODE_ACC_BYTE PRESENT | SEGMENT_DESCRIPTOR | EXECUTABLE | \
            0      |    0   
    %define DATA_ACC_BYTE PRESENT | SEGMENT_DESCRIPTOR |      0     | \
            0      | RW_BIT
    %define STACK_ACC_BYTE PRESENT| SEGMENT_DESCRIPTOR |      0     | \
       EXPAND_DOWN | RW_BIT 

    %define EXC_ACC_BYTE   PRESENT | EXC_GATE
    %define INT_ACC_BYTE   PRESENT | INT_GATE

    %define TSS_ACC_BYTE PRESENT | ACCESSED

    %define SYS_CALL_GATE_ACC_BYTE PRESENT | 0x64
    %define LDT_ACC_BYTE    PRESENT | 2

    ATIX_CODE_BASE  equ ATIX_SEG*0x10
    ATIX_STACK_BASE equ ATIX_SEG*0x10

    ; Interrupts
    %define IRQ0 0x20
    %define IRQ8 IRQ0+8
%endif
