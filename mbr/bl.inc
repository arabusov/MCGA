%ifndef BL_INC
    %define BL_INC
    ; boot loader ip
    %define BLIP    0x0100      
    ; boot loader cs
    %define BLCS    0x0100     
    ; maximum 3 sectors (512 bytes each)
    %define BLNSEC  0x03       
%endif
