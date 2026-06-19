ORG 100h
BITS 16
%define OFFSET
%define PTR
start:
mov ax,cs
mov ds,ax
mov es,ax
cld
call INIT_COMMAND
jmp s2
%assign __N 0
%assign __S 0

%macro DN 1
%ifndef N_%1
%xdefine N_%1 NV + __N
%assign __N __N + 2
%endif
%endmacro

%macro DS 1
%ifndef S_%1
%xdefine S_%1 SV + __S
%assign __S __S + 256
%endif
%endmacro

%macro DSLEN 2
%ifndef S_%1
%xdefine S_%1 SV + __S
%assign __S __S + %2 + 1
%endif
%endmacro

%macro DSA 2
%ifndef S_%1
%xdefine S_%1 SV + __S
%if %2 < 1
%assign __S __S + 2
%elif %2 <= 127
%assign __S __S + 1 + 2 * %2
%else
%assign __S __S + 2
%endif
%endif
%endmacro

%macro REQ 1
 %ifndef USE_%1
  %define USE_%1
 %endif
%endmacro
C DB 13,10

%ifdef BCBANNER
 ; ------------------------------------------------------------
 ; BASCOMP-only banner storage.
 ; These are normal BASCOMP string buffers:
 ; byte 0 = length, byte 1..n = payload, remaining bytes unused.
 ;
 ; They intentionally predefine S_X/S_A/S_B/S_R/S_K/S_D
 ; before the generated program reaches any DS X/A/B/R/K/D use.
 ; Therefore the DS macro will not allocate additional SV space
 ; for these variables.
 ; ------------------------------------------------------------

 %xdefine S_X BASBAN1
 %xdefine S_A BASBAN2
 %xdefine S_B BASBAN3
 %xdefine S_R BASBAN4
 %xdefine S_K BASBAN5
 %xdefine S_D BASBAN6

BASBAN1:
 db 58,"__________               _________                        "
 times 197 db 0

BASBAN2:
 db 58,"\______   \_____    _____\_   ___ \  ____   _____ ______  "
 times 197 db 0

BASBAN3:
 db 58," |    |  _/\__  \  /  ___/    \  \/ /  _ \ /     \\____ \ "
 times 197 db 0

BASBAN4:
 db 58," |    |   \ / __ \_\___ \\ 2.2 \___(  <_> )  Y Y  \  |_> >"
 times 197 db 0

BASBAN5:
 db 58," |______  /(____  /____  >\______  /\____/|__|_|  /   __/ "
 times 197 db 0

BASBAN6:
 db 58,"        \/      \/     \/        \/             \/|__|    "
 times 197 db 0

%xdefine S_E MSG2
%xdefine S_F MSG3
%xdefine S_I MSG4
%xdefine S_N MSG5

MSG2:
 db 25,"USAGE: BASCOMP file[.BAS]"
 times 230 db 0
MSG3:
 db 10,"COMPILING "
 times 245 db 0
MSG4:
 db 4," -> "
 times 251 db 0
MSG5:
 db 5,"FILE?"
 times 250 db 0

%endif

s2:

