%ifndef MBR_INC
    %define MBR_INC
    ; if BIOS info is not set or maybe
    ; because of another problem sometimes
    ; int 13h ah=08h returns inappropriate
    ; result, such as cx = 0 (and, therefore,
    ; maximum sector number = 0, which is 
    ; impossible). For this MBR must show an
    ; error code, which is defined here:
    %define ERR_BIOS_NOT_SET    0xad
    ; Error code for wrong number of read
    ; sectors.
    %define ERR_NSECREAD        0xbd
    ; If during read a sector above the boundary
    ; requested:
    %define ERR_CYL_OUT_OF_RANGE 0xcd
%endif
