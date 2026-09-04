; Uncomment to use a 256-byte private stack instead of 128 bytes.
; %define STACK256

%ifdef USE_LN
 %define USE_GR
%endif

; Exit code for DOS
; if a program has no END, execution stops here.
 
RT_EXIT:
  xor al,al

RT_EXIT_AL:
%ifdef USE_BI
  push ax
  call BIFLUSH
  pop ax
%endif
%ifdef USE_GR
  push ax
  call GR_RESET
  pop ax
%endif
%ifdef STACKMON
  mov [SM_EXIT],al
  jmp STACK_REPORT
%endif
RT_EXIT_DOS:
  mov ah,4Ch
  int 21h

; System variables
NV:
 times __N db 0
SV:
 times __S db 0


; ===== Runtime / library functions =====
%ifdef USE_IN
 %define USE_PR
 %define USE_NB
 %define USE_TMP
 %define USE_RTE
%endif

%ifdef USE_FI
 %define USE_NB
 FH: times 9 dw 0    ; handle for channel 1..9
 FM: times 9 db 0    ; 0=closed, 1=INPUT, 2=OUTPUT
%endif

%ifdef USE_DR
 %define USE_NB
%endif

%ifdef USE_FL
 %define USE_NB
 FLSALL db "*.*",0
 FLDTA: times 43 db 0
 FLDTA_OLD_OFF dw 0
 FLDTA_OLD_SEG dw 0
%endif

%ifdef USE_PN
 %define USE_NB
%endif

%ifdef USE_HX
 %define USE_ST
 %define USE_IB
%endif
%ifdef USE_OC
 %define USE_ST
 %define USE_IB
%endif
%ifdef USE_BN
 %define USE_ST
 %define USE_IB
%endif
%ifdef USE_SR
 %define USE_ST
%endif
%ifdef USE_ST
 %define USE_TMP
%endif

%ifdef USE_T4
 %define USE_ST
 %define USE_TMP
%endif
%ifdef USE_T5
 %define USE_ST
 %define USE_TMP
%endif
%ifdef USE_T6
 %define USE_ST
 %define USE_TMP
%endif

%ifdef USE_BI
 %define USE_NB
%endif

%ifdef USE_XA
 %define USE_ST
 %define USE_TMP
%endif

%ifdef USE_IX
 %define USE_AR
%endif

; =================================================
; Shared runtime error / message helpers
; =================================================
%ifdef USE_DA
 %define USE_RTE
%endif
%ifdef USE_MT
 %define USE_RTE
%endif
%ifdef USE_DV
 %define USE_RTE
%endif
%ifdef USE_FI
 %define USE_RTE
%endif
%ifdef USE_DR
 %define USE_RTE
%endif
%ifdef USE_BI
 %define USE_RTE
 %define USE_BV
%endif
%ifdef USE_PK
 %define USE_RTE
 %define USE_BV
%endif
%ifdef USE_IO
 %define USE_RTE
 %define USE_BV
%endif
%ifdef USE_XA
 %define USE_RTE
%endif
%ifdef USE_AR
 %define USE_RTE
%endif
%ifdef USE_IX
 %define USE_RTE
 %define USE_BV
%endif

%ifdef USE_DT
 %define USE_D2
%endif
%ifdef USE_TS
 %define USE_D2
%endif

; =================================================
; Shared DOS memory use
; USE_XA = external string arrays
; USE_AR = normal arrays, including large external INT arrays
; =================================================
%ifdef USE_XA
 %define USE_MEM
%endif

%ifdef USE_EX
 %define USE_MEM
%endif

%ifdef USE_AR
 %define USE_MEM
%endif

%ifdef STACKMON
 %define USE_MEM
%endif

%ifdef USE_NB
 NB: times 257 db 0
%endif

%ifdef USE_TMP
TMP$: times 256 db 0
%endif

%ifdef USE_ST
TMP2$: times 256 db 0
%endif

%ifdef USE_ST
TMP3$: times 256 db 0
%endif

%ifdef USE_T4
TMP4$: times 256 db 0
%endif
%ifdef USE_T5
TMP5$: times 256 db 0
%endif
%ifdef USE_T6
TMP6$: times 256 db 0
%endif

%ifdef USE_MEM
MEMINITD db 0
%endif

%ifdef USE_XA
XASEG: times 16 dw 0 ; segment per handle
XACNT: times 16 dw 0 ; String count per handle
XALEN: times 16 dw 0 ; Slot size in bytes = maxlen+1
%endif

%ifdef USE_PK
PSEG dw 0
%endif

%ifdef USE_BV
BVERR:
 db "BYTE VALUE ERROR"
%endif

%ifdef USE_RTE
; -------------------------------------------------
; RT_ABORT
; In : DX = message address
;      CX = message length
; Effect: writes message + CR/LF and terminates program
; -------------------------------------------------
RT_ABORT:
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov al,10
 jmp RT_EXIT_AL
%endif

INIT_COMMAND:
%ifdef USE_MEM
 ; -------------------------------------------------
 ; Private COM stack for DOS-memory features.
 ; Default: 128 bytes. Define STACK256 for 256 bytes.
 ; INIT_COMMAND is called directly from start via CALL.
 ; Therefore the return address is on the old stack.
 ; Procedure:
 ;   1. fetch return address from the old stack
 ;   2. set SS:SP to the private stack
 ;   3. place return address on the new stack
 ;   4. continue normally and RET at the end
 ; -------------------------------------------------
 pop bx                  ; save return address
%ifdef STACKMON
 push es
 push cs
 pop es
 mov di,OFFSET ENDPROG
%ifdef STACK256
 mov cx,128            ; 128 words = 256 bytes
%else
 mov cx,64             ; 64 words = 128 bytes
%endif
 mov ax,0A55Ah
 rep stosw
 pop es
%endif
 cli
 mov ax,cs
 mov ss,ax
%ifdef STACK256
 mov sp,OFFSET ENDPROG+256
%else
 mov sp,OFFSET ENDPROG+128
%endif
 sti

 push bx                 ; return address on new stack
%endif

%ifdef S_PROGDIR
 call PROGDIR_INIT
%endif

%ifdef USE_RN
 push ax
 push cx
 push dx
 mov ah,00h
 int 1Ah
 mov ax,dx
 xor ax,cx
 or ax,ax
 jne RNDINIT_OK
 mov ax,1
RNDINIT_OK:
 mov [RSEED],ax
 pop dx
 pop cx
 pop ax
%endif

%ifdef USE_PK
 push ax
 push cs
 pop ax
 mov [PSEG],ax
 pop ax
%endif

%ifdef S_COMMAND
 push si
 push di
 push cx

 xor cx,cx
 mov cl,[80h]          ; Length of the DOS command tail
 mov di,OFFSET S_COMMAND

 or cl,cl
 jne ICMD_HAVE
 mov BYTE [di],0
 jmp ICMD_DONE

ICMD_HAVE:
 mov si,81h            ; first tail character

 ; Optional: strip exactly one leading space
 cmp BYTE [si],' '
 jne ICMD_LEN_OK
 inc si
 dec cl

ICMD_LEN_OK:
 mov [di],cl
 inc di
 rep movsb

ICMD_DONE:
 pop cx
 pop di
 pop si
%endif

%ifdef S_CURDIR
 call CURDIR_UPDATE
%endif
 ret

%ifdef S_PROGDIR
; -------------------------------------------------
; PROGDIR_INIT
; Effect:
;   Initializes PROGDIR$ with the directory of the
;   currently running COM program.
;
; Output:
;   S_PROGDIR = counted string:
;      "C:\TOOLS\" for "C:\TOOLS\BASCOMP.COM"
;      "C:"       for "C:BASCOMP.COM"
;      ""         if no path information is available
;
; Notes:
;   Uses the DOS 3.x+ convention that the environment
;   block contains the fully qualified program name
;   after the double-zero environment terminator and
;   one following word.
; -------------------------------------------------
PROGDIR_INIT:
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 push ds
 push es

 push cs
 pop ds

 ; default: PROGDIR$ = ""
 mov di,OFFSET S_PROGDIR
 mov BYTE [di],0

 ; PSP:2Ch = environment segment
 mov ax,[2Ch]
 or ax,ax
 je PGD_DONE

 mov es,ax
 xor bx,bx

; -------------------------------------------------
; Find double-zero terminator of environment strings.
; Environment layout:
;   VAR=VALUE,0
;   VAR=VALUE,0
;   0
;   word
;   program path,0
; -------------------------------------------------
PGD_ENV_SCAN:
 cmp bx,0FFF0h
 jae PGD_DONE

 mov al,[es:bx]
 cmp al,0
 jne PGD_SKIP_STR

 cmp BYTE [es:bx+1],0
 je PGD_ENV_END

 inc bx
 jmp PGD_ENV_SCAN

PGD_SKIP_STR:
 cmp bx,0FFF0h
 jae PGD_DONE
 cmp BYTE [es:bx],0
 je PGD_AFTER_STR
 inc bx
 jmp PGD_SKIP_STR

PGD_AFTER_STR:
 jmp PGD_ENV_SCAN

PGD_ENV_END:
 ; skip double zero and following word before program name
 add bx,4

 ; ES:BX now points to ASCIIZ program path if available.
 ; Scan path and remember length up to last separator.
 xor cx,cx              ; total chars scanned
 xor dx,dx              ; directory length to copy
 mov si,bx

PGD_PATH_SCAN:
 cmp cx,255
 jae PGD_COPY

 mov al,[es:si]
 cmp al,0
 je PGD_COPY

 inc cx
 inc si

 cmp al,'\'
 je PGD_SETLEN
 cmp al,'/'
 je PGD_SETLEN
 cmp al,':'
 je PGD_SETLEN

 jmp PGD_PATH_SCAN

PGD_SETLEN:
 mov dx,cx              ; include separator
 jmp PGD_PATH_SCAN

PGD_COPY:
 ; DX = directory length, 0..255
 mov di,OFFSET S_PROGDIR
 mov [di],dl

 or dx,dx
 je PGD_DONE

 inc di
 mov si,bx
 mov cx,dx

PGD_COPY_LOOP:
 mov al,[es:si]
 mov [di],al
 inc si
 inc di
 loop PGD_COPY_LOOP

PGD_DONE:
 pop es
 pop ds
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_MEM
; -------------------------------------------------
; MEMINIT
; Out: CF clear = memory block successfully resized or already done
;      CF set   = resize failed, AX = DOS error code
; Preserves all other registers and preserves AX on success.
; -------------------------------------------------
MEMINIT:
 cmp BYTE [MEMINITD],0
 jne MEMINIT_OK

 push bp
 push ax
 push bx
 push ds
 push es

 push cs
 pop ds
 push cs
 pop es

 mov bx,((ENDPROG - start + 100h + 15) >> 4)
%ifdef STACK256
 add bx,16             ; reserve 256 stack bytes
%else
 add bx,8              ; reserve 128 stack bytes
%endif
 mov ah,4Ah
 int 21h
 jc MEMINIT_FAIL
 mov BYTE [MEMINITD],1

 pop es
 pop ds
 pop bx
 pop ax
 pop bp
MEMINIT_OK:
 CLC
 ret
MEMINIT_FAIL:
 mov bp,ax
 pop es
 pop ds
 pop bx
 pop ax
 mov ax,bp
 pop bp
 STC
 ret
%endif

%ifdef USE_ST
; -------------------------------------------------
; LEFT2 / RIGHT2 / MID2
; Compact expression wrappers around LEFT/RIGHT/MID.
;
; LEFT2 / RIGHT2:
;   In : SI = source counted string, CX = count
; MID2:
;   In : SI = source counted string, DX = start, CX = count
; All:
;   Out: result in TMP2$, SI = OFFSET TMP2$
;        DI preserved
; -------------------------------------------------
LEFT2:
 push di
 mov di,OFFSET TMP2$
 call LEFT
 jmp STRFUN2_DONE
RIGHT2:
 push di
 mov di,OFFSET TMP2$
 call RIGHT
 jmp STRFUN2_DONE
MID2:
 push di
 mov di,OFFSET TMP2$
 call MID
STRFUN2_DONE:
 mov si,OFFSET TMP2$
 pop di
 ret

LEFT:
  mov bl,[si]
  mov ch,0
  cmp cl,bl
  jbe LEFT_OK
  mov cl,bl
LEFT_OK:
  mov [di],cl
  inc si
  inc di
  rep movsb
  ret

MID:
 mov bl,[si]
 cmp dl,1
 jae MID_S1
 mov dl,1
MID_S1:
 cmp dl,bl
 jbe MID_IN
 mov BYTE PTR [di],0
 ret
MID_IN:
 dec dl
 xor dh,dh
 inc si
 add si,dx
 sub bl,dl
 mov ch,0
 cmp cl,bl
 jbe MID_OK
 mov cl,bl
MID_OK:
 mov [di],cl
 inc di
 rep movsb
 ret

RIGHT:
  mov bl,[si]
  cmp cl,bl
  jbe RIGHT_OK
  mov cl,bl
RIGHT_OK:
  mov dl,bl
  sub dl,cl
  inc dl
  jmp MID

LTRIM:
 xor cx,cx
 mov cl,[si]
 inc si
 or cl,cl
 je LTRIM_ZERO

LTRIM_SCAN:
 cmp BYTE PTR [si],' '
 jne LTRIM_COPY
 inc si
 dec cl
 jne LTRIM_SCAN
 jmp LTRIM_ZERO

LTRIM_COPY:
 mov [di],cl
 inc di
 rep movsb
 ret

LTRIM_ZERO:
 mov BYTE PTR [di],0
 ret

RTRIM:
 xor cx,cx
 mov cl,[si]
 mov bx,si
 inc bx
 or cl,cl
 jne RTRIM_PREP
 mov BYTE PTR [di],0
 ret

RTRIM_PREP:
 mov si,bx
 add si,cx
 dec si

