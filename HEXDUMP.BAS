10 F$ = LTRIM$(RTRIM$(COMMAND$))
20 IF F$ <> "" THEN GOTO 50
30 PRINT "DATEI?"
40 INPUT F$
50 OPEN F$ FOR INPUT AS #1
60 H$ = "0123456789ABCDEF"
70 L$ = ""
80 A$ = ""
90 C = 0
100 O = 0
110 IF EOF(1) <> 0 THEN GOTO 300
120 IF C <> 0 THEN GOTO 150
130 GOSUB 400
140 L$ = O$ + ": "
150 GET #1, B
160 HI = B / 16
170 LO = B MOD 16
180 L$ = L$ + MID$(H$, HI + 1, 1) + MID$(H$, LO + 1, 1) + " "
190 IF B < 32 THEN GOTO 220
200 IF B > 126 THEN GOTO 220
210 A$ = A$ + CHR$(B): GOTO 230
220 A$ = A$ + "."
230 C = C + 1
240 O = O + 1
250 IF C < 16 THEN GOTO 110
260 PRINT L$; " "; A$
270 L$ = ""
280 A$ = ""
290 C = 0: GOTO 110

300 IF C = 0 THEN GOTO 360
310 GOSUB 500
320 PRINT L$; " "; A$
360 CLOSE #1
370 END

400 REM O to O$ as 4-digit hex number
410 T = O / 4096
420 U = O MOD 4096
430 O$ = MID$(H$, T + 1, 1)
440 T = U / 256
450 U = U MOD 256
460 O$ = O$ + MID$(H$, T + 1, 1)
470 T = U / 16
480 U = U MOD 16
490 O$ = O$ + MID$(H$, T + 1, 1)
495 O$ = O$ + MID$(H$, U + 1, 1)
497 RETURN

500 REM padding remaining line in hex part to 16 bytes
510 IF C >= 16 THEN RETURN
520 P = 16 - C
530 IF P = 0 THEN RETURN
540 L$ = L$ + "   "
550 P = P - 1
560 GOTO 530
