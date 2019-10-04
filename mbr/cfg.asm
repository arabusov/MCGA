%include "cfg.inc"
%include "fat12.inc"
config_start:
%assign i 1
%rep    CFG_NSEC/2 
        dw  i
        times   NBYTEPSEC*NSECPCLU-2 db 0
%assign i i+1
%endrep
