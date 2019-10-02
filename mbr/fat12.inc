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
        %define NSECPTRACK       15
        %define ROOTSIZE    14
        %define NROOTRECS   224
        %define NTOTALSEC   2400
        %define NSECPCLU    1
        %define FATSIZE     7
    %elif FLOPPY_TYPE==1440
        %define FAT_ID 0xf0
        %define NHEADS      2
        %define NCYLS       80
        %define NSECPTRACK       18
        %define ROOTSIZE    14
        %define NROOTRECS   224
        %define NTOTALSEC   2880
        %define NSECPCLU    1
        %define FATSIZE     9
    %elif FLOPPY_TYPE==360
        %define FAT_ID 0xfd
        %define NHEADS      2
        %define NCYLS       40
        %define NSECPTRACK  9
        %define ROOTSIZE    7
        %define NROOTRECS   112
        %define NTOTALSEC   720
        %define NSECPCLU    2
        %define FATSIZE     2
    %endif
    ; fat1 begin
    %define NBYTEPSEC   512
    %define NHIDDSEC    0
    %define NRESSEC     1
    %define NFATCOPYS   2
%endif
