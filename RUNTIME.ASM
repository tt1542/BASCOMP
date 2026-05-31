; Exit code for DOS 
; if a program has no END, execution stops here.
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
%endif

%ifdef USE_FI
 %define USE_NB
 FH: times 9 dw 0    ; handle for channel 1..9
 FM: times 9 db 0    ; 0=closed, 1=INPUT, 2=OUTPUT
%endif

%ifdef USE_PN
 %define USE_NB
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

%ifdef USE_NB
 NB: times 256 db 0
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

INIT_COMMAND:
%ifdef USE_MEM
 ; -------------------------------------------------
 ; Private COM stack only for XA/string arrays.
 ; INIT_COMMAND is called directly from start via CALL.
 ; Therefore the return address is on the old stack.
 ; Procedure:
 ;   1. fetch return address from the old stack
 ;   2. set SS:SP to the private stack
 ;   3. place return address on the new stack
 ;   4. continue normally and RET at the end
 ; -------------------------------------------------
 pop bx                  ; save return address

 cli
 mov ax,cs
 mov ss,ax
 mov sp,OFFSET RT_STACK_TOP
 sti

 push bx                 ; return address on new stack
%endif

%ifdef USE_RN
 push ax
 push cx
 push dx
 mov ah,00h
 int 1Ah
 mov ax,dx
 xor ax,cx
 cmp ax,0
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

 cmp cl,0
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
 ret

%ifdef USE_MEM
MEMINIT:
 cmp BYTE [MEMINITD],0
 jne MEMINIT_DONE
 mov BYTE [MEMINITD],1

 push ax
 push bx
 push ds
 push es

 push cs
 pop ds
 push cs
 pop es

 mov bx,((ENDPROG - start + 100h + 15) >> 4)
 mov ah,4Ah
 int 21h

 pop es
 pop ds
 pop bx
 pop ax

MEMINIT_DONE:
 ret
%endif

%ifdef USE_ST
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
  call MID
  ret

LTRIM:
 xor cx,cx
 mov cl,[si]
 inc si
 cmp cl,0
 jne LTRIM_SCAN
 mov BYTE PTR [di],0
 ret

LTRIM_SCAN:
 cmp cl,0
 je LTRIM_ZERO
 cmp BYTE PTR [si],' '
 jne LTRIM_COPY
 inc si
 dec cl
 jmp LTRIM_SCAN

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
 cmp cl,0
 jne RTRIM_PREP
 mov BYTE PTR [di],0
 ret

RTRIM_PREP:
 mov si,bx
 add si,cx
 dec si

RTRIM_SCAN:
 cmp cl,0
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
 cmp cl,0
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
  cmp cl,0
  je CMP_ENDA
  cmp dl,0
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
  cmp dl,0
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
 cmp bh,0
 jne ICHK
 mov al,dl
 jmp INSTRS_END
ICHK:
 cmp dl,1
 jae IOK
 mov dl,1
IOK:
 cmp dl,bl
 ja INF
 xor dh,dh
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
 xor al,al
 jmp ICLEAN
IFND:
 pop di
 pop si
 pop cx
 mov al,bl
 sub al,cl
 inc al
 sub al,bh
 inc al
ICLEAN:
INSTRS_END:
 xor ah,ah
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

 cmp bx,0
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
 cmp cl,0
 jne TRIM_LEAD
 mov BYTE PTR [di],0
 ret

TRIM_LEAD:
 cmp cl,0
 je TRIM_ZERO
 cmp BYTE PTR [si],' '
 jne TRIM_HAVE
 inc si
 dec cl
 jmp TRIM_LEAD

TRIM_HAVE:
 mov bx,si
 add si,cx
 dec si

TRIM_TRAIL:
 cmp cl,0
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
 push cx
 push dx
 cmp ax,0
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
 pop cx
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
POWCR:
 db 13,10

POWS:
 push bx
 push cx
 push dx
 cmp bx,0
 jl POWS_NEG
 cmp bx,0
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
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET POWCR
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov ah,4Ch
 int 21h

POWS_DONE:
 pop dx
 pop cx
 pop bx
 ret
%endif

%ifdef USE_CV
VAL:
 xor ax,ax
 xor bx,bx
 xor cx,cx
 mov cl,[si]
 inc si

VAL_LEAD:
 cmp cl,0
 je VAL_DONE
 mov dl,[si]
 cmp dl,' '
 je VAL_LEAD_SKIP
 cmp dl,9
 je VAL_LEAD_SKIP
 cmp dl,'+'
 je VAL_SIGN
 cmp dl,'-'
 jne VAL_LOOP
 mov ch,1

VAL_SIGN:
 inc si
 dec cl
 jmp VAL_LOOP

VAL_LEAD_SKIP:
 inc si
 dec cl
 jmp VAL_LEAD

VAL_LOOP:
 cmp cl,0
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
 jmp VAL_LOOP

VAL_APPLY_SIGN:
 cmp ch,0
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

 cmp ax,0
 jne STRS_NZ
 mov BYTE PTR [si],1
 mov BYTE PTR [si+1],'0'
 jmp STRS_DONE

STRS_NZ:
 cmp ax,0
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
 cmp ax,0
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

; AL = ASCII or prefix, AH = scan code or prefix
;
; Normale BIOS-special key:
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
 push ax
 push dx
 mov ah,02h
 mov dl,'?'
 int 21h
 mov dl,' '
 int 21h
 pop dx
 pop ax
INPUTS_LOOP:
 mov ah,01h
 int 21h
 cmp al,8
 jne INPUT_NOT_BS
 cmp cl,0
 je INPUTS_LOOP
 dec di
 dec cl
 mov ah,02h
 mov dl,' '
 int 21h
 mov dl,8
 int 21h
 jmp INPUTS_LOOP
INPUT_NOT_BS:
 cmp al,13
 je INPUTS_DONE
 mov [di],al
 inc di
 inc cl
 cmp cl,255
 jne INPUTS_LOOP
INPUTS_DONE:
 pop di
 mov [di],cl
 call WRITE_CRLFH
 ret

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
 cmp ax,0
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
 jmp RLH_DONE
RLH_CR:
 push cx
 mov ah,3Fh
 mov cx,1
 mov dx,OFFSET NB
 int 21h
 pop cx
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
 cmp dl,0
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
 call GETHC
 mov dx,bx
 pop ax
 mov bx,dx
 ret

; -------------------------------------------------
; In : AL = channel
; Out: BX = DOS handle for OUTPUT
; AX is preserved
; -------------------------------------------------
GETHOUT:
 push ax
 mov ah,2
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
 call EOFH
 ret

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
FI_ABORT:
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov ah,4Ch
 int 21h

FI_BADCH:
 mov dx,OFFSET FICHERR
 mov cx,11
 jmp FI_ABORT

FI_NOTOPEN:
 mov dx,OFFSET FINOPERR
 mov cx,16
 jmp FI_ABORT

FI_MODE:
 mov dx,OFFSET FIMODERR
 mov cx,18
 jmp FI_ABORT

FI_INUSE:
 mov dx,OFFSET FIUSEERR
 mov cx,14
 jmp FI_ABORT

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
 jmp FI_ABORT
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
 mov cx,0
 int 21h
 jnc OPENO_OK
 mov dx,OFFSET OPOERR
 mov cx,17
 jmp FI_ABORT
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
 jmp FI_ABORT
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
 mov si,ax
 mov di,dx
 mov ah,42h
 mov al,2
 xor cx,cx
 xor dx,dx
 int 21h
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
 pop ax
 pop di
 pop si
 pop dx
 pop cx
 pop bx
 ret
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
 cmp cx,0
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
 cmp ax,0
 jne WNH_CH_SIGN
 mov al,'0'
 mov bx,si
 call WRITE_CHH
 jmp WNH_DONE
WNH_CH_SIGN:
 test ax,ax
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
 cmp ax,0
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
 jmp BI_ABORT
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
 cmp ax,0
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
 jmp BI_ABORT
READB_ERR:
 pop dx
 pop cx
 pop bx
 mov dx,OFFSET BI_RDERR
 mov cx,15
 jmp BI_ABORT

WRITE_BYTEH:
 cmp ah,0
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
 
WRITEB_ERR:
 pop dx
 pop cx
 pop bx
 mov dx,OFFSET BI_WRERR
 mov cx,16
 jmp BI_ABORT
WRITEB_VALERR:
 mov dx,OFFSET BI_VALERR
 mov cx,16
 jmp BI_ABORT

BI_ABORT:
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov ah,4Ch
 int 21h

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
 mov dx,OFFSET BI_WRERR
 mov cx,16
 jmp BI_ABORT
 
; Workaround: BASM places the following label in the generated code
 ; currently 2 bytes too early, directly on the short JMP.
 ; Two NOPs make both cases harmless.
 db 144,144
 
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
 call BIFLUSH
 ret

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
BI_VALERR:
 db "BYTE VALUE ERROR"
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
 cmp ch,0
 jne PK_VALERR
 push es
 mov es,ax
 mov [es:bx],cl
 pop es
 ret

