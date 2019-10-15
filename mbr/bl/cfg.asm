%include "cfg.inc"
%include "fat12.inc"
config_start:

        db  "address = 0050:0000", EOL
        db  "kernel  = ATIX.COM", EOL
        db  EOF
config_size equ $-config_start
        times   CFG_NSEC*NBYTEPSEC -  config_size db 0
