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
%macro REQ 1
 %ifndef USE_%1
  %define USE_%1
 %endif
%endmacro
C DB 13,10
s2:
