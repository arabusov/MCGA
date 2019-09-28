;----------------------------------------------------------------------------;
;                         Master boot record (MBR)                           ;
;                                                                            ;
;----------------------------------------------------------------------------;

%include "bl.inc"
%include "fat12.inc"
bits 16                             ; i8086 16-bits REAL mode, actually.
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
            org         7c00h       ; BIOS standard memory address
                                    ; for a boot loader.
start:      jmp         bootstrap   ; Ommit first 30 bytes.
            nop                     ; Traditional No operation.
            db          "ATIX001"   ; OEM name.
            dw          NBYTEPSEC   ; Number of bytes per sector.
            db          NSECPCLU    ; Number of sectors per cluster.
            dw          1           ; Number of reserved sectors.
            db          2           ; Number of FAT copies.
            dw          224         ; Number records (?) of the 
                                    ; ROOT directory.
            dw          2880        ; Total number of sectors.
            db          0xf0        ; Media descriptor, here is floppy.
            dw          FATSIZE     ; Number of FAT sectors.
            dw          NSECS       ; Number of sectors per track.
            dw          NHEADS      ; Number of heads.
            dw          0           ; Number of hidden sectors.
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
                                    ; Here we are going to use BIOS stack
                                    ; settings, hope it will not cause a bug.
                                    ; So we do nothing with SS:SP registers.
            push        dx          ; Save disc info to the stack.

            mov         ax, 0x0b800 ; Put the standard screen address into
                                    ; DS. I hope this program runs with a 
                                    ; colour display in text mode with
                                    ; 80x25 symbols per a page.
            mov         ds, ax      ; Each symbol takes two bytes, one
                                    ; for the symbol and another for
                                    ; an attribute.
            mov         ax, 0
            mov         es, ax      ; init data segment

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
disc_c:     and         dl, 0x7f    ; Remove the flag.
            add         dl, 'C'     ; Disk C -- first fixed-type disc.

                                    ; Here I'm using a trick to show disc
                                    ; letter: in the hello-message line
                                    ; I've marked one character for just
                                    ; one letter -- this disc letter.
save_l:     mov         [es:disc_p],dl

                                    ; Clear screen code.
                                    ; Initialize BX with the pointer to the
                                    ; latest screen character and fill every
                                    ; word with an empty symbol and nonempty
                                    ; attribute (02 means green on black).
            mov         bx, 80*25*2+2
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
            mov         bx, 0x00
            mov         es,bx       ; ES:DI must be 0000:0000
            mov         di,0x00     ; for some BIOS it's necessary
                                    ; according Wikipedia.
            int         0x13

                                    ; Check for errors.
            jc          error       ; AH has the error code.
            cmp         cx, 0x00    ; Check if BIOS doesn't understand
                                    ; the drive, max cyl = max sec = 0.
            mov         ah, 0xad    ; This is my error code.
            jz          error       ; Also jump to error.

                                    ; Save int13h8f result
            mov         ax, cx
            and         ax, 0x003f  ; 0000 0000 0011 1111
                                    ; sector
            mov         [maxsec], ax
            mov         ah, cl
            shr         ah, 6       ; 1100 0000 -> 0000 0011
            mov         al, ch      ; AX = MAXCYL
            mov         [maxcyl], ax
            mov         dl, dh
            mov         dh, 0
            mov         [maxhead], dx
                                    ; Max head.

                                    ; Arithmetics for LBA -> CHS
                                    ; AX = first LBA sector+1
            mov         ax, 1+2*FATSIZE+ROOTSIZE+1
            mov         cx, ax      ; Init values: cx = ax, others zero.
            mov         bx, 0
            mov         dx, 0
lba_chs:    cmp         cx, [maxsec]
            ja          sub_sec
            jmp         result      ; If CX <= maxsec this is the result
sub_sec:    sub         cx, [maxsec]
            inc         dx
            cmp         dx, [maxhead]
            ja          sub_head
            jmp         lba_chs

sub_head:   sub         dx, [maxhead]
            dec         dx          ; because n of heads = maxhead+1
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
            mov         al, dh
        
                                    ; Finally, CL[0--5] is sector
                                    ; CH and CL[6--7] is cyl
                                    ; DH is head
                    
                                    ; Now we are ready to read sector by
                                    ; sector.
            mov         ax, BLCS
            mov         es, ax
            mov         bx, BLIP    ; relative address for the BL
            mov         ah, 0x02
            mov         al, BLNSEC
read_loop:  cmp         al, 0       ; WRONG FIXME
            jz          bl_start
            mov         [rmd_nsec], al
                                    ; save AL
            mov         al, BLNSEC
            int         0x13
                                    ; Process INT 13h errors
                                    ;carry flag = 1 if error
            jc          error
            cmp         al, BLNSEC       ; al = number of actual sectors read
            jne         error

bl_start:   jmp         BLCS:BLIP   ; long jump to the BL
halt:       hlt
            jmp         halt

error:
        ; translate ah to ascii
        mov bx,0
        mov es,bx
        mov dh, ah
        and ah, 0x0f
        cmp ah, 0x0a
        jae adda
        ; add '0'
        add ah, '0'
        jmp contin
        ; add 'A'
adda:   add ah, 'A'
        sub ah, 0x0a

contin:
        shr dh, 4
        cmp dh, 0x0a
        jae adda2
        ; add '0'
        add dh, '0'
        jmp contin2
adda2:  add dh, 'A'
        sub dh, 0x0a
contin2:
        mov al, dh
        mov [es:errcod],ax
        mov bx, 80*2 ; next line relative to the first msg
        mov cx, errln
        mov bp, errmsg
        call    print
        jmp halt
;subroutines
print:  
        push es
        mov ax,0
        mov es,ax
        mov al, [es:bp]
        mov ah, 02h
loo:    mov [bx], ax
        add bx, 2
        inc bp
        mov al, [es:bp]
        loop loo
        shr bx,1

        mov dx, 0x03d4
        mov al, 0x0f
        out dx, al

        inc dl
        mov al, bl
        out dx, al

        dec dl
        mov al, 0x0e
        out dx, al

        inc dl
        mov al, bh
        out dx, al
        pop es
        ret

; data
mbrmsg: db  "Disk X"
disc_p  equ $-1
        db  "..."
mbrln   equ $-mbrmsg
errmsg: db  "READ ERR: 0xXX."
errcod: equ $-3
errln   equ $-errmsg
maxsec:     dw      0
maxcyl:     dw      0
maxhead:    dw      0
rmd_nsec    db      0
curr_cx     dw      0
size    equ $-start
        times 446-size db 0
;first partition
       ; times 16 db 0
        db  0x80
        db  PART1HEAD
        dw  PART1CYLSEC
        db  0x01 ;type
        db  PART1ENDHEAD
        dw  PART1ENDCYLSEC
        times 4 db  0x00
        times 4 db  0x00
        times 16*3 db 0
bios_magic: dw      0xaa55

