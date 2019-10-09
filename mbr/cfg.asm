%include "cfg.inc"
%include "fat12.inc"
config_start:

        db  "kernel=ATIX.COM", 0x0a
        db  "address=0040:0100", 0x0a, 0x04
config_size equ $-config_start
        times   CFG_NSEC*NBYTEPSEC -  config_size db 0
