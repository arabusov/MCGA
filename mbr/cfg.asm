%include "cfg.inc"
%include "fat12.inc"
config_start:

        db  "kernel=ATIX.COM", EOL
        db  "address=0040:0100", EOL
        db  EOF
config_size equ $-config_start
        times   CFG_NSEC*NBYTEPSEC -  config_size db 0