RTRIM_SCAN:
 or cl,cl
 je RTRIM_ZERO
 cmp BYTE PTR [si],' '
 jne RTRIM_COPY
 dec si
 dec cl
 jmp RTRIM_SCAN

RTRIM_COPY:
 mov [di],cl
 inc di
 mov si,bx
 rep movsb
 ret

RTRIM_ZERO:
 mov BYTE PTR [di],0
 ret

; -------------------------------------------------
; UCASE
; In : DS:SI = source, counted string
;      DS:DI = destination, counted string
; Out: destination = source with ASCII a..z converted to A..Z
;      other characters remain unchanged
; -------------------------------------------------
UCASE:
 xor cx,cx
 mov cl,[si]
 mov [di],cl
 inc si
 inc di
 or cl,cl
 je UCASE_DONE
UCASE_LOOP:
 lodsb
 cmp al,97
 jb UCASE_STORE
 cmp al,122
 ja UCASE_STORE
 sub al,32
UCASE_STORE:
 stosb
 loop UCASE_LOOP
UCASE_DONE:
 ret

LEN:
  xor ax,ax
  mov al,[si]
  ret

STRCPY:
  xor cx,cx
  mov cl,[si]
  mov [di],cl
  inc si
  inc di
  rep movsb
  ret

STRAPP:
 push ax
 push bx
 push cx
 push dx
 mov bx,di      ; BX = destination string
 mov dl,[bx]    ; DL = old destination length
 xor ax,ax
 mov al,[si]    ; AL = source length

 mov ah,255
 sub ah,dl      ; AH = free space
 cmp al,ah      ; source length <= free space?
 jbe STRAPP_FITS

 mov al,ah      ; copy only remaining free bytes
 mov BYTE [bx],255      ; overlong string is truncated
 jmp STRAPP_COPY

STRAPP_FITS:
 add [bx],al

STRAPP_COPY:
 xor cx,cx
 mov cl,dl
 add di,cx
 inc di
 inc si
 xor cx,cx
 mov cl,al
 rep movsb

 pop dx
 pop cx
 pop bx
 pop ax
 ret

STRCMP:
  push cx
  mov cl,[si]
  mov dl,[di]
  inc si
  inc di
CMP_LOOP:
  or cl,cl
  je CMP_ENDA
  or dl,dl
  je CMP_ENDB
  mov al,[si]
  mov ah,[di]
  cmp al,ah
  jne CMP_DIFF
  inc si
  inc di
  dec cl
  dec dl
  jmp CMP_LOOP
CMP_DIFF:
  sub al,ah
  pop cx
  ret
CMP_ENDA:
  or dl,dl
  je CMP_EQ
  mov al,-1
  pop cx
  ret
CMP_ENDB:
  mov al,1
  pop cx
  ret
CMP_EQ:
  xor al,al
  pop cx
  ret

INSTRS:
 push bx
 push cx
 push dx
 push si
 push di
 mov bl,[si]
 mov bh,[di]
 inc di
 cmp dx,1
 jae IOK
 mov dx,1
IOK:
 xor ax,ax
 mov al,bl
 cmp dx,ax
 ja INF
 or bh,bh
 jne ICHK
 mov ax,dx
 jmp ICLEAN
ICHK:
 add si,dx
 xor cx,cx
 mov cl,bl
 sub cx,dx
 inc cx
 xor ax,ax
 mov al,bh
 cmp cx,ax
 jb INF
 sub cx,ax
 inc cx
ILOOP:
 push cx
 push si
 push di
 xor cx,cx
 mov cl,bh
 repe cmpsb
 je IFND
 pop di
 pop si
 pop cx
 inc si
 loop ILOOP
INF:
 xor ax,ax
 jmp ICLEAN
IFND:
 pop di
 pop si
 pop cx
 xor ax,ax
 mov al,bl
 sub al,cl
 inc al
 sub al,bh
 inc al
ICLEAN:
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 ret
%endif

%ifdef USE_RN
RSEED dw 1

; -------------------------------------------------
; RNDS
; In : BX = upper limit n
; Out: AX = 1..n if n > 0
;      AX = 0 if n <= 0
; -------------------------------------------------
RNDS:
 push bx
 push dx

 or bx,bx
 jg RNDS_OK
 xor ax,ax
 jmp RNDS_DONE          

RNDS_OK:
 mov ax,[RSEED]
 mov dx,25173
 mul dx
 add ax,13849
 mov [RSEED],ax

 ; AX = new seed, BX = n
 mul bx         ; DX:AX = AX * BX
 mov ax,dx      ; 0..n-1
 inc ax         ; 1..n

RNDS_DONE:
 pop dx
 pop bx
 ret
%endif

%ifdef USE_TR
TRIM:
 xor cx,cx
 mov cl,[si]
 inc si
 or cl,cl
 je TRIM_ZERO

TRIM_LEAD:
 cmp BYTE PTR [si],' '
 jne TRIM_HAVE
 inc si
 dec cl
 jne TRIM_LEAD
 jmp TRIM_ZERO

TRIM_HAVE:
 mov bx,si
 add si,cx
 dec si

TRIM_TRAIL:
 or cl,cl
 je TRIM_ZERO
 cmp BYTE PTR [si],' '
 jne TRIM_COPY
 dec si
 dec cl
 jmp TRIM_TRAIL

TRIM_COPY:
 mov [di],cl
 inc di
 mov si,bx
 rep movsb
 ret

TRIM_ZERO:
 mov BYTE PTR [di],0
 ret
%endif

%ifdef USE_MT

; -------------------------------------------------
; SQRS
; In : AX = n
; Out: AX = floor(sqrt(n)); for n < 0: 0
; -------------------------------------------------
SQRS:
 push bx
 push dx
 or ax,ax
 jge SQRS_OK
 xor ax,ax
 jmp SQRS_DONE
SQRS_OK:
 mov bx,ax
 xor ax,ax
 mov dx,1
SQRS_LOOP:
 cmp bx,dx
 jb SQRS_DONE
 sub bx,dx
 inc ax
 add dx,2
 jmp SQRS_LOOP
SQRS_DONE:
 pop dx
 pop bx
 ret

; -------------------------------------------------
; MAXS
; In : AX = first value, BX = second value
; Out: AX = larger value
; -------------------------------------------------
MAXS:
 cmp ax,bx
 jge MAXS_DONE
 mov ax,bx
MAXS_DONE:
 ret

; -------------------------------------------------
; MINS
; In : AX = first value, BX = second value
; Out: AX = smaller value
; -------------------------------------------------
MINS:
 cmp ax,bx
 jle MINS_DONE
 mov ax,bx
MINS_DONE:
 ret

; -------------------------------------------------
; POWS
; In : AX = base, BX = exponent
; Out: AX = base^exponent
; Semantics:
;   exponent < 0  -> runtime abort "NEGATIVE EXPONENT"
;   exponent = 0  -> 1
;   exponent > 0  -> repeated signed 16-bit multiplication
; Overflow is not checked; DX is ignored as with other IMUL use.
; -------------------------------------------------
POWERR:
 db "NEGATIVE EXPONENT"

POWS:
 push bx
 push cx
 push dx
 or bx,bx
 jl POWS_NEG
 jne POWS_NZ
 mov ax,1
 jmp POWS_DONE

POWS_NZ:
 mov cx,bx
 mov bx,ax
 mov ax,1

POWS_LOOP:
 imul bx
 loop POWS_LOOP
 jmp POWS_DONE

POWS_NEG:
 mov dx,OFFSET POWERR
 mov cx,17
 jmp RT_ABORT

POWS_DONE:
 pop dx
 pop cx
 pop bx
 ret
%endif

%ifdef USE_DV
; -------------------------------------------------
; IABSS - checked 16-bit ABS
; In : AX = signed 16-bit value
; Out: AX = absolute value
; Abort: -32768 cannot be represented as positive INTEGER
; -------------------------------------------------
IAROVERR:
 db "INTEGER OVERFLOW"
IARDIVZR:
 db "DIVISION BY ZERO"
IABSS:
 cmp ax,8000h
 je IAR_OVERFLOW
 or ax,ax
 jns IABSS_DONE
 neg ax
IABSS_DONE:
 ret
; -------------------------------------------------
; IDIVS - checked signed 16-bit division
; In : AX = dividend, BX = divisor
; Out: AX = quotient, DX = remainder
; -------------------------------------------------
IDIVS:
 or bx,bx
 je IAR_DIVZERO
 cmp ax,8000h
 jne IDIVS_DO
 cmp bx,-1
 je IAR_OVERFLOW
IDIVS_DO:
 cwd
 idiv bx
 ret
IAR_DIVZERO:
 mov dx,OFFSET IARDIVZR
 mov cx,16
 jmp RT_ABORT
IAR_OVERFLOW:
 mov dx,OFFSET IAROVERR
 mov cx,16
 jmp RT_ABORT
%endif
%ifdef USE_CV
VAL:
 xor ax,ax
 xor bx,bx
 xor cx,cx
 mov cl,[si]
 inc si

VAL_LEAD:
 or cl,cl
 je VAL_DONE
 mov dl,[si]
 cmp dl,' '
 je VAL_LEAD_SKIP
 cmp dl,9
 je VAL_LEAD_SKIP
 cmp dl,'+'
 je VAL_SIGN
 cmp dl,'-'
 jne VAL_CHECK_PREFIX
 mov ch,1

VAL_SIGN:
 inc si
 dec cl

VAL_CHECK_PREFIX:
 or cl,cl
 je VAL_APPLY_SIGN
 mov dl,[si]
 cmp dl,'&'
 je VAL_PREFIX
 jmp VAL_DEC_LOOP

VAL_LEAD_SKIP:
 inc si
 dec cl
 jmp VAL_LEAD

VAL_PREFIX:
 inc si
 dec cl
 or cl,cl
 je VAL_APPLY_SIGN
 mov dl,[si]
 cmp dl,'H'
 je VAL_SET_HEX
 cmp dl,104      ; 'h'
 je VAL_SET_HEX
 cmp dl,'O'
 je VAL_SET_OCT
 cmp dl,111      ; 'o'
 je VAL_SET_OCT
 cmp dl,'B'
 je VAL_SET_BIN
 cmp dl,98       ; 'b'
 je VAL_SET_BIN
 jmp VAL_APPLY_SIGN

VAL_SET_HEX:
 mov bx,16
 jmp VAL_PREFIX_DONE

VAL_SET_OCT:
 mov bx,8
 jmp VAL_PREFIX_DONE

VAL_SET_BIN:
 mov bx,2

VAL_PREFIX_DONE:
 inc si
 dec cl
 jmp VAL_BASE_LOOP

VAL_DEC_LOOP:
 or cl,cl
 je VAL_APPLY_SIGN
 mov dl,[si]
 cmp dl,' '
 je VAL_SKIP
 cmp dl,9
 je VAL_SKIP
 cmp dl,'0'
 jb VAL_APPLY_SIGN
 cmp dl,'9'
 ja VAL_APPLY_SIGN
 sub dl,'0'
 xor dh,dh
 push dx
 mov bx,10
 mul bx
 pop dx
 add ax,dx

VAL_SKIP:
 inc si
 dec cl
 jmp VAL_DEC_LOOP

VAL_BASE_LOOP:
 or cl,cl
 je VAL_APPLY_SIGN
 mov dl,[si]
 cmp dl,' '
 je VAL_BASE_SKIP
 cmp dl,9
 je VAL_BASE_SKIP
 cmp dl,'0'
 jb VAL_APPLY_SIGN
 cmp dl,'9'
 jbe VAL_DIG_NUM
 cmp dl,'A'
 jb VAL_DIG_LOWER
 cmp dl,'F'
 jbe VAL_DIG_UPPER

VAL_DIG_LOWER:
 cmp dl,97       ; 'a'
 jb VAL_APPLY_SIGN
 cmp dl,102      ; 'f'
 ja VAL_APPLY_SIGN
 sub dl,87
 jmp VAL_DIG_OK

VAL_DIG_UPPER:
 sub dl,55
 jmp VAL_DIG_OK

VAL_DIG_NUM:
 sub dl,'0'

VAL_DIG_OK:
 cmp dl,bl
 jae VAL_APPLY_SIGN
 xor dh,dh
 push dx
 mul bx
 pop dx
 add ax,dx

VAL_BASE_SKIP:
 inc si
 dec cl
 jmp VAL_BASE_LOOP

VAL_APPLY_SIGN:
 or ch,ch
 je VAL_DONE
 neg ax

VAL_DONE:
 ret

; -------------------------------------------------
; STRS
; In : AX = signed 16-bit number
;      DI = destination buffer for counted string
; Out: [DI] = length, [DI+1..] = decimal representation
; Semantics: no leading space for positive numbers
; Examples: 0 -> "0", 123 -> "123", -123 -> "-123"
; -------------------------------------------------
STRS:
 push ax
 push bx
 push cx
 push dx
 push si
 push di

 mov si,di
 mov BYTE PTR [si],0

 or ax,ax
 jne STRS_NZ
 mov BYTE PTR [si],1
 mov BYTE PTR [si+1],'0'
 jmp STRS_DONE

STRS_NZ:
 jns STRS_ABS
 mov BYTE PTR [si],1
 mov BYTE PTR [si+1],'-'
 neg ax

STRS_ABS:
 xor cx,cx
 mov bx,10

STRS_DIV:
 xor dx,dx
 div bx
 add dl,'0'
 push dx
 inc cx
 or ax,ax
 jne STRS_DIV

 mov di,si
 xor ax,ax
 mov al,[si]
 add di,ax
 inc di

STRS_OUT:
 pop dx
 mov [di],dl
 inc di
 inc BYTE PTR [si]
 loop STRS_OUT

STRS_DONE:
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_HX
; -------------------------------------------------
; HEXS
; In : AX = 16-bit value, DI = destination counted string
; Out: uppercase hexadecimal without leading zeros
;      0 -> "0"; -1 -> "FFFF"
; -------------------------------------------------
HEXS:
 push bx
 mov bx,16
 call IBASES
 pop bx
 ret
%endif

%ifdef USE_OC
; -------------------------------------------------
; OCTS
; In : AX = 16-bit value, DI = destination counted string
; Out: octal without leading zeros
;      0 -> "0"; -1 -> "177777"
; -------------------------------------------------
OCTS:
 push bx
 mov bx,8
 call IBASES
 pop bx
 ret
%endif

%ifdef USE_BN
; -------------------------------------------------
; BINS
; In : AX = 16-bit value, DI = destination counted string
; Out: binary without leading zeros
;      0 -> "0"; -1 -> "1111111111111111"
; -------------------------------------------------
BINS:
 push bx
 mov bx,2
 call IBASES
 pop bx
 ret
%endif

%ifdef USE_IB
; -------------------------------------------------
; IBASES - shared unsigned 16-bit base conversion
; In : AX = 16-bit value, BX = radix 2/8/16,
;      DI = destination counted string
; Out: counted string without leading zeros, SI not significant
;      digits above 9 are uppercase A..F
; -------------------------------------------------
IBASES:
 push ax
 push cx
 push dx
 push si
 push di
 mov si,di
 mov BYTE [si],0
 or ax,ax
 jne IBASES_NZ
 mov BYTE [si],1
 mov BYTE [si+1],'0'
 jmp IBASES_DONE
IBASES_NZ:
 xor cx,cx
IBASES_DIV:
 xor dx,dx
 div bx
 push dx
 inc cx
 or ax,ax
 jne IBASES_DIV
 mov [si],cl
 inc si
IBASES_OUT:
 pop dx
 mov al,dl
 cmp al,9
 jbe IBASES_DIG
 add al,55
 jmp IBASES_PUT
IBASES_DIG:
 add al,48
IBASES_PUT:
 mov [si],al
 inc si
 loop IBASES_OUT
IBASES_DONE:
 pop di
 pop si
 pop dx
 pop cx
 pop ax
 ret
%endif

%ifdef USE_SR
; -------------------------------------------------
; STRINGS
; In : AX = count
;      BL = character code
;      DI = destination counted string
; Out: string with count repetitions of BL
;      count < 0 -> 0, count > 255 -> 255
; Used by:
;      SPACE$(count)
;      STRING$(count,charCode)
; -------------------------------------------------
STRINGS:
 push ax
 push bx
 push cx
 push di
 or ax,ax
 jge STRINGS_NN
 xor ax,ax
STRINGS_NN:
 cmp ax,255
 jbe STRINGS_LEN
 mov ax,255
STRINGS_LEN:
 mov [di],al
 mov cl,al
 xor ch,ch
 inc di
 mov al,bl
 rep stosb
 pop di
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_IK
; -------------------------------------------------
; INKEYS
; In : DI = destination buffer for counted string
; Out: [DI] = 0, 1 or 2
;      no key:
;          ""
;      normal key:
;          length 1, byte = ASCII
;      special key:
;          length 2, byte1 = 0, byte2 = scan code
; -------------------------------------------------
INKEYS:
    push ax
    push bx
    push cx
    push dx
    push di

; Key available?
; Enhanced keyboard status so cursor/enhanced keys
; are not lost through AH=01h/AH=00h.
mov ah,11h
int 16h
jnz INKEY_HAVE

; no key
mov BYTE PTR [di],0
jmp INKEY_DONE

INKEY_HAVE:
; read key
; Enhanced keyboard read.
mov ah,10h
int 16h

; Ctrl-C
 cmp al,03h
 je INKEY_BREAK


; AL = ASCII or prefix, AH = scan code or prefix
;
; Normal BIOS special key:
;   AL = 0, AH = scan code
;
; Enhanced keyboard variant:
;   AL = 224, AH = scan code
;
; Some BIOS/emulator variants may also
;   AH = 224, AL = scan code
; return this. It is normalized here as well.

cmp al,0
je INKEY_EXT_AH

cmp al,224
je INKEY_EXT_AH

cmp ah,224
je INKEY_EXT_AL

; normal character
mov BYTE PTR [di],1
mov [di+1],al
jmp INKEY_DONE

INKEY_EXT_AH:
; scan code is in AH
mov BYTE PTR [di],2
mov BYTE PTR [di+1],0
mov [di+2],ah
jmp INKEY_DONE

INKEY_EXT_AL:
; scan code is in AL
mov BYTE PTR [di],2
mov BYTE PTR [di+1],0
mov [di+2],al
jmp INKEY_DONE

INKEY_BREAK:
 pop di
 pop dx
 pop cx
 pop bx
 pop ax
 mov al,130
 jmp RT_EXIT_AL

INKEY_DONE:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
%endif


%ifdef USE_IN
INPUTN:
 push di
 xor cx,cx
 inc di
 jmp INPUTS_LOOP

INPUTS:
 push di
 xor cx,cx
 inc di

 ; prompt "? " via BIOS teletype
 push ax
 push bx
 mov ah,0Eh
 mov bh,0
 mov bl,7
 mov al,'?'
 int 10h
 mov al,' '
 int 10h
 pop bx
 pop ax

INPUTS_LOOP:
 ; BIOS blocking keyboard read
 mov ah,00h
 int 16h

 ; Ctrl-C
 cmp al,03h
 je INPUT_BREAK

 ; Ctrl-Break / zero word
 or ax,ax
 je INPUT_BREAK

 ; Ignore special / enhanced keys
 cmp al,0
 je INPUTS_LOOP
 cmp al,224
 je INPUTS_LOOP

 ; Backspace
 cmp al,8
 jne INPUT_NOT_BS
INPUT_BACKSPACE:
 or cl,cl
 je INPUTS_LOOP
 dec di
 dec cl

 ; erase previous character: BS, space, BS
 push ax
 push bx
 mov ah,0Eh
 mov bh,0
 mov bl,7
 mov al,8
 int 10h
 mov al,' '
 int 10h
 mov al,8
 int 10h
 pop bx
 pop ax

 jmp INPUTS_LOOP

INPUT_NOT_BS:
 ; Enter
 cmp al,13
 je INPUTS_DONE

 ; store character
 mov [di],al
 inc di
 inc cl

 ; echo character
 push ax
 push bx
 mov ah,0Eh
 mov bh,0
 mov bl,7
 int 10h
 pop bx
 pop ax

 cmp cl,255
 jne INPUTS_LOOP

 ; Buffer full: consume input until Enter. Backspace reopens one slot.
INPUTS_FULL:
 mov ah,00h
 int 16h
 cmp al,03h
 je INPUT_BREAK
 or ax,ax
 je INPUT_BREAK
 cmp al,0
 je INPUTS_FULL
 cmp al,224
 je INPUTS_FULL
 cmp al,13
 je INPUTS_DONE
 cmp al,8
 je INPUT_BACKSPACE
 jmp INPUTS_FULL

INPUTS_DONE:
 pop di
 mov [di],cl
 mov bx,1
 jmp WRITE_CRLFH

INPUT_BREAK:
 pop di
 mov al,130
 jmp RT_EXIT_AL

RLHERR:
 db "FILE READ ERROR"

READ_LINEH_ERROR:
 mov dx,OFFSET RLHERR
 mov cx,15
 jmp RT_ABORT

READ_LINEH:
 push ax
 push bx
 push cx
 push dx
 push si
 mov si,di
 inc di
 xor cx,cx
RLH_LOOP:
 push cx
 mov ah,3Fh
 mov cx,1
 mov dx,OFFSET NB
 int 21h
 pop cx
 jc READ_LINEH_ERROR
 or ax,ax
 je RLH_DONE
 mov al,[NB]
 cmp al,13
 je RLH_CR
 cmp al,10
 je RLH_DONE
 mov [di],al
 inc di
 inc cl
 cmp cl,255
 jne RLH_LOOP
 ; Preserve the 255-byte result, but consume the rest of this physical line.
RLH_DRAIN:
 push cx
 mov ah,3Fh
 mov cx,1
 mov dx,OFFSET NB
 int 21h
 pop cx
 jc READ_LINEH_ERROR
 or ax,ax
 je RLH_DONE
 mov al,[NB]
 cmp al,10
 je RLH_DONE
 cmp al,13
 jne RLH_DRAIN
RLH_CR:
 ; Consume an optional LF. If the next byte is not LF, seek back one byte.
 push cx
 mov ah,3Fh
 mov cx,1
 mov dx,OFFSET NB
 int 21h
 pop cx
 jc READ_LINEH_ERROR
 or ax,ax
 je RLH_DONE
 cmp BYTE [NB],10
 je RLH_DONE
 push cx
 push dx
 mov ax,4201h
 mov cx,-1
 mov dx,-1
 int 21h
 pop dx
 pop cx
 jc READ_LINEH_ERROR
RLH_DONE:
 mov [si],cl
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_FI
; -------------------------------------------------
; Channel 1..9 -> BL = index 0..8
; In : AL = channel
; Out: BX = index (0..8)
; -------------------------------------------------
CHKC:
 cmp al,1
 jb FI_BADCH
 cmp al,9
 ja FI_BADCH
 dec al
 xor bx,bx
 mov bl,al
 ret

; -------------------------------------------------
; Common handle/mode check
; In : AL = channel, AH = expected mode (1=input, 2=output)
; Out: BX = DOS handle
; -------------------------------------------------
GETHC:
 call CHKC
 mov dl,[FM+bx]
 or dl,dl
 je FI_NOTOPEN
 cmp dl,ah
 jne FI_MODE
 shl bx,1
 mov bx,[FH+bx]
 ret

; -------------------------------------------------
; In : AL = channel
; Out: BX = DOS handle for INPUT
; AX is preserved
; -------------------------------------------------
GETHIN:
 push ax
 mov ah,1
 jmp GETH_IO

; -------------------------------------------------
; In : AL = channel
; Out: BX = DOS handle for OUTPUT
; AX is preserved
; -------------------------------------------------
GETHOUT:
 push ax
 mov ah,2
GETH_IO:
 call GETHC
 mov dx,bx
 pop ax
 mov bx,dx
 ret

; -------------------------------------------------
; In : AL = channel
; Out: AX = EOF status (as before EOFH)
; -------------------------------------------------
EOFC:
 mov ah,1
 call GETHC
 jmp EOFH

; -------------------------------------------------
; In : AL = channel
; Effect: closes channel if open; otherwise no-op
; -------------------------------------------------
CLOSEC:
 call CHKC
 cmp BYTE [FM+bx],0
 je CLOSEC_DONE
 push bx
 shl bx,1
 mov bx,[FH+bx]
%ifdef USE_BI
 call BIFLUSH_IF_BX
%endif
 mov ah,3Eh
 int 21h
 pop bx
 mov BYTE [FM+bx],0
 shl bx,1
 mov WORD [FH+bx],0
CLOSEC_DONE:
 ret

; -------------------------------------------------
; Common file/channel error abort
; In : DX = message, CX = length
; -------------------------------------------------

FI_BADCH:
 mov dx,OFFSET FICHERR
 mov cx,11
 jmp RT_ABORT

FI_NOTOPEN:
 mov dx,OFFSET FINOPERR
 mov cx,16
 jmp RT_ABORT

FI_MODE:
 mov dx,OFFSET FIMODERR
 mov cx,18
 jmp RT_ABORT

FI_INUSE:
 mov dx,OFFSET FIUSEERR
 mov cx,14
 jmp RT_ABORT

FICHERR:
 db "BAD CHANNEL"
FINOPERR:
 db "CHANNEL NOT OPEN"
FIMODERR:
 db "CHANNEL MODE ERROR"
FIUSEERR:
 db "CHANNEL IN USE"

OPENI:
 call CHKC
 cmp BYTE [FM+bx],0
 jne FI_INUSE
 push bx
 mov ah,3Dh
 mov al,0
 int 21h
 jnc OPENI_OK
 mov dx,OFFSET OPNERR
 mov cx,13
 jmp RT_ABORT
OPENI_OK:
 pop bx
 mov BYTE [FM+bx],1
 shl bx,1
 mov [FH+bx],ax
 ret
OPNERR:
 db "NO INPUT FILE"

OPENO:
 call CHKC
 cmp BYTE [FM+bx],0
 jne FI_INUSE
 push bx
 mov ah,3Ch
 xor cx,cx
 int 21h
 jnc OPENO_OK
 mov dx,OFFSET OPOERR
 mov cx,17
 jmp RT_ABORT
OPENO_OK:
 pop bx
 mov BYTE [FM+bx],2
 shl bx,1
 mov [FH+bx],ax
 ret
OPOERR:
 db "OUTPUT FILE ERROR"

KILLF:
 mov ah,41h
 int 21h
 jnc KILLF_OK
 mov dx,OFFSET KILERR
 mov cx,17
 jmp RT_ABORT
KILLF_OK:
 ret

KILERR:
 db "FILE DELETE ERROR"

EXISTF:
 push bx
 push dx
 mov ah,3Dh
 mov al,0
 int 21h
 jc EXISTF_NO
 mov bx,ax
 mov ah,3Eh
 int 21h
 mov ax,1
 pop dx
 pop bx
 ret
EXISTF_NO:
 xor ax,ax
 pop dx
 pop bx
 ret

; CLOSEH:
;   mov ah,3Eh
;   int 21h
;   ret

EOFH:
 push bx
 push cx
 push dx
 push si
 push di
 mov ah,42h
 mov al,1
 xor cx,cx
 xor dx,dx
 int 21h
 jc EOFH_ERROR
 mov si,ax
 mov di,dx
 mov ah,42h
 mov al,2
 xor cx,cx
 xor dx,dx
 int 21h
 jc EOFH_ERROR
 cmp dx,di
 jne EOFH_NO
 cmp ax,si
 jne EOFH_NO
 mov ax,1
 jmp EOFH_RESTORE
EOFH_NO:
 xor ax,ax
EOFH_RESTORE:
 push ax
 mov ah,42h
 mov al,0
 mov cx,di
 mov dx,si
 int 21h
 jc EOFH_RESTORE_ERROR
 pop ax
EOFH_DONE:
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 ret
EOFH_RESTORE_ERROR:
 pop ax
EOFH_ERROR:
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 mov dx,OFFSET EOFERR
 mov cx,15
 jmp RT_ABORT
EOFERR:
 db "FILE SEEK ERROR"
%endif

%ifdef USE_DR
; -------------------------------------------------
; DIRF - common CHDIR/MKDIR/RMDIR DOS call
; In : AH    = DOS function number
;              39h MKDIR, 3Ah RMDIR, 3Bh CHDIR
;      DS:DX = ASCIIZ pathname
; -------------------------------------------------
DIRF:
 push ax
 int 21h
 jnc DIRF_OK
 pop ax
 mov dx,OFFSET DIRERR
 mov cx,15
 jmp RT_ABORT

DIRF_OK:
 pop ax
%ifdef S_CURDIR
 cmp ah,59
 jne DIRF_RET
 call CURDIR_UPDATE
DIRF_RET:
%endif
 ret
DIRERR:
 db "DIRECTORY ERROR"
%endif

%ifdef S_CURDIR
; -------------------------------------------------
; CURDIR_UPDATE
; Effect:
;   Updates S_CURDIR as counted string with current drive/path.
;   Format: "C:\" or "C:\DIR\SUB"
;
; Uses:
;   DOS AH=19h -> current drive, AL=0 for A:
;   DOS AH=47h -> current directory into DS:SI
;                 for DL=0 default drive
; -------------------------------------------------
CURDIR_UPDATE:
 push ax
 push bx
 push cx
 push dx
 push si
 push di

 mov di,OFFSET S_CURDIR

 ; drive letter
 mov ah,19h
 int 21h
 add al,'A'
 mov [di+1],al
 mov BYTE [di+2],':'
 mov BYTE [di+3],'\'

 ; get current directory without drive into S_CURDIR+4
 mov si,di
 add si,4
 mov dl,0
 mov ah,47h
 int 21h
 jc CURDIR_EMPTY

 ; length = 3 + strlen(path returned by AH=47h)
 mov cx,3
CURDIR_LEN:
 cmp BYTE [si],0
 je CURDIR_DONE
 inc si
 inc cx
 cmp cx,255
 jb CURDIR_LEN
 jmp CURDIR_DONE

CURDIR_EMPTY:
 mov cx,3

CURDIR_DONE:
 mov [di],cl

 pop di
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_FL
; -------------------------------------------------
; FILESF - QuickBASIC-style FILES [filespec$]
; In : DS:DX = ASCIIZ filespec, or FLSALL for default *.*
; Out: writes matching file names to DOS stdout, one per line
;
; DTA layout used here:
;   FLDTA+21 = attribute byte of matching file
;   FLDTA+30 = ASCIIZ filename
;
; Attribute mask:
;   CX = 10h -> include directory entries in addition to normal files
; -------------------------------------------------
FILESF:
 ; Save caller DTA.
 push es
 mov ah,2Fh
 int 21h
 mov [FLDTA_OLD_OFF],bx
 mov ax,es
 mov [FLDTA_OLD_SEG],ax
 pop es

 ; Install private DTA for this search.
 push dx
 mov dx,OFFSET FLDTA
 mov ah,1Ah
 int 21h
 pop dx

 mov cx,10h
 mov ah,4Eh
 int 21h
 jc FILES_DONE

FILES_LOOP:
 call FILES_PRINT
 mov ah,4Fh
 int 21h
 jnc FILES_LOOP

FILES_DONE:
 ; Restore caller DTA on every exit path.
 mov dx,[FLDTA_OLD_OFF]
 mov ax,[FLDTA_OLD_SEG]
 push ds
 mov ds,ax
 mov ah,1Ah
 int 21h
 pop ds
 ret

FILES_PRINT:
 push ax
 push bx
 push cx
 push dx
 push si

 mov si,OFFSET FLDTA+30

 ; skip "."
 cmp BYTE [si],'.'
 jne FILES_NOT_DOT
 cmp BYTE [si+1],0
 je FILES_PR_DONE

 ; skip ".."
 cmp BYTE [si+1],'.'
 jne FILES_NOT_DOT
 cmp BYTE [si+2],0
 je FILES_PR_DONE

FILES_NOT_DOT:
 xor cx,cx

FILES_LEN:
 cmp BYTE [si],0
 je FILES_OUT_NAME
 inc si
 inc cx
 cmp cx,13
 jb FILES_LEN

FILES_OUT_NAME:
 ; If directory attribute bit is set, print [name]
 mov si,OFFSET FLDTA
 mov al,[si+21]
 and al,10h
 je FILES_OUT_PL

 ; Directory: write "["
 push cx
 mov dx,OFFSET FLBRA
 mov cx,1
 mov bx,1
 mov ah,40h
 int 21h
 pop cx

 ; Directory: write name
 mov dx,OFFSET FLDTA+30
 mov bx,1
 mov ah,40h
 int 21h

 ; Directory: write "]"
 mov dx,OFFSET FLBRZ
 mov cx,1
 mov bx,1
 mov ah,40h
 int 21h

 jmp FILES_CRLF

FILES_OUT_PL:
 ; Normal file: write name only
 mov dx,OFFSET FLDTA+30
 mov bx,1
 mov ah,40h
 int 21h

FILES_CRLF:
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h

FILES_PR_DONE:
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret

FLBRA:
 db "["
FLBRZ:
 db "]"
%endif

%ifdef USE_SO
CATTR db 07h

COLORC:
 push ax
 push bx
 and al,0Fh
 and bl,07h
 shl bl,1
 shl bl,1
 shl bl,1
 shl bl,1
 or al,bl
 mov [CATTR],al
 pop bx
 pop ax
 ret

CLSCR:
 mov ax,0600h
 mov bh,[CATTR]
 xor cx,cx
 mov dx,184Fh
 int 10h
 mov ax,0200h
 xor bx,bx
 xor dx,dx
 int 10h
 ret
 
LOCATEC:
 cmp ax,1
 jb LOCATEC_DONE
 cmp ax,25
 ja LOCATEC_DONE
 cmp bx,1
 jb LOCATEC_DONE
 cmp bx,80
 ja LOCATEC_DONE
 dec ax
 dec bx
 xor dx,dx
 mov dh,al
 mov dl,bl
 xor bx,bx
 mov ah,02h
 int 10h
LOCATEC_DONE:
 ret

%endif

%ifdef USE_GR
; =================================================
; SCREEN / PSET graphics support
;
; SCREENC: AX = BASIC screen mode
;   0 -> BIOS mode 03h, 1 -> 04h, 2 -> 06h,
;   all other values are passed in AL as BIOS mode.
;
;   supported modes:
;   SCREEN 0  -> BIOS mode 03h
;   SCREEN 1  -> BIOS mode 04h
;   SCREEN 2  -> BIOS mode 06h
;   SCREEN 13 -> BIOS mode 13h
;
; PSETC: AX = x, BX = y, DX = color
;   Uses BIOS INT 10h AH=0Ch, page 0.
;
;   CIRCLEC: AX = center x, BX = center y, CX = radius, DX = color
;   Draws an integer outline circle using PSETC.
;
;   CIRCLEAC: AX = center x, BX = center y, CX = radius, DX = color,
;             SI = aspect_scaled, where 256 means 1.0.
;   Draws an integer outline ellipse by scaling the y offsets:
;       y' = y * aspect_scaled / 256
;
; =================================================
GR_USED db 0

SCREENC:
 or ax,ax
 jne SCR_N0
 mov BYTE [GR_USED],0
 mov al,3
 jmp SCR_SET
SCR_N0:
 mov BYTE [GR_USED],1
 cmp ax,1
 jne SCR_N1
 mov al,4
 jmp SCR_SET
SCR_N1:
 cmp ax,2
 jne SCR_SET
 mov al,6
SCR_SET:
 mov ah,00h
 int 10h
 ret

PSETC:
 push ax
 push bx
 push cx
 push dx
 mov cx,ax
 xchg ax,dx
 mov dx,bx
 xor bx,bx
 mov ah,0Ch
 int 10h
 pop dx
 pop cx
 pop bx
 pop ax
 ret

; -------------------------------------------------
; CIRCLEC
; In:
;   AX = center x
;   BX = center y
;   CX = radius
;   DX = color
; Effect:
;   Draws an outline circle using integer midpoint algorithm.
;   Uses PSETC internally.
;   Negative radius draws nothing.
;
; CIRCLEAC
; In:
;   AX = center x
;   BX = center y
;   CX = radius
;   DX = color
;   SI = aspect_scaled, 256 = 1.0
; Effect:
;   Draws an outline ellipse by scaling vertical offsets:
;      y' = y * aspect_scaled / 256
;
; Notes:
;   CIRCLEC remains backward compatible. It sets SI=256 and then
;   calls CIRCLEAC, so existing compiler output still draws circles.
; -------------------------------------------------
GC_CX   dw 0
GC_CY   dw 0
GC_COL  dw 0
GC_X    dw 0
GC_Y    dw 0
GC_D    dw 0
GC_ASP  dw 0
GC_XS   dw 0
GC_YS   dw 0

CIRCLEC:
 push si
 mov si,256
 call CIRCLEAC
 pop si
 ret

CIRCLEAC:
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 or cx,cx
 jl CIRCLEC_DONE

 or si,si
 jge CIRCLEC_ASP_OK
 neg si
CIRCLEC_ASP_OK:
 mov [GC_ASP],si

 mov [GC_CX],ax
 mov [GC_CY],bx
 mov [GC_COL],dx
 mov WORD [GC_X],0
 mov [GC_Y],cx

 ; d = 3 - 2*r
 mov ax,3
 sub ax,cx
 sub ax,cx
 mov [GC_D],ax

CIRCLE_LOOP:
 mov ax,[GC_X]
 mov bx,[GC_Y]
 cmp ax,bx
 jg CIRCLEC_DONE

 call CIRCLE_PLOT8

 mov ax,[GC_D]
 or ax,ax
 jge CIRCLE_DECY

 ; d = d + 4*x + 6
 mov ax,[GC_X]
 shl ax,1
 shl ax,1
 add ax,6
 add [GC_D],ax
 jmp CIRCLE_INCX

CIRCLE_DECY:
 ; d = d + 4*(x-y) + 10
 mov ax,[GC_X]
 mov bx,[GC_Y]
 sub ax,bx
 shl ax,1
 shl ax,1
 add ax,10
 add [GC_D],ax

 dec WORD [GC_Y]

CIRCLE_INCX:
 inc WORD [GC_X]
 jmp CIRCLE_LOOP

CIRCLEC_DONE:
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret

; -------------------------------------------------
; CIRCLE_SCALEY
; In : AX = non-negative circle offset
; Out: AX = floor(AX * GC_ASP / 256)
; Uses unsigned multiplication. GC_ASP is normalized
; to non-negative in CIRCLEAC.
; -------------------------------------------------
CIRCLE_SCALEY:
 push bx
 push dx
 mov bx,[GC_ASP]
 cmp bx,256
 jne CIRCLE_SCALEY_CALC
 pop dx
 pop bx
 ret

CIRCLE_SCALEY_CALC:
 mul bx
 mov al,ah
 mov ah,dl
 pop dx
 pop bx
 ret

; -------------------------------------------------
; CIRCLE_PLOT8
; Plots the eight symmetric points for current GC_X/GC_Y.
; Uses PSETC.
; For aspect ellipses, vertical offsets are scaled:
;   GC_YS = GC_Y * GC_ASP / 256
;   GC_XS = GC_X * GC_ASP / 256
; -------------------------------------------------
CIRCLE_PLOT8:
 mov si,[GC_X]
 mov di,[GC_Y]

 ; Scale y offsets for aspect ellipse.
 mov ax,di
 call CIRCLE_SCALEY
 mov [GC_YS],ax
 mov ax,si
 call CIRCLE_SCALEY
 mov [GC_XS],ax
 mov dx,[GC_COL]

 ; cx+x, cy+y'
 mov ax,[GC_CX]
 add ax,si
 mov bx,[GC_CY]
 add bx,[GC_YS]
 call PSETC

 ; cx-x, cy+y'
 mov ax,[GC_CX]
 sub ax,si
 mov bx,[GC_CY]
 add bx,[GC_YS]
 call PSETC

 ; cx+x, cy-y'
 mov ax,[GC_CX]
 add ax,si
 mov bx,[GC_CY]
 sub bx,[GC_YS]
 call PSETC

 ; cx-x, cy-y'
 mov ax,[GC_CX]
 sub ax,si
 mov bx,[GC_CY]
 sub bx,[GC_YS]
 call PSETC

 ; cx+y, cy+x'
 mov ax,[GC_CX]
 add ax,di
 mov bx,[GC_CY]
 add bx,[GC_XS]
 call PSETC

 ; cx-y, cy+x'
 mov ax,[GC_CX]
 sub ax,di
 mov bx,[GC_CY]
 add bx,[GC_XS]
 call PSETC

 ; cx+y, cy-x'
 mov ax,[GC_CX]
 add ax,di
 mov bx,[GC_CY]
 sub bx,[GC_XS]
 call PSETC

 ; cx-y, cy-x'
 mov ax,[GC_CX]
 sub ax,di
 mov bx,[GC_CY]
 sub bx,[GC_XS]
 call PSETC
 ret

; -------------------------------------------------
; GR_RESET
; Effect:
;   If SCREEN was used, restore text mode 03h.
;   BIOS mode set to 03h also clears the screen.
; -------------------------------------------------
GR_RESET:
 cmp BYTE [GR_USED],0
 je GR_RESET_DONE
 mov BYTE [GR_USED],0
 mov ax,0003h
 int 10h
GR_RESET_DONE:
 ret
%endif

%ifdef USE_LN
; -------------------------------------------------
; LINEC
; In:
;   AX = x1
;   BX = y1
;   CX = x2
;   DX = y2
;   SI = color
;   DI = mode
;        0 = line
;        1 = box
;        2 = filled box
; Effect:
;   Draws a line, rectangle, or filled rectangle.
;   Uses PSETC internally.
; -------------------------------------------------

GL_X1   dw 0
GL_Y1   dw 0
GL_X2   dw 0
GL_Y2   dw 0
GL_OX1  dw 0
GL_OY1  dw 0
GL_OX2  dw 0
GL_OY2  dw 0
GL_COL  dw 0
GL_DX   dw 0
GL_DY   dw 0
GL_SX   dw 0
GL_SY   dw 0
GL_ERR  dw 0
GL_E2   dw 0
GL_YC   dw 0

LINEC:
 push ax
 push bx
 push cx
 push dx
 push si
 push di

 mov [GL_OX1],ax
 mov [GL_OY1],bx
 mov [GL_OX2],cx
 mov [GL_OY2],dx
 mov [GL_COL],si

 cmp di,1
 je LINEC_BOX
 cmp di,2
 je LINEC_FILL

 mov [GL_X1],ax
 mov [GL_Y1],bx
 mov [GL_X2],cx
 mov [GL_Y2],dx
 call LINE_D_STORED
 jmp LINEC_DONE

LINEC_BOX:
 ; top: (x1,y1)-(x2,y1)
 mov ax,[GL_OX1]
 mov [GL_X1],ax
 mov ax,[GL_OY1]
 mov [GL_Y1],ax
 mov ax,[GL_OX2]
 mov [GL_X2],ax
 mov ax,[GL_OY1]
 mov [GL_Y2],ax
 call LINE_D_STORED

 ; right: (x2,y1)-(x2,y2)
 mov ax,[GL_OX2]
 mov [GL_X1],ax
 mov ax,[GL_OY1]
 mov [GL_Y1],ax
 mov ax,[GL_OX2]
 mov [GL_X2],ax
 mov ax,[GL_OY2]
 mov [GL_Y2],ax
 call LINE_D_STORED

 ; bottom: (x2,y2)-(x1,y2)
 mov ax,[GL_OX2]
 mov [GL_X1],ax
 mov ax,[GL_OY2]
 mov [GL_Y1],ax
 mov ax,[GL_OX1]
 mov [GL_X2],ax
 mov ax,[GL_OY2]
 mov [GL_Y2],ax
 call LINE_D_STORED

 ; left: (x1,y2)-(x1,y1)
 mov ax,[GL_OX1]
 mov [GL_X1],ax
 mov ax,[GL_OY2]
 mov [GL_Y1],ax
 mov ax,[GL_OX1]
 mov [GL_X2],ax
 mov ax,[GL_OY1]
 mov [GL_Y2],ax
 call LINE_D_STORED

 jmp LINEC_DONE

LINEC_FILL:
 ; normalize x1/x2
 mov ax,[GL_OX1]
 mov cx,[GL_OX2]
 cmp ax,cx
 jle LINEC_FILL_XOK
 mov bx,[GL_OX2]
 mov [GL_OX1],bx
 mov [GL_OX2],ax
LINEC_FILL_XOK:

 ; normalize y1/y2
 mov ax,[GL_OY1]
 mov cx,[GL_OY2]
 cmp ax,cx
 jle LINEC_FILL_YOK
 mov bx,[GL_OY2]
 mov [GL_OY1],bx
 mov [GL_OY2],ax
LINEC_FILL_YOK:

 mov ax,[GL_OY1]
 mov [GL_YC],ax

LINEC_FL_LOOP:
 mov ax,[GL_YC]
 mov cx,[GL_OY2]
 cmp ax,cx
 jg LINEC_DONE

 mov ax,[GL_OX1]
 mov [GL_X1],ax
 mov ax,[GL_YC]
 mov [GL_Y1],ax
 mov ax,[GL_OX2]
 mov [GL_X2],ax
 mov ax,[GL_YC]
 mov [GL_Y2],ax

 call LINE_D_STORED

 inc WORD [GL_YC]
 jmp LINEC_FL_LOOP

LINEC_DONE:
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret

; -------------------------------------------------
; LINE_D_STORED
; Uses:
;   GL_X1, GL_Y1, GL_X2, GL_Y2, GL_COL
; Draws line using integer Bresenham.
; Mutates GL_X1 / GL_Y1 while drawing.
; Avoids ALU reg,[mem] forms for BASM compatibility.
; -------------------------------------------------
LINE_D_STORED:
 ; dx = abs(x2-x1), sx = sign(x2-x1)
 mov ax,[GL_X2]
 sub ax,[GL_X1]
 mov WORD [GL_SX],1
 or ax,ax
 jge LDS_DX_OK
 neg ax
 mov WORD [GL_SX],-1
LDS_DX_OK:
 mov [GL_DX],ax

 ; dy = -abs(y2-y1), sy = sign(y2-y1)
 mov ax,[GL_Y2]
 sub ax,[GL_Y1]
 mov WORD [GL_SY],1
 or ax,ax
 jge LDS_DY_POS
 neg ax
 mov WORD [GL_SY],-1
LDS_DY_POS:
 neg ax
 mov [GL_DY],ax

 ; err = dx + dy
 mov ax,[GL_DX]
 add ax,[GL_DY]
 mov [GL_ERR],ax

LDS_LOOP:
 ; plot current point
 mov ax,[GL_X1]
 mov bx,[GL_Y1]
 mov dx,[GL_COL]
 call PSETC

 ; done if current == target
 mov ax,[GL_X1]
 cmp ax,[GL_X2]
 jne LDS_CONT
 mov ax,[GL_Y1]
 cmp ax,[GL_Y2]
 je LDS_DONE

LDS_CONT:
 ; e2 = 2*err
 mov ax,[GL_ERR]
 add ax,ax
 mov [GL_E2],ax

 ; if e2 >= dy then err += dy, x += sx
 mov ax,[GL_E2]
 cmp ax,[GL_DY]
 jl LDS_SKIP_X

 mov ax,[GL_DY]
 add [GL_ERR],ax

 mov ax,[GL_SX]
 add [GL_X1],ax

LDS_SKIP_X:
 ; if e2 <= dx then err += dx, y += sy
 mov ax,[GL_E2]
 cmp ax,[GL_DX]
 jg LDS_SKIP_Y

 mov ax,[GL_DX]
 add [GL_ERR],ax

 mov ax,[GL_SY]
 add [GL_Y1],ax

LDS_SKIP_Y:
 jmp LDS_LOOP

LDS_DONE:
 ret
%endif

%ifdef USE_PR
WRITE_RAW:
%ifdef USE_SO
 cmp bx,1
 jne WRITE_RAW_DOS
 push ax
 push bx
 push cx
 push dx
 push bp
 push es
 xor cx,cx
 mov cl,[si]
 inc si
 or cx,cx
 je WRITE_RAW_CD
 push cx              ; save string length
 mov ah,03h
 xor bh,bh
 int 10h              ; BIOS overwrites CH/CL
 pop cx               ; restore string length
 push ds
 pop es
 mov bp,si
 mov bl,[CATTR]
 mov ax,1301h
 xor bh,bh
 int 10h
WRITE_RAW_CD:
 pop es
 pop bp
 pop dx
 pop cx
 pop bx
 pop ax
 ret
WRITE_RAW_DOS:
%endif
 push bx
 push cx
 push dx
%ifdef USE_BI
 call BIFLUSH_IF_BX
%endif
 xor cx,cx
 mov cl,[si]
 inc si
 mov dx,si
 mov ah,40h
 int 21h
 pop dx
 pop cx
 pop bx
 ret
WRITE_CRLFH:
 push ax
 push cx
 push dx
%ifdef USE_BI
 call BIFLUSH_IF_BX
%endif
 mov dx,OFFSET C
 mov cx,2
 mov ah,40h
 int 21h
 pop dx
 pop cx
 pop ax
 ret
%ifdef USE_FI
WRITE_RAWCRLF2:
 mov al,2
 call GETHOUT
 call WRITE_RAW
 jmp WRITE_CRLFH
%endif
%endif

%ifdef USE_PN
WRITE_CHH:
%ifdef USE_SO
 cmp bx,1
 jne WRITE_CHH_DOS
 push ax
 push bx
 push cx
 push dx
 push bp
 push es
 mov [NB],al
 mov ah,03h
 xor bh,bh
 int 10h
 push ds
 pop es
 mov bp,OFFSET NB
 mov cx,1
 mov bl,[CATTR]
 mov ax,1301h
 xor bh,bh
 int 10h
 pop es
 pop bp
 pop dx
 pop cx
 pop bx
 pop ax
 ret
WRITE_CHH_DOS:
%endif
push cx
 push dx
%ifdef USE_BI
 call BIFLUSH_IF_BX
%endif
 mov [NB],al
 mov dx,OFFSET NB
 mov cx,1
 mov ah,40h
 int 21h
 pop dx
 pop cx
 ret

WRITE_NUMH:
 push ax
 push bx
 push cx
 push dx
 push si
 mov si,bx
 or ax,ax
 jne WNH_CH_SIGN
 mov al,'0'
 mov bx,si
 call WRITE_CHH
 jmp WNH_DONE
WNH_CH_SIGN:
 jns WNH_NONZERO
 push ax
 mov al,'-'
 mov bx,si
 call WRITE_CHH
 pop ax
 neg ax
WNH_NONZERO:
 xor cx,cx
 mov bx,10
WNH_LOOP:
 xor dx,dx
 div bx
 push dx
 inc cx
 or ax,ax
 jne WNH_LOOP
WNH_OUT:
 pop dx
 mov al,dl
 add al,'0'
 mov bx,si
 call WRITE_CHH
 loop WNH_OUT
WNH_DONE:
 pop si
 pop dx
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_BI
; ---- buffered byte output
BIBUF: times 255 db 0
BILEN db 0
BIBH  dw 0   ; current handle for buffer

SEEK_BYTEH:
 cmp ax,1
 jb SEEKB_BADPOS
 dec ax
 call BIFLUSH_IF_BX
 push cx
 push dx
 xor cx,cx
 mov dx,ax
 mov ah,42h
 mov al,0
 int 21h
 pop dx
 pop cx
 jnc SEEKB_OK
SEEKB_BADPOS:
 mov dx,OFFSET BI_POSERR
 mov cx,12
 jmp RT_ABORT
SEEKB_OK:
 ret

READ_BYTEH:
 push bx
 push cx
 push dx
 mov ah,3Fh
 mov cx,1
 mov dx,OFFSET NB
 int 21h
 jc READB_ERR
 or ax,ax
 je READB_EOF
 cmp ax,1
 jne READB_ERR
 xor ah,ah
 mov al,[NB]
 pop dx
 pop cx
 pop bx
 ret
READB_EOF:
 pop dx
 pop cx
 pop bx
 mov dx,OFFSET BI_EOFERR
 mov cx,13
 jmp RT_ABORT
READB_ERR:
 pop dx
 pop cx
 pop bx
 mov dx,OFFSET BI_RDERR
 mov cx,15
 jmp RT_ABORT

WRITE_BYTEH:
 or ah,ah
 jne WRITEB_VALERR
 push bx
 push cx
 push dx
 push di
 cmp BYTE [BILEN],0
 je WRITEB_SETH
 cmp bx,[BIBH]
 je WRITEB_APPEND
 ; different handle -> write old buffer
 call BIFLUSH
WRITEB_SETH:
 mov [BIBH],bx
WRITEB_APPEND:
 mov di,OFFSET BIBUF
 xor cx,cx
 mov cl,[BILEN]
 add di,cx
 mov [di],al
 inc BYTE [BILEN]
 cmp BYTE [BILEN],255
 jne WRITEB_DONE
 call BIFLUSH
WRITEB_DONE:
 pop di
 pop dx
 pop cx
 pop bx
 ret
 
WRITEB_VALERR:
 mov dx,OFFSET BVERR
 mov cx,16
 jmp RT_ABORT

; -------------------------------------------------
; BIFLUSH - writes buffered byte block
; -------------------------------------------------
BIFLUSH:
 push ax
 push bx
 push cx
 push dx

 cmp BYTE [BILEN],0
 je BIFLUSH_DONE

 mov bx,[BIBH]
 mov dx,OFFSET BIBUF
 xor cx,cx
 mov cl,[BILEN]
 mov ah,40h
 int 21h
 jc BIFLUSH_ERR
 cmp ax,cx
 jne BIFLUSH_ERR

 mov BYTE [BILEN],0

BIFLUSH_DONE:
 pop dx
 pop cx
 pop bx
 pop ax
 ret

BIFLUSH_ERR:
 pop dx
 pop cx
 pop bx
 pop ax
 ; Avoid retrying the same failed buffer from RT_ABORT -> RT_EXIT_AL.
 mov BYTE [BILEN],0
 mov dx,OFFSET BI_WRERR
 mov cx,16
 jmp RT_ABORT
 
 
; -------------------------------------------------
; BIFLUSH_IF_BX - flush only if the handle matches
; -------------------------------------------------
BIFLUSH_IF_BX:
 push ax
 cmp BYTE [BILEN],0
 je BIFIB_DONE
 cmp bx,[BIBH]
 jne BIFIB_DONE
 pop ax
 jmp BIFLUSH

BIFIB_DONE:
 pop ax
 ret

BI_POSERR:
 db "BAD FILE POS"
BI_EOFERR:
 db "READ PAST EOF"
BI_RDERR:
 db "FILE READ ERROR"
BI_WRERR:
 db "FILE WRITE ERROR"
%endif

%ifdef USE_PK
; =================================================
; PEEK / POKE / DEF SEG
;
; PEEKD:
;   In : BX = Offset
;   Out: AX = byte 0..255 from PSEG:BX
;
; PEEKC:
;   In : AX = segment, BX = Offset
;   Out: AX = byte 0..255 from AX:BX
;
; POKED:
;   In : BX = offset, CX = byte value 0..255
;   Effect: writes CL to PSEG:BX
;
; POKEC:
;   In : AX = segment, BX = offset, CX = byte value 0..255
;   Effect: writes CL to AX:BX
;
; DEFSEGC:
;   In : AX = new DEF SEG segment
;
; DEFSEGR:
;   Effect: reset DEF SEG to the program segment
; =================================================

DEFSEGR:
 push cs
 pop ax
 mov [PSEG],ax
 ret

DEFSEGC:
 mov [PSEG],ax
 ret

PEEKD:
 mov ax,[PSEG]

PEEKC:
 push es
 mov es,ax
 xor ax,ax
 mov al,[es:bx]
 pop es
 ret

POKED:
 mov ax,[PSEG]

POKEC:
 or ch,ch
 jne PK_VALERR
 push es
 mov es,ax
 mov [es:bx],cl
 pop es
 ret

PK_VALERR:
 mov dx,OFFSET BVERR
 mov cx,16
 jmp RT_ABORT

%endif

%ifdef USE_IO
; =================================================
; INP / OUT port I/O
;
; INPC:
;   In : DX = port
;   Out: AX = byte 0..255 read from port
;
; OUTC:
;   In : DX = port
;        AX = byte value 0..255
;   Effect: writes AL to port DX
; =================================================

INPC:
 DB 236              ; IN AL,DX
 xor ah,ah
 ret

OUTC:
 or ah,ah
 jne IO_VALERR
 DB 238              ; OUT DX,AL
 ret

IO_VALERR:
 mov dx,OFFSET BVERR
 mov cx,16
 jmp RT_ABORT

%endif

%ifdef USE_XA
; =================================================
; XA - External String Array Runtime
;
; Handles : 1..16
; index   : 1..Count
;
; XALLOC(count)         -> maxlen = 255, slot = 256 Bytes
; XALLOC(count,maxlen)  -> slot = maxlen + 1 Bytes
;
; String format per slot:
;   Byte 0      = length 0..maxlen
;   Byte 1..n   = payload data
;
; Safety rules:
;   count  : 1..32767
;   maxlen : 1..255, BX=0 means default 255
;   count * (maxlen+1) <= 65536
; =================================================

XAERR:
 db "XARRAY ERROR"


; -------------------------------------------------
; XAALLOC
; In : AX = number of strings
;      BX = max. payload length
;           BX=0 -> default 255
; Out: AX = handle 1..16, AX=0 on error
; -------------------------------------------------
XAALLOC:
 call MEMINIT
 jc XAALLOC_MEMFAIL
 push bx
 push cx
 push dx
 push si
 push di
 push bp

 cmp ax,1
 jb XAALLOC_FAIL
 cmp ax,32767
 ja XAALLOC_FAIL

 mov cx,ax              ; CX = Count

 or bx,bx
 jne XAALLOC_LN_GVN
 mov bx,255             ; default maxlen

XAALLOC_LN_GVN:
 cmp bx,1
 jb XAALLOC_FAIL
 cmp bx,255
 ja XAALLOC_FAIL

 inc bx                 ; BX = slot size = maxlen+1
 mov bp,bx              ; BP = slot size

 ; Bytes = Count * slot size
 mov ax,cx
 mul bp                 ; DX:AX = Count * slot size

 ; allowed: at most 65536 bytes
 or dx,dx
 jne XAALLOC_CHK64K

 ; Bytes < 65536
 add ax,15
 jc XAALLOC_FAIL
 mov bx,ax
 shr bx,1
 shr bx,1
 shr bx,1
 shr bx,1
 jmp XAALLOC_HVPRS

XAALLOC_CHK64K:
 cmp dx,1
 jne XAALLOC_FAIL
 or ax,ax
 jne XAALLOC_FAIL
 mov bx,4096            ; exactly 65536 bytes

XAALLOC_HVPRS:
 ; find free slot 0..15
 mov si,OFFSET XASEG
 xor dx,dx              ; DX = slot number 0..15

XAALLOC_FIND:
 cmp WORD [si],0
 je XAALLOC_FOUND
 add si,2
 inc dx
 cmp dx,16
 jb XAALLOC_FIND
 jmp XAALLOC_FAIL

XAALLOC_FOUND:
 ; BX = Paragraphs
 ; CX = Count
 ; BP = slot size
 ; DX = slot number
 push ds
 push es
 push si
 push cx
 push dx
 push bp
 mov ah,48h
 int 21h
 pop bp
 pop dx
 pop cx
 pop si
 pop es
 pop ds
 jc XAALLOC_FAIL

 mov [si],ax            ; save segment

 mov bx,dx
 shl bx,1
 mov [XACNT+bx],cx      ; save count
 mov [XALEN+bx],bp      ; slot size save

 mov ax,dx
 inc ax                 ; handle = slot + 1
 jmp XAALLOC_DONE

XAALLOC_MEMFAIL:
 xor ax,ax
 ret
XAALLOC_FAIL:
 xor ax,ax

XAALLOC_DONE:
 pop bp
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 ret

; -------------------------------------------------
; XAPTR
; In : AX = handle 1..16
;      BX = index 1..Count
; Out: ES:DI = slot address
;      CX    = max. payload length
; error: runtime abort
; -------------------------------------------------
XAPTR:
 push ax
 push bx
 push si

 cmp ax,1
 jb XAPTR_ERR
 cmp ax,16
 ja XAPTR_ERR
 cmp bx,1
 jb XAPTR_ERR

 dec ax
 mov si,ax
 shl si,1               ; SI = table offset

 cmp WORD [XASEG+si],0
 je XAPTR_ERR

 cmp bx,[XACNT+si]
 ja XAPTR_ERR

 mov ax,[XASEG+si]
 mov es,ax

 ; Offset = (index-1) * slot size
 dec bx
 mov ax,bx
 mov bx,[XALEN+si]
 mul bx                 ; DX:AX = Offset
 or dx,dx
 jne XAPTR_ERR

 mov di,ax
 mov cx,bx
 dec cx                 ; CX = max. payload length

 pop si
 pop bx
 pop ax
 ret

XAPTR_ERR:
 mov dx,OFFSET XAERR
 mov cx,12
 jmp RT_ABORT

; -------------------------------------------------
; XACOPY_2EXT
; In : DS:SI = source, counted string
;      ES:DI = destination slot
;      CX = maximum payload length of destination slot
;
; Effect:
;   Copies at most CX payload bytes.
;   Overlong strings are truncated.
; -------------------------------------------------
XACOPY_2EXT:
 push ax
 push cx
 push si
 push di

 lodsb                  ; AL = source length
 cmp al,cl
 jbe XACTE_LEN_OK
 mov al,cl              ; truncate to slot payload length

XACTE_LEN_OK:
 stosb                  ; destination length byte
 mov cl,al
 or cl,cl
 je XACTE_DONE
 rep movsb

XACTE_DONE:
 pop di
 pop si
 pop cx
 pop ax
 ret

; -------------------------------------------------
; XACOPY_EXT
; In : ES:SI = source slot
;      DS:DI = destination counted string
;      CX = maximum payload length of source slot
;
; Effect:
;   Robust against corrupt length bytes:
;   reads at most CX payload bytes.
; -------------------------------------------------
XACOPY_EXT:
 push ax
 push cx
 push si
 push di

 mov al,[es:si]
 cmp al,cl
 jbe XACFE_LEN_OK
 mov al,cl

XACFE_LEN_OK:
 mov [di],al
 inc si
 inc di
 mov cl,al
 or cl,cl
 je XACFE_DONE

XACFE_LOOP:
 mov al,[es:si]
 mov [di],al
 inc si
 inc di
 loop XACFE_LOOP

XACFE_DONE:
 pop di
 pop si
 pop cx
 pop ax
 ret

; -------------------------------------------------
; XASET
; In : AX = handle
;      BX = index
;      DS:SI = source
; -------------------------------------------------
XASET:
 push es
 push si
 call XAPTR             ; ES:DI = destination, CX = maxlen
 pop si
 call XACOPY_2EXT
 pop es
 ret

; -------------------------------------------------
; XAGET
; In : AX = handle
;      BX = index
;      DS:DI = destination
; -------------------------------------------------
XAGET:
 push es
 push di
 call XAPTR             ; ES:DI = source, CX = maxlen
 mov si,di              ; ES:SI = source
 pop di                 ; DS:DI = destination
 call XACOPY_EXT
 pop es
 ret

; -------------------------------------------------
; XAFREE
; In : AX = handle 1..16
; Effect: frees external string array
; -------------------------------------------------
XAFREE:
 push ax
 push bx
 push si
 push es

 cmp ax,1
 jb XAFREE_ERR
 cmp ax,16
 ja XAFREE_ERR

 dec ax
 mov si,ax
 shl si,1

 cmp WORD [XASEG+si],0
 je XAFREE_ERR

 mov ax,[XASEG+si]
 mov es,ax

 push si
 mov ah,49h
 int 21h
 pop si
 jc XAFREE_ERR

 mov WORD [XASEG+si],0
 mov WORD [XACNT+si],0
 mov WORD [XALEN+si],0

 pop es
 pop si
 pop bx
 pop ax
 ret

XAFREE_ERR:
 mov dx,OFFSET XAERR
 mov cx,12
 jmp RT_ABORT

%endif

%ifdef USE_AR
; =================================================
; Arrays
;
; Small INT arrays:
;   [si]/[di] = element count 1..127
;   elements from offset +1 as signed 16-bit words
;
; Large INT arrays:
;   [si]/[di]     = 255  ; marker for external array
;   [si+1]/[di+1] = handle 1..16
;
; External INT arrays use DOS memory:
;   XISEG[slot] = segment
;   XICNT[slot] = element count
; =================================================

XISEG: times 16 dw 0
XICNT: times 16 dw 0

; -------------------------------------------------
; Common array error output
; Expected:
;   DX = message
;   CX = length
; -------------------------------------------------

ARR_SIZE_ERR:
 mov dx,OFFSET ARRDERR
 mov cx,14
 jmp RT_ABORT

ARR_INDEX_ERR:
 mov dx,OFFSET ARRIERR
 mov cx,17
 jmp RT_ABORT

ARR_MEM_ERR:
 mov dx,OFFSET ARRMERR
 mov cx,18
 jmp RT_ABORT

ARRDERR:
 db "BAD ARRAY SIZE"

ARRIERR:
 db "ARRAY INDEX ERROR"

ARRMERR:
 db "ARRAY MEMORY ERROR"

; -------------------------------------------------
; XIALLOC
; In : AX = number of elements 1..32767
; Out: AX = handle 1..16, AX=0 on error
;
; Memory requirement:
;   count * 2 bytes, rounded to paragraphs.
; -------------------------------------------------
XIALLOC:
 call MEMINIT
 jc XIALLOC_MEMFAIL

 push bx
 push cx
 push dx
 push si
 push di
 push es

 cmp ax,1
 jb XIALLOC_FAIL
 cmp ax,32767
 ja XIALLOC_FAIL

 mov cx,ax              ; CX = Count

 ; find free slot
 mov si,OFFSET XISEG
 xor dx,dx              ; DX = Slot 0..15

XIALLOC_FIND:
 cmp WORD [si],0
 je XIALLOC_FOUND
 add si,2
 inc dx
 cmp dx,16
 jb XIALLOC_FIND
 jmp XIALLOC_FAIL

XIALLOC_FOUND:
 ; paragraphs = ceil(count*2 / 16) = (count+7)/8
 mov bx,cx
 add bx,7
 shr bx,1
 shr bx,1
 shr bx,1

 push ds
 push es
 push si
 push cx
 push dx

 mov ah,48h
 int 21h

 pop dx
 pop cx
 pop si
 pop es
 pop ds

 jc XIALLOC_FAIL

 ; save segment
 mov [si],ax

 ; save count
 mov bx,dx
 shl bx,1
 mov [XICNT+bx],cx

 ; zero memory: ES = new segment, DI=0, CX=count words
 push ax
 mov es,ax
 xor di,di
 xor ax,ax
 rep stosw
 pop ax

 ; handle = slot + 1
 mov ax,dx
 inc ax
 jmp XIALLOC_DONE

XIALLOC_MEMFAIL:
 xor ax,ax
 ret
XIALLOC_FAIL:
 xor ax,ax

XIALLOC_DONE:
 pop es
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 ret

; -------------------------------------------------
; XIPTR
; In : AX = handle 1..16
;      BX = index 1..Count
; Out: ES:DI = address of the INT element
; -------------------------------------------------
XIPTR:
 push ax
 push bx
 push si

 cmp ax,1
 jb XIPTR_ERR
 cmp ax,16
 ja XIPTR_ERR

 cmp bx,1
 jb XIPTR_ERR

 dec ax
 mov si,ax
 shl si,1

 cmp WORD [XISEG+si],0
 je XIPTR_ERR

 cmp bx,[XICNT+si]
 ja XIPTR_ERR

 mov ax,[XISEG+si]
 mov es,ax

 dec bx
 add bx,bx
 mov di,bx

 pop si
 pop bx
 pop ax
 ret

XIPTR_ERR:
 pop si
 pop bx
 pop ax
 jmp ARR_INDEX_ERR

; -------------------------------------------------
; XIGET
; In : AX = handle
;      BX = index
; Out: AX = value
; -------------------------------------------------
XIGET:
 push es
 call XIPTR
 mov ax,[es:di]
 pop es
 ret

; -------------------------------------------------
; XISET
; In : AX = handle
;      BX = index
;      CX = value
; -------------------------------------------------
XISET:
 push es
 call XIPTR
 mov [es:di],cx
 pop es
 ret

; -------------------------------------------------
; XIFREE
; In : AX = handle
; Effect: frees external INT array
; -------------------------------------------------
XIFREE:
 push ax
 push si
 push es

 cmp ax,1
 jb XIFREE_ERR
 cmp ax,16
 ja XIFREE_ERR

 dec ax
 mov si,ax
 shl si,1

 cmp WORD [XISEG+si],0
 je XIFREE_ERR

 mov ax,[XISEG+si]
 mov es,ax

 push si
 mov ah,49h
 int 21h
 pop si

 jc XIFREE_ERR

 mov WORD [XISEG+si],0
 mov WORD [XICNT+si],0

 pop es
 pop si
 pop ax
 ret

XIFREE_ERR:
 pop es
 pop si
 pop ax
 jmp ARR_MEM_ERR

; -------------------------------------------------
; ARRFREE_DESC
; In : DI = array descriptor S_x
; Effect:
;   If the descriptor describes an external INT array,
;   the associated DOS memory is freed.
; -------------------------------------------------
ARRFREE_DESC:
 push ax
 cmp BYTE [di],255
 jne ARRFREE_DC
 xor ax,ax
 mov al,[di+1]
 or ax,ax
 je ARRFREE_DC
 call XIFREE
ARRFREE_DC:
 mov BYTE [di],0
 mov BYTE [di+1],0
 pop ax
 ret

; -------------------------------------------------
; ARRCLR
; In : AX = number of elements
;      DI = descriptor / internal array buffer
;
; 1..127:
;   internal array in the S_x buffer
;
; 128..32767:
;   external INT array in DOS memory
; -------------------------------------------------
ARRCLR:
 push ax
 push bx
 push cx
 push di

 cmp ax,1
 jb ARRCLR_BADS
 cmp ax,32767
 ja ARRCLR_BADS

 ; safely preserve requested size across ARRFREE_DESC
 push ax
 call ARRFREE_DESC
 pop ax

 cmp ax,127
 jbe ARRCLR_SMALL

 ; large external array
 call XIALLOC
 or ax,ax
 je ARRCLR_NOMEM

 mov BYTE [di],255
 mov [di+1],al

 pop di
 pop cx
 pop bx
 pop ax
 ret

ARRCLR_SMALL:
 mov [di],al
 xor ah,ah
 mov cx,ax
 add cx,cx
 inc di
 xor al,al
 rep stosb

 pop di
 pop cx
 pop bx
 pop ax
 ret

ARRCLR_BADS:
 pop di
 pop cx
 pop bx
 pop ax
 jmp ARR_SIZE_ERR

ARRCLR_NOMEM:
 pop di
 pop cx
 pop bx
 pop ax
 jmp ARR_MEM_ERR

; -------------------------------------------------
; ARRGETB
; In : AX = index
;      SI = descriptor / internal array buffer
; Out: AX = value
; -------------------------------------------------
ARRGETB:
 push bx

 cmp BYTE [si],255
 je ARRGETB_EXT

 ; internal array
 cmp ax,1
 jb ARRGETB_ERR

 xor bx,bx
 mov bl,[si]
 cmp ax,bx
 ja ARRGETB_ERR

 add ax,ax
 dec ax
 add si,ax
 mov ax,[si]

 pop bx
 ret

ARRGETB_EXT:
 mov bx,ax          ; index
 xor ax,ax
 mov al,[si+1]      ; handle
 call XIGET

 pop bx
 ret

ARRGETB_ERR:
 pop bx
 jmp ARR_INDEX_ERR

; -------------------------------------------------
; ARRSETB
; In : AX = value
;      BX = index
;      SI = descriptor / internal array buffer
; -------------------------------------------------
ARRSETB:
 push ax
 push dx
 push cx

 cmp BYTE [si],255
 je ARRSETB_EXT

 ; internal array
 cmp bx,1
 jb ARRSETB_IDXERR

 xor dx,dx
 mov dl,[si]
 cmp bx,dx
 ja ARRSETB_IDXERR

 add bx,bx
 dec bx
 add si,bx
 mov [si],ax

 pop cx
 pop dx
 pop ax
 ret

ARRSETB_EXT:
 mov cx,ax          ; value
 xor ax,ax
 mov al,[si+1]      ; handle
 call XISET

 pop cx
 pop dx
 pop ax
 ret

ARRSETB_IDXERR:
 pop cx
 pop dx
 pop ax
 jmp ARR_INDEX_ERR

%endif

%ifdef USE_TM
; =================================================
; TIMER()
; AX = seconds since start of day modulo 65536
; DOS INT 21h, AH=2Ch returns CH=hour, CL=minute, DH=second
; =================================================
TIMERC:
 push bx
 push cx
 push dx
 mov ah,2Ch
 int 21h
 mov bl,cl
 mov cl,dh
 mov al,ch
 xor ah,ah
 mov dx,60
 mul dx
 xor bh,bh
 add ax,bx
 mov bx,60
 mul bx
 xor ch,ch
 add ax,cx
 pop dx
 pop cx
 pop bx
 ret
%endif

%ifdef USE_D2
; -------------------------------------------------
; D2_TWO
; In : AL = value 0..99
; Out: two decimal digits to [DI], DI += 2
; Uses: AX, BX, DX
; -------------------------------------------------
D2_TWO:
 xor ah,ah
 xor dx,dx
 mov bx,10
 div bx              ; AX = tens, DX = ones
 add al,'0'
 mov [di],al
 inc di
 mov al,dl
 add al,'0'
 mov [di],al
 inc di
 ret
%endif

%ifdef USE_DT
; =================================================
; DATE$ / DATES
;
; QuickBASIC-compatible date format:
;   mm-dd-yyyy
;
; In:
;   DI = destination buffer for counted string
;
; Out:
;   [DI]      = 10
;   [DI+1..] = "mm-dd-yyyy"
;
; DOS INT 21h / AH=2Ah:
;   CX = year
;   DH = month
;   DL = day
; =================================================

DATES:
 push ax
 push bx
 push cx
 push dx
 push di

 mov ah,2Ah
 int 21h

 mov BYTE PTR [di],10
 inc di

 ; month DH -> two digits
 mov al,dh
 call D2_TWO

 mov BYTE PTR [di],'-'
 inc di

 ; day DL -> two digits
 mov al,dl
 call D2_TWO

 mov BYTE PTR [di],'-'
 inc di

 ; year CX -> four digits
 mov ax,cx
 call DT_FOUR

 pop di
 pop dx
 pop cx
 pop bx
 pop ax
 ret

; -------------------------------------------------
; DT_FOUR
; In : AX = year, e.g. 2026
; Out: four decimal digits to [DI], DI += 4
; -------------------------------------------------
DT_FOUR:
 xor dx,dx
 mov bx,1000
 div bx              ; AX = thousands, DX = remainder
 add al,'0'
 mov [di],al
 inc di

 mov ax,dx
 xor dx,dx
 mov bx,100
 div bx              ; AX = hundreds, DX = remainder
 add al,'0'
 mov [di],al
 inc di

 mov ax,dx
 xor dx,dx
 mov bx,10
 div bx              ; AX = tens, DX = ones
 add al,'0'
 mov [di],al
 inc di

 mov ax,dx
 add al,'0'
 mov [di],al
 inc di
 ret
%endif

%ifdef USE_TS
; =================================================
; TIME$ / TIMESTR
;
; QuickBASIC-compatible time format:
;   hh:mm:ss
;
; In:
;   DI = destination buffer for counted string
;
; Out:
;   [DI]      = 8
;   [DI+1..] = "hh:mm:ss"
;
; DOS INT 21h / AH=2Ch:
;   CH = hour
;   CL = minute
;   DH = second
;   DL = hundredths of a second, ignored here
; =================================================

TIMESTR:
 push ax
 push bx
 push cx
 push dx
 push di

 mov ah,2Ch
 int 21h

 mov BYTE PTR [di],8
 inc di

 ; hour CH -> two digits
 mov al,ch
 call D2_TWO

 mov BYTE PTR [di],':'
 inc di

 ; minute CL -> two digits
 mov al,cl
 call D2_TWO

 mov BYTE PTR [di],':'
 inc di

 ; second DH -> two digits
 mov al,dh
 call D2_TWO

 pop di
 pop dx
 pop cx
 pop bx
 pop ax
 ret
%endif

%ifdef USE_EX
; =================================================
; EXEC(program$, args$)
;
; Calling convention:
;   EX_SETPROG:
;       DS:SI = counted string with program name
;       Effect: EX_PROG = ASCIIZ, append ".COM" if needed
;
;   EXECC:
;       DS:SI = counted string with arguments without leading space
;       AX = 0 on success, otherwise DOS error code from INT 21h / AX=4B00h
;
; Note:
;   USE_EX enables USE_MEM above. This includes INIT_COMMAND/MEMINIT
;   and shrinks the COM memory block before EXEC.
; =================================================

EX_SETPROG:
 push ax
 push cx
 push si
 push di
 mov BYTE [EX_HASDOT],0
 xor cx,cx
 mov cl,[si]
 inc si
 cmp cl,123
 jbe EXSP_LEN_OK
 mov cl,123
EXSP_LEN_OK:
 mov di,OFFSET EX_PROG
EXSP_COPY:
 or cl,cl
 je EXSP_END
 mov al,[si]
 mov [di],al
 cmp al,46
 je EXSP_DOT
 cmp al,58
 je EXSP_PATHSEP
 cmp al,92
 je EXSP_PATHSEP
 cmp al,47
 je EXSP_PATHSEP
 jmp EXSP_NEXT
EXSP_DOT:
 mov BYTE [EX_HASDOT],1
 jmp EXSP_NEXT
EXSP_PATHSEP:
 mov BYTE [EX_HASDOT],0
EXSP_NEXT:
 inc si
 inc di
 dec cl
 jmp EXSP_COPY
EXSP_END:
 cmp BYTE [EX_HASDOT],0
 jne EXSP_ZERO
 mov BYTE [di],46
 inc di
 mov BYTE [di],67
 inc di
 mov BYTE [di],79
 inc di
 mov BYTE [di],77
 inc di
EXSP_ZERO:
 mov BYTE [di],0
 pop di
 pop si
 pop cx
 pop ax
 ret

EXECC:
 call MEMINIT
 jc EXECC_MEMFAIL
 push ds
 push bx
 push cx
 push dx
 push si
 push di
 push es

 ; -------------------------------------------------
 ; Build DOS command tail for child program.
 ; DS:SI points to counted args string.
 ; No argument:
 ;   Length 0, then CR
 ; With argument:
 ;   Length = argslen + 1
 ;   Byte 1 = space
 ;   then argument text
 ;   then CR
 ; Maximum 127 tail characters including leading space.
 ; -------------------------------------------------
 mov di,OFFSET EX_CMDTAIL
 xor cx,cx
 mov cl,[si]
 inc si
 or cl,cl
 jne EXC_HAVE_ARGS
 mov BYTE [di],0
 inc di
 mov BYTE [di],13
 jmp EXC_BUILD_PB

EXC_HAVE_ARGS:
 cmp cl,126
 jbe EXC_ARG_LEN_OK
 mov cl,126
EXC_ARG_LEN_OK:
 mov al,cl
 inc al
 mov [di],al
 inc di
 mov BYTE [di],32
 inc di
 rep movsb
 mov BYTE [di],13

EXC_BUILD_PB:
 xor ax,ax
 mov [EX_PB_ENV],ax
 mov ax,OFFSET EX_CMDTAIL
 mov [EX_PB_CMD_OFF],ax
 mov ax,cs
 mov [EX_PB_CMD_SEG],ax
 mov ax,5Ch
 mov [EX_PB_FCB1_OFF],ax
 mov ax,cs
 mov [EX_PB_FCB1_SEG],ax
 mov ax,6Ch
 mov [EX_PB_FCB2_OFF],ax
 mov ax,cs
 mov [EX_PB_FCB2_SEG],ax

 ; -------------------------------------------------
 ; EXEC
 ; DS:DX = ASCIIZ program name
 ; ES:BX = parameter block
 ; -------------------------------------------------
 mov dx,OFFSET EX_PROG
 mov bx,OFFSET EX_PARAMBLK
 mov ax,cs
 mov es,ax
mov ax,4B00h
 int 21h
 jc EXC_ERR

 ; Child ran. Fetch child return code immediately.
 mov ah,4Dh
 int 21h              ; AH = termination type, AL = child return code

 or ah,ah
 jne EXC_ABTERM

 ; Normal child termination: return AL as AX = 0..255
 xor ah,ah
 jmp EXC_SAVE

EXC_ABTERM:
 ; Abnormal child termination:
 ; AH = 1 Ctrl-C, 2 critical error, 3 TSR
 ; Return as negative code: -(256 + AH)
 mov al,ah
 xor ah,ah
 add ax,256
 neg ax
 jmp EXC_SAVE

EXC_ERR:
 ; EXEC load/execute failed.
 ; DOS error code is in AX. Return it negative.
 neg ax

EXC_SAVE:
 push cs
 pop ds
 mov [EX_RETCODE],ax

 pop es
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 mov ax,[EX_RETCODE]
 pop ds
 ret
EXECC_MEMFAIL:
 neg ax
 ret

EX_PARAMBLK:
EX_PB_ENV:      dw 0
EX_PB_CMD_OFF:  dw 0
EX_PB_CMD_SEG:  dw 0
EX_PB_FCB1_OFF: dw 0
EX_PB_FCB1_SEG: dw 0
EX_PB_FCB2_OFF: dw 0
EX_PB_FCB2_SEG: dw 0

EX_RETCODE: dw 0
EX_HASDOT:  db 0
EX_PROG:    times 128 db 0
EX_CMDTAIL: times 128 db 0
%endif

