%ifndef BL_INC
    %define BL_INC
    ; boot loader ip
    %define BLIP    0x0100      
    ; boot loader cs
    %define BLCS    0x0100     
    ; maximum 10 sectors (512 bytes each)
    %define BLNSEC  10
    ; screen memory address
    %define SCRSEG  0xb800
    %define SCRNRW  25
    %define SCRNCL  80
    ; boot loader stack size
    %define BLSTCKSIZE 0x40*4
%endif
