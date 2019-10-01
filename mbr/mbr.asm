;----------------------------------------------------------------------------;
;                         Master boot record (MBR)                           ;
;                                                                            ;
;----------------------------------------------------------------------------;

%include "mbr.inc"
%include "bl.inc"
%include "fat12.inc"
%include "floppy.inc"
bits 16                             ; i8086 16-bits REAL mode, actually.
CPU  286
section .text                       ; All code and data are
                                    ; in the single section.
;----------------------------------------------------------------------------;
;                             MBR for FAT 12                                 ;
;                                                                            ;
; BIOS loads first (literally first, CHS = (0, 0, 1) sector to 0000:7c00     ;
; address in memory. The prerequirement is only two magic bytes at the end   ;
; of the sector: 0xaa55. So, our MBR code is at least limited by 510 bytes,  ;
; but there should be also so-called "partition information", despite we are ;
; not going to split our poor diskette to partitions (I'm event not sure how ;
; to fill such fields.                                                       ;
;     Another prerequirement comes from FAT 12 descrition. Guys from         ;
; Microsoft thought, that they were clever and used the boot sector for      ;
; some almost useless stuff for the boot sector, which limits the MBR code   ;
; even worse, than MBR partition standard. Roughly speaking, we have only    ;
; a few hundreds of bytes to read the real bootloader into a new memory      ;
; address and then jump to that code.                                        ;
;     I suggest, that the real bootloader is the first FAT 12 file, placed   ;
; without fragmentation just after the ROOT directory of the file system     ;
; (this is after of course the first sector, but also after two FAT tables,  ;
; and also after FAT ROOT directory).                                        ;
;                                                                            ;
;----------------------------------------------------------------------------;

%define     BTSTRPTR    30          ; First 30 bytes are FAT-12 description.
            org         0x7c00      ; BIOS standard memory address
                                    ; for a boot loader.
start:      jmp         bootstrap   ; Ommit first 30 bytes.
            nop                     ; Traditional No operation.
            db          "ATIX001"   ; OEM name.
            dw          NBYTEPSEC   ; Number of bytes per sector.
            db          NSECPCLU    ; Number of sectors per cluster.
            dw          NRESSEC     ; Number of reserved sectors.
            db          NFATCOPYS   ; Number of FAT copies.
            dw          NROOTRECS   ; Number records (?) of the 
                                    ; ROOT directory.
            dw          NTOTALSEC   ; Total number of sectors.
            db          MEDIADESC   ; Media descriptor, here is floppy.
            dw          FATSIZE     ; Number of FAT sectors.
            dw          NSECPTRACK  ; Number of sectors per track.
            dw          NHEADS      ; Number of heads.
            dw          NHIDDSEC    ; Number of hidden sectors.
fillsize    equ         $-start     ; Size of the FAT-12 boot sector head,
                                    ; should be 30.

            times       BTSTRPTR-fillsize  db  0
                                    ; This should generate nothing, but
                                    ; if I made a mistake above, this
                                    ; assembler directive will generate
                                    ; zeroes.
;----------------------------------------------------------------------------;
;                               MBR code                                     ;
;                                                                            ;
; Here the actual code starts. We need to:                                   ;
;    i) print a quasi-"hello" message,                                       ;
;   ii) read first N sectors of the real bootloader,                         ;
;  iii) jump to the real bootloader.                                         ;
;                                                                            ;
;----------------------------------------------------------------------------;

bootstrap:
            mov         ax, 0
            mov         ss, ax
            mov         ds, ax
            mov         es, ax      ; Init extra data segment
            mov         sp, 0x7c00-2  ; Set stack to the MBR image in memory.
            push        dx          ; Save disc info to the stack.