%ifdef USE_CP
; =================================================
; CPUID()
;
; Return value in AX:
;   86   = Intel 8086/8088 class
;   120  = NEC V20/V30 class, 8080 emulation present
;   186  = Intel 80186/80188 class
;   286  = 80286
;   386  = 80386
;   486  = 80486 or compatible without CPUID
;   586  = CPUID-Family 5
;   686  = CPUID-Family 6
;   1500 = CPUID-Family F
;   999  = CPUID present, family not mapped separately
;
; Advanced instructions are encoded as DB.
; They are executed only after the CPU class has been
; identified as sufficient for them.
; =================================================

CPUIDC:
 ; save original FLAGS.
 DB 156              ; PUSHF
 pop ax
 mov [CP_FLG],ax

 ; -------------------------------------------------
 ; 8086/80186/NEC vs. 286+:
 ; Before 286, FLAGS bits 12..15 remain 1.
 ; On 286+, these bits can become 0 in real mode.
 ; -------------------------------------------------
 xor ax,ax
 push ax
 DB 157              ; POPF
 DB 156              ; PUSHF
 pop ax
 and ax,0F000H
 cmp ax,0F000H
 je CP_LT286

 ; -------------------------------------------------
 ; 286 vs. 386+:
 ; Try to set FLAGS bits 12..14.
 ; If they remain 0: 286.
 ; If they can be set: 386+.
 ; -------------------------------------------------
 mov ax,7000H
 push ax
 DB 157              ; POPF
 DB 156              ; PUSHF
 pop ax
 and ax,7000H
 or ax,ax
 je CP_80286

  ; -------------------------------------------------
 ; From here on, 386+ is assumed.
 ;
 ; 386 vs. 486+:
 ; Test AC bit in EFLAGS.
 ; 32-bit opcodes are encoded as DB with operand-size prefix.
 ; -------------------------------------------------

 ; pushfd / pop eax / mov ecx,eax
 DB 102,156          ; PUSHFD
 DB 102,88           ; POP EAX
 DB 102,137,193      ; MOV ECX,EAX

 ; xor eax,00040000h / push eax / popfd
 DB 102,53,0,0,4,0   ; XOR EAX,00040000h
 DB 102,80           ; PUSH EAX
 DB 102,157          ; POPFD

 ; pushfd / pop eax / xor eax,ecx / test eax,00040000h
 DB 102,156          ; PUSHFD
 DB 102,88           ; POP EAX
 DB 102,49,200       ; XOR EAX,ECX
 DB 102,169,0,0,4,0  ; TEST EAX,00040000h
 je CP_80386_RST

 ; AC bit test successful: restore EFLAGS from ECX.
 DB 102,81           ; PUSH ECX
 DB 102,157          ; POPFD

 ; -------------------------------------------------
 ; CPUID availability:
 ; Test ID bit in EFLAGS.
 ; If not toggleable: 486 without CPUID.
 ; -------------------------------------------------

 ; pushfd / pop eax / mov ecx,eax
 DB 102,156          ; PUSHFD
 DB 102,88           ; POP EAX
 DB 102,137,193      ; MOV ECX,EAX

 ; xor eax,00200000h / push eax / popfd
 DB 102,53,0,0,32,0  ; XOR EAX,00200000h
 DB 102,80           ; PUSH EAX
 DB 102,157          ; POPFD

 ; pushfd / pop eax / xor eax,ecx / test eax,00200000h
 DB 102,156          ; PUSHFD
 DB 102,88           ; POP EAX
 DB 102,49,200       ; XOR EAX,ECX
 DB 102,169,0,0,32,0 ; TEST EAX,00200000h
 je CP_80486_RST

 ; ID bit test successful: restore EFLAGS from ECX.
 DB 102,81           ; PUSH ECX
 DB 102,157          ; POPFD

 ; -------------------------------------------------
 ; Execute CPUID leaf 1.
 ; EAX then contains the processor signature.
 ; Family is in bits 8..11 of AX.
 ; -------------------------------------------------
 DB 102,184,1,0,0,0  ; MOV EAX,1
 DB 15,162           ; CPUID

 mov bx,ax
 and bx,0F00H

 cmp bx,0400H
 je CP_FAM4
 cmp bx,0500H
 je CP_FAM5
 cmp bx,0600H
 je CP_FAM6
 cmp bx,0F00H
 je CP_FAMF

 mov ax,999
 jmp CP_RET

CP_80386_RST:
 DB 102,81           ; PUSH ECX
 DB 102,157          ; POPFD
 mov ax,386
 jmp CP_RET

CP_80486_RST:
 DB 102,81           ; PUSH ECX
 DB 102,157          ; POPFD
 mov ax,486
 jmp CP_RET

CP_LT286:
 ; -------------------------------------------------
 ; NEC V20/V30-Test:
 ; On NEC V20/V30, ZF is set by MUL according to the result.
 ; On Intel 8086/80186, ZF is not evaluated that way.
 ;
 ; Encoding:
 ;   F6 E0 = MUL AL
 ; Therefore BASM does not need to know MUL AL as a mnemonic.
 ; -------------------------------------------------
 xor al,al
 DB 246,224          ; MUL AL
 je CP_NECV

 ; -------------------------------------------------
 ; Intel 8086/8088 vs. Intel 80186/80188:
 ; 80186 masks variable shift counts to 5 bits.
 ; 8086 shifts by the full CL value.
 ; FFh >> 33:
 ;   8086  -> 0
 ;   80186 -> 7Fh, because 33 & 31 = 1
 ; -------------------------------------------------
 mov al,255
 mov cl,33
 shr al,cl
 cmp al,0
 jne CP_80186

 jmp CP_8086

CP_NECV:
 mov ax,120
 jmp CP_RET

CP_8086:
 mov ax,86
 jmp CP_RET

CP_80186:
 mov ax,186
 jmp CP_RET

CP_80286:
 mov ax,286
 jmp CP_RET

CP_FAM4:
 mov ax,486
 jmp CP_RET

CP_FAM5:
 mov ax,586
 jmp CP_RET

CP_FAM6:
 mov ax,686
 jmp CP_RET

CP_FAMF:
 mov ax,1500

CP_RET:
 ; Restore 16-bit FLAGS and preserve result AX.
 push ax
 mov ax,[CP_FLG]
 push ax
 DB 157              ; POPF
 pop ax
 ret

CP_FLG dw 0
%endif

%ifdef USE_IX
; =================================================
; CALLINT intno, regs()
;
; In:
;   AX = interrupt number, must be 0..255
;   SI = descriptor/address of numeric array regs()
;
; regs(1) = AX
; regs(2) = BX
; regs(3) = CX
; regs(4) = DX
; regs(5) = SI
; regs(6) = DI
; regs(7) = FLAGS output only
;
; This CALLINT interface intentionally exposes only the
; general-purpose registers and returned FLAGS.
; =================================================

IX_NO    db 0
IX_DESC  dw 0
IX_AX    dw 0
IX_BX    dw 0
IX_CX    dw 0
IX_DX    dw 0
IX_SI    dw 0
IX_DI    dw 0
IX_FL    dw 0

CALLINTC:
 or ah,ah
 jne IX_VALERR
 mov [IX_NO],al
 mov [IX_DESC],si

 ; --- read register block from BASIC array ---
 mov ax,1
 mov si,[IX_DESC]
 call ARRGETB
 mov [IX_AX],ax

 mov ax,2
 mov si,[IX_DESC]
 call ARRGETB
 mov [IX_BX],ax

 mov ax,3
 mov si,[IX_DESC]
 call ARRGETB
 mov [IX_CX],ax

 mov ax,4
 mov si,[IX_DESC]
 call ARRGETB
 mov [IX_DX],ax

 mov ax,5
 mov si,[IX_DESC]
 call ARRGETB
 mov [IX_SI],ax

 mov ax,6
 mov si,[IX_DESC]
 call ARRGETB
 mov [IX_DI],ax

 ; --- patch interrupt opcode operand ---
 mov al,[IX_NO]
 mov [IX_INT+1],al

 ; --- load CPU registers ---
 mov ax,[IX_AX]
 mov bx,[IX_BX]
 mov cx,[IX_CX]
 mov dx,[IX_DX]
 mov si,[IX_SI]
 mov di,[IX_DI]

IX_INT:
 DB 205,0              ; INT imm8, immediate byte is patched above

 ; Capture FLAGS before any flag-changing instruction.
 DB 156                ; PUSHF
 push cs
 pop ds                ; restore program data segment
 push cs
 pop es                ; keep ES consistent with program segment

 mov [IX_AX],ax
 pop ax
 mov [IX_FL],ax

 mov [IX_BX],bx
 mov [IX_CX],cx
 mov [IX_DX],dx
 mov [IX_SI],si
 mov [IX_DI],di

 ; --- write result block back to BASIC array ---
 mov si,[IX_DESC]
 mov bx,1
 mov ax,[IX_AX]
 call ARRSETB

 mov si,[IX_DESC]
 mov bx,2
 mov ax,[IX_BX]
 call ARRSETB

 mov si,[IX_DESC]
 mov bx,3
 mov ax,[IX_CX]
 call ARRSETB

 mov si,[IX_DESC]
 mov bx,4
 mov ax,[IX_DX]
 call ARRSETB

 mov si,[IX_DESC]
 mov bx,5
 mov ax,[IX_SI]
 call ARRSETB

 mov si,[IX_DESC]
 mov bx,6
 mov ax,[IX_DI]
 call ARRSETB

 mov si,[IX_DESC]
 mov bx,7
 mov ax,[IX_FL]
 jmp ARRSETB

IX_VALERR:
 mov dx,OFFSET BVERR
 mov cx,16
 jmp RT_ABORT
%endif

%ifdef USE_BP
BEEPC:
 mov ah,02h
 mov dl,7
 int 21h
 ret
%endif

%ifdef USE_DA
DATREC dw DATA_BEGIN
DATCNT dw 0
DATPTR dw 0

READW:
 cmp WORD [DATCNT],0
 jne READW_HAVE
 mov bx,[DATREC]
 or bx,bx
 je READW_OOD
 mov ax,[bx]
 mov [DATREC],ax
 mov ax,[bx+2]
 or ax,ax
 je READW_OOD
 mov [DATCNT],ax
 add bx,4
 mov [DATPTR],bx

READW_HAVE:
 mov bx,[DATPTR]
 mov ax,[bx]
 add bx,2
 mov [DATPTR],bx
 dec WORD [DATCNT]
 ret

READW_OOD:
 mov dx,OFFSET DAERR
 mov cx,11
 jmp RT_ABORT

DAERR:
 db "OUT OF DATA"
%endif

%ifdef USE_BK
; =================================================
; BREAK / CTRL-C support
;
; BIOS-only break check:
;   - enabled through REQ BK / USE_BK
;   - no INT 23h handler registration
;   - no DOS AH=0Bh polling
;
; BRKCHK polls the BIOS keyboard buffer via
; INT 16h AH=01h, but only every 32 calls to keep
; large loops fast.
;
; Abort conditions checked through BIOS:
;   Ctrl-C      : AL = 03h, commonly AX = 2E03h
;   Ctrl-Break : BIOS may report AX = 0000 with ZF=0
;
; On abort, the pending key is consumed with
; INT 16h AH=00h, then the program exits with
; errorlevel 130.
; =================================================

BRKCNT db 31

BRKCHK:
 push ax

 ; Poll BIOS only every 32 calls.
 ; BRKCNT starts at 31, so the first BRKCHK checks immediately.
 inc BYTE [BRKCNT]
 mov al,[BRKCNT]
 and al,31
 jne BRKCHK_DONE

 ; BIOS keyboard status, no key removal.
 mov ah,01h
 int 16h
 jz BRKCHK_DONE

 ; Ctrl-C: AL = 03h, commonly AX = 2E03h.
 cmp al,03h
 je BRKCHK_ABORT

 ; Ctrl-Break: many BIOSes report a zero word but ZF=0.
 or ax,ax
 je BRKCHK_ABORT

BRKCHK_DONE:
 pop ax
 ret

BRKCHK_ABORT:
 ; Consume pending break key before terminating.
 mov ah,00h
 int 16h
 pop ax
 mov al,130
 jmp RT_EXIT_AL
%endif

%ifdef STACKMON
; -------------------------------------------------
; Stack high-water report for the private runtime stack.
; The stack was filled with A55Ah before it became active.
; Output: STACK MAX n followed by CR/LF.
; -------------------------------------------------
SM_EXIT db 0
SM_MSG db "STACK MAX "
STACK_REPORT:
 mov si,OFFSET ENDPROG
%ifdef STACK256
 mov di,OFFSET ENDPROG+256
%else
 mov di,OFFSET ENDPROG+128
%endif
SM_SCAN:
 cmp si,di
 jae SM_FOUND
 cmp WORD [si],0A55Ah
 jne SM_FOUND
 add si,2
 jmp SM_SCAN
SM_FOUND:
 mov ax,di
 sub ax,si
 push ax
 mov dx,OFFSET SM_MSG
 mov cx,10
 mov bx,1
 mov ah,40h
 int 21h
 pop ax
 xor cx,cx
 mov bx,10
SM_DIV:
 xor dx,dx
 div bx
 push dx
 inc cx
 or ax,ax
 jne SM_DIV
SM_OUT:
 pop dx
 add dl,'0'
 mov ah,02h
 int 21h
 loop SM_OUT
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov al,[SM_EXIT]
 jmp RT_EXIT_DOS
%endif

%ifdef USE_MEM
; -------------------------------------------------
; Reserve the selected stack size after the loaded image through MEMINIT.
; Default: 128 bytes. Define STACK256 for 256 bytes.
; These bytes are present in memory, but not stored in the COM file.
; -------------------------------------------------
%endif

ENDPROG:

; for determining the actual COM size by MEMINIT.

