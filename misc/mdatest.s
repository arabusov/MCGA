; IBM 5151 Monochrome Display
; (From the technical reference manual, IBM Monochrome display)
; Video signal: 
;  - Maximum bandwidth of 16.257 MHz at -3dB
; Vertical drive:
;  - Screen refreshed at 50 Hz with 350 lines of vertical
; resolution and 720 lines of horizontal resolution
; Horizontal drive:
;   - Positive level, TTL-compatibility, at a frequency of
; 18.432 kHz
;
; What Wikipedia tells about TTL:
;   - Input
;     * Low: 0--0.8 V
;     * High: 2--5 V
;   - Output
;     * Low: 0--0.4 V
;     * High: 2.4--VCC
;     (so at least 0.4 V of noise immunity)
;
; Monochrome Display Adapter
; (From the technical reference manual, IBM Monochrome Display
; and Printer Adapter)
; The adapter is build around the Motorolla 6845 CRT Controller
; Module plus it hase 4K Bytes of RAM as a display buffer.
; The CPU has access only to two ports of direct access.
; 16-bits word is fetched from the buffer in 553 ns (1.8 M/s rate)
; - Characteristics:
;    * 80x25 characters on screen
;    * 18 kHz monitor
; Table of mapping 6845 to the MDA
;------------------------;
; 6845 Reg | MDA Address ;
;----------|-------------;
;    R0    |    0x61     ;
;    R1    |    0x50     ;
;    R2    |    0x52     ; 
;    R3    |    0x0F     ;
;    R4    |    0x19     ;
;    R5    |    0x06     ;
;    R6    |    0x19     ;
;    R7    |    0x19     ;
;    R8    |    0x02     ;
;    R9    |    0x0D     ;
;   R10    |    0x0B     ;
;   R11    |    0x0C     ;
;   R12    |    0x00     ;
;   R13    |    0x00     ;
;   R14    |    0x00     ;
;   R15    |    0x00     ;
;   R16    |    0x00     ;
;   R17    |    0x00     ;
;------------------------;
; MDA Basic Initialization
;   Issue to the CRT Control Port 1 (0x03B8) command 0x01
; to set the high-resolution mode.
; MDA 4K RAM
; Starts at 0xB0000, each 16-bits word has ASCII-symbol (LB)
; and attribute (HB).
; Attribute:
;_______________________________________________;
;  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  ;
;Blink|    Background   |Inten|    Foreground   ;
;-----------------------------------------------;
; Background/Foreground triplets:
;     0x0 | 0x0 | Non-Display
;     0x0 | 0x1 | Underline
;     0x0 | 0x7 | "White" Character/Black background
;     0x7 | 0x0 | Reserve video
; MDA I/O Mapping:
;------------------------------------;
; Register Address |      Function   ;
;------------------|-----------------;
;      0x03B4      | 6845 Index Reg. ;
;      0x03B5      | 6845 Data Reg.  ;
;      0x03B8      | CRT Cntrl Prt 1 ;
;      0x03BA      | CRT Stat. Prt 1 ;
; Next: Printer stuff, I don't care  ;
;------------------------------------;
; CRT Control Port 1:
;----------------------------;
; Bit # |      Function      ;
;-------|--------------------;
;   0   | + High resol. mode ;
;   3   | + Video enable     ;
;   5   | + Enable blink     ;
;----------------------------;
; CRT Status Port 1:
;----------------------------;
; Bit # |      Function      ;
;-------|--------------------;
;   0   | + Horizontal Drive ;
;   3   | + Black/White Video;
;----------------------------;
; Voltages:
; Signal down: 0--0.6 V
; Signal up: 2.4--3.5 V
; DA-9 Connector:
; 1, 2 --- Ground
; 3--5 --- Not Used
; 6 --- + Intensity
; 7 --- + Video
; 8 --- + Horizontal
; 9 --- - Vertical
;
; Motorolla 6845 CRT Controller Module
; CM6845 registers
;-----------------------------------------------------------;
; Register # | Register File |  Unit  | Read | Write | #bits;
;------------|---------------|--------|------|-------|------;
;     AR     | Address reg   |   -    |  No  |  Yes  |   5  ;
;     R0     | Horiz. total  | Char.  |  No  |  Yes  |   8  ;
;     R1     | Horiz. displ. | Char.  |  No  |  Yes  |   8  ;
;     R2     | H. Sync. pos. | Char.  |  No  |  Yes  |   8  ;
;     R3     | Sync. Width   |   -    |  No  |  Yes  |  4H  ;
;     R4     | Vertical Tot. | Ch.Row.|  No  |  Yes  |   7  ;
;     R5     | V. Tot. Adj.  | ScanL. |  No  |  Yes  |   5  ;
;     R6     | Vert. displ.  | Ch.Row.|  No  |  Yes  |   7  ;
;     R7     | V. Sync. pos. | Ch.Row.|  No  |  Yes  |   7  ;
;     R8     | Iface mode&sk | Ch.Row.|  No  |  Yes  |  2I  ;
;     R9     | Max scan laddr| ScanL. |  No  |  Yes  |   5  ;
;    R10     | Cursor start  | ScanL. |  No  |  Yes  | 7BP  ;
;    R11     | Cursor end    | ScanL. |  No  |  Yes  |   5  ;
;    R12     | Start addr H  |   -    |  No  |  Yes  | 006  ;
;    R13     | Start addr L  |   -    |  No  |  Yes  |   8  ;
;    R14     | Cursor H      |   -    |  Yes |  No   | 006  ;
;    R15     | Cursor L      |   -    |  Yes |  No   |   8  ;
;    R16     | Light pen H   |   -    |  Yes |  No   | 006  ;
;    R17     | Light pen L   |   -    |  Yes |  No   |   8  ;
;-----------------------------------------------------------;
;
; IBM PC XT BIOS initialization for MDA B&W Text mode
; see page 376 of IBM PC XT Hardware Reference Library Technical Reference
; Monochrome Display Adapter
            use16   286
            ;; Ok, I'll try to use it with my own bootloader
            org     0x100
            jmp     _start
;;; Parameters table
init_seq:   .byte   0x61, 0x50, 0x52, 0x0f, 0x19, 0x06, 0x19
            .byte   0x19, 0x02, 0x0d, 0x0b, 0x0c
            .byte   0x00, 0x00, 0x00, 0x00
init_seq_size equ    *-init_seq
port_6845:  .word   0x03b4  ; Index register address
                            ; 0x03B5 --- Data register (R0 -- R17)
                            ; 0x03B8 --- CRT Control Port 1
                            ; 0x03BA --- CRT Status  Port 1
mode_flag:  .byte   0x01    ; High resolution mode
mode_set:   .byte   0x29    ; Bits # 0, 3, and 5 must be 1, 0 otherwise

_start:     call    set_mda_mode
            call    test_mda
            ;; Wait
            mov     cx, #0xffff
wait_loop:       nop
            loop    wait_loop
            ;; Get back to Color 80x25 text mode
            mov     ah, #0
            mov     al, #3
            int     0x10
            ;; Exit to MS-DOS
            mov     ax, #0x4c00
            int     0x21
            ret

test_mda:   push    ds
            push    ax
            push    bx
            push    cx

            mov     ax, #0xb000
            mov     ds, ax

            mov     bx, #0
            mov     cx, #25*80
            mov     ax, 0x0741
test_loop:
            mov     [bx], ax
            add     bx, #2
            loop    test_loop
            ret

            pop     cx
            pop     bx
            pop     ax
            pop     ds
            ret

set_mda_mode:
            push    ax
            push    dx
            push    cx
            push    bx
            ;; Say "Set mode" to the 6845
            mov     dx, #port_6845
            push    dx
            ;; Control port is port_6845 + 4
            add     dx, #4
            mov     al, mode_flag
            out     dx, al
            pop     dx

            mov     bx, #init_seq
            mov     cx, #init_seq_size
            xor     ah, ah
            ;; Now loop through all parameters
out_par_table:
            mov     al, ah
            out     dx, al
            inc     dx
            inc     ah
            mov     al, [bx]
            out     dx, al
            inc     bx
            dec     dx
            loop    out_par_table

            ;; Now say "Video enable"
            mov     dx, #port_6845
            ;; Control port is port_6845 + 4
            add     dx, #4
            mov     al, mode_set
            out     dx, al
            
            
            pop     bx
            pop     cx
            pop     dx
            pop     ax
            ret
