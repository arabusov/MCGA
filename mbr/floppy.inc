%ifndef FLOPPY_INC
    %define FLOPPY_INC
    %ifndef FLOPPY_TYPE
        %define FLOPPY_TYPE 360
    %endif
    %if FLOPPY_TYPE==1440
        %define MEDIADESC   0xf0
    %elif FLOPPY_TYPE==360
        %define MEDIADESC   0xfd
    %elif FLOPPY_TYPE==1200
        %define MEDIADESC   0xf9
    %endif
%endif