;----------------------------------------------------------------------------;
;                           Print on the screen                              ;
;                                                                            ;
; First, we want to show, that the MBR code at least runs. Second, we want   ;
; to show something usefull at the screen, I think it should be information  ;
; about the disc from which the MBR is running. I suppose to use disketts,   ;
; therefore it should be either DISK A or DISK B (DL == 0x00 or 0x01).       ;
;                                                                            ;
;----------------------------------------------------------------------------;

            test        dl,0x80     ; 8th bit of the DL register shows if
                                    ; the disc is a removable one (bit = 0)
                                    ; or a fixed one (bit = 1).
            jnz         disc_c      ; DOS tradition to call fixed hard drives
                                    ; from the letter 'C', jump there if the
                                    ; test result is nonzero (bit is up).

            add         dl, 'A'     ; Convert DL to an ASCII code. DL==0
                                    ; corresponds to disk A.
            jmp         save_l      ; Jump to the common code for all types.

                                    ; Fixed disc type case.
disc_c:     and         dl, 0x7f    ; Set 8th bit of DL to zero.
            add         dl, 'C'     ; Disk C -- first fixed-type disc.

                                    ; Here I'm using a trick to show disc
                                    ; letter: in the hello-message line
                                    ; I've marked one character for just
                                    ; one letter -- this disc letter.
save_l:     mov         [disc_p],dl

                                    ; Clear screen code.
                                    ; Initialize BX with the pointer to the
                                    ; latest screen character and fill every
                                    ; word with an empty symbol and nonempty
                                    ; attribute (02 means green on black).
            mov         bx, 80*25*2+2

            mov         ax, 0x0b800 ; Put the standard screen address into
                                    ; DS. I hope this program runs with a 
                                    ; colour display in text mode with
                                    ; 80x25 symbols per a page.
            mov         ds, ax      ; Each symbol takes two bytes, one
                                    ; for the symbol and another for
                                    ; an attribute.
            mov         ax, 0x0200  ; 0x02 is the attribute
clear:      mov         [bx-2], ax
            sub         bx, 2
            jnz         clear       ; Loop for until BX is zero.
                                    
                                    ; Print the first message on the screen.
                                    ; Arguments: BX is the pointer to the
                                    ; first screen character,
                                    ; CX is the message length,
                                    ; and BP is the pointer to the message.
            mov         bx, 0
            mov         cx, mbrln
            mov         bp, mbrmsg
            call        print

;----------------------------------------------------------------------------;
;                         Read the real bootloader                           ;
;                                                                            ;
; I'm going to use BIOS system calls to read the bootloader (INT 13H).       ;
; First, we need to read the drive parameters: number of sectors per track,  ;
; number of heads and cylinders. Our read programm must not exceed these     ;
; values.                                                                    ;
;     From the FAT arragement we know, that the first data sector starts     ;
; after this boot sector, two FAT tables and the ROOT directory. In total it ;
; takes 1+2*9+14=33 sectors, so we shall read the 34th sector (33 in LBA     ;
; notation). For almost all IMB PC diskettes this number is above the max    ;
; number of sectors per track (5 1/4 HD has 15 sectors/track, 3 1/2 HD 1440K ;
; has 18 sectors/track, and only 3 1/2 ED 2880K diskette has 36 sec/track).  ;
;     Fortunately, QEMU emulates the latest floppy driver, so for tests we   ;
; may not care about CHS geometry, but for the real applications we should   ;
; take this into account.                                                    ;
;     First, we need to read the drive information and to store max cyl,     ;
; head, and sector somewhere (memory?). Then, we must calculate the first    ;
; CHS address from the known LBA (33) -- for various diskettes it can be     ;
; different. Then, we need to read all bootloader sectors by one sector      ;
; to avoid cylinder bounds. Finally, we shall jump to the read sectors.      ;
;     During reading every error is FATAL, so we shall jump to the error     ;
; processing instruction, print a message with the error code, and halt the  ;
; processor.                                                                 ;
;                                                                            ;
;----------------------------------------------------------------------------;

                                    ; Read disc drive info.
            pop         dx          ; Restore DL.
            push        dx          ; And save again for INT 13H 0x02 (read).
            mov         ah, 0x08    ; AH is always the procedure number.
            xor         bx, bx
            mov         es, bx      ; ES:DI must be 0000:0000
            mov         di, 0x00    ; for some BIOS it's necessary
                                    ; according Wikipedia.
            int         0x13

                                    ; Check for errors.
            jc          error       ; AH has the error code.
            
            cmp         cx, 0x00    ; Check if BIOS doesn't understand
                                    ; the drive, max cyl = max sec = 0.
            mov         ah, ERR_BIOS_NOT_SET
                                    ; This is my error code.
            jz          error       ; Also jump to error.

                                    ; Save int13h8f result
            mov         ax, 0
            mov         ds, ax
            mov         ax, cx
            and         cx, 0x003f  ; 0000 0000 0011 1111
                                    ; sector
            mov         [maxsec], cx
            shr         al, 6       ; 1100 0000 -> 0000 0011
            mov         ch, al
            mov         cl, ah      ; AX = MAXCYL
            mov         [maxcyl], cx
            mov         [maxhead], dh
                                    ; Max head.

                                    ; Arithmetics for LBA -> CHS
                                    ; AX = first LBA sector+1
            mov         cx, 1+2*FATSIZE+ROOTSIZE+1
            mov         bx, 0
            mov         dh, 0