PK_VALERR:
 mov dx,OFFSET PKVERR
 mov cx,16
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov ah,4Ch
 int 21h

PKVERR:
 db "BYTE VALUE ERROR"
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

XA_ABORT:
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov ah,4Ch
 int 21h

; -------------------------------------------------
; XAALLOC
; In : AX = number of strings
;      BX = max. payload length
;           BX=0 -> default 255
; Out: AX = handle 1..16, AX=0 on error
; -------------------------------------------------
XAALLOC:
 call MEMINIT
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

 cmp bx,0
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
 cmp dx,0
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
 cmp ax,0
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
 ; BX = Paragraphen
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
 cmp dx,0
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
 jmp XA_ABORT

; -------------------------------------------------
; XACOPY_2EXT
; In : DS:SI = source, counted string
;      ES:DI = destination slot
;      CX    = max. payload length des Zielslots
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
 cmp cl,0
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
;      CX    = max. payload length des Quellslots
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
 cmp cl,0
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
 jmp XA_ABORT

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
;   [si+1]/[di+1] = handle 1..8
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
ARR_ABORT:
 mov bx,1
 mov ah,40h
 int 21h
 mov dx,OFFSET C
 mov cx,2
 mov bx,1
 mov ah,40h
 int 21h
 mov ah,4Ch
 int 21h

ARR_SIZE_ERR:
 mov dx,OFFSET ARRDERR
 mov cx,14
 jmp ARR_ABORT

ARR_INDEX_ERR:
 mov dx,OFFSET ARRIERR
 mov cx,17
 jmp ARR_ABORT

ARR_MEM_ERR:
 mov dx,OFFSET ARRMERR
 mov cx,18
 jmp ARR_ABORT

ARRDERR:
 db "BAD ARRAY SIZE"

ARRIERR:
 db "ARRAY INDEX ERROR"

ARRMERR:
 db "ARRAY MEMORY ERROR"

; -------------------------------------------------
; XIALLOC
; In : AX = number of elements 1..32767
; Out: AX = handle 1..8, AX=0 on error
;
; Memory requirement:
;   count * 2 bytes, rounded to paragraphs.
; -------------------------------------------------
XIALLOC:
 call MEMINIT

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
; In : AX = handle 1..8
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
 jne ARRFREE_DD

 xor ax,ax
 mov al,[di+1]
 cmp ax,0
 je ARRFREE_DC

 call XIFREE

ARRFREE_DC:
 mov BYTE [di],0
 mov BYTE [di+1],0

ARRFREE_DD:
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
 cmp ax,0
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
 mov [TM_HH],ch
 mov [TM_MM],cl
 mov [TM_SS],dh
 xor ax,ax
 mov al,[TM_HH]
 mov bx,60
 mul bx
 xor bx,bx
 mov bl,[TM_MM]
 add ax,bx
 mov bx,60
 mul bx
 xor bx,bx
 mov bl,[TM_SS]
 add ax,bx
 pop dx
 pop cx
 pop bx
 ret
TM_HH db 0
TM_MM db 0
TM_SS db 0
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
 call DT_TWO

 mov BYTE PTR [di],'-'
 inc di

 ; day DL -> two digits
 mov al,dl
 call DT_TWO

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
; DT_TWO
; In : AL = value 0..99
; Out: two decimal digits to [DI], DI += 2
; -------------------------------------------------
DT_TWO:
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
 call TS_TWO

 mov BYTE PTR [di],':'
 inc di

 ; minute CL -> two digits
 mov al,cl
 call TS_TWO

 mov BYTE PTR [di],':'
 inc di

 ; second DH -> two digits
 mov al,dh
 call TS_TWO

 pop di
 pop dx
 pop cx
 pop bx
 pop ax
 ret

; -------------------------------------------------
; TS_TWO
; In : AL = value 0..99
; Out: two decimal digits to [DI], DI += 2
; -------------------------------------------------
TS_TWO:
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
 cmp cl,0
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
 cmp cl,0
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
 mov ax,0
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
 xor ax,ax
 jmp EXC_SAVE

EXC_ERR:
 ; AX contains DOS error code

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
 cmp ax,0
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
 ; 8086 shifts mit full CL-value.
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
 jmp CP_RET

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

%ifdef USE_MEM
; -------------------------------------------------
; Runtime stack for external DOS memory use.
; Used by XA string arrays and large INT arrays
; use it.
; Must be before ENDPROG because MEMINIT calculates the size
; of the COM block from ENDPROG.
; -------------------------------------------------
RT_STACK_AREA:
 times 1024 db 0
RT_STACK_TOP:
%endif

ENDPROG:

; for determining the actual COM size by MEMINIT.
