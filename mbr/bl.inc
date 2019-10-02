%ifndef BL_INC
    %define BL_INC
    ; boot loader physical addr: 
    ; boot loader size: n sectors
    ; boot loader ip
    ; try to follow the MS-DOS standard of .com
    ; executables.
    %define BLIP    0x0100
    ; boot loader cs
    ; literally  the next floppy sector after
    %define BLCS    0x07c0 + 0x0020 - 0x0010
    ; maximum 10 sectors (512 bytes each)
    %include "fat12.inc"
    %define BLNSEC  10
    %define BLFST   2*FATSIZE+ROOTSIZE+1+NSECPCLU
    %define BLFSTCYL  0
    %define BLFSTHEAD 1
    %define BLFSTSEC  16
    ; screen memory address
    %define SCRSEG  0xb800
    %define SCRNRW  25
    %define SCRNCL  80
    ; boot loader stack size
    %define BLSTCKSIZE 0x40*4
    ; partition entry no. 1 pointer:
    %define PART1PTR 0x1be
    ; first sector of partition 1
    %define PART1CYLSEC 1
    ; first head of the same thing
    %define PART1HEAD   0x00
    ; geometry: 512 bytes x 18 sectors x 80 cylinders x 2 heads
    %define PART1ENDHEAD 0x01
    %define PART1ENDCYLSEC 18+78*256
    %define BL_ERR_CYL_OUT_OF_RANGE 0xca
%endif