lba_chs:    cmp         cx, [maxsec]
            jna         result      ; If CX <= maxsec this is the result

sub_sec:    sub         cx, [maxsec]
            inc         dh
            cmp         dh, [maxhead]
            ja          sub_head
            jmp         lba_chs

sub_head:   sub         dh, [maxhead]
            dec         dh          ; because n of heads = maxhead+1
            inc         bx
            cmp         bx, [maxcyl]
            ja          sub_cyl
            jmp         lba_chs
sub_cyl:    sub         bx, [maxcyl]
            dec         bx          ; the same reason as for heads
            jmp         lba_chs
result:                             ; Result: CX -- sector, DX -- head,
                                    ; and BX -- cylinder.
            mov         ch, bl      ; Pack BX CX DX to BIOS CHS standard
            shl         bh, 6
            or          cl, bh      ; Now CX is ready
            mov         ax, dx
            pop         dx          ; Stack stores DL with drive number
            mov         dh, ah
        
                                    ; Finally, CL[0--5] is sector
                                    ; CH and CL[6--7] is cyl
                                    ; DH is head
                    
                                    ; Now we are ready to read sector by
                                    ; sector.
            mov         bx, BLIP    ; relative address for the BL
            mov         ah, 0x02
            mov         al, BLNSEC
                                    ; Save CX
            mov         [cx_tmp], cx

                                    ; Loop for read the boot loader
                                    ; starts here:

read_loop:  cmp         al, 0       ; Read sectors one by one
            
                                    ; untill all are read.
            jz          bl_start
            mov         [rmd_nsec], al
            mov         ax, BLCS
            mov         es, ax
                                    ; save AL -- counter of 
                                    ; reminded sectors to read,
            mov         ax, 0x0201  ; and read only one sector.
                                    ; Restore CX
            mov         cx, [cx_tmp]
            int         0x13
                                    ; Process INT 13h errors
                                    ;carry flag = 1 if error
            jc          error
            mov         ah, ERR_NSECREAD
                                    ; Prepare to print an error:
            cmp         al, 1       ; al = number of actual sectors read
            jne         error       ; and print error, if it happend

            mov         al, [rmd_nsec]


                                    ; Restore AL.
                                    ; And as we read a sector:
            dec         al          ; decrease AL by 1
                                    ; and increase BX by the number of
                                    ; bytes per one sector.
            add         bx, NBYTEPSEC
            and         cl, 0x3f    ; Find only sector information in CX
            inc         cl          ; and increase it by one
            cmp         cl, [maxsec]
            ja          dec_sec     ; If the sector number is above the
                                    ; maximum, we must set n_sec to one
                                    ; and increase the number of heads
                                    ; by one,
            and         word [cx_tmp], 0x00a0
            or          [cx_tmp], cx
                                    ; So, CX is saved to cx_tmp
            jmp         read_loop   ; otherwise just read the next sector
                                    ; of the track.

dec_sec:    mov         cl, 1       ; Set sector number to 1
            and         byte [cx_tmp], 0xa0
            or          [cx_tmp], cl
                                    ; and two high bits of CL.
            mov         cx, [cx_tmp]
                                    ; CH is immutable during this operations.
            inc         dh
            mov         [cx_tmp], cx
            cmp         dh, [maxhead]
                                    ; Check if the head number is above the
                                    ; maximum head available
            ja          dec_head
            jmp         read_loop

dec_head:                           ; Increase cylinder by one -- the most
                                    ; difficult part.
                                    ; First, form the number of cylinder
                                    ; in the cx_tmp
            mov         dh, ch      ; Temporary use DH to store CH
            shr         cl, 6
            mov         ch, cl
            mov         cl, dh
                                    ; Now CX is number of cylinders
            inc         cx

            mov         dh, ch
            shl         dh, 6
            or          dh, 0x01    ; Now DH is future CL
            mov         [cx_tmp], dh
            mov         [cx_tmp+1], cl
            xor         dh, dh      ; and head to 0, because this is the new
                                    ; cylinder.
            cmp         cx, [maxcyl]
            jnz         read_loop
            mov         ah, ERR_CYL_OUT_OF_RANGE
            jmp         error
bl_start:
            jmp         BLCS:BLIP   ; long jump to the BL
halt:       hlt                     ; Infinite stop
            jmp         halt

;----------------------------------------------------------------------------;
;                               Subroutines                                  ;
;                                                                            ;
;    1. ERROR                                                                ;
;    2. PRINT                                                                ;
;                                                                            ;
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
;                           Error subroutine                                 ;
;                                                                            ;
; Doesn't return back to the code, prints an error message with an error     ;
; code and falls into an infinite loop of halt instruction.                  ;
;                                                                            ;
;----------------------------------------------------------------------------;

error:
                                    ; Translate AH to ascii
            mov         bx,0x00
            mov         ds,bx
            mov         dh, ah
            and         ah, 0x0f
            cmp         ah, 0x0a
            jae         adda
            add         ah, '0'     ; add '0'
            jmp         contin
                                    ; add 'A'
adda:       add         ah, 'A'
            sub         ah, 0x0a

contin:
            shr         dh, 4       ; Second character
            cmp         dh, 0x0a
            jae         adda2
            add         dh, '0'
            jmp         contin2
adda2:      add         dh, 'A'
            sub         dh, 0x0a
contin2:
            mov         al, dh
            mov         [errcod],ax
                                    ; Change an error code to the obtained
                                    ; value.
            mov         bx, 80*2    ; next line relative to the first msg.
            mov         cx, errln
            mov         bp, errmsg
            call        print
            jmp         halt        ; Infinite halt.

;----------------------------------------------------------------------------;
;                               Print subroutine                             ;
;                                                                            ;
; Prints a message from memory.                                              ;
; Arguments:                                                                 ;
; BP --- pointer to the message,                                             ;
; CX --- length of the message.                                              ;
;                                                                            ;
;----------------------------------------------------------------------------;

print:  
            mov         ax, 0xb800
            mov         ds, ax
            xor         ax, ax
            mov         es,ax
            mov         al, [es:bp]
            mov         ah, 0x02
loo:        mov         [bx], ax
            add         bx, 2
            inc         bp
            mov         al, [es:bp]
            loop        loo
            shr         bx,1
                                    ; Move cursor                                    
            mov         dx, 0x03d4
            mov         al, 0x0f
            out         dx, al

            inc         dl
            mov         al, bl
            out         dx, al

            dec         dl
            mov         al, 0x0e
            out         dx, al

            inc         dl
            mov         al, bh
            out         dx, al
            ret

;-----------------------------------------------------------------------------;
;                      Data within the .text section                          ;
;                                                                             ;
;-----------------------------------------------------------------------------;

mbrmsg:     db          "Disk X"
disc_p      equ         $-1
            db          "."
mbrln       equ         $-mbrmsg
errmsg:     db          "ERR: 0xXX."
errcod:     equ         $-3
errln       equ         $-errmsg
maxsec:     dw          0
maxcyl:     dw          0
maxhead:    db          0
rmd_nsec:   db          0
cx_tmp:     dw          0
size        equ         $-start
            times       510-size        db 0
bios_magic: dw          0xaa55

