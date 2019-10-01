%include "floppy.inc"
%ifndef FAT12_INC
    %define FAT12_INC
    %ifndef FLOPPY_TYPE
        %define FLOPPY_TYPE 360
    %endif
    %if FLOPPY_TYPE==1200
        %define FAT_ID 0xf9
        %define NHEADS      2
        %define NCYLS       80
        %define NSECS       15
        %define ROOTSIZE    14
    %elif FLOPPY_TYPE==1440
        %define FAT_ID 0xf0
        %define NHEADS      2
        %define NCYLS       80
        %define NSECS       18
        %define ROOTSIZE    14
    %elif FLOPPY_TYPE==360
        %define FAT_ID 0xfd
        %define NHEADS      2
        %define NCYLS       40
        %define NSECS       9
        %define ROOTSIZE    7
    %endif
    ; fat1 begin
    %define FATSIZE     9
    %define NBYTEPSEC   512
    %define NSECPCLU    1
    %define NHIDDSEC    0
%endif
