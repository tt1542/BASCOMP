' ===============================================================
' BASCOMP.BAS
' ===============================================================
' +-------------------------------------------------------------+
' | GLOBAL VARIABLE MAP                                         |
' +-------------------------------------------------------------+
'
' === MAIN INPUT, MODE AND DISPATCH =============================
' A = current BASIC source line number
' A$ = current input line
' QBLINE = generated line number in unnumbered/QBasic-style mode
' SRCMODE = -1 unknown, 0 numbered source, 1 unnumbered source
' LNO = last accepted line number in numbered source mode
' R$ = current source remainder, PRINT list, or THEN list
' B$ = current statement or THEN sub-statement
' N = more sub-statements pending in current source line
' M = nested dispatcher return depth for THEN processing
' DISPMODE = nested dispatcher flag
'
' === GENERAL SCANNER AND SCRATCH REGISTERS =====================
' I/J/K/L = scan positions, bounds, comma positions, parser indices
' P/Q = statement splitter positions
' O/S = quote flags in general scanners
' E/F/G/H = numeric helpers, flags, lengths, limits, precedence
' T/U = temporary numeric helpers and saved parser state
' V = current target or label number
' R = global generated symbol/label counter
' W/X/Y/Z = general scratch registers
' MC = current character code in general scanners
' CMC = current character code in constant-expression scanner
'
' === COMMON STRING SCRATCH AND IDENTIFIERS ======================
' D$ = target variable or helper string
' E$ = current expression, RHS, or source fragment
' Z$ = target string variable or helper string
' N$ = numeric subexpression or function argument
' I$ = THEN label or saved THEN splitter remainder
' K$ = dispatcher keyword, PRINT item, or "call "/"jmp " prefix
' L$ = literal, identifier, file text, DB/ASCIIZ payload
' Q$ = five-digit generated label text
' X$ = current string expression for SI or input filename
' Y$ = current string expression for DI or output filename
' W$ = general string scratch
' SAVEDID$ = saved identifier name or short-lived FOR/NEXT codegen scratch
' IDKIND = READID type flag, 0 numeric / 1 string
' CLOSEPAR = saved matching closing parenthesis
' XC$(40) = saved L$ in numeric factor lookahead
' ER = compiler error code for shared error message dispatcher
'
' === NUMERIC EXPRESSION PARSER =================================
' TK = token code: 0 EOF, 1 MOD, 2 XOR, 3 AND, 4 OR, 5 NOT, else ASCII
' C = current minimum precedence
' OP = numeric/logical operator helper
' OPC = IF comparison code: 1 =, 2 <, 3 >, 4 <>, 5 <=, 6 >=
' OH/TH = saved H values during token lookahead
' LO = quote flag in low-level comma/parenthesis scanners
' EXPDEPTH = recursive EXPR C-stack depth
' EC1..EC4 = saved C values for EXPDEPTH
' NUMDEPTH = numeric parser context depth
' ND1..ND4 = saved D for NUMCTX
' NC1..NC4 = saved C for NUMCTX
' NK1..NK4 = saved TK for NUMCTX
' NJ1..NJ4 = saved J for NUMCTX
' NH1..NH4 = saved H for NUMCTX
' NP1..NP4 = saved CLOSEPAR for NUMCTX
'
' === NUMERIC CONSTANT FOLDING ==================================
' COK = constant-folding success flag
' CVAL = current constant value or final folded result
' CD = current scan position in N$; CMC = current character code
' CFLEV = constant-folding value/operator stack depth
' CLEFT/COP = saved left operand and operator during reduction
' CDIG/CHEX = current digit value and hexadecimal digit count
' CF(1..8)/CO(1..8) = saved values/operators for nested reductions
'
' === STRING LEXER, STRING PARSER AND STRING FUNCTIONS ==========
' OT = string lexer token type
' FL = string function token length
' STRLEVEL = string expression parser depth
' OLDSTRDP = saved STRLEVEL while comparing string expressions in IF
' FUNLEVEL = nested string-function depth
' FNE1..FNE4 = saved continuation positions after string function calls
' STRDEPTH = string parser context depth
' SD1..SD8 = saved D for STRCTX
' SC1..SC8 = saved C for STRCTX
' ST1..ST8 = saved TK for STRCTX
' SJN1..SJN8 = saved J for STRCTX
' SH1..SH8 = saved H for STRCTX
'
' === EXTENDED STRING CONTEXT STORAGE XC ========================
' XC$(1..45) = shared fixed-length compiler context storage
' XC$(1..4) = saved numeric E$ contexts
' XC$(5..8), XC$(27..28), XC$(33..34) = saved string E$ contexts
' XC$(9..12) = saved FUNDEPTH E$ contexts
' XC$(13..16), XC$(29..30), XC$(35..36) = saved L$ contexts
' XC$(17..20), XC$(31..32), XC$(37..38) = saved X$ contexts
' XC$(21..24) = saved SRCDEPTH E$ contexts
' XC$(25..26) = saved nested THEN/ELSE branch text
' XC$(39) = active ELSE branch text
' XC$(40) = saved L$ in numeric factor lookahead
' XC$(41) = shared nonrecursive expression/remainder scratch
' XC$(42..45) = saved XC$(41) for BOOLDEP levels 1..4
'
' === SOURCE, STRFUN AND THEN/ELSE CONTEXT STACKS ===============
' SRCDEPTH = source context stack depth
' SRP1..SRP4 = saved CLOSEPAR for SRCDEPTH
' SRJ1..SRJ4 = saved J for SRCDEPTH
' SRH1..SRH4 = saved H for SRCDEPTH
' SRO1..SRO4 = saved O for SRCDEPTH
' FUNDEPTH = string-function helper context depth
' OFD1..OFD4 = saved D for FUNDEPTH
' OFC1..OFC4 = saved C for FUNDEPTH
' OFT1..OFT4 = saved TK for FUNDEPTH
' OFH1..OFH4 = saved H for FUNDEPTH
' IFCTX = nested THEN/ELSE context depth
' TSK1/TSK2 = saved FALSELBL
' TEND1/TEND2 = saved ENDIFLBL
' TEL1/TEL2 = saved HASELSE
'
' === IF / ELSE / SELECT CASE STATE =============================
' FALSELBL = active numeric false/skip label
' HASELSE = ELSE flag in current single-line IF
' ENDIFLBL = label after THEN/ELSE block
' XC$(39) = active ELSE branch text
' NOTPAR = parity of leading NOT operators for current IF atom
' BOOLDEP = nested boolean parenthesis context depth
' BT$(1..4) = saved outer boolean TRUE label strings
' BF$(1..4) = saved outer boolean FALSE label strings
' BSK(1..4) = saved outer numeric false/skip labels
' IFLEVEL = block IF stack depth
' IFN1..IFN4 = block IF next/false labels
' IFE1..IFE4 = block IF end labels
' IFS1..IFS4 = block IF ELSE-seen flags
' CURFALSE/CURENDIF/CURELSE = current block IF stack entry
' SELMODE = SELECT CASE active flag
' SELSTR = SELECT CASE type: 0 numeric, 1 string
' CASEBODY = normal statements allowed in current CASE body
' NEXTCASE/ENDSEL = SELECT CASE next/end labels
' HASCELSE = CASE ELSE already seen
'
' === FOR / WHILE / LOOP STATE ==================================
' B = FOR/WHILE/DO stack depth
' S$/T$/U$/V$ = saved FOR variable names for levels 1..4
' LL(1..4) = FOR label or WHILE/DO start label per loop level
' LS(1..4) = FOR STEP or WHILE/DO end label per loop level
' LT(1..4) = loop type per level: 0 FOR, 1 WHILE, 2 DO
' FS = temporary FOR STEP
' LOOPHEAD/LOOPEXIT = current WHILE start/end labels
' DOKIND = DO/LOOP condition kind used while compiling a statement
'
' === DATA, FILES, PRINT, INPUT AND TARGET RESOLUTION ===========
' DA = most recently generated DATA record label, 0 before first DATA
' UDA = REQ DA emission flag
' FC = current file channel 1..9
' OGT/OGC/OGE = ON GOTO/GOSUB table/check/end labels
' OGK = ON target kind, 4 GOTO / 5 GOSUB
' K$ also stores "call " or "jmp " in common GOTO/GOSUB resolution
'
' === UPPERCASE NORMALIZATION ==================================
' UCQ = position of first source-space in numbered mode
' UCI = uppercase scanner index
' UCO = quote flag while uppercasing source text
' UCCH = current character while uppercasing
' R$ is used as uppercased source output buffer during 12010
'
' === GRAPHICS AND DRAWING SCRATCH ==============================
' L1..L8 = LINE/CIRCLE/PSET parser positions, options, temporary values
'
' === RUNTIME REQUIREMENT FLAGS =================================
' UPR = REQ PR; UIN = REQ IN; UFI = REQ FI; UST = REQ ST
' UCV = REQ CV; UAR = REQ AR; UBI = REQ BI; UPN = REQ PN
' USO = REQ SO; UGR = REQ GR; URN = REQ RN; UMT = REQ MT
' UXA = REQ XA; UDT = REQ DT; UTS = REQ TS; UTM = REQ TM
' UEX = REQ EX; UCP = REQ CP; UPK = REQ PK; UIO = REQ IO
' UDR = REQ DR; UFL = REQ FL; UBP = REQ BP; UIX = REQ IX
' UBK = REQ BK; UDV = REQ DV
' UT4/UT5/UT6 = REQ flags for TMP4$/TMP5$/TMP6$
'
' === RUNTIME SYMBOLS EMITTED BY THE COMPILER ===================
' TMP$/TMP2$/TMP3$..TMP6$ = temporary runtime strings
' NB = shared 257-byte runtime I/O and conversion buffer
' CURDIR$ = current directory buffer
' N_SCSELV = generated numeric SELECT CASE selector storage
' S_SCSELS = generated string SELECT CASE selector storage
' S_A = emitted string buffer backing WORD ARRAY A(I)
' ARRCLR/ARRGETB/ARRSETB = runtime WORD ARRAY helpers
'
' === COMMAND LINE AND FILE NAME HELPERS ========================
' X$ = input filename or active string expression
' Y$ = output filename or destination string expression
' filename/path character parsing uses MC
'
' === SYSTEM, FILE, MEMORY AND DEVICE FEATURE SCRATCH ===========
' PEEK/POKE/DEF SEG/CALLINT use I/J/K/L/F/G/H/N$/D$/L$ as parser scratch
' TIMER/RANDOMIZE/EXEC/CPUID/INP/OUT use shared expression/parser scratch
' CHDIR/MKDIR/RMDIR/FILES use X$/D$/L$/N$ and REQ flags
' XALLOC/XSET/XFREE/XGET$ use XC plus numeric/string parser contexts
'
' === PARSER NOTES ==============================================
' READID returns identifier in L$ and type flag in H
' FORMATQ formats V into Q$
' NEXTSYM increments R, stores new symbol number in V, then formats Q$
' ERROR jumps set ER and dispatch through the shared message table
'
' === ACTIVE VARIABLE SET SUMMARY ===============================
' Scalars: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
' Extra scalars: MC CMC TK OP OPC ER FC FL OT LO OH TH CLOSEPAR IDKIND
' Constant-folding scalars: COK CVAL CD CFLEV CLEFT COP CDIG CHEX
' DATA scalars: DA UDA
' Context scalars: NUMDEPTH STRDEPTH SRCDEPTH FUNDEPTH EXPDEPTH IFCTX BOOLDEP STRLEVEL OLDSTRDP FUNLEVEL
' IF scalars: FALSELBL HASELSE ENDIFLBL NOTPAR IFLEVEL CURFALSE CURENDIF CURELSE
' SELECT scalars: SELMODE SELSTR CASEBODY NEXTCASE ENDSEL HASCELSE
' SCSELS = generated SELECT CASE string selector variable
' LOOP scalars: FS LOOPHEAD LOOPEXIT DOKIND
' LOOP arrays: LL LS LT
' Mode scalars: QBLINE SRCMODE DISPMODE LNO
' Uppercase scalars: UCQ UCI UCO UCCH
' Graphics scalars: L1 L2 L3 L4 L5 L6 L7 L8
' String variables: A$ B$ D$ E$ I$ K$ L$ N$ Q$ R$ S$ T$ U$ V$ W$ X$ Y$ Z$
' Other strings: SAVEDID$
' Boolean context strings: BT$(1..4), BF$(1..4)
'
' === CONTEXT VARIABLE SET SUMMARY ==============================
' NUMCTX: ND1 ND2 ND3 ND4 NC1 NC2 NC3 NC4 NK1 NK2 NK3 NK4
' NUMCTX: NJ1 NJ2 NJ3 NJ4 NH1 NH2 NH3 NH4 NP1 NP2 NP3 NP4
' STRCTX: SD1 SD2 SD3 SD4 SD5 SD6 SD7 SD8
' STRCTX: SC1 SC2 SC3 SC4 SC5 SC6 SC7 SC8
' STRCTX: ST1 ST2 ST3 ST4 ST5 ST6 ST7 ST8
' STRCTX: SJN1 SJN2 SJN3 SJN4 SJN5 SJN6 SJN7 SJN8
' STRCTX: SH1 SH2 SH3 SH4 SH5 SH6 SH7 SH8
' SRCDEPTH: SRJ1..SRJ4 SRH1..SRH4 SRO1..SRO4 SRP1..SRP4
' FUNDEPTH: OFD1 OFD2 OFD3 OFD4 OFC1 OFC2 OFC3 OFC4
' FUNDEPTH: OFT1 OFT2 OFT3 OFT4 OFH1 OFH2 OFH3 OFH4
' EXPRC: EC1 EC2 EC3 EC4
' STRFUN: FNE1 FNE2 FNE3 FNE4
' BLOCK IF: IFN1 IFN2 IFN3 IFN4 IFE1 IFE2 IFE3 IFE4 IFS1 IFS2 IFS3 IFS4
' THENI: TSK1 TSK2 TEND1 TEND2 TEL1 TEL2
' BOOLCTX: BT$(1..4) BF$(1..4) BSK(1..4); XC$(42..45) save XC$(41)
' LOOPCTX: LL1..LL4 LS1..LS4 LT1..LT4 via arrays LL/LS/LT
' CONSTNUM: CF1..CF8 CO1..CO8 via arrays CF/CO
'
' === REQ FLAG SET SUMMARY =====================================
' UPR UIN UFI UST UCV UAR UBI UPN USO UGR URN UMT UXA UDT UTS UTM
' UEX UCP UPK UIO UDR UFL UBP UIX UBK UDV UT4 UT5 UT6 UDA
'
' === EMITTED RUNTIME NAME SUMMARY ==============================
' TMP$ TMP2$ TMP3$ TMP4$ TMP5$ TMP6$ NB CURDIR$ SCSELV SCSELS S_A
' ARRCLR ARRGETB ARRSETB
'
' === LIMITS ====================================================
' FOR/WHILE stack depth <= 4
' BLOCK IF stack depth <= 4
' NUMCTX/SRCDEPTH/FUNDEPTH/BOOLDEP depth <= 4
' STRCTX depth <= 8; IFCTX depth <= 2; STRLEVEL/FUNLEVEL checked by parser
' File channels are 1..9; small emitted WORD ARRAY cells are 1..127; larger arrays use external descriptors
' ===============================================================
' During the following part, some pre-initialized strings from HEADER.ASM
' are being printed.
Print X$
Print A$
Print B$
Print R$
Print K$
Print D$
X$ = Trim$(Command$)
If Len(X$) <> 0 Then Goto L_BOOT_01
Print N$
Input X$
X$ = Trim$(X$)
L_BOOT_01:
Gosub L_CMD_LINE_PARSE
If E <> 0 Then Print E$: End 1
Open X$ For Input As #1
Close #1
Open Y$ For Output As #2
Print F$; X$; I$; Y$
' ---------------- ASM header -------------
D$ = Progdir$ + "HEADER.ASM"
Gosub L_COPY_INCLUDE_F
Dim XC$(45) As String * 255
Dim SD(8)
Dim SC(8)
Dim ST(8)
Dim SJN(8)
Dim SH(8)
Dim ND(4)
Dim NC(4)
Dim NK(4)
Dim NJ(4)
Dim NH(4)
Dim NP(4)
Dim EC(4)
Dim SRJ(4)
Dim SRH(4)
Dim SRO(4)
Dim SRP(4)
Dim OFD(4)
Dim OFC(4)
Dim OFT(4)
Dim OFH(4)
Dim TSK(2)
Dim TEND(2)
Dim TEL(2)
Dim IFN(4)
Dim IFE(4)
Dim IFS(4)
Dim LL(4)
Dim LS(4)
Dim LT(4)
SRCMODE = -1
Dim CF(8)
Dim CO(8)
Dim BT$(4) As String * 5
Dim BF$(4) As String * 5
Dim BSK(4)
Dim S$ As String * 8
Dim T$ As String * 8
Dim U$ As String * 8
Dim V$ As String * 8
Dim Q$ As String * 5
Dim SAVEDID$ As String * 8
Dim Z$ As String * 8
QBLINE = 1
LNO = 0
Open X$ For Input As #1
Goto L_MAIN_LOOP
' === MAIN LOOP: READ SOURCE LINE BY LINE ===

' ===============================================================
' GLOBAL LABEL GENERATION AND FORMATTING
' ===============================================================

L_NEXTSYM:
' ---- NEXTSYM: global label number to Q$ ----
R = R + 1
V = R
Goto L_FORMATQ
L_EMITDBL:
' ---- EMITDBL: output L$ as a length-prefixed byte list ----
Print #2, "DB "; Len(L$)
L_EMITDBBY:
' ---- EMITDBBYTES: output L$ as raw DB bytes ----
K = 1
L_EMITDBBY_01:
If K > Len(L$) Then Return
Print #2, "DB "; Asc(Mid$(L$, K, 1))
K = K + 1
Goto L_EMITDBBY_01
L_FORMATQ:
' ---- FORMATQ: format V as a five-digit label number into Q$ ----
Q$ = Right$("00000" + Str$(V), 5)
Return
L_COPY_INCLUDE_F:
' ---- COPY INCLUDE FILE D$ TO #2 ----
Open D$ For Input As #1
L_COPY_INCLUD_01:
If Eof(1) <> 0 Then Close #1: Return
Line Input #1, A$
Print #2, A$
Goto L_COPY_INCLUD_01

' ===============================================================
' MAIN SOURCE INPUT AND DISPATCH LOOP
' ===============================================================

L_MAIN_LOOP:
' ---------------- Main loop ---------
' Read source line by line via LINE INPUT.
' A real end-of-file terminates compilation.
L_MAIN_LOOP_01:
If Eof(1) <> 0 Then Goto L_FOOTER_RUNTIME
Line Input #1, A$
Gosub L_TIE_UPPERCAS_S
A$ = Trim$(A$)
If Len(A$) = 0 Then Goto L_MAIN_LOOP_01
If SRCMODE <> -1 Then Goto L_MAIN_LOOP_02
Gosub L_LEFT_MC_2: If MC >= 48 And MC <= 57 Then SRCMODE = 0 Else SRCMODE = 1
L_MAIN_LOOP_02:
If SRCMODE = 0 Then Goto L_MAIN_LOOP_03
Gosub L_LEFT_MC_2: If MC >= 48 And MC <= 57 Then Goto L_END_02
A = QBLINE
QBLINE = QBLINE + 1
Goto L_COMP_LINE
L_MAIN_LOOP_03:
Gosub L_FLSEP: If I = 0 Then D$ = A$ Else D$ = Left$(A$, I - 1)
J = 1
L_MAIN_LOOP_04:
If J > Len(D$) Then Goto L_MAIN_LOOP_05
MC = Asc(Mid$(D$, J, 1)): If MC < 48 Or MC > 57 Then Goto L_END_04
J = J + 1
Goto L_MAIN_LOOP_04
L_MAIN_LOOP_05:
A = Val(D$): If A < 1 Or A > 32767 Then Goto L_END_04
If A <= LNO Then Goto L_END_04
LNO = A
L_COMP_LINE:
' ---------------- Compile one line -
V = A
Gosub L_FORMATQ
Gosub L_FLSEP
If SRCMODE <> 0 Then Goto L_COMP_LINE_01
If I = 0 Then Goto L_MAIN_LOOP
R$ = Mid$(A$, I + 1, Len(A$) - I)
Goto L_COMP_LINE_02
L_COMP_LINE_01:
R$ = A$
Gosub L_QB_LBL_LINE
If E = 0 Then Goto L_COMP_LINE_02
Print #2, "L"; Q$; ":"
Print #2, "QB_"; L$; ":"
Goto L_MAIN_LOOP
L_COMP_LINE_02:
R$ = Ltrim$(R$)
If Len(R$) = 0 Then Goto L_MAIN_LOOP
Print #2, "L"; Q$; ":"
' ---- Splitter for sub-statements in R$ ----
P = 1
Gosub L_FIND_STMT
L_TRIM_BOTH_SIDE:
' ---- Trim B$ on both sides ----
B$ = Trim$(B$)
If Len(B$) = 0 Then Goto L_CONTINUE_SUB_S
Goto L_DISPATCH
L_CONTINUE_SUB_S:
' ---- Continue after a sub-statement ----
If M = 0 Then Goto L_CONTINUE_SU_01
M = M - 1
Return
L_CONTINUE_SU_01:
If N = 0 Then Goto L_MAIN_LOOP
P = Q + 1
Gosub L_FIND_STMT
Goto L_TRIM_BOTH_SIDE
L_DISPATCH:
' ---------------- Dispatcher -------------
DISPMODE = 0
' Pre-check for DIM
K$ = "DIM"
Gosub L_CHECK_WHETHER
If E = 0 Then Goto L_DISPATCH_WRAPP
Gosub L_CHECK_WHETH_03
Goto L_DIM

' ===============================================================
' STATEMENT RECOGNITION AND DISPATCH
' ===============================================================

L_CHECK_WHETHER:
' ---- check whether B$ starts with K$ as a real statement ----
E = 0
I = Len(K$)
If Len(B$) < I Then Return
J = 1
L_CHECK_WHETH_01:
If J > I Then Goto L_CHECK_WHETH_02
MC = Asc(Mid$(B$, J, 1))
If MC <> Asc(Mid$(K$, J, 1)) Then Return
J = J + 1
Goto L_CHECK_WHETH_01
L_CHECK_WHETH_02:
If Len(B$) = I Then E = 1: Return
MC = Asc(Mid$(B$, I + 1, 1))
If MC >= 65 And MC <= 90 Or MC >= 48 And MC <= 57 Or MC = 95 Or MC = 36 Then Return
E = 1
Return
' ---- wrapper setup for common dispatcher ----
L_CHECK_WHETH_03:
If DISPMODE = 0 Then Return
M = M + 1
Return
L_DISPATCH_WRAPP:
' ---- common dispatcher / wrapper entry ----
If SELMODE = 0 Or CASEBODY <> 0 Then Goto L_DISPATCH_WR_01
If Left$(B$, 4) = "CASE" Or B$ = "END SELECT" Then Goto L_DISPATCH_WR_02
Goto L_END_02
L_DISPATCH_WR_01:
MC = Asc(Left$(B$, 1))
If MC = 63 Then B$ = "PRINT " + Mid$(B$, 2, Len(B$) - 1): Gosub L_CHECK_WHETH_03: Goto L_PRINT_PRINT
If MC = 33 Then B$ = "INPUT " + Mid$(B$, 2, Len(B$) - 1): Gosub L_CHECK_WHETH_03: Goto L_LET_01
If B$ = "." Then B$ = "END": Gosub L_CHECK_WHETH_03: Goto L_END
If Left$(B$, 2) = ". " Then B$ = "END " + Mid$(B$, 3, Len(B$) - 2): Gosub L_CHECK_WHETH_03: Goto L_END
If MC = 91 Then Goto L_INLINE_ASSEMBL
If MC = 39 Then Goto L_DISPATCH_WR_03
L_DISPATCH_WR_02:
K$ = "REM"
Gosub L_CHECK_WHETHER
If E = 0 Then Goto L_DISPATCH_WR_04
L_DISPATCH_WR_03:
If DISPMODE = 0 Then N = 0: Goto L_CONTINUE_SUB_S
I$ = ""
Return
L_DISPATCH_WR_04:
K$ = "DATAB"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_DATAB
K$ = "DATA"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_DATA_DATAW
K$ = "READ"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_READ_NUM
K$ = "RESTORE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_REST
K$ = "CALLDATA"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CALLDATA_LINE
K$ = "LET"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_LET
If Left$(B$, 10) <> "LINE INPUT" Then Goto L_DISPATCH_WR_05
Gosub L_CHECK_WHETH_03
Goto L_LINE
L_DISPATCH_WR_05:
K$ = "INPUT"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_LET_01
K$ = "PRINT"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_PRINT_PRINT
K$ = "ELSEIF"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_BLOCK_ELSEIF
If B$ = "ELSE" Then Gosub L_CHECK_WHETH_03: Goto L_BLOCK
If B$ = "ENDIF" Or B$ = "END IF" Then Gosub L_CHECK_WHETH_03: Goto L_BLOCK_END
K$ = "IF"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_EXPR_OP_EXPR
K$ = "ON"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_EXPR_GOSUB_GOT
K$ = "GOSUB"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_GOSUB
K$ = "GOTO"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_GOTO
K$ = "RETURN"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_RET
K$ = "FOR"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_RET_01
K$ = "NEXT"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_RET_14
K$ = "WHILE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_WHILE_BEGIN
K$ = "WEND"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_WEND
K$ = "DO"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_DO_BEGIN
K$ = "LOOP"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_LOOP
K$ = "OPEN"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_OPEN
K$ = "CLOSE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CLOSE
K$ = "KILL"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_KILL
K$ = "CHDIR"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CHDIR_MKDIR_RM
K$ = "MKDIR"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CHDIR_MKDIR_RM
K$ = "RMDIR"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CHDIR_MKDIR_RM
K$ = "FILES"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_FILES
K$ = "LOCATE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: K = 8: Gosub L_END_01: Print #2, "call LOCATEC": Goto L_CONTINUE_SUB_S
K$ = "COLOR"
Gosub L_CHECK_WHETHER
If E = 0 Then Goto L_DISPATCH_WR_06
Gosub L_CHECK_WHETH_03
K = 7
Gosub L_END_01
Print #2, "call COLORC"
Goto L_CONTINUE_SUB_S
L_DISPATCH_WR_06:
K$ = "DEF"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_DEF_SEG
K$ = "RANDOMIZE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_RANDOMIZ
K$ = "CLS"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CLS
K$ = "BEEP"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_BEEP
K$ = "GET"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_GET
K$ = "PUT"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_PUT
K$ = "XSET"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_XSET_HANDLE_IN
K$ = "XFREE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_XFREE_HANDLE
K$ = "LINE": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_LINE_2
K$ = "SCREEN": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_SCREEN_MODE
K$ = "PSET": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_PSET_COLOR
K$ = "POKE": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_POKE_OFFSET_VA
K$ = "CIRCLE": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CIRCLE
K$ = "OUT": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_OUT_PORT_VALUE
K$ = "CALLINT": Gosub L_CHECK_WHETHER: If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_CALLINT_INTNO
K$ = "SELECT"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_SELECT_CASE
K$ = "CASE"
Gosub L_CHECK_WHETHER
If E = 0 Then Goto L_DISPATCH_WR_07
Gosub L_CHECK_WHETH_03
Goto L_CASE_CASE
L_DISPATCH_WR_07:
If B$ = "STOP" Then B$ = "END": Gosub L_CHECK_WHETH_03: Goto L_END
If Left$(B$, 5) = "STOP " Then B$ = "END " + Mid$(B$, 6, Len(B$) - 5): Gosub L_CHECK_WHETH_03: Goto L_END
K$ = "EXIT"
Gosub L_CHECK_WHETHER
If E = 0 Then Goto L_DISPATCH_WR_08
If B$ = "EXIT FOR" Then Gosub L_CHECK_WHETH_03: Goto L_END_EXIT_EXIT
If B$ = "EXIT SELECT" Then Gosub L_CHECK_WHETH_03: Goto L_EXIT_SELECT
If B$ = "EXIT WHILE" Then Gosub L_CHECK_WHETH_03: Goto L_EXIT_WHILE
If B$ = "EXIT DO" Then Gosub L_CHECK_WHETH_03: Goto L_EXIT_DO
L_DISPATCH_WR_08:
K$ = "ERASE"
Gosub L_CHECK_WHETHER
If E <> 0 Then Gosub L_CHECK_WHETH_03: Goto L_ERASE

K$ = "END"
Gosub L_CHECK_WHETHER
If E = 0 Then Goto L_IMPLICIT_LET_D
If B$ = "END SELECT" Then Gosub L_CHECK_WHETH_03: Goto L_END_SELECT
If B$ = "END WHILE" Then Gosub L_CHECK_WHETH_03: Goto L_WEND
If B$ = "END FOR" Then Gosub L_CHECK_WHETH_03: Goto L_END_EXIT_EXIT
Gosub L_CHECK_WHETH_03
Goto L_END
L_IMPLICIT_LET_D:
' === implicit LET in the common dispatcher ===
Gosub L_PUSH_STRCTX
E$ = B$
D = 1
Gosub L_READID
SAVEDID$ = L$
Gosub L_POP_STRCTX
If Len(SAVEDID$) = 0 Then Goto L_END_02
If Instr(B$, "=") = 0 Then Goto L_END_02
B$ = "LET " + B$
Gosub L_CHECK_WHETH_03

' ===============================================================
' ASSIGNMENTS AND DECLARATIONS
' ===============================================================

L_LET:
' ---------------- LET -------------------
I = Instr(B$, "=")
If I = 0 Then Goto L_END_02
D$ = Mid$(B$, 5, I - 5)
E$ = Mid$(B$, I + 1, Len(B$) - I)
' ---- trim D$ on both sides ----
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_02
' ---- trim E$ on the left ----
E$ = Ltrim$(E$)
If Len(E$) = 0 Then Goto L_END_02
Gosub L_LET_3
If E <> 0 Then Goto L_CONTINUE_SUB_S
Gosub L_RIGHT_MC: If MC = 36 Then Goto L_STR_ASSIGNME
Gosub L_NUM_LHS_DISPAT
Goto L_CONTINUE_SUB_S
L_STR_ASSIGNME:
' String assignments
' --- NEW STRING PARSER DISPATCH --- emit target string address to DI and push it before RHS evaluation
Z$ = Left$(D$, Len(D$) - 1)
Gosub L_EMIT_DS_DI
Gosub L_EMIT_PUSHDI
Gosub L_PURE_STR_LIT_2
If H <> 0 Then Gosub L_ASSIGN_PURE_ST: Goto L_CONTINUE_SUB_S
X$ = E$: Gosub L_HAS_TOP_PLUS: If E <> 0 Then Goto L_STR_ASSIGNM_01
Gosub L_COMP_SI
Gosub L_EMIT_POPDI
Gosub L_EMIT_STRCOPY
Goto L_CONTINUE_SUB_S
L_STR_ASSIGNM_01:
Gosub L_STR_EXPR_PARSE
Gosub L_EMIT_POPDI
Gosub L_EMIT_STRCOPY
Goto L_CONTINUE_SUB_S
L_DIM:
' ---------------- DIM --------------------
D$ = Mid$(B$, 4, Len(B$) - 3)
Gosub L_LTRIM
If Len(D$) = 0 Then Goto L_END_02
Gosub L_DIM_3
If E <> 0 Then Goto L_CONTINUE_SUB_S
Gosub L_DIM_2
If E <> 0 Then Goto L_DIM_STR
I = Instr(D$, "(")
If I = 0 Then Goto L_END_02
Gosub L_RIGHT_MC: If MC <> 41 Then Goto L_END_02
Z$ = Left$(D$, I - 1)
Z$ = Rtrim$(Z$)
If Len(Z$) = 0 Then Goto L_END_02
Gosub L_RIGHT_MC_2: If MC = 36 Then Goto L_END_02
N$ = Mid$(D$, I + 1, Len(D$) - I - 1)
Gosub L_EMIT_DSA
' COMPILE SIZE AS A NUMERIC EXPRESSION
E$ = N$
Gosub L_COMP_AX
Gosub L_EMIT_DS_DI
Gosub L_EMIT_REQ_AR
Print #2, "call ARRCLR"
Goto L_CONTINUE_SUB_S
L_NUM_LHS_DISPAT:
' ---- NUM LHS DISPATCH: SCALAR OR WORD ARRAY ----
I = Instr(D$, "(")
If I = 0 Then Goto L_NUM_SCALAR_PAT
Gosub L_RIGHT_MC: If MC <> 41 Then Goto L_END_02
Goto L_LET_2
L_NUM_SCALAR_PAT:
' ---- NUMERIC SCALAR ASSIGNMENT PATH ----
If E$ = "0" Then Print #2, "xor ax,ax": Gosub L_EMIT_STORE_AX: Return
' load target address to DI immediately and save it on the runtime stack
Print #2, "DN "; D$
Print #2, "mov di,OFFSET N_"; D$
Gosub L_EMIT_PUSHDI
Gosub L_COMP_AX
Gosub L_EMIT_POPDI
Print #2, "mov [di],ax"
Return
L_LET_2:
' ---- LET A(I)=EXPR FOR WORD ARRAY ----
Z$ = Left$(D$, I - 1)
Z$ = Rtrim$(Z$)
If Len(Z$) = 0 Then Goto L_END_02
N$ = Mid$(D$, I + 1, Len(D$) - I - 1)
' SAVE TARGET ARRAY IMMEDIATELY SO RECURSIVE RHS PATHS NO LONGER DISTURB Z$
Print #2, "DS "; Z$
Print #2, "mov si,OFFSET S_"; Z$
Print #2, "push si"
' COMPILE INDEX FIRST -> INDEX IS THEN ON THE STACK
Gosub L_COMP_NUM_SUBEX
' EVALUATE RIGHT SIDE -> VALUE IS THEN ON THE STACK ABOVE THE INDEX
Gosub L_COMP_AX
Gosub L_EMIT_POPBX
Print #2, "pop si"
Gosub L_EMIT_REQ_AR
Print #2, "call ARRSETB"
Return

' ===============================================================
' INPUT AND OUTPUT STATEMENTS
' ===============================================================

L_LET_01:
' ---------------- INPUT ["prompt",] var / var$ --------
D$ = Mid$(B$, 6, Len(B$) - 5)
Gosub L_LTRIM
If Len(D$) = 0 Then Goto L_END_02
Gosub L_LEFT_MC: If MC <> 34 Then Goto L_PROC
' ---- scan optional prompt literal ----
J = 2
L_LET_02:
If J > Len(D$) Then Goto L_END_06
If Asc(Mid$(D$, J, 1)) = 34 Then Goto L_LET_03
J = J + 1
Goto L_LET_02
L_LET_03:
L$ = Mid$(D$, 2, J - 2)
If J >= Len(D$) Then Goto L_END_02
D$ = Mid$(D$, J + 1, Len(D$) - J)
Gosub L_LTRIM
If Len(D$) = 0 Then Goto L_END_02
Gosub L_LEFT_MC: If MC <> 44 Then Goto L_END_02
D$ = Mid$(D$, 2, Len(D$) - 1)
Gosub L_LTRIM
If Len(D$) = 0 Then Goto L_END_02
' ---- output prompt literal ----
Gosub L_EMIT_LIT_RAW
L_PROC:
' ---- normal INPUT processing ----
Gosub L_RIGHT_MC: If MC <> 36 Then Goto L_NUM
' ---- INPUT string ----
Z$ = Left$(D$, Len(D$) - 1)
Gosub L_EMIT_DS_DI
Gosub L_EMIT_CALL
Goto L_CONTINUE_SUB_S
L_NUM:
' ---- INPUT numeric ----
Print #2, "mov di,OFFSET NB"
Gosub L_EMIT_CALL
Print #2, "mov si,OFFSET NB"
Gosub L_EMIT_REQ_CV
Print #2, "call VAL"
Gosub L_EMIT_STORE_AX
Goto L_CONTINUE_SUB_S
L_LINE:
' ------------- LINE INPUT #n, A$ ----------
I = Instr(B$, "#")
J = Instr(B$, ",")
If I = 0 Or J = 0 Then Goto L_END_02
D$ = Mid$(B$, I + 1, J - I - 1): Gosub L_PARSE_CHANNEL
D$ = Mid$(B$, J + 1, Len(B$) - J)
Gosub L_LTRIM
If Len(D$) < 2 Then Goto L_END_02
Gosub L_RIGHT_MC: If MC <> 36 Then Goto L_END_02
If FC < 1 Or FC > 9 Then Goto L_END_02
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call GETHIN"
Z$ = Left$(D$, Len(D$) - 1)
Gosub L_EMIT_DS_DI
Gosub L_EMIT_REQ
Print #2, "call READ_LINEH"
Goto L_CONTINUE_SUB_S
L_PRINT_PRINT:
' ---------------- PRINT / PRINT # --------
XC$(41) = R$
FC = 0
If Left$(B$, 6) = "PRINT#" Then Goto L_PRINT_PRINT_01
If Left$(B$, 7) = "PRINT #" Then Goto L_PRINT_PRINT_01
R$ = Mid$(B$, 6, Len(B$) - 5)
Goto L_SPLIT_PRINT_LI
L_PRINT_PRINT_01:
I = Instr(B$, "#")
J = Instr(B$, ",")
If I = 0 Or J = 0 Then Goto L_END_02
D$ = Mid$(B$, I + 1, J - I - 1): Gosub L_PARSE_CHANNEL
If FC < 1 Or FC > 9 Then Goto L_END_02
R$ = Mid$(B$, J + 1, Len(B$) - J)
If FC <> 2 Then Goto L_SPLIT_PRINT_LI
E$ = Trim$(R$)
Gosub L_PURE_STR_LIT_2: If H = 0 Then Goto L_SPLIT_PRINT_LI
Gosub L_EMIT_LIT_RAWCR
R$ = XC$(41)
Goto L_CONTINUE_SUB_S
L_SPLIT_PRINT_LI:
' ---- split print list in R$ by ; ----
If Len(R$) = 0 Then Goto L_END_LINE_ENTIR
I = 1
S = 0
H = 0
L_SPLIT_PRINT_01:
If I > Len(R$) Then Goto L_SPLIT_PRINT_09
MC = Asc(Mid$(R$, I, 1))
If MC <> 34 Then Goto L_SPLIT_PRINT_03
If S <> 0 Then Goto L_SPLIT_PRINT_02
S = 1
Goto L_SPLIT_PRINT_08
L_SPLIT_PRINT_02:
S = 0
L_SPLIT_PRINT_03:
If S <> 0 Then Goto L_SPLIT_PRINT_08
If MC <> 40 Then Goto L_SPLIT_PRINT_04
H = H + 1
Goto L_SPLIT_PRINT_08
L_SPLIT_PRINT_04:
If MC <> 41 Then Goto L_SPLIT_PRINT_05
If H > 0 Then H = H - 1
Goto L_SPLIT_PRINT_08
L_SPLIT_PRINT_05:
If H <> 0 Then Goto L_SPLIT_PRINT_08
If MC = 59 Then Goto L_SPLIT_PRINT_06
If MC <> 44 Then Goto L_SPLIT_PRINT_08
L_SPLIT_PRINT_06:
K$ = Left$(R$, I - 1)
If I <> Len(R$) Then Goto L_SPLIT_PRINT_07
R$ = ""
Goto L_TRIM_BOTH_SI_2
L_SPLIT_PRINT_07:
R$ = Mid$(R$, I + 1, Len(R$) - I)
Goto L_TRIM_BOTH_SI_2
L_SPLIT_PRINT_08:
I = I + 1
Goto L_SPLIT_PRINT_01
L_SPLIT_PRINT_09:
K$ = R$
R$ = ""
L_TRIM_BOTH_SI_2:
' ---- trim K$ on both sides ----
K$ = Trim$(K$)
If Len(K$) = 0 Then Goto L_NUM_ITEM_01
' ---- determine item type ----
If Asc(Left$(K$, 1)) <> 34 Then Goto L_TRIM_BOTH_S_01
E$ = K$
Gosub L_PURE_STR_LIT_2
If H <> 0 Then Goto L_PURE_STR_LIT
Goto L_STR_EXPR_PRINT
L_TRIM_BOTH_S_01:
X$ = K$
Gosub L_HAS_TOP_PLUS
If E <> 0 Then Goto L_STR_EXPR_PRINT
If Left$(K$, 5) = "CHR$(" Then Goto L_PRINT_SPECIAL
If Left$(K$, 4) = "LEN(" Then Goto L_PRINT_SPECIA_2
If Left$(K$, 6) = "LEFT$(" Or Left$(K$, 5) = "MID$(" Or Left$(K$, 7) = "RIGHT$(" Then Goto L_STR_EXPR_PRINT
If Left$(K$, 7) = "LTRIM$(" Or Left$(K$, 6) = "TRIM$(" Or Left$(K$, 7) = "RTRIM$(" Then Goto L_STR_EXPR_PRINT
If Left$(K$, 5) = "STR$(" Or Left$(K$, 5) = "HEX$(" Or Left$(K$, 7) = "SPACE$(" Then Goto L_STR_EXPR_PRINT
If Left$(K$, 8) = "STRING$(" Or Left$(K$, 7) = "UCASE$(" Or Left$(K$, 6) = "XGET$(" Then Goto L_STR_EXPR_PRINT
I = Instr(K$, "$("): If I <> 0 Then If Instr(K$, "(") = I + 1 Then Goto L_STR_EXPR_PRINT
If K$ = "DATE$" Or K$ = "TIME$" Or K$ = "INKEY$" Or K$ = "INPUT$" Then Goto L_STR_EXPR_PRINT
If Len(K$) < 2 Then Goto L_NUM_ITEM
If Asc(Right$(K$, 1)) <> 36 Then Goto L_NUM_ITEM
Goto L_PRINT_SPECIA_3
L_PURE_STR_LIT:
' ---- pure string literal as PRINT item ----
Gosub L_EMIT_LIT_RAW
Goto L_NUM_ITEM_01
L_PRINT_SPECIAL:
' ---- PRINT SPECIAL CASE CHR$(numexpr) ----
E$ = Mid$(K$, 6, Len(K$) - 6)
Gosub L_COMP_AX
Gosub L_EMIT_PRINT_CHA
Gosub L_EMIT_REQ_PN
Print #2, "call WRITE_CHH"
Goto L_NUM_ITEM_01
L_PRINT_SPECIA_2:
' ---- PRINT SPECIAL CASE LEN(X$) FOR SIMPLE STRING VARIABLE ----
D$ = Mid$(K$, 5, Len(K$) - 5)
Gosub L_TRIM
E$ = D$
D = 1
Gosub L_READID
If Len(L$) = 0 Then Goto L_NUM_ITEM
If H = 0 Then Goto L_NUM_ITEM
If D <= Len(E$) Then Goto L_NUM_ITEM
D$ = L$
Gosub L_EMIT_DS_SI
Gosub L_EMIT_REQ_ST
Print #2, "call LEN"
Gosub L_EMIT_PRINT_CHA
Gosub L_EMIT_REQ_PN
Print #2, "call WRITE_NUMH"
Goto L_NUM_ITEM_01
L_STR_EXPR_PRINT:
' ---- string expression as PRINT item ----
E$ = K$
Gosub L_STR_EXPR_PARSE
Gosub L_EMIT_PRINT_CHA
Gosub L_EMIT_REQ_PR
Print #2, "call WRITE_RAW"
Goto L_NUM_ITEM_01
L_PRINT_SPECIA_3:
' ---- PRINT SPECIAL CASE STRING VARIABLE X$ ----
D$ = Left$(K$, Len(K$) - 1)
Gosub L_EMIT_PRINT_CHA
Gosub L_EMIT_DS_SI
Gosub L_EMIT_REQ_PR
Print #2, "call WRITE_RAW"
Goto L_NUM_ITEM_01
L_NUM_ITEM:
' ---- numeric item ----
E$ = K$
Gosub L_COMP_AX
Gosub L_EMIT_PRINT_CHA
Gosub L_EMIT_REQ_PN
Print #2, "call WRITE_NUMH"
' ---- next item or end of line ----
L_NUM_ITEM_01:
If Len(R$) = 0 Then Goto L_END_LINE_ENTIR
I = 1
S = 0
H = 0
Goto L_SPLIT_PRINT_01
L_END_LINE_ENTIR:
' ---- end of line for entire print list ----
MC = Asc(Right$(B$, 1))
If MC = 59 Or MC = 44 Then Goto L_END_LINE_EN_01
Gosub L_EMIT_PRINT_CHA
Gosub L_EMIT_REQ_PR
Print #2, "call WRITE_CRLFH"
L_END_LINE_EN_01:
If FC <> 0 Then Goto L_END_LINE_EN_02
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
L_END_LINE_EN_02:
R$ = XC$(41)
Goto L_CONTINUE_SUB_S
L_EMIT_PRINT_CHA:
' ---- emit current PRINT channel to BX ----
If FC <> 0 Then Goto L_EMIT_PRINT_01
Print #2, "mov bx,1"
Return
L_EMIT_PRINT_01:
Goto L_EMIT_GETHOUT_K
L_EMIT_LIT_RAW:
' ---- EMIT_LITERAL_RAW: output L$ via WRITE_RAW ----
Gosub L_NEXTSYM
Print #2, "jmp PLX_"; Q$
Print #2, "PLD_"; Q$; ":"
Gosub L_EMITDBL
Print #2, "PLX_"; Q$; ":"
Gosub L_EMIT_PRINT_CHA
Print #2, "mov si,OFFSET PLD_"; Q$
Gosub L_EMIT_REQ_PR
Print #2, "call WRITE_RAW"
Return
L_EXPR_OP_EXPR:
' ---------------- IF <expr> <op> <expr> THEN <stmts> ----------
Goto L_BOOL_EXPR_STMT

' ===============================================================
' SELECT CASE COMPILATION
' ===============================================================

L_SELECT_CASE:
' ---------------- SELECT CASE -------------
If SELMODE <> 0 Then Goto L_END_02
If Left$(B$, 11) <> "SELECT CASE" Then Goto L_END_02
If Len(B$) = 11 Then Goto L_END_02
If Asc(Mid$(B$, 12, 1)) <> 32 Then Goto L_END_02

E$ = Mid$(B$, 12, Len(B$) - 11)
E$ = Ltrim$(E$)
If Len(E$) = 0 Then Goto L_END_02

A$ = E$
Gosub L_CHECK_WHETHE_2
SELSTR = E
If SELSTR <> 0 Then Goto L_SELECT_CASE_01

Gosub L_COMP_AX
Print #2, "DN SCSELV"
Print #2, "mov [N_SCSELV],ax"
Goto L_SELECT_CASE_02

L_SELECT_CASE_01:
X$ = E$
Gosub L_STR_EXPR_PARSE
Print #2, "DS SCSELS"
Print #2, "mov di,OFFSET S_SCSELS"
Gosub L_EMIT_STRCOPY

L_SELECT_CASE_02:
Gosub L_NEXTSYM
ENDSEL = V
SELMODE = 1
CASEBODY = 0
HASCELSE = 0
NEXTCASE = 0
Goto L_CONTINUE_SUB_S
L_CASE_CASE:
' ---------------- CASE / CASE ELSE --------
If SELMODE = 0 Then Goto L_END_02
If B$ = "CASE ELSE" Then Goto L_CASE
If HASCELSE <> 0 Then Goto L_END_02
If Left$(B$, 5) <> "CASE " Then Goto L_END_02

N$ = Mid$(B$, 6, Len(B$) - 5)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02

Gosub L_FINISH_CASE_BO
Gosub L_EMIT_OPEN_NEXT
Gosub L_NEXTSYM
NEXTCASE = V

If SELSTR <> 0 Then Goto L_CASE_CASE_01

Gosub L_NEXTSYM
W = V
W$ = N$
L_CASE_NUM_LOOP:
E$ = W$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then N$ = W$: W$ = "": Goto L_CASE_NUM_ITEM
N$ = Left$(W$, F - 1)
W$ = Mid$(W$, F + 1, Len(W$) - F)
If Len(W$) = 0 Then Goto L_END_02
L_CASE_NUM_ITEM:
N$ = Trim$(N$)
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Print #2, "DN SCSELV"
Print #2, "mov ax,[N_SCSELV]"
Print #2, "cmp ax,bx"
V = W
Gosub L_FORMATQ
Print #2, "je SCM_"; Q$
If Len(W$) <> 0 Then Goto L_CASE_NUM_LOOP
V = NEXTCASE
Gosub L_FORMATQ
Print #2, "jmp SCN_"; Q$
V = W
Gosub L_FORMATQ
Print #2, "SCM_"; Q$; ":"
Goto L_CASE_CASE_03

L_CASE_CASE_01:
Gosub L_NEXTSYM
W = V
W$ = N$
L_CASE_STR_LOOP:
E$ = W$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then X$ = W$: W$ = "": Goto L_CASE_STR_ITEM
X$ = Left$(W$, F - 1)
W$ = Mid$(W$, F + 1, Len(W$) - F)
If Len(W$) = 0 Then Goto L_END_02
L_CASE_STR_ITEM:
X$ = Trim$(X$)
If Len(X$) = 0 Then Goto L_END_02
Gosub L_COMP_SI
Print #2, "mov di,si"
Print #2, "DS SCSELS"
Print #2, "mov si,OFFSET S_SCSELS"
Print #2, "call STRCMP"
Print #2, "cmp al,0"
V = W
Gosub L_FORMATQ
Print #2, "je SCM_"; Q$
If Len(W$) <> 0 Then Goto L_CASE_STR_LOOP
V = NEXTCASE
Gosub L_FORMATQ
Print #2, "jmp SCN_"; Q$
V = W
Gosub L_FORMATQ
Print #2, "SCM_"; Q$; ":"
Goto L_CASE_CASE_03

L_CASE_CASE_02:
V = NEXTCASE
Gosub L_FORMATQ
Print #2, "jne SCN_"; Q$
L_CASE_CASE_03:
CASEBODY = 1
Goto L_CONTINUE_SUB_S
L_CASE:
' ---------------- CASE ELSE ---------------
If HASCELSE <> 0 Then Goto L_END_02
Gosub L_FINISH_CASE_BO
Gosub L_EMIT_OPEN_NEXT
HASCELSE = 1
CASEBODY = 1
NEXTCASE = 0
Goto L_CONTINUE_SUB_S
L_END_SELECT:
' ---------------- END SELECT --------------
If SELMODE = 0 Then Goto L_END_02
Gosub L_EMIT_OPEN_NEXT
V = ENDSEL
Gosub L_FORMATQ
Print #2, "SCE_"; Q$; ":"
SELMODE = 0
SELSTR = 0
Goto L_CONTINUE_SUB_S
L_FINISH_CASE_BO:
' ---- FINISH CURRENT CASE BODY AT SELECT END ----
If CASEBODY <> 0 Then Goto L_FINISH_CASE_01
Return
L_FINISH_CASE_01:
V = ENDSEL
Gosub L_FORMATQ
Print #2, "jmp SCE_"; Q$
Return
L_EMIT_OPEN_NEXT:
' ---- EMIT OPEN NEXTCASE LABEL ----
If NEXTCASE = 0 Then Return
V = NEXTCASE
Gosub L_FORMATQ
Print #2, "SCN_"; Q$; ":"
Return
L_FIND_TOP_LEVEL:
' ---- find first top-level ELSE in R$, result in F ----
F = 0
H = 0
S = 0
T = 0
I = 1
L_FIND_TOP_LE_01:
If I > Len(R$) - 3 Then Return
MC = Asc(Mid$(R$, I, 1))
If MC <> 34 Then Goto L_FIND_TOP_LE_02
If S = 0 Then S = 1 Else S = 0
Goto L_FIND_TOP_LE_08
L_FIND_TOP_LE_02:
If S <> 0 Then Goto L_FIND_TOP_LE_08
If MC <> 40 Then Goto L_FIND_TOP_LE_03
H = H + 1
Goto L_FIND_TOP_LE_08
L_FIND_TOP_LE_03:
If MC <> 41 Then Goto L_FIND_TOP_LE_04
H = H - 1
Goto L_FIND_TOP_LE_08
L_FIND_TOP_LE_04:
If H <> 0 Then Goto L_FIND_TOP_LE_08
' ---- detect nested single-line IF ----
If Mid$(R$, I, 3) <> "IF " Then Goto L_FIND_TOP_LE_05
If I = 1 Then T = T + 1: Goto L_FIND_TOP_LE_08
MC = Asc(Mid$(R$, I - 1, 1))
If MC = 32 Or MC = 58 Then T = T + 1: Goto L_FIND_TOP_LE_08
L_FIND_TOP_LE_05:
If Mid$(R$, I, 4) <> "ELSE" Then Goto L_FIND_TOP_LE_08
If I = 1 Then Goto L_FIND_TOP_LE_06
MC = Asc(Mid$(R$, I - 1, 1))
If MC <> 32 And MC <> 58 Then Goto L_FIND_TOP_LE_08
L_FIND_TOP_LE_06:
If T = 0 Then Goto L_FIND_TOP_LE_07
T = T - 1
Goto L_FIND_TOP_LE_08
L_FIND_TOP_LE_07:
If I + 4 > Len(R$) Then F = I: Return
MC = Asc(Mid$(R$, I + 4, 1))
If MC >= 65 And MC <= 90 Or MC >= 48 And MC <= 57 Or MC = 95 Or MC = 36 Then Goto L_FIND_TOP_LE_08
F = I
Return
L_FIND_TOP_LE_08:
I = I + 1
Goto L_FIND_TOP_LE_01
L_SPLIT_PART_SUB:
' ---- split THEN part into sub-statements and execute ----
P = 1
L_SPLIT_PART_01:
Gosub L_FIND_STMT
B$ = Trim$(B$)
If Len(B$) = 0 Then Goto L_SPLIT_PART_03
If Left$(B$, 2) <> "IF" Then Goto L_SPLIT_PART_02
Gosub L_PUSH_THENI
DISPMODE = 1
Gosub L_DISPATCH_WRAPP
DISPMODE = 0
Gosub L_POP_THENI
Goto L_SPLIT_PART_03
L_SPLIT_PART_02:
DISPMODE = 1
Gosub L_DISPATCH_WRAPP
DISPMODE = 0
L_SPLIT_PART_03:
R$ = I$
If Len(R$) = 0 Then Return
P = 1
Goto L_SPLIT_PART_01
L_FINISH_BRANCHE:
' ---- finish IF branches / process ELSE ----
Gosub L_SPLIT_PART_SUB
If HASELSE = 0 Then Goto L_FINISH_BRAN_01
V = ENDIFLBL
Gosub L_FORMATQ
Gosub L_EMIT_JMP_SKP
V = FALSELBL
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
R$ = XC$(39)
Gosub L_SPLIT_PART_SUB
V = ENDIFLBL
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
Goto L_CONTINUE_SUB_S
L_FINISH_BRAN_01:
V = FALSELBL
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
Goto L_CONTINUE_SUB_S

' ===============================================================
' PROGRAM CONTROL TRANSFER AND LOOPS
' ===============================================================

L_EXPR_GOSUB_GOT:
' ---------------- ON expr GOSUB/GOTO table ----------------
I = 4
O = 0
H = 0
F = 0
OGK = 0
L_EXPR_GOSUB_01:
If I > Len(B$) - 3 Then Goto L_END_02
MC = Asc(Mid$(B$, I, 1))
If MC = 34 Then O = 1 - O: Goto L_EXPR_GOSUB_04
If O <> 0 Then Goto L_EXPR_GOSUB_04
If MC = 40 Then H = H + 1: Goto L_EXPR_GOSUB_04
If MC = 41 Then H = H - 1: Goto L_EXPR_GOSUB_04
If H <> 0 Then Goto L_EXPR_GOSUB_04
If Mid$(B$, I, 5) = "GOSUB" Then OGK = 5: Goto L_EXPR_GOSUB_02
If Mid$(B$, I, 4) <> "GOTO" Then Goto L_EXPR_GOSUB_04 Else OGK = 4
L_EXPR_GOSUB_02:
If I = 1 Then Goto L_EXPR_GOSUB_03
MC = Asc(Mid$(B$, I - 1, 1)): If MC <> 32 And MC <> 9 Then Goto L_EXPR_GOSUB_04
L_EXPR_GOSUB_03:
If I + OGK > Len(B$) Then Goto L_EXPR_GOSUB_05
MC = Asc(Mid$(B$, I + OGK, 1)): If MC = 32 Or MC = 9 Then Goto L_EXPR_GOSUB_05
L_EXPR_GOSUB_04:
I = I + 1
Goto L_EXPR_GOSUB_01
L_EXPR_GOSUB_05:
XC$(41) = R$
F = I
N$ = Mid$(B$, 4, F - 4)
Gosub L_TRIM_2
R$ = Trim$(Mid$(B$, F + OGK, Len(B$) - F - OGK + 1))
If Len(N$) = 0 Or Len(R$) = 0 Then Goto L_END_02
Gosub L_NEXTSYM
OGT = V
Gosub L_NEXTSYM
OGC = V
Gosub L_NEXTSYM
OGE = V
V = OGC
Gosub L_FORMATQ
Print #2, "jmp ONC_"; Q$
V = OGT
Gosub L_FORMATQ
Print #2, "ONGT_"; Q$; ":"
G = 0
L_EXPR_GOSUB_06:
G = G + 1
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then D$ = R$: R$ = "": Goto L_EXPR_GOSUB_07
D$ = Left$(R$, F - 1)
R$ = Mid$(R$, F + 1, Len(R$) - F)
L_EXPR_GOSUB_07:
Gosub L_TRIM: If Len(D$) = 0 Then Goto L_END_02
If SRCMODE <> 0 Then Goto L_EXPR_GOSUB_08
E = Val(D$): If E = 0 Then Goto L_END_04 Else V = E: Gosub L_FORMATQ: Print #2, "DW L"; Q$: Goto L_EXPR_GOSUB_09
L_EXPR_GOSUB_08:
E$ = D$: D = 1: Gosub L_READ_LBL_IDENT: If Len(L$) = 0 Then Goto L_END_02
If H <> 0 Then Goto L_END_02
If D <= Len(E$) Then Goto L_END_02 Else Print #2, "DW QB_"; L$
L_EXPR_GOSUB_09:
R$ = Ltrim$(R$): If Len(R$) <> 0 Then Goto L_EXPR_GOSUB_06
V = OGC
Gosub L_FORMATQ
Print #2, "ONC_"; Q$; ":"
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
V = OGE
Gosub L_FORMATQ
Print #2, "dec ax"
Print #2, "cmp ax,"; G
Print #2, "jae ONE_"; Q$
Print #2, "shl ax,1"
Print #2, "mov bx,ax"
V = OGT
Gosub L_FORMATQ
Print #2, "mov ax,[ONGT_"; Q$; "+BX+0]"
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
If OGK = 5 Then Print #2, "DB 255,208" Else Print #2, "DB 255,224"
V = OGE
Gosub L_FORMATQ
Print #2, "ONE_"; Q$; ":"
R$ = XC$(41)
Goto L_CONTINUE_SUB_S
L_GOSUB:
' ---------------- GOSUB -------------------
D$ = Mid$(B$, 7, Len(B$) - 6)
Gosub L_TRIM
K$ = "call "
Gosub L_TGT_RESOLUTI_G
Goto L_CONTINUE_SUB_S
L_GOTO:
' ---------------- GOTO --------------------
D$ = Mid$(B$, 6, Len(B$) - 5)
Gosub L_TRIM
K$ = "jmp "
Gosub L_TGT_RESOLUTI_G
Goto L_CONTINUE_SUB_S
L_TGT_RESOLUTI_G:
' ---- COMMON TARGET RESOLUTION FOR GOTO/GOSUB ----
' Input:
'   D$ = already trimmed target
'   K$ = "call " OR "jmp "
' Effect:
'   emits K$ + "Lxxxxx" or K$ + "QB_name"
If SRCMODE = 0 Then Goto L_TGT_RESOLUT_02
E = Val(D$)
If E <> 0 Then Goto L_TGT_RESOLUT_01
E$ = D$
D = 1
Gosub L_READ_LBL_IDENT
If Len(L$) = 0 Then Goto L_END_02
L_TGT_RESOLUT_01:
If H <> 0 Then Goto L_END_02
If D <= Len(E$) Then Goto L_END_02
Print #2, K$; "QB_"; L$
Return
L_TGT_RESOLUT_02:
If Len(D$) = 0 Then Goto L_END_04
V = 0
J = 1
L_TGT_RESOLUT_03:
If J > Len(D$) Then Goto L_TGT_RESOLUT_04
MC = Asc(Mid$(D$, J, 1))
If MC < 48 Or MC > 57 Then Goto L_END_04
If V > 3276 Then Goto L_END_04
If V = 3276 And MC > 55 Then Goto L_END_04
V = V * 10 + MC - 48
J = J + 1
Goto L_TGT_RESOLUT_03
L_TGT_RESOLUT_04:
If V < 1 Then Goto L_END_04
Gosub L_FORMATQ
Print #2, K$; "L"; Q$
Return
L_RET:
' ---------------- RETURN ------------------
Print #2, "ret"
Goto L_CONTINUE_SUB_S
L_RET_01:
' ---------------- FOR ---------------------
B = B + 1
If B > 4 Then Goto L_END_03
J = Instr(B$, "=")
If J = 0 Then Goto L_END_03
D$ = Mid$(B$, 5, J - 5)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_03
L = Len(B$) - J
X$ = Mid$(B$, J + 1, L)
I = Instr(X$, " TO ")
If I = 0 Then Goto L_END_03
I = I + J + 1
FS = 1
L = Len(B$) - I - 1
X$ = Mid$(B$, I + 2, L)
K = Instr(X$, " STEP ")
If K <> 0 Then K = K + I + 2
L = I - J - 1
E$ = Mid$(B$, J + 1, L)
E$ = Trim$(E$)
If Len(E$) = 0 Then Goto L_END_03
If K = 0 Then Goto L_RET_02
L = Len(B$) - K - 3
X$ = Mid$(B$, K + 4, L)
N$ = Trim$(X$)
If Len(N$) = 0 Then Goto L_END_03
Gosub L_CONSTNUM
If COK = 0 Then Goto L_END_03
FS = CVAL
If FS = 0 Then Goto L_END_03
L_RET_02:
Gosub L_NEXTSYM
LL(B) = R
LS(B) = FS
LT(B) = 0
On B Goto L_RET_03,L_RET_04,L_RET_05,L_RET_06
L_RET_03:
S$ = D$
Goto L_RET_07
L_RET_04:
T$ = D$
Goto L_RET_07
L_RET_05:
U$ = D$
Goto L_RET_07
L_RET_06:
V$ = D$
L_RET_07:
Gosub L_COMP_AX
On B Goto L_RET_07A,L_RET_07B,L_RET_07C,L_RET_07D
L_RET_07A:
D$ = S$
Goto L_RET_07E
L_RET_07B:
D$ = T$
Goto L_RET_07E
L_RET_07C:
D$ = U$
Goto L_RET_07E
L_RET_07D:
D$ = V$
L_RET_07E:
V = LL(B)
Gosub L_FORMATQ
Gosub L_EMIT_STORE_AX
J = Instr(B$, "=")
L = Len(B$) - J
X$ = Mid$(B$, J + 1, L)
I = Instr(X$, " TO ")
I = I + J + 1
L = Len(B$) - I - 1
X$ = Mid$(B$, I + 2, L)
K = Instr(X$, " STEP ")
If K <> 0 Then K = K + I + 2
If K <> 0 Then L = K - I - 3: N$ = Mid$(B$, I + 3, L): Goto L_RET_07F
L = Len(B$) - I - 2
N$ = Mid$(B$, I + 3, L)
L_RET_07F:
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
V = LL(B)
FS = LS(B)
On B Goto L_RET_08,L_RET_09,L_RET_10,L_RET_11
L_RET_08:
D$ = S$
Goto L_RET_12
L_RET_09:
D$ = T$
Goto L_RET_12
L_RET_10:
D$ = U$
Goto L_RET_12
L_RET_11:
D$ = V$
L_RET_12:
Gosub L_FORMATQ
SAVEDID$ = D$
Z$ = "__F" + Q$
D$ = Z$
Gosub L_EMIT_STORE_AX
D$ = SAVEDID$
Print #2, "L_FOR_"; Q$; ":"
Print #2, "mov ax,[N_"; D$; "]"
Print #2, "cmp ax,[N_"; Z$; "]"
If FS > 0 Then Print #2, "jg L_END_"; Q$: Goto L_RET_13
Print #2, "jl L_END_"; Q$
L_RET_13:
Goto L_CONTINUE_SUB_S
L_RET_14:
' ---------------- NEXT --------------------
If B = 0 Then Goto L_END_03
If LT(B) <> 0 Then Goto L_END_03
If Len(B$) = 4 Then D$ = "": Goto L_RET_15
D$ = Mid$(B$, 6, Len(B$) - 5)
Gosub L_TRIM
L_RET_15:
On B Goto L_RET_16,L_RET_17,L_RET_18,L_RET_19
L_RET_16:
SAVEDID$ = S$
Goto L_RET_20
L_RET_17:
SAVEDID$ = T$
Goto L_RET_20
L_RET_18:
SAVEDID$ = U$
Goto L_RET_20
L_RET_19:
SAVEDID$ = V$
L_RET_20:
If Len(D$) = 0 Then D$ = SAVEDID$
If D$ <> SAVEDID$ Then Goto L_END_03
E = LL(B)
FS = LS(B)
Print #2, "mov ax,[N_"; D$; "]"
Print #2, "add ax,"; FS
Print #2, "mov [N_"; D$; "],ax"
V = E
Gosub L_FORMATQ
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
Print #2, "jmp L_FOR_"; Q$
Print #2, "L_END_"; Q$; ":"
B = B - 1
Goto L_CONTINUE_SUB_S
L_OPEN:
' ---------------- OPEN --------------------
K = Instr(B$, "#")
If K = 0 Then Goto L_END_02
D$ = Mid$(B$, K + 1, Len(B$) - K): Gosub L_PARSE_CHANNEL
If FC < 1 Or FC > 9 Then Goto L_END_02
I = Instr(B$, Chr$(34))
If I <> 0 Then Goto L_OPEN_FILE
' ---- OPEN X$ FOR ... ----
I = Instr(B$, " FOR ")
If I = 0 Then Goto L_END_02
L$ = Mid$(B$, 6, I - 6)
L$ = Trim$(L$)
If Len(L$) = 0 Then Goto L_END_02
If Asc(Right$(L$, 1)) <> 36 Then Goto L_END_02
If Len(L$) < 2 Then Goto L_END_02
D$ = Left$(L$, Len(L$) - 1)
Gosub L_EMIT_DS_SI
Gosub L_EMIT_NB_ASCIIZ
D$ = Mid$(B$, I + 5, Len(B$) - I - 4)
Goto L_OPEN_FILE_03
L_OPEN_FILE:
' ---- OPEN "FILE" FOR ... ----
J = I + 1
L_OPEN_FILE_01:
If J > Len(B$) Then Goto L_END_06
If Asc(Mid$(B$, J, 1)) = 34 Then Goto L_OPEN_FILE_02
J = J + 1
Goto L_OPEN_FILE_01
L_OPEN_FILE_02:
Gosub L_NEXTSYM
Print #2, "jmp OPN_"; Q$
Print #2, "FNM_"; Q$; ":"
L$ = Mid$(B$, I + 1, J - I - 1)
Gosub L_EMITDBBY
Print #2, "DB 0"
Print #2, "OPN_"; Q$; ":"
Print #2, "mov dx,OFFSET FNM_"; Q$
D$ = Mid$(B$, J + 1, Len(B$) - J)
I = Instr(D$, " FOR ")
If I = 0 Then Goto L_END_02
D$ = Mid$(D$, I + 5, Len(D$) - I - 4)
L_OPEN_FILE_03:
D$ = Trim$(D$)
I = Instr(D$, " AS ")
If I = 0 Then Goto L_END_02
X$ = Trim$(Left$(D$, I - 1))
N$ = Trim$(Mid$(D$, I + 4, Len(D$) - I - 3))
If N$ <> "#" + Str$(FC) Then Goto L_END_02
If X$ <> "INPUT" Then Goto L_OPEN_FILE_04
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call OPENI"
Goto L_CONTINUE_SUB_S
L_OPEN_FILE_04:
If X$ <> "OUTPUT" Then Goto L_END_02
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call OPENO"
Goto L_CONTINUE_SUB_S
L_CLOSE:
' ---------------- CLOSE -------------------
I = Instr(B$, "#")
If I = 0 Then Goto L_END_02
D$ = Mid$(B$, I + 1, Len(B$) - I): Gosub L_PARSE_CHANNEL
If FC < 1 Or FC > 9 Then Goto L_END_02
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call CLOSEC"
Goto L_CONTINUE_SUB_S
L_KILL:
' ---------------- KILL --------------------
If Len(B$) < 5 Then Goto L_END_02
X$ = Mid$(B$, 6, Len(B$) - 5)
Gosub L_COMP_SI
Gosub L_EMIT_NB_ASCIIZ
Gosub L_EMIT_REQ_FI
Print #2, "call KILLF"
Goto L_CONTINUE_SUB_S
L_CLS:
' ---------------- CLS --------------------
If Len(B$) <> 3 Then Goto L_END_02
Gosub L_EMIT_REQ_SO
Print #2, "call CLSCR"
Goto L_CONTINUE_SUB_S
L_END:
' ---------------- END [ERRORLEVEL] --------
If B <> 0 Then Goto L_END_03
E$ = Ltrim$(Mid$(B$, 4, Len(B$) - 3))
If Len(E$) = 0 Then Print #2, "call RT_EXIT": Goto L_CONTINUE_SUB_S
Gosub L_COMP_AX
Print #2, "call RT_EXIT_AL"
Goto L_CONTINUE_SUB_S
' ---- LOCATE/COLOR COMMON PREAMBLE ----
L_END_01:
E$ = Mid$(B$, K, Len(B$) - K + 1): K = 1: L = Len(E$): Gosub L_FIND_TOP_LEV_2: If F = 0 Then Goto L_END_02
N$ = Left$(E$, F - 1)
Gosub L_COMP_NUM_SUBEX
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(E$, F + 1, Len(E$) - F)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Goto L_EMIT_REQ_SO
' ------------- ERROR MESSAGES --------------
L_END_02:
ER = 1
Goto L_END_10
L_END_03:
ER = 2
Goto L_END_10
L_END_04:
ER = 3
Goto L_END_10
L_END_05:
ER = 4
Goto L_END_10
L_END_06:
ER = 5
Goto L_END_10
L_END_07:
ER = 6
Goto L_END_10
L_END_08:
ER = 7
Goto L_END_10
L_END_09:
ER = 8
L_END_10:
Print "ERROR LINE "; A; ": ";
On ER Goto L_END_11,L_END_12,L_END_13,L_END_14,L_END_15,L_END_16,L_END_17,L_END_18
L_END_11:
Print "SYNTAX ERROR"
Goto L_BASIC_END_VERY
L_END_12:
Print "FOR ERROR"
Goto L_BASIC_END_VERY
L_END_13:
Print "BAD LINE NUMBER"
Goto L_BASIC_END_VERY
L_END_14:
Print "MISSING )"
Goto L_BASIC_END_VERY
L_END_15:
Print "MISSING QUOTE"
Goto L_BASIC_END_VERY
L_END_16:
Print "TYPE MISMATCH"
Goto L_BASIC_END_VERY
L_END_17:
Print "INTERNAL ERROR"
Goto L_BASIC_END_VERY
L_END_18:
Print "IF ERROR"
Goto L_BASIC_END_VERY
L_FOOTER_RUNTIME:
' ---------------- Footer + Runtime ----------
If B <> 0 Then Goto L_END_03
If IFLEVEL <> 0 Then Goto L_END_09
If SELMODE <> 0 Then Goto L_END_02
If DA <> 0 Then Goto L_FOOTER_RUNT_01
If UDA = 0 Then Goto L_FOOTER_RUNT_02
Print #2, "DATA_BEGIN:"
Print #2, "DW 0"
Print #2, "DW 0"
Goto L_FOOTER_RUNT_02
L_FOOTER_RUNT_01:
V = DA
Gosub L_FORMATQ
Print #2, "DTN"; Q$; ":"
Print #2, "DW 0"
Print #2, "DW 0"
L_FOOTER_RUNT_02:
Close #1
D$ = Progdir$ + "RUNTIME.ASM"
Gosub L_COPY_INCLUDE_F
Close #2
Print "DONE."
Goto L_BASIC_END_VERY

' ===============================================================
' SCANNER CHARACTER AND TRIM HELPERS
' ===============================================================
L_FLSEP:
' ---- FIND FIRST SPACE OR TAB IN A$, RESULT IN I; 0 IF NONE ----
I = 1
L_FLSEP_01:
If I > Len(A$) Then I = 0: Return
MC = Asc(Mid$(A$, I, 1))
If MC = 32 Or MC = 9 Then Return
I = I + 1
Goto L_FLSEP_01

L_CHAR_MC:
' ---- CHAR_E_D_TO_MC ----
MC = Asc(Mid$(E$, D, 1))
Return
L_CHAR_MC_2:
' ---- CHAR_E_I_TO_MC ----
MC = Asc(Mid$(E$, I, 1))
Return
L_CHAR_CD_CMC:
' ---- CHAR_N_CD_TO_CMC ----
CMC = Asc(Mid$(N$, CD, 1))
Return
L_CHAR_MC_3:
' ---- CHAR_X_I_TO_MC ----
MC = Asc(Mid$(X$, I, 1))
Return
L_LEFT_MC:
' ---- LEFT_D_TO_MC ----
MC = Asc(Left$(D$, 1))
Return
L_RIGHT_MC:
' ---- RIGHT_D_TO_MC ----
MC = Asc(Right$(D$, 1))
Return
L_LEFT_MC_2:
' ---- LEFT_A_TO_MC ----
MC = Asc(Left$(A$, 1))
Return
L_RIGHT_MC_2:
' ---- RIGHT_F_TO_MC ----
MC = Asc(Right$(Z$, 1))
Return
L_TRIM:
' ---- TRIM_D ----
D$ = Trim$(D$)
Return
L_TRIM_2:
' ---- TRIM_N ----
N$ = Trim$(N$)
Return
L_LTRIM:
' ---- LTRIM_D ----
D$ = Ltrim$(D$)
Return

' ===============================================================
' NUMERIC EXPRESSION LEXER AND PARSER
' ===============================================================

L_READID:
' ---- READID: identifier up to 8 characters ----
L$ = ""
H = 0
If D > Len(E$) Then Return
Gosub L_CHAR_MC
If MC < 65 Or MC > 90 Then Return
L$ = Chr$(MC)
D = D + 1
L_READID_01:
If D > Len(E$) Then Goto L_READID_03
Gosub L_CHAR_MC
If MC = 95 Or MC >= 48 And MC <= 57 Or MC >= 65 And MC <= 90 Then Goto L_READID_02
Goto L_READID_03
L_READID_02:
If Len(L$) >= 8 Then Goto L_END_02
L$ = L$ + Chr$(MC)
D = D + 1
Goto L_READID_01
L_READID_03:
If D > Len(E$) Then Return
If MC <> 36 Then Return
H = 1
D = D + 1
Return

L_READ_LBL_IDENT:
' ---- READ LABEL IDENTIFIER, MAXIMUM 16 CHARACTERS ----
L$ = ""
H = 0
If D > Len(E$) Then Return
Gosub L_CHAR_MC
If MC < 65 Or MC > 90 Then Return
L$ = Chr$(MC)
D = D + 1
L_READ_LBL_ID_01:
If D > Len(E$) Then Return
Gosub L_CHAR_MC
If MC <> 95 And (MC < 48 Or MC > 57) And (MC < 65 Or MC > 90) Then Return
If Len(L$) >= 16 Then Goto L_END_02
L$ = L$ + Chr$(MC)
D = D + 1
Goto L_READ_LBL_ID_01

L_NEXTTOKE:
' ---------------- NEXTTOKEN ----------------
L_NEXTTOKE_01:
If D > Len(E$) Then TK = 0: Return
Gosub L_CHAR_MC
If MC = 32 Then D = D + 1: Goto L_NEXTTOKE_01
If MC < 65 Or MC > 90 Then Goto L_NEXTTOKE_03
T = D
OH = H
Gosub L_READID
TH = H
H = OH
If TH <> 0 Then Goto L_NEXTTOKE_02
Select Case L$
Case "MOD"
  TK = 1
  Return
Case "XOR"
  TK = 2
  Return
Case "AND"
  TK = 3
  Return
Case "OR"
  TK = 4
  Return
Case "NOT"
  TK = 5
  Return
End Select
L_NEXTTOKE_02:
D = T
L_NEXTTOKE_03:
TK = Asc(Mid$(E$, D, 1))
D = D + 1
Return

L_PREC:
' ---------------- PREC ---------------------
If TK = 5 Then H = 7: Return
If TK = 94 Then H = 6: Return
If TK = 1 Or TK = 47 Or TK = 92 Or TK = 42 Then H = 5: Return
If TK = 43 Or TK = 45 Then H = 4: Return
If TK = 3 Then H = 3: Return
If TK = 2 Then H = 2: Return
If TK = 4 Then H = 1: Return
H = 0
Return

L_FACTOR:
' ---------------- FACTOR -------------------
If TK <> 5 Then Goto L_FACTOR_01
Gosub L_NEXTTOKE
Gosub L_FACTOR
Gosub L_EMIT_POPAX
Print #2, "not ax"
Goto L_EMIT_PUSHAX
L_FACTOR_01:
If TK <> 43 Then Goto L_FACTOR_02
Gosub L_NEXTTOKE
Goto L_FACTOR
L_FACTOR_02:
If TK <> 45 Then Goto L_FACTOR_03
Gosub L_NEXTTOKE
If TK < 48 Or TK > 57 Then Goto L_FACTOR_02_01
N$ = ""
E = 0
L_FACTOR_02_02:
If TK < 48 Or TK > 57 Then Goto L_FACTOR_02_03
If E > 3276 Then Goto L_END_02
If E = 3276 And TK > 56 Then Goto L_END_02
E = E * 10 + TK - 48
N$ = N$ + Chr$(TK)
Gosub L_NEXTTOKE
Goto L_FACTOR_02_02
L_FACTOR_02_03:
Print #2, "mov ax,-"; N$
Goto L_EMIT_PUSHAX
L_FACTOR_02_01:
Gosub L_FACTOR
Gosub L_EMIT_POPAX
Print #2, "neg ax"
Goto L_EMIT_PUSHAX
L_FACTOR_03:
If TK < 65 Then Goto L_FACTOR_04
If TK > 90 Then Goto L_FACTOR_04
T = D
OH = H
XC$(40) = L$
D = D - 1
Gosub L_READID
TH = H
U = D
D = T
H = OH
L$ = XC$(40)
If TH <> 0 Then Goto L_FACTOR_04
If U > Len(E$) Then Goto L_FACTOR_04
If MC <> 40 Then Goto L_FACTOR_04
Select Case L$
Case "LEN"
  Goto L_LEN
Case "ABS"
  Goto L_ABS
Case "SGN"
  Goto L_SGN
Case "RND"
  Goto L_RND
Case "INT"
  Goto L_INT
Case "SQR"
  Goto L_SQR
Case "VAL"
  Goto L_VAL
Case "MIN"
  Gosub L_MIN_MAX_PREAMB
  Print #2, "call MINS"
  Goto L_MIN_MAX_PRE_01
Case "MAX"
  Gosub L_MIN_MAX_PREAMB
  Print #2, "call MAXS"
  Goto L_MIN_MAX_PRE_01
Case "XALLOC"
  Goto L_XALLOC
Case "TIMER"
  Goto L_TIMER
Case "EXEC"
  Goto L_EXEC
Case "CPUID"
  Goto L_CPUID
Case "PEEK"
  Goto L_PEEK
Case "INP"
  Goto L_INP
Case "ASC"
  Goto L_ASC
Case "EOF"
  Goto L_EOF
Case "EXIST"
  Goto L_EXIST
Case "INSTR"
  Goto L_INSTR
Case Else
  Goto L_WORD_ARR_FACTO
End Select
L_FACTOR_04:
If TK = 40 Then Goto L_FACTOR_05
If TK = 38 Then Goto L_HEX_LIT_H0000
If TK >= 48 Then Goto L_FACTOR_07
If TK >= 65 Then Goto L_FACTOR_10
Goto L_END_02
L_FACTOR_05:
Gosub L_NEXTTOKE
I = C
C = 1
Gosub L_EXPR
C = I
If TK <> 41 Then Goto L_END_05
Goto L_NEXTTOKE
L_FACTOR_07:
If TK > 57 Then Goto L_FACTOR_10
N$ = ""
E = 0
L_FACTOR_08:
If TK < 48 Or TK > 57 Then Goto L_FACTOR_09
If E > 3276 Then Goto L_END_02
If E = 3276 And TK > 55 Then Goto L_END_02
E = E * 10 + TK - 48
N$ = N$ + Chr$(TK)
Gosub L_NEXTTOKE
Goto L_FACTOR_08
L_FACTOR_09:
Print #2, "mov ax,"; N$
Goto L_EMIT_PUSHAX
L_FACTOR_10:
D = D - 1
Gosub L_READID
If H = 0 And L$ = "TRUE" Then Print #2, "mov ax,-1": Gosub L_EMIT_PUSHAX: Goto L_NEXTTOKE
If H = 0 And L$ = "FALSE" Then Print #2, "xor ax,ax": Gosub L_EMIT_PUSHAX: Goto L_NEXTTOKE
If H <> 0 Then Goto L_END_07
Print #2, "DN "; L$
Print #2, "mov ax,[N_"; L$; "]"
Gosub L_EMIT_PUSHAX
Goto L_NEXTTOKE
L_EXPR:
' ---------------- EXPR ---------------------
Gosub L_FACTOR
L_JUMP_LBL:
' jump label
Gosub L_PREC
If H < C Then Return
If TK <> 94 Then Goto L_JUMP_LBL_01
Gosub L_PREP_BINOP_RHS
Gosub L_EMIT_REQ_MT
Print #2, "call POWS"
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
L_JUMP_LBL_01:
If TK <> 43 Then Goto L_JUMP_LBL_02
Gosub L_PREP_BINOP_RHS
Print #2, "add ax,bx"
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
L_JUMP_LBL_02:
If TK <> 45 Then Goto L_JUMP_LBL_03
Gosub L_PREP_BINOP_RHS
Print #2, "sub ax,bx"
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
L_JUMP_LBL_03:
If TK <> 42 Then Goto L_JUMP_LBL_04
Gosub L_PREP_BINOP_RHS
Print #2, "imul bx"
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
L_JUMP_LBL_04:
If TK = 47 Then Goto L_JUMP_LBL_05
If TK <> 92 Then Goto L_JUMP_LBL_06
L_JUMP_LBL_05:
Gosub L_PREP_BINOP_RHS
Gosub L_EMIT_REQ_DV
Print #2, "call IDIVS"
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
L_JUMP_LBL_06:
If TK <> 1 Then Goto L_JUMP_LBL_07
Gosub L_PREP_BINOP_RHS
Gosub L_EMIT_REQ_DV
Print #2, "call IDIVS"
Print #2, "mov ax,dx"
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
L_JUMP_LBL_07:
If TK = 2 Then OP = 2: Goto L_JUMP_LBL_08
If TK = 3 Then OP = 3: Goto L_JUMP_LBL_08
If TK = 4 Then OP = 4: Goto L_JUMP_LBL_08
Goto L_END_02
L_JUMP_LBL_08:
Gosub L_PREP_BINOP_RHS
If OP = 2 Then Print #2, "xor ax,bx": Goto L_JUMP_LBL_09
If OP = 3 Then Print #2, "and ax,bx": Goto L_JUMP_LBL_09
Print #2, "or ax,bx"
L_JUMP_LBL_09:
Gosub L_EMIT_PUSHAX
Goto L_JUMP_LBL
' end
' ---- NUMFUNCARG: parse one numeric function argument into stack ----
L_JUMP_LBL_10:
I = D + 2
Gosub L_FIND_MATCH
CLOSEPAR = J
N$ = Mid$(E$, I + 1, CLOSEPAR - I - 1)
Goto L_COMP_NUM_SUBEX
L_ABS:
' ---- ABS(num) ----
Gosub L_JUMP_LBL_10
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_DV
Print #2, "call IABSS"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_SGN:
' ---- SGN(num) ----
Gosub L_JUMP_LBL_10
Gosub L_EMIT_POPAX
Gosub L_NEXTSYM
L$ = Q$
Print #2, "or ax,ax"
Print #2, "je SGN_"; L$
Print #2, "mov ax,1"
Print #2, "jg SGN_"; L$
Print #2, "mov ax,-1"
Print #2, "SGN_"; L$; ":"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_LEN:
' ---- LEN(str) ----
I = D + 2
Gosub L_NUMSTRAR
Gosub L_EMIT_REQ_ST
Print #2, "call LEN"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_RND:
' ---- RND(num) ----
Gosub L_JUMP_LBL_10
Gosub L_EMIT_POPAX
Print #2, "mov bx,ax"
Gosub L_EMIT_REQ_RN
Print #2, "call RNDS"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_VAL:
' ---- VAL(str) ----
I = D + 2
Gosub L_NUMSTRAR
Gosub L_EMIT_REQ_CV
Print #2, "call VAL"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_INT:
' ---- INT(num) ----
Gosub L_JUMP_LBL_10
Goto L_EXIST_01
L_ASC:
' ---- ASC(str); empty string returns 0 ----
I = D + 2
Gosub L_NUMSTRAR
Gosub L_NEXTSYM
L$ = Q$
Print #2, "xor ax,ax"
Print #2, "cmp BYTE [si],0"
Print #2, "je ASC_"; L$
Print #2, "mov al,[si+1]"
Print #2, "ASC_"; L$; ":"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_SQR:
' ---- SQR(num) ----
Gosub L_JUMP_LBL_10
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_MT
Print #2, "call SQRS"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_EOF:
' ---- EOF(channel) ----
I = D + 2
Gosub L_FIND_MATCH
N$ = Mid$(E$, I + 1, J - I - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_POPAX
Print #2, "call EOFC"
Gosub L_EMIT_PUSHAX
D = J + 1
Goto L_NEXTTOKE
L_EXIST:
' ---- EXIST(str) ----
I = D + 4
Gosub L_NUMSTRAR
Gosub L_EMIT_NB_ASCIIZ
Gosub L_EMIT_REQ_FI
Print #2, "call EXISTF"
Gosub L_EMIT_PUSHAX
' ---- NEXT_AFTER_JPAREN ----
L_EXIST_01:
D = CLOSEPAR + 1
Goto L_NEXTTOKE
L_INSTR:
' ---- INSTR(str, pat) / INSTR(start, str, pat) ----
I = D + 4
Gosub L_FIND_MATCH
K = I + 1
L = J - 1
Gosub L_FIND_TOP_LEV_2
G = F
If G = 0 Then Goto L_END_02
K = G + 1
L = J - 1
Gosub L_FIND_TOP_LEV_2
H = F
Gosub L_EMIT_REQ_ST
If H <> 0 Then Goto L_INSTR_01
X$ = Mid$(E$, I + 1, G - I - 1)
Y$ = Mid$(E$, G + 1, J - G - 1)
Gosub L_COMP_SI
Print #2, "mov dl,1"
Gosub L_COMP_DI
Print #2, "call INSTRS"
Gosub L_EMIT_PUSHAX
I = D + 4
Gosub L_FIND_MATCH
D = J + 1
Goto L_NEXTTOKE
L_INSTR_01:
N$ = Mid$(E$, I + 1, G - I - 1)
X$ = Mid$(E$, G + 1, H - G - 1)
Y$ = Mid$(E$, H + 1, J - H - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "push ax"
Gosub L_COMP_SI
Gosub L_COMP_DI
Print #2, "pop dx"
Print #2, "call INSTRS"
Gosub L_EMIT_PUSHAX
I = D + 4
Gosub L_FIND_MATCH
D = J + 1
Goto L_NEXTTOKE
L_FIND_MATCH:
' ---- find matching ) for I, result in J ----
OH = H
If I < 1 Then I = D
If I < 1 Then I = 1
J = I
H = 0
LO = 0
L_FIND_MATCH_01:
If J > Len(E$) Then Goto L_END_05
MC = Asc(Mid$(E$, J, 1))
If MC <> 34 Then Goto L_FIND_MATCH_02
If LO = 0 Then LO = 1: Goto L_FIND_MATCH_04
LO = 0
Goto L_FIND_MATCH_04
L_FIND_MATCH_02:
If LO <> 0 Then Goto L_FIND_MATCH_04
If MC <> 40 Then Goto L_FIND_MATCH_03
H = H + 1
Goto L_FIND_MATCH_04
L_FIND_MATCH_03:
If MC <> 41 Then Goto L_FIND_MATCH_04
H = H - 1
If H <> 0 Then Goto L_FIND_MATCH_04
H = OH
Return
L_FIND_MATCH_04:
J = J + 1
Goto L_FIND_MATCH_01
L_FIND_TOP_LEV_2:
' ---- find first top-level comma from K to L, result in F ----
F = 0
H = 0
LO = 0
L_FIND_TOP_LE_2:
If K > L Then Return
MC = Asc(Mid$(E$, K, 1))
If MC <> 34 Then Goto L_FIND_TOP_LE_3
If LO = 0 Then LO = 1: Goto L_FIND_TOP_LE_6
LO = 0
Goto L_FIND_TOP_LE_6
L_FIND_TOP_LE_3:
If LO <> 0 Then Goto L_FIND_TOP_LE_6
If MC <> 40 Then Goto L_FIND_TOP_LE_4
H = H + 1
Goto L_FIND_TOP_LE_6
L_FIND_TOP_LE_4:
If MC <> 41 Then Goto L_FIND_TOP_LE_5
H = H - 1
Goto L_FIND_TOP_LE_6
L_FIND_TOP_LE_5:
If MC <> 44 Then Goto L_FIND_TOP_LE_6
If H <> 0 Then Goto L_FIND_TOP_LE_6
F = K
Return
L_FIND_TOP_LE_6:
K = K + 1
Goto L_FIND_TOP_LE_2

' ===============================================================
' STRING AND ARRAY EXPRESSION COMPILATION
' ===============================================================

L_COMP_SI:
' ---- compile X$ to SI ----
Gosub L_PUSH_STRFUNCT
X$ = Trim$(X$)
Gosub L_HAS_TOP_PLUS
If E <> 0 Then Goto L_DEFAULT_PATH_T
If Len(X$) < 2 Then Goto L_END_02
If Asc(Left$(X$, 1)) = 34 Then Goto L_DEFAULT_PAT_02
If Left$(X$, 5) = "CHR$(" Then Goto L_DEFAULT_PAT_01
If Left$(X$, 6) = "LEFT$(" Then I = 6: Gosub L_LEFT_RIGHT_PRE: Print #2, "call LEFT2": Goto L_POP_STRFUNCT
If Left$(X$, 6) = "XGET$(" Then Goto L_XGET
If Left$(X$, 7) = "RIGHT$(" Then I = 7: Gosub L_LEFT_RIGHT_PRE: Print #2, "call RIGHT2": Goto L_POP_STRFUNCT
If Left$(X$, 7) = "LTRIM$(" Then I = 7: Gosub L_STRFUN_ARG: Print #2, "call LTRIM": Goto L_STRFUN_FINISH
If Left$(X$, 6) = "TRIM$(" Then I = 6: Gosub L_STRFUN_ARG: Print #2, "REQ TR": Print #2, "call TRIM": Goto L_STRFUN_FINISH
If Left$(X$, 7) = "RTRIM$(" Then I = 7: Gosub L_STRFUN_ARG: Print #2, "call RTRIM": Goto L_STRFUN_FINISH
If Left$(X$, 7) = "UCASE$(" Then I = 7: Gosub L_STRFUN_ARG: Print #2, "call UCASE": Goto L_STRFUN_FINISH
If Left$(X$, 5) = "STR$(" Then Goto L_COMP_STR
If Left$(X$, 5) = "HEX$(" Or Left$(X$, 5) = "OCT$(" Or Left$(X$, 5) = "BIN$(" Then Goto L_COMP_HEX_OCT
If Left$(X$, 7) = "SPACE$(" Then Goto L_COMP_SPACE
If Left$(X$, 8) = "STRING$(" Then Goto L_COMP_STR_2
If Left$(X$, 5) = "MID$(" Then Goto L_COMP_MID
If X$ <> "DATE$" Then Goto L_COMP_SI_01
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_REQ_DT
Print #2, "call DATES"
Gosub L_EMIT_SI_TMP
Goto L_POP_STRFUNCT
L_COMP_SI_01:
If X$ <> "TIME$" Then Goto L_COMP_SI_02
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_REQ_TS
Print #2, "call TIMESTR"
Gosub L_EMIT_SI_TMP
Goto L_POP_STRFUNCT
L_COMP_SI_02:
If X$ <> "INKEY$" Then Goto L_COMP_SI_03
Gosub L_EMIT_DI_TMP
Print #2, "REQ IK"
Print #2, "call INKEYS"
Gosub L_EMIT_SI_TMP
Goto L_POP_STRFUNCT
L_COMP_SI_03:
If X$ <> "INPUT$" Then Goto L_COMP_SI_04
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_INPUTS
Gosub L_EMIT_SI_TMP
Goto L_POP_STRFUNCT
L_COMP_SI_04:
Gosub L_PUSH_STRCTX
E$ = X$
D = 1
Gosub L_READID
SAVEDID$ = L$
IDKIND = H
I = D
Gosub L_POP_STRCTX
If Len(SAVEDID$) = 0 Or IDKIND = 0 Then Goto L_END_02
If I > Len(X$) Then Goto L_COMP_SI_05
If Mid$(X$, I, 1) = "(" Then E$ = X$: D = I: L$ = SAVEDID$: Gosub L_COMP: If D > Len(E$) Then Goto L_POP_STRFUNCT Else Goto L_END_02
Goto L_END_02
L_COMP_SI_05:
Print #2, "DS "; SAVEDID$
Print #2, "mov si,OFFSET S_"; SAVEDID$
Goto L_POP_STRFUNCT
L_DEFAULT_PATH_T:
' ---- DEFAULT PATH FOR TOP-LEVEL STRING CONCATENATION ----
E$ = X$
Gosub L_STR_EXPR_PARSE
Goto L_POP_STRFUNCT
L_DEFAULT_PAT_01:
N$ = Mid$(X$, 6, Len(X$) - 6)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Gosub L_EMIT_SI_TMP2
Print #2, "mov BYTE PTR [si],1"
Print #2, "mov [si+1],al"
Gosub L_EMIT_SI_TMP2
Goto L_POP_STRFUNCT
L_DEFAULT_PAT_02:
L$ = Mid$(X$, 2, Len(X$) - 2)
Gosub L_NEXTSYM
Print #2, "jmp SVX_"; Q$
Print #2, "SVD_"; Q$; ":"
Gosub L_EMITDBL
Print #2, "SVX_"; Q$; ":"
Print #2, "mov si,OFFSET SVD_"; Q$
Goto L_POP_STRFUNCT
L_COMP_MID:
' ---- compile MID$(str,start,len) to SI ----
Gosub L_PUSH_SRCCTX
E$ = X$
I = 5
Gosub L_FIND_MATCH
K = 6
L = J - 1
Gosub L_FIND_TOP_LEV_2
G = F
If G = 0 Then Goto L_END_02
K = G + 1
L = J - 1
Gosub L_FIND_TOP_LEV_2
H = F
If H = 0 Then Goto L_END_02
X$ = Mid$(E$, 6, G - 6)
N$ = Mid$(E$, G + 1, H - G - 1)
Gosub L_COMP_NUM_SUBEX
I = 5
Gosub L_FIND_MATCH
K = 6
L = J - 1
Gosub L_FIND_TOP_LEV_2
G = F
K = G + 1
Gosub L_FIND_TOP_LEV_2
H = F
N$ = Mid$(E$, H + 1, J - H - 1)
Gosub L_COMP_NUM_SUBEX
E$ = X$
Gosub L_STR_EXPR_PARSE
Gosub L_POP_SRCCTX
Print #2, "pop cx"
Print #2, "pop dx"
Print #2, "call MID2"
Goto L_POP_STRFUNCT
L_COMP_DI:
' ---- compile Y$ to DI (wrapper around 17450) ----
X$ = Y$
Print #2, "push si"
Gosub L_COMP_SI
Print #2, "mov di,si"
Print #2, "pop si"
Return
L_WORD_ARR_FACTO:
' ---- WORD ARRAY FACTOR A(I) ----
Z$ = L$
I = U
Gosub L_FIND_MATCH
CLOSEPAR = J
N$ = Mid$(E$, I + 1, CLOSEPAR - I - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "DS "; Z$
Print #2, "mov si,OFFSET S_"; Z$
Gosub L_EMIT_REQ_AR
Print #2, "call ARRGETB"
Gosub L_EMIT_PUSHAX
D = CLOSEPAR + 1
Goto L_NEXTTOKE
L_COMP_NUM_SUBEX:
' ---- compile N$ as numeric subexpression ----
Gosub L_PUSH_NUMCTX
Gosub L_CONSTNUM
If COK <> 0 Then Print #2, "mov ax,"; CVAL: Gosub L_EMIT_PUSHAX: Goto L_POP_NUMCTX
E$ = N$
D = 1
C = 1
Gosub L_NEXTTOKE
Gosub L_EXPR
If TK <> 0 Then Goto L_END_02
Goto L_POP_NUMCTX
L_COMP_AX:
' ---- COMPILE_E_TO_AX: compile numeric expression E$ from start, emit pop ax ----
N$ = E$
Gosub L_CONSTNUM
If COK <> 0 Then Print #2, "mov ax,"; CVAL: Return
D = 1
C = 1
Gosub L_NEXTTOKE
Gosub L_EXPR
If TK <> 0 Then Goto L_END_02
Goto L_EMIT_POPAX
' ---- COMMON COUNTED STRFUN PREAMBLE ---- FOR LEFT/RIGHT: STRING SOURCE IN SI, COUNT ON TOP OF STACK
L_COMP_AX_01:
Gosub L_POP_SRCCTX
Print #2, "pop cx"
Goto L_EMIT_REQ_ST
L_STRFUN_ARG:
' ---- SIMPLE_STRFUN_ARG: X$=function call, I=position of "(" ----
Gosub L_PUSH_SRCCTX
E$ = X$
Gosub L_FIND_MATCH
X$ = Mid$(E$, I + 1, J - I - 1)
E$ = X$
Gosub L_STR_EXPR_PARSE
Gosub L_POP_SRCCTX
Gosub L_EMIT_PUSHDI
Gosub L_EMIT_DI_TMP2
Goto L_EMIT_REQ_ST
L_STRFUN_FINISH:
' ---- SIMPLE_STRFUN_FINISH: TMP2$ to SI, restore STRFUNCTX ----
Gosub L_EMIT_POPDI
Gosub L_EMIT_SI_TMP2
Goto L_POP_STRFUNCT
L_COMP_STR:
' ---- compile STR$(num) to SI ----
E$ = X$
I = 5
Gosub L_FIND_MATCH
N$ = Mid$(E$, 6, J - 6)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Gosub L_EMIT_DI_TMP2
Gosub L_EMIT_REQ_ST
Gosub L_EMIT_REQ_CV
Print #2, "call STRS"
Gosub L_EMIT_SI_TMP2
Goto L_POP_STRFUNCT
L_MINIMAL_STR_LE:
' === STRING EXPRESSION LEXER ===
' Input: E$ (string expression)
' Output: OT = token type, L$ = token value
' OT: 0=EOF 1=VAR 2=LIT 3=FUNC 4=INPUT$ 5=INKEY$ 6=DATE$ 7=TIME$ 8=PLUS 9=COMMA 10=LP 11=RP 12=BAD
' State: D = position in E$
L_MINIMAL_STR_01:
If D > Len(E$) Then OT = 0: Return
Gosub L_CHAR_MC
' Skip spaces
If MC = 32 Or MC = 9 Or MC = 10 Or MC = 13 Then D = D + 1: Goto L_MINIMAL_STR_01
' String literal
If MC = 34 Then Goto L_SCAN_UNTIL_CLO
' String variable (A$..Z$)
Gosub L_READID
If Len(L$) = 0 Then Goto L_OP
Select Case L$
Case "LEFT", "TRIM", "XGET"
    FL = 5
    Goto L_MIN_STR_FUNC
Case "MID", "CHR", "STR"
    FL = 4
    Goto L_MIN_STR_FUNC
Case "RIGHT", "LTRIM", "RTRIM"
    FL = 6
    Goto L_MIN_STR_FUNC
Case "OCT", "BIN", "HEX"
    FL = 4
    Goto L_MINIMAL_STR_14
Case "SPACE"
    FL = 6
    Goto L_MINIMAL_STR_14
Case "STRING"
    FL = 7
    Goto L_MINIMAL_STR_14
Case "UCASE"
    Goto L_MINIMAL_STR_12
Case "INKEY"
    If H = 0 Then Goto L_MINIMAL_STR_13
    OT = 5
    Return
Case "DATE"
    If H = 0 Then Goto L_MINIMAL_STR_13
    OT = 6
    Return
Case "TIME"
    If H = 0 Then Goto L_MINIMAL_STR_13
    OT = 7
    Return
Case "INPUT"
    If H = 0 Then Goto L_MINIMAL_STR_13
    OT = 4
    Return
Case Else
    Goto L_MINIMAL_STR_02
End Select

L_MIN_STR_FUNC:
Gosub L_SCAN_UNTIL_03
If MC = 40 Then OT = 3: Return
OT = 1
Return

L_MINIMAL_STR_02:
If D > Len(E$) Then OT = 1: Return
Gosub L_SCAN_UNTIL_03
If MC <> 40 Or H <> 0 Then OT = 1: Return
OT = 3
FL = 5
Return

L_MINIMAL_STR_12:
If H = 0 Then OT = 1: Return
Gosub L_SCAN_UNTIL_03
If MC = 40 Then OT = 3: FL = 6: Return
L_MINIMAL_STR_13:
OT = 1
Return
L_MINIMAL_STR_14:
If H = 0 Then OT = 1: Return
If D > Len(E$) Then OT = 1: Return
Gosub L_CHAR_MC
If MC = 40 Then OT = 3: Return Else OT = 1: Return
L_OP:
' Operator +
If MC = 43 Then OT = 8: D = D + 1: Return
' Comma
If MC = 44 Then OT = 9: D = D + 1: Return
' Parentheses
If MC = 40 Then OT = 10: D = D + 1: Return
If MC = 41 Then OT = 11: D = D + 1: Return
OT = 12
D = D + 1
Return
' Quoted string
L_SCAN_UNTIL_CLO:
' Scan until closing quote
J = D + 1
L_SCAN_UNTIL_01:
If J > Len(E$) Then Goto L_END_06
MC = Asc(Mid$(E$, J, 1))
If MC = 34 Then Goto L_SCAN_UNTIL_02
J = J + 1
Goto L_SCAN_UNTIL_01
L_SCAN_UNTIL_02:
OT = 2
T = D + 1
U = J - D - 1
L$ = Mid$(E$, T, U)
D = J + 1
Return
L_SCAN_UNTIL_03:
If D > Len(E$) Then MC = 0: Return
Gosub L_CHAR_MC
If MC <> 36 Then Return
D = D + 1
If D > Len(E$) Then MC = 0: Return
Goto L_CHAR_MC
L_STR_EXPR_PARSE:
' === STRING EXPRESSION PARSER (RESULT IN TMP$, SI) ===
' Input : E$ (string expression)
' Output: result accumulator TMP$, SI -> TMP$
' Independent of assignment (Z$)
Gosub L_PUSH_STRCTX: ' save STRCTX
STRLEVEL = STRLEVEL + 1
If STRLEVEL > 4 Then Goto L_END_08
D = 1
' --- initialize accumulator ---
Gosub L_EMIT_DI_TMP
Print #2, "mov BYTE PTR [di],0"
' --- parse first term ---
Gosub L_PARSE_STR_TERM
' --- copy first operand into TMP$ ---
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_STRCOPY
L_HANDLE_CHAIN:
' === handle + chain ===
Gosub L_MINIMAL_STR_LE
If OT = 8 Then Goto L_SAVE_ACCUMULA
' --- no more terms ---
Goto L_SAVE_ACCUMU_01
L_SAVE_ACCUMULA:
' --- SAVE ACCUMULATOR TMP$ BEFORE NESTED TERM ---
Print #2, "mov si,OFFSET TMP$"
Gosub L_EMIT_DI_STSAVE
Gosub L_EMIT_STRCOPY
' --- parse next term ---
Gosub L_PARSE_STR_TERM
' --- SAVE NEW TERM TO TMP2$ ---
Gosub L_EMIT_DI_TMP2
Gosub L_EMIT_STRCOPY
' --- RESTORE OLD ACCUMULATOR FROM TMP3$ TO TMP$ ---
Gosub L_EMIT_SI_STSAVE
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_STRCOPY
' --- APPEND TMP2$ TO TMP$ ---
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_SI_TMP2
Print #2, "call STRAPP"
Gosub L_EMIT_SI_TMP
Goto L_HANDLE_CHAIN
' --- final result ---
L_SAVE_ACCUMU_01:
Gosub L_EMIT_SI_TMP
STRLEVEL = STRLEVEL - 1
Goto L_POP_STRCTX: ' restore STRCTX
L_PARSE_STR_TERM:
' === parse one string term into SI ===
' expects: D at start of term
Gosub L_MINIMAL_STR_LE
If OT = 1 Then If Mid$(E$, D, 1) = "(" Then Goto L_COMP
On OT Goto L_STR_VAR,L_STR_LIT,L_STR_FUNC,L_STR_LIT_01,L_INKEY,L_DATE,L_TIME
Goto L_END_02
L_STR_VAR:
' --- string variable ---
Print #2, "DS "; L$
Print #2, "mov si,OFFSET S_"; L$
' D already points to the next character (+ oder end)
Return
L_STR_LIT:
' --- string literal ---
Gosub L_NEXTSYM
Print #2, "jmp SLX_"; Q$
Print #2, "SLD_"; Q$; ":"
Gosub L_EMITDBL
Print #2, "SLX_"; Q$; ":"
Print #2, "mov si,OFFSET SLD_"; Q$
Return
L_STR_LIT_01:
' --- INPUT$ ---
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_INPUTS
Goto L_EMIT_SI_TMP
L_INKEY:
' --- INKEY$ ---
Gosub L_EMIT_DI_TMP
Print #2, "REQ IK"
Print #2, "call INKEYS"
Goto L_EMIT_SI_TMP
L_STR_FUNC:
' --- string function ---
G = D - FL
I = D
Gosub L_FIND_MATCH
FUNLEVEL = FUNLEVEL + 1
If FUNLEVEL > 4 Then Goto L_END_08
If FUNLEVEL = 1 Then FNE1 = J + 1
If FUNLEVEL = 2 Then FNE2 = J + 1
If FUNLEVEL = 3 Then FNE3 = J + 1
If FUNLEVEL = 4 Then FNE4 = J + 1
X$ = Mid$(E$, G, J - G + 1)
Gosub L_PUSH_STRCTX
Gosub L_PEEK_STRFUNCT
Gosub L_PUSH_NUMCTX
E$ = X$
D = 1
Gosub L_COMP_SI
Gosub L_POP_NUMCTX
Gosub L_POP_STRCTX
If FUNLEVEL = 1 Then D = FNE1: FUNLEVEL = 0: Goto L_STR_FUNC_01
If FUNLEVEL = 2 Then D = FNE2: FUNLEVEL = 1: Goto L_STR_FUNC_01
If FUNLEVEL = 3 Then D = FNE3: FUNLEVEL = 2: Goto L_STR_FUNC_01
If FUNLEVEL = 4 Then D = FNE4: FUNLEVEL = 3: Goto L_STR_FUNC_01
Goto L_END_08
L_STR_FUNC_01:
Return
L_DATE:
' --- DATE$ ---
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_REQ_DT
Print #2, "call DATES"
Goto L_EMIT_SI_TMP
L_PURE_STR_LIT_2:
' ---- PURE STRING LITERAL TEST IN E$ ----
H = 0
If Len(E$) < 2 Then Return
If Asc(Left$(E$, 1)) <> 34 Then Return
J = 2
L_PURE_STR_LI_01:
If J > Len(E$) Then Return
If Asc(Mid$(E$, J, 1)) = 34 Then Goto L_PURE_STR_LI_02
J = J + 1
Goto L_PURE_STR_LI_01
L_PURE_STR_LI_02:
I = J + 1
L_PURE_STR_LI_03:
If I > Len(E$) Then Goto L_PURE_STR_LI_04
Gosub L_CHAR_MC_2
If MC = 32 Or MC = 9 Then I = I + 1: Goto L_PURE_STR_LI_03
Return
L_PURE_STR_LI_04:
H = 1
L$ = Mid$(E$, 2, J - 2)
Return
L_ASSIGN_PURE_ST:
' ---- ASSIGN PURE STRING LITERAL L$ TO SAVED DI ----
If Len(L$) <> 0 Then Goto L_ASSIGN_PURE_01
Gosub L_EMIT_POPDI
Print #2, "mov BYTE PTR [di],0"
Return
L_ASSIGN_PURE_01:
Gosub L_NEXTSYM
Print #2, "jmp SLA_"; Q$
Print #2, "SLD_"; Q$; ":"
Gosub L_EMITDBL
Print #2, "SLA_"; Q$; ":"
Gosub L_EMIT_POPDI
Print #2, "mov si,OFFSET SLD_"; Q$
Goto L_EMIT_STRCOPY

' ===============================================================
' BOOLEAN TARGET CONTEXT HELPERS
' ===============================================================

L_PUSH_BOOL_TARG:
' ---- PUSH_BOOL_TARGETS ----
BOOLDEP = BOOLDEP + 1
If BOOLDEP > 4 Then Goto L_END_08
BT$(BOOLDEP) = I$
BF$(BOOLDEP) = K$
BSK(BOOLDEP) = FALSELBL
Return
L_POP_BOOL_TARGE:
' ---- POP_BOOL_TARGETS ----
If BOOLDEP < 1 Or BOOLDEP > 4 Then Goto L_END_08
I$ = BT$(BOOLDEP)
K$ = BF$(BOOLDEP)
FALSELBL = BSK(BOOLDEP)
BOOLDEP = BOOLDEP - 1
Return

' ===============================================================
' BOOLEAN EXPRESSIONS AND IF COMPILATION
' ===============================================================

L_BOOL_EXPR_STMT:
' ---------------- IF <bool-expr> THEN <stmts> ----------
E$ = B$
N$ = "THEN"
G = 4
K = 4
Gosub L_FIND_TOP_LEV_3
P = F
If P = 0 Then Goto L_END_02
L$ = Mid$(B$, 4, P - 4)
R$ = Mid$(B$, P + 5, Len(B$) - P - 4)
R$ = Trim$(R$)
If Len(R$) = 0 Then Goto L_BLOCK_BEGIN
HASELSE = 0
Gosub L_FIND_TOP_LEVEL
If F = 0 Then Goto L_BOOL_EXPR_S_02
HASELSE = 1
XC$(39) = Mid$(R$, F + 4, Len(R$) - F - 3)
R$ = Left$(R$, F - 1)
R$ = Rtrim$(R$)
If Asc(Right$(R$, 1)) <> 58 Then Goto L_BOOL_EXPR_S_01
R$ = Left$(R$, Len(R$) - 1)
L_BOOL_EXPR_S_01:
XC$(39) = Ltrim$(XC$(39))
L_BOOL_EXPR_S_02:
Gosub L_NEXTSYM
FALSELBL = V
If HASELSE = 0 Then Goto L_BOOL_EXPR_S_03
Gosub L_NEXTSYM
ENDIFLBL = V
L_BOOL_EXPR_S_03:
Gosub L_NEXTSYM
I$ = Q$
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
Goto L_FINISH_BRANCHE
L_COMP_BOOL_EXPR:
' ---- compile boolean expression in L$ as OR chain ----
L_COMP_BOOL_E_01:
E$ = L$
N$ = " OR "
G = 4
K = 1
Gosub L_FIND_TOP_LEV_3
If F = 0 Then Goto L_COMP_BOOL_E_02
B$ = Left$(L$, F - 1)
W$ = Mid$(L$, F + 4, Len(L$) - F - 3)
Gosub L_NEXTSYM
K$ = Q$
Gosub L_COMP_GROUP
Print #2, "SKP_"; K$; ":"
L$ = W$
Goto L_COMP_BOOL_E_01
L_COMP_BOOL_E_02:
B$ = L$
V = FALSELBL
Gosub L_FORMATQ
K$ = Q$
Goto L_COMP_GROUP
L_FIND_TOP_LEV_3:
' ---- find first top-level operator N$ in E$, result in F ----
F = 0
H = 0
O = 0
I = K
L_FIND_TOP_LE_7:
If I > Len(E$) - G + 1 Then Return
Gosub L_CHAR_MC_2
If MC <> 34 Then Goto L_FIND_TOP_LE_8
If O = 0 Then O = 1: Goto L_FIND_TOP_LE_11
O = 0
Goto L_FIND_TOP_LE_11
L_FIND_TOP_LE_8:
If O <> 0 Then Goto L_FIND_TOP_LE_11
If MC <> 40 Then Goto L_FIND_TOP_LE_9
H = H + 1
Goto L_FIND_TOP_LE_11
L_FIND_TOP_LE_9:
If MC <> 41 Then Goto L_FIND_TOP_LE_10
H = H - 1
Goto L_FIND_TOP_LE_11
L_FIND_TOP_LE_10:
If H <> 0 Then Goto L_FIND_TOP_LE_11
If Mid$(E$, I, G) <> N$ Then Goto L_FIND_TOP_LE_11
F = I
Return
L_FIND_TOP_LE_11:
I = I + 1
Goto L_FIND_TOP_LE_7
L_PAREN_BOOL_NON:
' ---- PAREN BOOL AS NONFINAL AND TERM ----
Gosub L_PUSH_BOOL_TARG
XC$(BOOLDEP + 41) = XC$(41)
Gosub L_NEXTSYM
I$ = Q$
L$ = Mid$(A$, 2, Len(A$) - 2)
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
B$ = XC$(BOOLDEP + 41)
Gosub L_POP_BOOL_TARGE
Goto L_COMP_GROUP_01
L_NOT_PAREN_BOOL:
' ---- NOT PAREN BOOL: SWAP TRUE/FALSE PATHS ----
Gosub L_PUSH_BOOL_TARG
XC$(BOOLDEP + 41) = XC$(41)
L$ = Mid$(A$, 2, Len(A$) - 2)
Gosub L_NEXTSYM
FALSELBL = V
Gosub L_FORMATQ
K$ = Q$
Gosub L_NEXTSYM
I$ = Q$
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
Print #2, "jmp SKP_"; BF$(BOOLDEP)
V = FALSELBL
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
XC$(41) = XC$(BOOLDEP + 41)
Goto L_POP_BOOL_TARGE
L_COMP_GROUP:
' ---- compile AND group in B$; FALSE -> SKP_K$, TRUE -> THN_I$ ----
L_COMP_GROUP_01:
E$ = B$
N$ = " AND "
G = 5
K = 1
Gosub L_FIND_TOP_LEV_3
If F = 0 Then Goto L_COMP_GROUP_03
A$ = Trim$(Left$(B$, F - 1))
XC$(41) = Mid$(B$, F + 5, Len(B$) - F - 4)
If Len(A$) = 0 Then Goto L_END_02
Gosub L_LEFT_MC_2
If MC <> 40 Then Goto L_COMP_GROUP_02
E$ = A$: I = 1: Gosub L_FIND_MATCH: If J = Len(A$) Then Goto L_PAREN_BOOL_NON
L_COMP_GROUP_02:
Gosub L_COMP_ATOM
B$ = XC$(41)
Goto L_COMP_GROUP_01
L_COMP_GROUP_03:
A$ = Trim$(B$)
If Len(A$) = 0 Then Goto L_END_02
Gosub L_LEFT_MC_2: If MC <> 40 Then Goto L_COMP_GROUP_04
E$ = A$
I = 1
Gosub L_FIND_MATCH
If J <> Len(A$) Then Goto L_COMP_GROUP_04
L$ = Mid$(A$, 2, Len(A$) - 2)
Goto L_COMP_BOOL_EXPR
L_COMP_GROUP_04:
Gosub L_COMP_ATOM
Print #2, "jmp THN_"; I$
Return
L_COMP_ATOM:
' ---- compile IF atom in A$; FALSE -> SKP_K$ ----
NOTPAR = 0
Gosub L_TRIM_BOOL_ATOM
L_COMP_ATOM_01:
If Left$(A$, 4) <> "NOT " Then Goto L_COMP_ATOM_02
NOTPAR = 1 - NOTPAR
A$ = Mid$(A$, 5, Len(A$) - 4)
Gosub L_TRIM_BOOL_ATOM
Goto L_COMP_ATOM_01
L_COMP_ATOM_02:
If NOTPAR = 0 Then Goto L_COMP_ATOM_03
Gosub L_LEFT_MC_2: If MC <> 40 Then Goto L_COMP_ATOM_03
E$ = A$
I = 1
Gosub L_FIND_MATCH
If J = Len(A$) Then Goto L_NOT_PAREN_BOOL
L_COMP_ATOM_03:
J = 1
O = 0
H = 0
L_COMP_ATOM_04:
If J > Len(A$) Then Goto L_BARE_NUM_TRUTH
MC = Asc(Mid$(A$, J, 1))
If MC <> 34 Then Goto L_COMP_ATOM_05
If O = 0 Then O = 1: Goto L_COMP_ATOM_13
O = 0
Goto L_COMP_ATOM_13
L_COMP_ATOM_05:
If O <> 0 Then Goto L_COMP_ATOM_13
If MC <> 40 Then Goto L_COMP_ATOM_06
H = H + 1
Goto L_COMP_ATOM_13
L_COMP_ATOM_06:
If MC <> 41 Then Goto L_COMP_ATOM_07
H = H - 1
Goto L_COMP_ATOM_13
L_COMP_ATOM_07:
If H <> 0 Then Goto L_COMP_ATOM_13
If Mid$(A$, J, 2) <> "<>" Then Goto L_COMP_ATOM_08
OPC = 4
H = 2
Goto L_COMP_ATOM_14
L_COMP_ATOM_08:
If Mid$(A$, J, 2) <> "<=" Then Goto L_COMP_ATOM_09
OPC = 5
H = 2
Goto L_COMP_ATOM_14
L_COMP_ATOM_09:
If Mid$(A$, J, 2) <> ">=" Then Goto L_COMP_ATOM_10
OPC = 6
H = 2
Goto L_COMP_ATOM_14
L_COMP_ATOM_10:
If MC <> 61 Then Goto L_COMP_ATOM_11
OPC = 1
H = 1
Goto L_COMP_ATOM_14
L_COMP_ATOM_11:
If MC <> 60 Then Goto L_COMP_ATOM_12
OPC = 2
H = 1
Goto L_COMP_ATOM_14
L_COMP_ATOM_12:
If MC <> 62 Then Goto L_COMP_ATOM_13
OPC = 3
H = 1
Goto L_COMP_ATOM_14
L_COMP_ATOM_13:
J = J + 1
Goto L_COMP_ATOM_04
L_COMP_ATOM_14:
X$ = A$
B$ = Mid$(X$, J + H, Len(X$) - J - H + 1)
A$ = Left$(X$, J - 1)
Gosub L_TRIM_BOOL_ATOM
Gosub L_CHECK_WHETHE_2
If E <> 0 Then Goto L_COMP_ATOM_16
X$ = A$
A$ = B$
Gosub L_CHECK_WHETHE_2
A$ = X$
If E <> 0 Then Goto L_COMP_ATOM_16
If B$ <> "0" Then Goto L_COMP_ATOM_15
E$ = A$
Gosub L_COMP_AX
Print #2, "or ax,ax"
Goto L_EMIT_JUMP_SKP
L_COMP_ATOM_15:
E$ = A$
D = 1
C = 1
Gosub L_NEXTTOKE
Gosub L_EXPR
E$ = B$
D = 1
C = 1
Gosub L_NEXTTOKE
Gosub L_EXPR
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Print #2, "cmp ax,bx"
Goto L_EMIT_JUMP_SKP
L_COMP_ATOM_16:
X$ = A$
Y$ = B$
Gosub L_COMP_SI
Print #2, "mov di,OFFSET TMP3$"
Gosub L_EMIT_STRCOPY
OLDSTRDP = STRLEVEL
STRLEVEL = STRLEVEL + 1
If STRLEVEL > 3 Then STRLEVEL = OLDSTRDP: Goto L_END_08
Gosub L_COMP_DI
STRLEVEL = OLDSTRDP
Print #2, "mov si,OFFSET TMP3$"
Print #2, "call STRCMP"
Print #2, "cmp al,0"
Goto L_EMIT_JUMP_SKP
L_BARE_NUM_TRUTH:
' ---- bare numeric truth expression ----
E$ = A$
Gosub L_COMP_AX
Print #2, "or ax,ax"
If NOTPAR = 0 Then Print #2, "je SKP_"; K$: Return
Print #2, "jne SKP_"; K$
Return
L_EMIT_JUMP_SKP:
' ---- EMIT JUMP TO SKP_K$ (NORMAL OR NOT) ----
If OPC < 1 Or OPC > 6 Then Goto L_END_02
If NOTPAR <> 0 Then Goto L_EMIT_JUMP_S_01
On OPC Goto L_EMIT_JUMP_S_02,L_EMIT_JUMP_S_04,L_EMIT_JUMP_S_06,L_EMIT_JUMP_S_03,L_EMIT_JUMP_S_07,L_EMIT_JUMP_S_05
L_EMIT_JUMP_S_01:
On OPC Goto L_EMIT_JUMP_S_03,L_EMIT_JUMP_S_05,L_EMIT_JUMP_S_07,L_EMIT_JUMP_S_02,L_EMIT_JUMP_S_06,L_EMIT_JUMP_S_04
L_EMIT_JUMP_S_02:
D$ = "jne"
Goto L_EMIT_JUMP_S_08
L_EMIT_JUMP_S_03:
D$ = "je"
Goto L_EMIT_JUMP_S_08
L_EMIT_JUMP_S_04:
D$ = "jge"
Goto L_EMIT_JUMP_S_08
L_EMIT_JUMP_S_05:
D$ = "jl"
Goto L_EMIT_JUMP_S_08
L_EMIT_JUMP_S_06:
D$ = "jle"
Goto L_EMIT_JUMP_S_08
L_EMIT_JUMP_S_07:
D$ = "jg"
L_EMIT_JUMP_S_08:
Print #2, D$; " SKP_"; K$
Return
L_TRIM_BOOL_ATOM:
' ---- trim A$ and B$ for boolean IF atom ----
A$ = Trim$(A$)
B$ = Trim$(B$)
Return
L_CHECK_WHETHE_2:
' ---- check whether A$ is a string expression, result in E ----
L_CHECK_WHETH_2:
E = 0
If Len(A$) = 0 Then Return
' --- strip one outer parenthesis layer if fully enclosing ---
Gosub L_LEFT_MC_2: If MC <> 40 Then Goto L_DIRECT_STR_LIT
Gosub L_PUSH_STRCTX
E$ = A$
I = 1
Gosub L_FIND_MATCH
If J <> Len(A$) Then Goto L_CHECK_WHETH_3
Gosub L_POP_STRCTX
A$ = Mid$(A$, 2, Len(A$) - 2)
Goto L_CHECK_WHETH_2
L_CHECK_WHETH_3:
Gosub L_POP_STRCTX
L_DIRECT_STR_LIT:
' --- direct string literal or string identifier/function ---
Gosub L_LEFT_MC_2: If MC = 34 Then E = 1: Return
' --- check string identifier/function X$ ---
Gosub L_PUSH_STRCTX
E$ = A$
D = 1
Gosub L_READID
SAVEDID$ = L$
IDKIND = H
Gosub L_POP_STRCTX
If Len(SAVEDID$) = 0 Or IDKIND = 0 Then Return
E = 1
Return
L_PUSH_EXPRC:
' ---- PUSH_EXPRC ----
EXPDEPTH = EXPDEPTH + 1
If EXPDEPTH > 4 Then Goto L_END_08
EC(EXPDEPTH) = C
Return
L_POP_EXPRC:
' ---- POP_EXPRC ----
If EXPDEPTH < 1 Or EXPDEPTH > 4 Then Goto L_END_08
C = EC(EXPDEPTH)
EXPDEPTH = EXPDEPTH - 1
Return
L_PREP_BINOP_RHS:
' ---- PREP_BINOP_RHS ----
L = H
Gosub L_NEXTTOKE
Gosub L_PUSH_EXPRC
C = L + 1
Gosub L_EXPR
Gosub L_POP_EXPRC
Gosub L_EMIT_POPBX
Goto L_EMIT_POPAX
L_PUSH_NUMCTX:
' ---- PUSH_NUMCTX ----
NUMDEPTH = NUMDEPTH + 1
If NUMDEPTH > 4 Then Goto L_END_08
XC$(NUMDEPTH) = E$
ND(NUMDEPTH) = D
NC(NUMDEPTH) = C
NK(NUMDEPTH) = TK
NJ(NUMDEPTH) = J
NH(NUMDEPTH) = H
NP(NUMDEPTH) = CLOSEPAR
Return
L_POP_NUMCTX:
' ---- POP_NUMCTX ----
If NUMDEPTH < 1 Or NUMDEPTH > 4 Then Goto L_END_08
E$ = XC$(NUMDEPTH)
D = ND(NUMDEPTH)
C = NC(NUMDEPTH)
TK = NK(NUMDEPTH)
J = NJ(NUMDEPTH)
H = NH(NUMDEPTH)
CLOSEPAR = NP(NUMDEPTH)
NUMDEPTH = NUMDEPTH - 1
Return
L_PUSH_STRCTX:
' ---- PUSH_STRCTX ----
STRDEPTH = STRDEPTH + 1
If STRDEPTH > 8 Then Goto L_END_08
If STRDEPTH > 4 Then Goto L_PUSH_STRCTX_01
K = STRDEPTH + 4
XC$(K) = E$
K = K + 8
XC$(K) = L$
K = K + 4
XC$(K) = X$
Goto L_PUSH_STRCTX_04
L_PUSH_STRCTX_01:
If STRDEPTH > 6 Then Goto L_PUSH_STRCTX_02
K = STRDEPTH + 22
Goto L_PUSH_STRCTX_03
L_PUSH_STRCTX_02:
K = STRDEPTH + 26
L_PUSH_STRCTX_03:
XC$(K) = E$
K = K + 2
XC$(K) = L$
K = K + 2
XC$(K) = X$
L_PUSH_STRCTX_04:
K = STRDEPTH
SD(K) = D
SC(K) = C
ST(K) = TK
SJN(K) = J
SH(K) = H
Return
L_POP_STRCTX:
' ---- POP_STRCTX ----
If STRDEPTH < 1 Or STRDEPTH > 8 Then Goto L_END_08
If STRDEPTH > 4 Then Goto L_POP_STRCTX_01
K = STRDEPTH + 4
E$ = XC$(K)
K = K + 8
L$ = XC$(K)
K = K + 4
X$ = XC$(K)
Goto L_POP_STRCTX_04
L_POP_STRCTX_01:
If STRDEPTH > 6 Then Goto L_POP_STRCTX_02
K = STRDEPTH + 22
Goto L_POP_STRCTX_03
L_POP_STRCTX_02:
K = STRDEPTH + 26
L_POP_STRCTX_03:
E$ = XC$(K)
K = K + 2
L$ = XC$(K)
K = K + 2
X$ = XC$(K)
L_POP_STRCTX_04:
K = STRDEPTH
D = SD(K)
C = SC(K)
TK = ST(K)
J = SJN(K)
H = SH(K)
STRDEPTH = STRDEPTH - 1
Return
L_PUSH_SRCCTX:
' ---- PUSH_SRCCTX ----
SRCDEPTH = SRCDEPTH + 1
If SRCDEPTH > 4 Then Goto L_END_08
K = SRCDEPTH + 20
XC$(K) = E$
SRJ(SRCDEPTH) = J
SRH(SRCDEPTH) = H
SRO(SRCDEPTH) = O
SRP(SRCDEPTH) = CLOSEPAR
Return
L_POP_SRCCTX:
' ---- POP_SRCCTX ----
If SRCDEPTH < 1 Or SRCDEPTH > 4 Then Goto L_END_08
K = SRCDEPTH + 20
E$ = XC$(K)
J = SRJ(SRCDEPTH)
H = SRH(SRCDEPTH)
O = SRO(SRCDEPTH)
CLOSEPAR = SRP(SRCDEPTH)
SRCDEPTH = SRCDEPTH - 1
Return
L_PUSH_THENI:
' ---- PUSH_THENI ----
IFCTX = IFCTX + 1
If IFCTX > 2 Then Goto L_END_08
K = IFCTX + 24
XC$(K) = XC$(39)
TSK(IFCTX) = FALSELBL
TEND(IFCTX) = ENDIFLBL
TEL(IFCTX) = HASELSE
Return
L_POP_THENI:
' ---- POP_THENI ----
If IFCTX = 0 Then Goto L_END_08
K = IFCTX + 24
FALSELBL = TSK(IFCTX)
ENDIFLBL = TEND(IFCTX)
HASELSE = TEL(IFCTX)
XC$(39) = XC$(K)
IFCTX = IFCTX - 1
Return
L_TIE_UPPERCAS_S:
' ---- tie uppercasing to SRCMODE ----
If SRCMODE = 0 Then Goto L_TIE_UPPERCA_02
If SRCMODE = 1 Then Goto L_TIE_UPPERCA_01
D$ = Ltrim$(A$)
If Len(D$) = 0 Then Goto L_TIE_UPPERCA_01
Gosub L_LEFT_MC: If MC >= 48 And MC <= 57 Then Goto L_TIE_UPPERCA_02
L_TIE_UPPERCA_01:
R$ = ""
UCO = 0
UCI = 1
Goto L_TIE_UPPERCA_03
L_TIE_UPPERCA_02:
Gosub L_FLSEP
UCQ = I
If UCQ = 0 Then Return
R$ = Left$(A$, UCQ)
UCO = 0
UCI = UCQ + 1
L_TIE_UPPERCA_03:
If UCI > Len(A$) Then Goto L_TIE_UPPERCA_06
UCCH = Asc(Mid$(A$, UCI, 1))
If UCCH <> 34 Then Goto L_TIE_UPPERCA_04
If UCO = 0 Then UCO = 1: Goto L_TIE_UPPERCA_05
UCO = 0
Goto L_TIE_UPPERCA_05
L_TIE_UPPERCA_04:
If UCO <> 0 Then Goto L_TIE_UPPERCA_05
If UCCH < 97 Or UCCH > 122 Then Goto L_TIE_UPPERCA_05
UCCH = UCCH - 32
L_TIE_UPPERCA_05:
R$ = R$ + Chr$(UCCH)
UCI = UCI + 1
Goto L_TIE_UPPERCA_03
L_TIE_UPPERCA_06:
A$ = R$
Return

' ===============================================================
' ASSEMBLY EMISSION HELPERS
' ===============================================================

L_EMIT_POPAX:
' ---- EMIT_POPAX ----
Print #2, "pop ax"
Return
L_EMIT_PUSHAX:
' ---- EMIT_PUSHAX ----
Print #2, "push ax"
Return
L_EMIT_POPBX:
' ---- EMIT_POPBX ----
Print #2, "pop bx"
Return
L_EMIT_SI_TMP2:
' ---- EMIT_SI_TMP2 ----
Print #2, "mov si,OFFSET TMP2$"
Return
L_EMIT_STRCOPY:
' ---- EMIT_STRCOPY ----
Gosub L_EMIT_REQ_ST
Print #2, "call STRCPY"
Return
L_EMIT_SI_TMP:
' ---- EMIT_SI_TMP ----
Print #2, "mov si,OFFSET TMP$"
Return
L_EMIT_DI_TMP:
' ---- EMIT_DI_TMP ----
Print #2, "mov di,OFFSET TMP$"
Return
L_EMIT_DI_TMP2:
' ---- EMIT_DI_TMP2 ----
Print #2, "mov di,OFFSET TMP2$"
Return
L_EMIT_INPUTS:
' ---- EMIT_INPUTS ----
Gosub L_EMIT_REQ
Print #2, "call INPUTS"
Return
L_EMIT_PUSHDI:
' ---- EMIT_PUSHDI ----
Print #2, "push di"
Return
L_EMIT_POPDI:
' ---- EMIT_POPDI ----
Print #2, "pop di"
Return
L_EMIT_REQ_PR:
' ---- EMIT_REQ_PR ----
If UPR = 0 Then Print #2, "REQ PR": Let UPR = 1
Return
L_EMIT_REQ:
' ---- EMIT_REQ_IN ----
If UIN = 0 Then Print #2, "REQ IN": Let UIN = 1
Return
L_EMIT_REQ_FI:
' ---- EMIT_REQ_FI ----
If UFI = 0 Then Print #2, "REQ FI": Let UFI = 1
Return
L_EMIT_REQ_ST:
' ---- EMIT_REQ_ST ----
If UST = 0 Then Print #2, "REQ ST": Let UST = 1
Return
L_EMIT_REQ_CV:
' ---- EMIT_REQ_CV ----
If UCV = 0 Then Print #2, "REQ CV": Let UCV = 1
Return
L_EMIT_REQ_AR:
' ---- EMIT_REQ_AR ----
If UAR = 0 Then Print #2, "REQ AR": Let UAR = 1
Return
L_EMIT_NB_ASCIIZ:
' ---- EMIT_NB_ASCIIZ_FROM_SI ----
Print #2, "mov di,OFFSET NB"
Gosub L_EMIT_STRCOPY
Print #2, "xor bx,bx"
Print #2, "mov bl,[NB]"
Print #2, "mov BYTE PTR [NB+bx+1],0"
Print #2, "mov dx,OFFSET NB+1"
Return
L_EMIT_REQ_BI:
' ---- EMIT_REQ_BI ----
If UBI = 0 Then Print #2, "REQ BI": Let UBI = 1
Return
L_EMIT_REQ_FL:
' ---- EMIT_REQ_FL ----
If UFL = 0 Then Print #2, "REQ FL": Let UFL = 1
Return
L_EMIT_REQ_DR:
' ---- EMIT_REQ_DR ----
If UDR = 0 Then Print #2, "REQ DR": Let UDR = 1
Return
L_EMIT_REQ_GR:
' ---- EMIT_REQ_GR ----
If UGR = 0 Then Print #2, "REQ GR": Let UGR = 1
Return
L_EMIT_REQ_RN:
' ---- EMIT_REQ_RN ----
If URN = 0 Then Print #2, "REQ RN": Let URN = 1
Return
L_EMIT_REQ_MT:
' ---- EMIT_REQ_MT ----
If UMT = 0 Then Print #2, "REQ MT": Let UMT = 1
Return
L_EMIT_REQ_XA:
' ---- EMIT_REQ_XA ----
If UXA = 0 Then Print #2, "REQ XA": Let UXA = 1
Return
L_EMIT_GETHOUT_K:
' --- EMIT_GETHOUT_KEEPAX ----
Gosub L_EMIT_PUSHAX
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call GETHOUT"
Goto L_EMIT_POPAX
L_EMIT_LBL_SKP:
' ---- EMIT_LABEL_SKP_Q ----
Print #2, "SKP_"; Q$; ":"
Return
L_EMIT_REQ_PK:
' ---- EMIT_REQ_PK ----
If UPK = 0 Then Print #2, "REQ PK": Let UPK = 1
Return
L_EMIT_MOV_AL:
' ---- EMIT_MOV_AL_FC ----
Print #2, "mov al,"; FC
Return
L_EMIT_DS_DI:
' ---- EMIT_DS_DI_F ----
Print #2, "DS "; Z$
Print #2, "mov di,OFFSET S_"; Z$
Return
L_EMIT_DS_SI:
' ---- EMIT_DS_SI_D ----
Print #2, "DS "; D$
Print #2, "mov si,OFFSET S_"; D$
Return
L_PARSE_CHANNEL:
' ---- PARSE STATIC CHANNEL IN D$: exactly one digit 1..9 ----
D$ = Trim$(D$)
If Len(D$) <> 1 Then Goto L_END_02
MC = Asc(D$)
If MC < 49 Or MC > 57 Then Goto L_END_02
FC = MC - 48
Return
L_PARSE_BINIO:
' ---- PARSE_BINIO: success -> E=1, FC=channel 1..9 ----
E = 0
I = Instr(B$, "#")
J = Instr(B$, ",")
If I = 0 Or J = 0 Then Return
D$ = Mid$(B$, I + 1, J - I - 1): Gosub L_PARSE_CHANNEL
If FC < 1 Or FC > 9 Then Return
XC$(41) = R$
R$ = Mid$(B$, J + 1, Len(B$) - J)
R$ = Ltrim$(R$)
If Len(R$) = 0 Then Return
If Asc(Left$(R$, 1)) <> 44 Then Goto L_PARSE_BINIO_01
D$ = Mid$(R$, 2, Len(R$) - 1)
N$ = ""
Goto L_PARSE_BINIO_02
L_PARSE_BINIO_01:
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then D$ = R$: N$ = "": Goto L_PARSE_BINIO_02
N$ = Left$(R$, F - 1)
D$ = Mid$(R$, F + 1, Len(R$) - F)
L_PARSE_BINIO_02:
Gosub L_TRIM
If Len(D$) = 0 Then Return
Gosub L_PUSH_STRCTX
E$ = D$
D = 1
Gosub L_READID
SAVEDID$ = L$
IDKIND = H
I = D
Gosub L_POP_STRCTX
If Len(SAVEDID$) = 0 Or IDKIND <> 0 Then Return
If I > Len(D$) Then Goto L_PARSE_BINIO_03
Return
L_PARSE_BINIO_03:
E = 1
Return
L_QB_LBL_LINE:
' ---- QB label line? A$ = IDENT: -> E=1, L$=IDENT ----
E = 0
If Len(A$) < 2 Then Return
If Asc(Right$(A$, 1)) <> 58 Then Return
E$ = Left$(A$, Len(A$) - 1)
D = 1
Gosub L_READ_LBL_IDENT
If Len(L$) = 0 Then Return
If H <> 0 Then Return
If D <= Len(E$) Then Return
E = 1
Return
L_GET:
' ---------------- GET ---------------------
Gosub L_PARSE_BINIO
If E = 0 Then Goto L_END_02
If Len(N$) = 0 Then Goto L_GET_01
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_REQ_BI
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call GETHIN"
Gosub L_EMIT_POPAX
Print #2, "call SEEK_BYTEH"
L_GET_01:
Gosub L_EMIT_REQ_BI
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call GETHIN"
Print #2, "call READ_BYTEH"
Print #2, "DN "; SAVEDID$
Print #2, "mov [N_"; SAVEDID$; "],ax"
R$ = XC$(41)
Goto L_CONTINUE_SUB_S
L_PUT:
' ---------------- PUT ---------------------
Gosub L_PARSE_BINIO
If E = 0 Then Goto L_END_02
If Len(N$) = 0 Then Goto L_PUT_01
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_REQ_BI
Gosub L_EMIT_REQ_FI
Gosub L_EMIT_MOV_AL
Print #2, "call GETHOUT"
Gosub L_EMIT_POPAX
Print #2, "call SEEK_BYTEH"
L_PUT_01:
Gosub L_EMIT_REQ_BI
Print #2, "DN "; SAVEDID$
Print #2, "mov ax,[N_"; SAVEDID$; "]"
Gosub L_EMIT_GETHOUT_K
Print #2, "call WRITE_BYTEH"
R$ = XC$(41)
Goto L_CONTINUE_SUB_S
L_BASIC_END_VERY:
' ---- real BASIC end at the very end of the file ----
End ER
' <- ER = ERRORLEVEL for DOS
L_EMIT_REQ_PN:
' ---- EMIT_REQ_PN ----
If UPN = 0 Then Print #2, "REQ PN": Let UPN = 1
Return
L_EMIT_LBL_THN:
' ---- EMIT_LABEL_THN_I ----
Print #2, "THN_"; I$; ":"
Return
L_EMIT_STORE_AX:
' ---- EMIT_STORE_N_D_AX ----
Print #2, "DN "; D$
Print #2, "mov [N_"; D$; "],ax"
Return
L_EMIT_JMP_SKP:
' ---- EMIT_JMP_SKP_Q ----
Print #2, "jmp SKP_"; Q$
Return
L_EMIT_DSA:
' ---- EMIT_DSA_F_N: uses D$/I/MC/V scratch; N$/Z$ preserved ----
D$ = Trim$(N$)
If Len(D$) = 0 Then Goto L_EMIT_DSA_03
I = 1
L_EMIT_DSA_01:
If I > Len(D$) Then Goto L_EMIT_DSA_02
MC = Asc(Mid$(D$, I, 1))
If MC < 48 Or MC > 57 Then Goto L_EMIT_DSA_03
I = I + 1
Goto L_EMIT_DSA_01
L_EMIT_DSA_02:
V = Val(D$)
If V < 1 Or V > 32767 Then Goto L_EMIT_DSA_03
Print #2, "DSA "; Z$; ","; D$
Return
L_EMIT_DSA_03:
Print #2, "DS "; Z$
Return
L_EMIT_REQ_IO:
' ---- EMIT_REQ_IO ----
If UIO = 0 Then Print #2, "REQ IO": Let UIO = 1
Return
L_EMIT_REQ_SO:
' ---- EMIT_REQ_SO ----
If USO = 0 Then Print #2, "REQ SO": Let USO = 1
Return
L_EMIT_REQ_BK:
' ---- EMIT_REQ_BK ----
If UBK = 0 Then Print #2, "REQ BK": Let UBK = 1
Return
L_EMIT_REQ_DV:
' ---- EMIT_REQ_DV: CHECKED INTEGER ABS/DIVISION ----
If UDV = 0 Then Print #2, "REQ DV": Let UDV = 1
Return

' ===============================================================
' BLOCK IF AND LOOP CONTROL
' ===============================================================

L_BLOCK_BEGIN:
' ---------- BLOCK IF BEGIN ----------
If DISPMODE <> 0 Then Goto L_END_02
If IFLEVEL < 4 Then Goto L_BLOCK_BEGIN_01
Goto L_END_09
L_BLOCK_BEGIN_01:
Gosub L_NEXTSYM
CURFALSE = V
Gosub L_NEXTSYM
CURENDIF = V
Gosub L_NEXTSYM
I$ = Q$
FALSELBL = CURFALSE
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
IFLEVEL = IFLEVEL + 1
IFN(IFLEVEL) = CURFALSE
IFE(IFLEVEL) = CURENDIF
IFS(IFLEVEL) = 0
Goto L_CONTINUE_SUB_S
L_BLOCK_ELSEIF:
' ---------- BLOCK ELSEIF ----------
If DISPMODE <> 0 Then Goto L_END_02
If IFLEVEL > 0 Then Goto L_BLOCK_ELSEI_01
Goto L_END_09
L_BLOCK_ELSEI_01:
Gosub L_LOAD_STACK_ENT
If CURELSE = 0 Then Goto L_BLOCK_ELSEI_02
Goto L_END_09
L_BLOCK_ELSEI_02:
E$ = B$
N$ = "THEN"
G = 4
K = 8
Gosub L_FIND_TOP_LEV_3
I = F
If I = 0 Then Goto L_END_02
L$ = Mid$(B$, 8, I - 8)
R$ = Mid$(B$, I + 5, Len(B$) - I - 4)
R$ = Trim$(R$)
If Len(R$) <> 0 Then Goto L_END_02
V = CURENDIF
Gosub L_FORMATQ
Gosub L_EMIT_JMP_SKP
V = CURFALSE
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
Gosub L_NEXTSYM
CURFALSE = V
Gosub L_NEXTSYM
I$ = Q$
FALSELBL = CURFALSE
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
Gosub L_STORE_STACK_EN
Goto L_CONTINUE_SUB_S
L_BLOCK:
' ---------- BLOCK ELSE ----------
If DISPMODE <> 0 Then Goto L_END_02
If IFLEVEL > 0 Then Goto L_BLOCK_01
Goto L_END_09
L_BLOCK_01:
Gosub L_LOAD_STACK_ENT
If CURELSE = 0 Then Goto L_BLOCK_02
Goto L_END_09
L_BLOCK_02:
V = CURENDIF
Gosub L_FORMATQ
Gosub L_EMIT_JMP_SKP
V = CURFALSE
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
CURELSE = 1
Gosub L_STORE_STACK_EN
Goto L_CONTINUE_SUB_S
L_BLOCK_END:
' ---------- BLOCK END IF ----------
If DISPMODE <> 0 Then Goto L_END_02
If IFLEVEL > 0 Then Goto L_BLOCK_END_01
Goto L_END_09
L_BLOCK_END_01:
Gosub L_LOAD_STACK_ENT
If CURELSE <> 0 Then Goto L_BLOCK_END_02
V = CURFALSE
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
L_BLOCK_END_02:
V = CURENDIF
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
IFLEVEL = IFLEVEL - 1
Goto L_CONTINUE_SUB_S
L_LOAD_STACK_ENT:
' ---------- LOAD CURRENT IF STACK ENTRY ----------
If IFLEVEL < 1 Or IFLEVEL > 4 Then Goto L_END_09
CURFALSE = IFN(IFLEVEL)
CURENDIF = IFE(IFLEVEL)
CURELSE = IFS(IFLEVEL)
Return
L_STORE_STACK_EN:
' ---------- STORE CURRENT IF STACK ENTRY ----------
If IFLEVEL < 1 Or IFLEVEL > 4 Then Goto L_END_09
IFN(IFLEVEL) = CURFALSE
IFE(IFLEVEL) = CURENDIF
IFS(IFLEVEL) = CURELSE
Return
L_WHILE_BEGIN:
' ---------- WHILE BEGIN ----------
If DISPMODE <> 0 Then Goto L_END_02
B = B + 1
If B > 4 Then Goto L_END_03
E$ = Mid$(B$, 6, Len(B$) - 5)
E$ = Trim$(E$)
If Len(E$) = 0 Then Goto L_END_02
L$ = E$
Gosub L_NEXTSYM
LOOPHEAD = V
Gosub L_NEXTSYM
LOOPEXIT = V
Gosub L_NEXTSYM
I$ = Q$
V = LOOPHEAD
Gosub L_FORMATQ
Print #2, "WHL_"; Q$; ":"
FALSELBL = LOOPEXIT
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
LL(B) = LOOPHEAD
LS(B) = LOOPEXIT
LT(B) = 1
Goto L_CONTINUE_SUB_S
L_WEND:
' ---------- WEND ----------
If DISPMODE <> 0 Then Goto L_END_02
If B = 0 Then Goto L_END_03
If LT(B) <> 1 Then Goto L_END_03
LOOPHEAD = LL(B)
LOOPEXIT = LS(B)
V = LOOPHEAD
Gosub L_FORMATQ
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
Print #2, "jmp WHL_"; Q$
V = LOOPEXIT
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
B = B - 1
Goto L_CONTINUE_SUB_S

' ===============================================================
' SYSTEM, FILE, GRAPHICS AND MEMORY FEATURES
' ===============================================================

L_XSET_HANDLE_IN:
' ---------- XSET handle,index,string ----------
If DISPMODE <> 0 Then Goto L_END_02
E$ = Mid$(B$, 6, Len(B$) - 5)
E$ = Trim$(E$)
If Len(E$) = 0 Then Goto L_END_02
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L1 = F
K = L1 + 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L2 = F
N$ = Left$(E$, L1 - 1)
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L1 + 1, L2 - L1 - 1)
Gosub L_COMP_NUM_SUBEX
X$ = Mid$(E$, L2 + 1, Len(E$) - L2)
X$ = Trim$(X$)
If Len(X$) = 0 Then Goto L_END_02
E$ = X$
Gosub L_STR_EXPR_PARSE
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_XA
Print #2, "call XASET"
Goto L_CONTINUE_SUB_S
L_XFREE_HANDLE:
' ---------- XFREE handle ----------
If DISPMODE <> 0 Then Goto L_END_02
N$ = Mid$(B$, 7, Len(B$) - 6)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_XA
Print #2, "call XAFREE"
Goto L_CONTINUE_SUB_S
L_XALLOC:
' ---------- XALLOC(count[,maxlen]) ----------
I = D + 5
Gosub L_FIND_MATCH
CLOSEPAR = J
K = I + 1
L = CLOSEPAR - 1
If K > L Then Goto L_END_02
Gosub L_FIND_TOP_LEV_2
If F <> 0 Then Goto L_XALLOC_01
N$ = Mid$(E$, I + 1, CLOSEPAR - I - 1)
Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "xor bx,bx"
Goto L_XALLOC_02
L_XALLOC_01:
N$ = Mid$(E$, I + 1, F - I - 1)
Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
K = D + 6
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(E$, F + 1, CLOSEPAR - F - 1)
Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
L_XALLOC_02:
Gosub L_EMIT_REQ_XA
Print #2, "call XAALLOC"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_XGET:
' ---------- XGET$(handle,index) ----------
Gosub L_PUSH_SRCCTX
E$ = X$
I = 6
Gosub L_FIND_MATCH
CLOSEPAR = J
K = 7
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
G = F
N$ = Mid$(E$, 7, G - 7)
Gosub L_COMP_NUM_SUBEX
K = 7
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(E$, F + 1, CLOSEPAR - F - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_REQ_XA
Print #2, "call XAGET"
Gosub L_EMIT_SI_TMP
Gosub L_POP_SRCCTX
Goto L_POP_STRFUNCT
L_EMIT_CALL:
' ---- EMIT_INPUT_CALL: H=0 INPUTS, H<>0 INPUTN ----
If H = 0 Then Goto L_EMIT_INPUTS
Gosub L_EMIT_REQ
Print #2, "call INPUTN"
Return
L_TIMER:
' ---------- TIMER() ----------
I = D + 4
Gosub L_FIND_MATCH
CLOSEPAR = J
If CLOSEPAR <> I + 1 Then Goto L_END_02
If UTM = 0 Then Print #2, "REQ TM": Let UTM = 1
Print #2, "call TIMERC"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_EXEC:
' ---------- EXEC(program$, args$) ----------
I = D + 3
Gosub L_FIND_MATCH
CLOSEPAR = J
K = I + 1
L = CLOSEPAR - 1
If K > L Then Goto L_END_02
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
G = F
T = I + 1
U = G - I - 1
X$ = Mid$(E$, T, U)
Gosub L_COMP_SI
If UEX = 0 Then Print #2, "REQ EX": Let UEX = 1
Print #2, "call EX_SETPROG"
I = D + 3
Gosub L_FIND_MATCH
CLOSEPAR = J
K = I + 1
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
T = F + 1
U = CLOSEPAR - F - 1
X$ = Mid$(E$, T, U)
Gosub L_COMP_SI
Print #2, "call EXECC"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_CPUID:
' ---------- CPUID() ----------
I = D + 4
Gosub L_FIND_MATCH
CLOSEPAR = J
If CLOSEPAR <> I + 1 Then Goto L_END_02
If UCP = 0 Then Print #2, "REQ CP": Let UCP = 1
Print #2, "call CPUIDC"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_EMIT_REQ_DT:
' ---- EMIT_REQ_DT ----
If UDT = 0 Then Print #2, "REQ DT": Let UDT = 1
Return
L_RANDOMIZ:
' ---------- RANDOMIZE [TIMER|TIMER()|numexpr] ----------
D$ = Mid$(B$, 10, Len(B$) - 9)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_02
If D$ = "TIMER" Or D$ = "TIMER()" Then Goto L_QUICKBAS_COMPA
' ---- general numeric seed expression ----
E$ = D$
Gosub L_COMP_AX
Goto L_AX_CONTAINS_SE
L_QUICKBAS_COMPA:
' ---- QuickBASIC-compatible: RANDOMIZE TIMER ----
If UTM = 0 Then Print #2, "REQ TM": Let UTM = 1
Print #2, "call TIMERC"
L_AX_CONTAINS_SE:
' ---- AX contains Seed
Gosub L_NEXTSYM
L$ = Q$
Print #2, "or ax,ax"
Print #2, "jne RNDSEED_"; L$
Print #2, "mov ax,1"
Print #2, "RNDSEED_"; L$; ":"
Gosub L_EMIT_REQ_RN
Print #2, "mov [RSEED],ax"
Goto L_CONTINUE_SUB_S
L_EMIT_REQ_TS:
' ---- EMIT_REQ_TS ----
If UTS = 0 Then Print #2, "REQ TS": Let UTS = 1
Return
L_TIME:
' --- TIME$ ---
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_REQ_TS
Print #2, "call TIMESTR"
Gosub L_EMIT_SI_TMP
P = 2
Return
L_DIM_STR:
' ---------- DIM STRING: DIM X$(MAXLEN) / DIM X[$] AS STRING * MAXLEN ----------
If Len(Z$) < 1 Then Goto L_END_02
Gosub L_RIGHT_MC_2: If MC <> 36 Then Goto L_DIM_STR_01
Z$ = Left$(Z$, Len(Z$) - 1)
L_DIM_STR_01:
If Len(Z$) = 0 Then Goto L_END_02
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
G = 0
J = 1
L_DIM_STR_02:
If J > Len(N$) Then Goto L_DIM_STR_03
MC = Asc(Mid$(N$, J, 1))
If MC < 48 Or MC > 57 Then Goto L_END_02
G = G * 10 + MC - 48
J = J + 1
Goto L_DIM_STR_02
L_DIM_STR_03:
If G < 1 Or G > 255 Then Goto L_END_02
Print #2, "DSLEN "; Z$; ","; G
Goto L_CONTINUE_SUB_S
L_DIM_2:
' ---- DIM [X$|X] AS STRING * N ----
E = 0
I = Instr(D$, " AS STRING * ")
If I = 0 Then Return
E$ = Left$(D$, I - 1)
E$ = Rtrim$(E$)
N$ = Mid$(D$, I + 13, Len(D$) - I - 12)
D = 1
Gosub L_READID
If Len(L$) = 0 Or D <= Len(E$) Then Goto L_END_02
Z$ = L$
E = 1
Return
L_PUSH_STRFUNCT:
' ---- PUSH_STRFUNCTX: save E$/D/C/TK/H for 13080 ----
FUNDEPTH = FUNDEPTH + 1
If FUNDEPTH > 4 Then Goto L_END_08
K = FUNDEPTH + 8
XC$(K) = E$
OFD(FUNDEPTH) = D
OFC(FUNDEPTH) = C
OFT(FUNDEPTH) = TK
OFH(FUNDEPTH) = H
Return
L_POP_STRFUNCT:
' ---- POP_STRFUNCTX: restore E$/D/C/TK/H for 13080 ----
If FUNDEPTH = 0 Then Goto L_END_08
K = FUNDEPTH + 8
E$ = XC$(K)
D = OFD(FUNDEPTH)
C = OFC(FUNDEPTH)
TK = OFT(FUNDEPTH)
H = OFH(FUNDEPTH)
FUNDEPTH = FUNDEPTH - 1
Return
L_PEEK_STRFUNCT:
' ---- PEEK_STRFUNCTX: restore E$/D/C/TK/H without FUNDEPTH pop ----
If FUNDEPTH = 0 Then Return
K = FUNDEPTH + 8
E$ = XC$(K)
D = OFD(FUNDEPTH)
C = OFC(FUNDEPTH)
TK = OFT(FUNDEPTH)
H = OFH(FUNDEPTH)
Return
L_HAS_TOP_PLUS:
' ---- HAS_TOP_PLUS_QP: top-level + outside quotes/parens? -> E=1 ----
E = 0
S = 0
H = 0
I = 1
L_HAS_TOP_PLU_01:
If I > Len(X$) Then Return
Gosub L_CHAR_MC_3
If MC <> 34 Then Goto L_HAS_TOP_PLU_02
If S = 0 Then S = 1 Else S = 0
Goto L_HAS_TOP_PLU_05
L_HAS_TOP_PLU_02:
If S <> 0 Then Goto L_HAS_TOP_PLU_05
If MC <> 40 Then Goto L_HAS_TOP_PLU_03
H = H + 1
Goto L_HAS_TOP_PLU_05
L_HAS_TOP_PLU_03:
If MC <> 41 Then Goto L_HAS_TOP_PLU_04
If H > 0 Then H = H - 1
Goto L_HAS_TOP_PLU_05
L_HAS_TOP_PLU_04:
If MC <> 43 Then Goto L_HAS_TOP_PLU_05
If H = 0 Then E = 1: Return
L_HAS_TOP_PLU_05:
I = I + 1
Goto L_HAS_TOP_PLU_01
L_EMIT_DI_STSAVE:
' ---- EMIT_DI_STSAVE: DI to save buffer by STRLEVEL ----
D$ = "di"
Goto L_EMIT_SI_STS_01
L_EMIT_SI_STSAVE:
' ---- EMIT_SI_STSAVE: SI to save buffer by STRLEVEL ----
D$ = "si"
L_EMIT_SI_STS_01:
Select Case STRLEVEL
Case 1
    Print #2, "mov "; D$; ",OFFSET TMP3$"
Case 2
    Gosub L_EMIT_REQ_T4
    Print #2, "mov "; D$; ",OFFSET TMP4$"
Case 3
    Gosub L_EMIT_REQ_T5
    Print #2, "mov "; D$; ",OFFSET TMP5$"
Case 4
    Gosub L_EMIT_REQ_T6
    Print #2, "mov "; D$; ",OFFSET TMP6$"
Case Else
    Goto L_END_08
End Select
Return
L_EMIT_REQ_T4:
' ---- EMIT_REQ_T4 ----
If UT4 <> 0 Then Return
Print #2, "REQ T4"
UT4 = 1
Return
L_EMIT_REQ_T5:
' ---- EMIT_REQ_T5 ----
If UT5 <> 0 Then Return
Print #2, "REQ T5"
UT5 = 1
Return
L_EMIT_REQ_T6:
' ---- EMIT_REQ_T6 ----
If UT6 <> 0 Then Return
Print #2, "REQ T6"
UT6 = 1
Return
L_PEEK:
' ---------- PEEK(offset) / PEEK(segment,offset) ----------
I = D + 3
Gosub L_FIND_MATCH
CLOSEPAR = J
K = I + 1
L = CLOSEPAR - 1
If K > L Then Goto L_END_02
Gosub L_FIND_TOP_LEV_2
If F <> 0 Then Goto L_PEEK_01
N$ = Mid$(E$, I + 1, CLOSEPAR - I - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_REQ_PK
Print #2, "call PEEKD"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_PEEK_01:
N$ = Mid$(E$, I + 1, F - I - 1)
Gosub L_COMP_NUM_SUBEX
K = D + 4
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(E$, F + 1, CLOSEPAR - F - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_PK
Print #2, "call PEEKC"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_POKE_OFFSET_VA:
' ---------- POKE offset,value / POKE segment,offset,value ----------
D$ = Mid$(B$, 6, Len(B$) - 5)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_02
E$ = D$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L1 = F
K = L1 + 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F <> 0 Then L2 = F: Goto L_POKE_OFFSET_01
N$ = Left$(E$, L1 - 1)
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L1 + 1, Len(E$) - L1)
Gosub L_COMP_NUM_SUBEX
Print #2, "pop cx"
Gosub L_EMIT_POPBX
Gosub L_EMIT_REQ_PK
Print #2, "call POKED"
Goto L_CONTINUE_SUB_S
L_POKE_OFFSET_01:
N$ = Left$(E$, L1 - 1)
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L1 + 1, L2 - L1 - 1)
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L2 + 1, Len(E$) - L2)
Gosub L_COMP_NUM_SUBEX
Print #2, "pop cx"
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_PK
Print #2, "call POKEC"
Goto L_CONTINUE_SUB_S
L_DEF_SEG:
' ---------- DEF SEG [= segment] ----------
If Left$(B$, 7) <> "DEF SEG" Then Goto L_END_02
D$ = Mid$(B$, 8, Len(B$) - 7)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_DEF_SEG_01
Gosub L_LEFT_MC: If MC <> 61 Then Goto L_END_02
N$ = Mid$(D$, 2, Len(D$) - 1)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_PK
Print #2, "call DEFSEGC"
Goto L_CONTINUE_SUB_S
L_DEF_SEG_01:
Gosub L_EMIT_REQ_PK
Print #2, "call DEFSEGR"
Goto L_CONTINUE_SUB_S
L_HEX_LIT_H0000:
' ---------- HEX LITERAL &H0000..&HFFFF ----------
If D > Len(E$) Then Goto L_END_02
If Asc(Mid$(E$, D, 1)) <> 72 Then Goto L_END_02
D = D + 1
L$ = ""
L_HEX_LIT_H00_01:
If D > Len(E$) Then Goto L_HEX_LIT_H00_03
Gosub L_CHAR_MC
If MC >= 48 And MC <= 57 Or MC >= 65 And MC <= 70 Then Goto L_HEX_LIT_H00_02
Goto L_HEX_LIT_H00_03
L_HEX_LIT_H00_02:
L$ = L$ + Chr$(MC)
If Len(L$) > 4 Then Goto L_END_02
D = D + 1
Goto L_HEX_LIT_H00_01
L_HEX_LIT_H00_03:
If Len(L$) = 0 Then Goto L_END_02
Print #2, "mov ax,0"; L$; "H"
Gosub L_EMIT_PUSHAX
Goto L_NEXTTOKE
L_END_EXIT_EXIT:
' ---------- END FOR / EXIT FOR / EXIT INNERMOST FOR ----------
If B = 0 Then Goto L_END_03
If LT(B) <> 0 Then Goto L_END_03
V = LL(B)
Gosub L_FORMATQ
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
Print #2, "jmp L_END_"; Q$
Goto L_CONTINUE_SUB_S
L_EXIT_SELECT:
' ---------- EXIT SELECT ----------
If SELMODE = 0 Then Goto L_END_02
If CASEBODY = 0 Then Goto L_END_02
Gosub L_FINISH_CASE_BO
Goto L_CONTINUE_SUB_S
L_EXIT_WHILE:
' ---------- EXIT WHILE ----------
If B = 0 Then Goto L_END_03
If LT(B) <> 1 Then Goto L_END_03
V = LS(B)
Gosub L_FORMATQ
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
Print #2, "jmp SKP_"; Q$
Goto L_CONTINUE_SUB_S
L_CHDIR_MKDIR_RM:
' ---------- CHDIR / MKDIR / RMDIR COMMON ----------
If Len(B$) < 7 Then Goto L_END_02
X$ = Mid$(B$, 7, Len(B$) - 6)
Gosub L_COMP_SI
Gosub L_EMIT_NB_ASCIIZ
Gosub L_EMIT_REQ_DR
If Left$(B$, 5) = "CHDIR" Then Print #2, "mov ah,59": Goto L_CHDIR_MKDIR_01
If Left$(B$, 5) = "MKDIR" Then Print #2, "mov ah,57": Goto L_CHDIR_MKDIR_01
Print #2, "mov ah,58"
L_CHDIR_MKDIR_01:
Print #2, "call DIRF"
Goto L_CONTINUE_SUB_S
L_MIN_MAX_PREAMB:
' ---- MIN/MAX COMMON PREAMBLE ----
I = D + 2
Gosub L_FIND_MATCH
CLOSEPAR = J
K = I + 1
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
G = F
N$ = Mid$(E$, I + 1, G - I - 1)
Gosub L_COMP_NUM_SUBEX
K = D + 3
L = CLOSEPAR - 1
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(E$, F + 1, CLOSEPAR - F - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Goto L_EMIT_REQ_MT
L_MIN_MAX_PRE_01:
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_FILES:
' ---------- FILES [filespec$] ----------
If Len(B$) = 5 Then Goto L_FILES_01
If Asc(Mid$(B$, 6, 1)) <> 32 Then Goto L_END_02
X$ = Mid$(B$, 7, Len(B$) - 6)
X$ = Trim$(X$): If Len(X$) = 0 Then Goto L_END_02
Gosub L_COMP_SI
Gosub L_EMIT_NB_ASCIIZ
Goto L_FILES_02
L_FILES_01:
Print #2, "mov dx,OFFSET FLSALL"
L_FILES_02:
Gosub L_EMIT_REQ_FL
Print #2, "call FILESF"
Goto L_CONTINUE_SUB_S
L_LEFT_RIGHT_PRE:
' ---- LEFT$/RIGHT$ COMMON PREAMBLE ----
Gosub L_PUSH_SRCCTX
E$ = X$
Gosub L_FIND_MATCH
K = I + 1
L = J - 1
Gosub L_FIND_TOP_LEV_2
G = F
If G = 0 Then Goto L_END_02
X$ = Mid$(E$, I + 1, G - I - 1)
N$ = Mid$(E$, G + 1, J - G - 1)
Gosub L_COMP_NUM_SUBEX
E$ = X$
Gosub L_STR_EXPR_PARSE
Goto L_COMP_AX_01
L_NUMSTRAR:
' ---- NUMSTRARG: set string argument to SI, set CLOSEPAR ----
Gosub L_FIND_MATCH
CLOSEPAR = J
X$ = Mid$(E$, I + 1, CLOSEPAR - I - 1)
Goto L_COMP_SI
L_SCREEN_MODE:
' ---------- SCREEN mode ----------
N$ = Mid$(B$, 8, Len(B$) - 7)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_GR
Print #2, "call SCREENC"
Goto L_CONTINUE_SUB_S
L_PSET_COLOR:
' ---------- PSET x,y,color ----------
E$ = Mid$(B$, 6, Len(B$) - 5)
E$ = Trim$(E$)
If Len(E$) = 0 Then Goto L_END_02
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L1 = F
K = L1 + 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L2 = F
N$ = Left$(E$, L1 - 1)
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L1 + 1, L2 - L1 - 1)
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L2 + 1, Len(E$) - L2)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "mov dx,ax"
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_GR
Print #2, "call PSETC"
Goto L_CONTINUE_SUB_S
L_INP:
' ---------- INP(port) ----------
I = D + 2
Gosub L_FIND_MATCH
CLOSEPAR = J
N$ = Mid$(E$, I + 1, CLOSEPAR - I - 1)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "mov dx,ax"
Gosub L_EMIT_REQ_IO
Print #2, "call INPC"
Gosub L_EMIT_PUSHAX
Goto L_EXIST_01
L_OUT_PORT_VALUE:
' ---------- OUT port,value ----------
D$ = Mid$(B$, 4, Len(B$) - 3)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_02
E$ = D$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
G = F
N$ = Left$(E$, G - 1)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
G = F
N$ = Mid$(E$, G + 1, Len(E$) - G)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "mov bx,ax"
Gosub L_EMIT_POPAX
Print #2, "mov dx,ax"
Print #2, "mov ax,bx"
Gosub L_EMIT_REQ_IO
Print #2, "call OUTC"
Goto L_CONTINUE_SUB_S
L_CALLINT_INTNO:
' ---------- CALLINT intno, regarray ----------
D$ = Mid$(B$, 8, Len(B$) - 7)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_02
E$ = D$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
N$ = Left$(E$, F - 1)
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
D$ = Mid$(E$, F + 1, Len(E$) - F)
Gosub L_TRIM
If Len(D$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
E$ = D$
D = 1
Gosub L_READID
If Len(L$) = 0 Or H <> 0 Or D <= Len(E$) Then Goto L_END_02
Print #2, "DS "; L$
Print #2, "mov si,OFFSET S_"; L$
If UIX = 0 Then Print #2, "REQ IX": Let UIX = 1
Print #2, "call CALLINTC"
Goto L_CONTINUE_SUB_S
L_CMD_LINE_PARSE:
' ---- COMMAND LINE PARSE / BUILD X$ INPUT AND Y$ OUTPUT ----
Let E = 0
If Len(X$) = 0 Or X$ = "/?" Or X$ = "/HELP" Or X$ = "/help" Or Instr(X$, " ") <> 0 Then Let E = 1: Return
Let I = Len(X$)
Let J = 0
L_CMD_LINE_PA_01:
If I <= 0 Then Goto L_CMD_LINE_PA_02
Gosub L_CHAR_MC_3
If MC = 46 Then Let J = I: Goto L_CMD_LINE_PA_02
If MC = 92 Or MC = 58 Then Goto L_CMD_LINE_PA_02
Let I = I - 1
Goto L_CMD_LINE_PA_01
L_CMD_LINE_PA_02:
If J <> 0 Then Let Y$ = Left$(X$, J - 1) + ".ASM": Return
Let Y$ = X$ + ".ASM"
Let X$ = X$ + ".BAS"
Return
L_LINE_2:
' ---------- LINE (x1,y1)-(x2,y2),color[,B|BF] ----------
E$ = Mid$(B$, 5, Len(B$) - 4)
E$ = Trim$(E$)
If Len(E$) = 0 Then Goto L_END_02
If Left$(E$, 1) <> "(" Then Goto L_END_02
I = 1
Gosub L_FIND_MATCH
L1 = J
I = L1 + 1
L_LINE_01:
If I > Len(E$) Then Goto L_END_02
Gosub L_CHAR_MC_2: If MC = 32 Then I = I + 1: Goto L_LINE_01
Gosub L_CHAR_MC_2: If MC <> 45 Then Goto L_END_02
I = I + 1
L_LINE_02:
If I > Len(E$) Then Goto L_END_02
Gosub L_CHAR_MC_2: If MC = 32 Then I = I + 1: Goto L_LINE_02
Gosub L_CHAR_MC_2: If MC <> 40 Then Goto L_END_02
L2 = I
I = L2
Gosub L_FIND_MATCH
L3 = J
I = L3 + 1
L_LINE_03:
If I > Len(E$) Then Goto L_END_02
Gosub L_CHAR_MC_2: If MC = 32 Then I = I + 1: Goto L_LINE_03
Gosub L_CHAR_MC_2: If MC <> 44 Then Goto L_END_02
L4 = I + 1
K = 2
L = L1 - 1
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L5 = F
K = L2 + 1
L = L3 - 1
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
L6 = F
K = L4
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
L7 = F
L8 = 0
If L7 = 0 Then Goto L_LINE_04
K$ = Mid$(E$, L7 + 1, Len(E$) - L7)
K$ = Trim$(K$)
If K$ = "B" Then L8 = 1: Goto L_LINE_04
If K$ = "BF" Then L8 = 2: Goto L_LINE_04
Goto L_END_02
L_LINE_04:
N$ = Mid$(E$, 2, L5 - 2): Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L5 + 1, L1 - L5 - 1): Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L2 + 1, L6 - L2 - 1): Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
N$ = Mid$(E$, L6 + 1, L3 - L6 - 1): Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
If L7 = 0 Then N$ = Mid$(E$, L4, Len(E$) - L4 + 1): Goto L_LINE_05
N$ = Mid$(E$, L4, L7 - L4)
Gosub L_TRIM_2
L_LINE_05:
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
Print #2, "pop si"
Print #2, "pop dx"
Print #2, "pop cx"
Print #2, "pop bx"
Print #2, "pop ax"
Print #2, "mov di,"; L8
Print #2, "REQ LN"
Print #2, "call LINEC"
Goto L_CONTINUE_SUB_S
L_BEEP:
' ---------- BEEP ----------
If B$ <> "BEEP" Then Goto L_END_02
If UBP = 0 Then Print #2, "REQ BP": Let UBP = 1
Print #2, "call BEEPC"
Goto L_CONTINUE_SUB_S
L_CIRCLE:
' ---------------- CIRCLE (x,y),r[,color][,,,aspect] --------
D$ = Mid$(B$, 7, Len(B$) - 6)
Gosub L_LTRIM
If Len(D$) = 0 Then Goto L_END_02
Gosub L_LEFT_MC: If MC <> 40 Then Goto L_END_02
E$ = D$
I = 1
Gosub L_FIND_MATCH
L1 = J
K = 2: L = L1 - 1: Gosub L_FIND_TOP_LEV_2: If F = 0 Then Goto L_END_02
N$ = Mid$(D$, 2, F - 2): Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
E$ = D$
K = 2
L = L1 - 1
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(D$, F + 1, L1 - F - 1): Gosub L_TRIM_2: If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
If L1 >= Len(D$) Then Goto L_END_02
If Asc(Mid$(D$, L1 + 1, 1)) <> 44 Then Goto L_END_02
R$ = Ltrim$(Mid$(D$, L1 + 2, Len(D$) - L1 - 1)): If Len(R$) = 0 Then Goto L_END_02
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then N$ = Trim$(R$): R$ = "": Goto L_CIRCLE_01
N$ = Left$(R$, F - 1)
Gosub L_TRIM_2
R$ = Mid$(R$, F + 1, Len(R$) - F)
L_CIRCLE_01:
If Len(N$) = 0 Then Goto L_END_02
Gosub L_COMP_NUM_SUBEX
X$ = "15"
Y$ = "256"
If Len(R$) = 0 Then Goto L_CIRCLE_02
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then X$ = Trim$(R$): R$ = "": Goto L_CIRCLE_02
X$ = Trim$(Left$(R$, F - 1))
R$ = Mid$(R$, F + 1, Len(R$) - F)
If Len(X$) = 0 Then X$ = "15"
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then If Len(Trim$(R$)) <> 0 Then Goto L_END_02 Else R$ = "": Goto L_CIRCLE_02
D$ = Left$(R$, F - 1)
Gosub L_TRIM
R$ = Mid$(R$, F + 1, Len(R$) - F)
If Len(D$) <> 0 Then Goto L_END_02
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F = 0 Then If Len(Trim$(R$)) <> 0 Then Goto L_END_02 Else R$ = "": Goto L_CIRCLE_02
D$ = Left$(R$, F - 1)
Gosub L_TRIM
R$ = Mid$(R$, F + 1, Len(R$) - F)
If Len(D$) <> 0 Then Goto L_END_02
If Len(R$) = 0 Then Goto L_CIRCLE_02
E$ = R$
K = 1
L = Len(E$)
Gosub L_FIND_TOP_LEV_2
If F <> 0 Then Goto L_END_02
Y$ = Trim$(R$): If Len(Y$) = 0 Then Y$ = "256"
L_CIRCLE_02:
N$ = X$
Gosub L_COMP_NUM_SUBEX
N$ = Y$
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_REQ_GR
Print #2, "pop si"
Print #2, "pop dx"
Print #2, "pop cx"
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Print #2, "call CIRCLEAC"
Goto L_CONTINUE_SUB_S

' ===============================================================
' DATA, READ AND CONSTANT PROCESSING
' ===============================================================

L_DATAB:
' ------------- DATAB -------------
D$ = Mid$(B$, 6, Len(B$) - 5)
V = A
Gosub L_FORMATQ
L$ = Q$
Gosub L_NEXTSYM
I$ = Q$
Print #2, "jmp DBS"; I$
Print #2, "DB"; L$; ":"
K$ = "DB "
Gosub L_EMIT_COMMA_SEP
Print #2, "DBS"; I$; ":"
Goto L_CONTINUE_SUB_S
L_DATA_DATAW:
' DATA = DATAW
D$ = Mid$(B$, 5, Len(B$) - 4)
Gosub L_COUNT_COMMA_SE
Gosub L_NEXTSYM
I$ = Q$
Print #2, "jmp DTS"; I$
If DA = 0 Then Print #2, "DATA_BEGIN:" Else V = DA: Gosub L_FORMATQ: Print #2, "DTN"; Q$; ":"
Gosub L_NEXTSYM
DA = V
Print #2, "DW DTN"; Q$
Print #2, "DW "; C
K$ = "DW "
Gosub L_EMIT_COMMA_SEP
Print #2, "DTS"; I$; ":"
Goto L_CONTINUE_SUB_S
L_READ_NUM:
' READ numeric
D$ = Mid$(B$, 5, Len(B$) - 4)
Gosub L_TRIM
E$ = D$
D = 1
Gosub L_READID
If Len(L$) = 0 Then Goto L_END_02
If H <> 0 Then Goto L_END_07
If D <= Len(E$) Then Goto L_END_02
If UDA = 0 Then Print #2, "REQ DA": UDA = 1
Print #2, "call READW"
Print #2, "DN "; L$
Print #2, "mov [N_"; L$; "],ax"
Goto L_CONTINUE_SUB_S
L_REST:
' RESTORE
D$ = Mid$(B$, 8, Len(B$) - 7)
Gosub L_TRIM
If Len(D$) <> 0 Then Goto L_END_02
If UDA = 0 Then Print #2, "REQ DA": UDA = 1
Print #2, "mov WORD [DATREC],DATA_BEGIN"
Print #2, "mov WORD [DATCNT],0"
Goto L_CONTINUE_SUB_S
L_CALLDATA_LINE:
' CALLDATA line
D$ = Mid$(B$, 9, Len(B$) - 8)
Gosub L_TRIM
I = 1
L_CALLDATA_LI_01:
If I > Len(D$) Then Goto L_CALLDATA_LI_02
MC = Asc(Mid$(D$, I, 1)): If MC < 48 Or MC > 57 Then Goto L_END_04
I = I + 1
Goto L_CALLDATA_LI_01
L_CALLDATA_LI_02:
E = Val(D$): If E < 1 Or E > 32767 Then Goto L_END_04
V = E
Gosub L_FORMATQ
Print #2, "call DB"; Q$
Goto L_CONTINUE_SUB_S
L_COUNT_COMMA_SE:
' count comma-separated values in D$
Gosub L_TRIM: If Len(D$) = 0 Then Goto L_END_02
C = 1
I = 1
L_COUNT_COMMA_01:
If I > Len(D$) Then Return
If Asc(Mid$(D$, I, 1)) = 44 Then C = C + 1
I = I + 1
Goto L_COUNT_COMMA_01
L_EMIT_COMMA_SEP:
' emit comma-separated literal list in D$ with prefix K$
L_EMIT_COMMA_01:
Gosub L_TRIM
If Len(D$) = 0 Then Return
I = Instr(D$, ",")
If I = 0 Then N$ = D$: D$ = "": Goto L_EMIT_COMMA_02
N$ = Left$(D$, I - 1)
D$ = Mid$(D$, I + 1, Len(D$) - I)
L_EMIT_COMMA_02:
Gosub L_CONSTNUM: If COK = 0 Then Goto L_END_02
Print #2, K$; CVAL
Goto L_EMIT_COMMA_01
L_DIM_3:
' ---- DIM X$(COUNT) AS STRING * MAXLEN ----
E = 0: I = Instr(D$, "$("): If I = 0 Then Return
SAVEDID$ = Left$(D$, I - 1): If Len(SAVEDID$) = 0 Then Goto L_END_02
E$ = D$
D = I + 1
Gosub L_FIND_MATCH
N$ = Mid$(E$, D + 1, J - D - 1)
X$ = Ltrim$(Mid$(E$, J + 1, Len(E$) - J))
If Left$(X$, 12) <> "AS STRING * " Then Goto L_END_02
XC$(41) = Mid$(X$, 13, Len(X$) - 12)
Gosub L_COMP_NUM_SUBEX
N$ = XC$(41)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_XA
Print #2, "call XAALLOC"
Gosub L_NEXTSYM
X$ = Q$
Gosub L_NEXTSYM
Y$ = Q$
Print #2, "or ax,ax"
Print #2, "je XAR_DONE_"; Y$
Print #2, "push ax"
Print #2, "DN XA_"; SAVEDID$
Print #2, "mov ax,[N_XA_"; SAVEDID$; "]"
Print #2, "or ax,ax"
Print #2, "je XAR_STORE_"; X$
Print #2, "call XAFREE"
Print #2, "XAR_STORE_"; X$; ":"
Print #2, "pop ax"
Print #2, "mov [N_XA_"; SAVEDID$; "],ax"
Print #2, "XAR_DONE_"; Y$; ":"
E = 1
Return
L_EMIT_XA_HANDLE:
' ---- EMIT XA HANDLE AND INDEX ON STACK ----
Print #2, "DN XA_"; SAVEDID$
Print #2, "mov ax,[N_XA_"; SAVEDID$; "]"
Gosub L_EMIT_PUSHAX
Goto L_COMP_NUM_SUBEX
L_COMP:
' ---- COMPILE X$(INDEX) TO SI ----
SAVEDID$ = L$
I = D
Gosub L_FIND_MATCH
CLOSEPAR = J
N$ = Mid$(E$, D + 1, CLOSEPAR - D - 1)
Gosub L_EMIT_XA_HANDLE
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_DI_TMP
Gosub L_EMIT_REQ_XA
Print #2, "call XAGET"
Gosub L_EMIT_SI_TMP
D = CLOSEPAR + 1
Return
L_LET_3:
' ---- LET X$(INDEX)=STRINGEXPR ----
E = 0: I = Instr(D$, "$("): If I = 0 Then Return
Gosub L_RIGHT_MC: If MC <> 41 Then Goto L_END_02
SAVEDID$ = Left$(D$, I - 1): If Len(SAVEDID$) = 0 Then Goto L_END_02
N$ = Mid$(D$, I + 2, Len(D$) - I - 2)
XC$(41) = E$
Gosub L_EMIT_XA_HANDLE
E$ = XC$(41)
Gosub L_STR_EXPR_PARSE
Gosub L_EMIT_POPBX
Gosub L_EMIT_POPAX
Gosub L_EMIT_REQ_XA
Print #2, "call XASET"
E = 1
Return
L_COMP_HEX_OCT:
' ---- compile HEX$/OCT$/BIN$(num) to SI ----
E$ = X$
I = 5
Gosub L_FIND_MATCH
N$ = Mid$(E$, 6, J - 6)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Gosub L_EMIT_DI_TMP2
SAVEDID$ = Left$(X$, 1)
Select Case SAVEDID$
Case "H"
    SAVEDID$ = "HX"
    D$ = "HEXS"
Case "O"
    SAVEDID$ = "OC"
    D$ = "OCTS"
Case "B"
    SAVEDID$ = "BN"
    D$ = "BINS"
End Select
Gosub L_EMIT_REQ_ST
Print #2, "REQ "; SAVEDID$
Print #2, "call "; D$
Gosub L_EMIT_SI_TMP2
Goto L_POP_STRFUNCT
L_COMP_SPACE:
' ---- compile SPACE$(num) to SI ----
E$ = X$
I = 7
Gosub L_FIND_MATCH
N$ = Mid$(E$, 8, J - 8)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "mov bl,32"
Goto L_COMP_STR_01
L_COMP_STR_2:
' ---- compile STRING$(count,charcode) to SI ----
E$ = X$
I = 8
Gosub L_FIND_MATCH
K = 9
L = J - 1
Gosub L_FIND_TOP_LEV_2
If F = 0 Then Goto L_END_02
N$ = Mid$(E$, 9, F - 9)
Gosub L_COMP_NUM_SUBEX
K = 9
L = J - 1
Gosub L_FIND_TOP_LEV_2
N$ = Mid$(E$, F + 1, J - F - 1)
Gosub L_COMP_NUM_SUBEX
Gosub L_EMIT_POPAX
Print #2, "mov bl,al"
Gosub L_EMIT_POPAX
L_COMP_STR_01:
Gosub L_EMIT_DI_TMP2
Gosub L_EMIT_REQ_ST
Print #2, "REQ SR"
Print #2, "call STRINGS"
Gosub L_EMIT_SI_TMP2
Goto L_POP_STRFUNCT
L_CONSTNUM:
' ---- CONSTNUM: try constant numeric expression in N$ ----
' INPUT N$, OUTPUT COK=1 AND CVAL=result IF SAFE, ELSE COK=0
COK = 0
CVAL = 0
CD = 1
CFLEV = 0
Gosub L_CONSTNUM_SKIP
If CD > Len(N$) Then Return
Gosub L_CONSTNUM_EXPR
If COK = 0 Then Return
Gosub L_CONSTNUM_SKIP
If CD > Len(N$) Then Return
COK = 0
Return
L_CONSTNUM_SKIP:
' ---- CONSTNUM SKIP SPACES ----
If CD > Len(N$) Then Return
Gosub L_CHAR_CD_CMC
If CMC = 32 Or CMC = 9 Then CD = CD + 1: Goto L_CONSTNUM_SKIP
Return
L_CONSTNUM_EXPR:
' ---- CONSTNUM EXPR: + - ----
Gosub L_CONSTNUM_TERM
If COK = 0 Then Return
L_CONSTNUM_EX_01:
Gosub L_CONSTNUM_SKIP
If CD > Len(N$) Then Return
Gosub L_CHAR_CD_CMC
If CMC = 43 Or CMC = 45 Then Goto L_CONSTNUM_EX_02
Return
L_CONSTNUM_EX_02:
CFLEV = CFLEV + 1
If CFLEV > 8 Then COK = 0: Return
CF(CFLEV) = CVAL
CO(CFLEV) = CMC
CD = CD + 1
Gosub L_CONSTNUM_TERM
If COK = 0 Then CFLEV = CFLEV - 1: Return
CLEFT = CF(CFLEV)
COP = CO(CFLEV)
CFLEV = CFLEV - 1
If COP = 43 Then Goto L_CONSTNUM_EX_03
If CLEFT >= 0 And CVAL < 0 Then If CLEFT > 32767 + CVAL Then COK = 0: Return
If CLEFT < 0 And CVAL > 0 Then If CLEFT < -32768 + CVAL Then COK = 0: Return
CVAL = CLEFT - CVAL
Goto L_CONSTNUM_EX_04
L_CONSTNUM_EX_03:
If CLEFT > 0 And CVAL > 0 Then If CLEFT > 32767 - CVAL Then COK = 0: Return
If CLEFT < 0 And CVAL < 0 Then If CLEFT < -32768 - CVAL Then COK = 0: Return
CVAL = CLEFT + CVAL
L_CONSTNUM_EX_04:
Goto L_CONSTNUM_EX_01
L_CONSTNUM_TERM:
' ---- CONSTNUM TERM: * / \ ----
Gosub L_CONSTNUM_FACTO
If COK = 0 Then Return
L_CONSTNUM_TE_01:
Gosub L_CONSTNUM_SKIP
If CD > Len(N$) Then Return
Gosub L_CHAR_CD_CMC
If CMC = 42 Or CMC = 47 Or CMC = 92 Then Goto L_CONSTNUM_TE_02
Return
L_CONSTNUM_TE_02:
CFLEV = CFLEV + 1
If CFLEV > 8 Then COK = 0: Return
CF(CFLEV) = CVAL
CO(CFLEV) = CMC
CD = CD + 1
Gosub L_CONSTNUM_FACTO
If COK = 0 Then CFLEV = CFLEV - 1: Return
CLEFT = CF(CFLEV)
COP = CO(CFLEV)
CFLEV = CFLEV - 1
If COP <> 42 Then Goto L_CONSTNUM_TE_03
If CLEFT < -181 Or CLEFT > 181 Then COK = 0: Return
If CVAL < -181 Or CVAL > 181 Then COK = 0: Return
CVAL = CLEFT * CVAL
Goto L_CONSTNUM_TE_05
L_CONSTNUM_TE_03:
If CVAL <> 0 Then Goto L_CONSTNUM_TE_04
COK = 0
Return
L_CONSTNUM_TE_04:
If CLEFT < 0 Or CVAL < 0 Then COK = 0: Return
CVAL = CLEFT \ CVAL
L_CONSTNUM_TE_05:
Goto L_CONSTNUM_TE_01
L_CONSTNUM_FACTO:
' ---- CONSTNUM FACTOR ----
Gosub L_CONSTNUM_SKIP
If CD > Len(N$) Then COK = 0: Return
Gosub L_CHAR_CD_CMC
If CMC = 43 Then CD = CD + 1: Goto L_CONSTNUM_FACTO
If CMC <> 45 Then Goto L_CONSTNUM_FA_01
CD = CD + 1
Gosub L_CONSTNUM_FACTO
If COK = 0 Then Return
CVAL = -CVAL
Return
L_CONSTNUM_FA_01:
If CMC <> 40 Then Goto L_CONSTNUM_FA_02
CD = CD + 1
Gosub L_CONSTNUM_EXPR
If COK = 0 Then Return
Gosub L_CONSTNUM_SKIP
If CD > Len(N$) Then COK = 0: Return
If Asc(Mid$(N$, CD, 1)) <> 41 Then COK = 0: Return
CD = CD + 1
Return
L_CONSTNUM_FA_02:
If Mid$(N$, CD, 4) = "TRUE" Then COK = 1: CVAL = -1: CD = CD + 4: Return
If Mid$(N$, CD, 5) = "FALSE" Then COK = 1: CVAL = 0: CD = CD + 5: Return
If CMC = 38 Then Goto L_CONSTNUM_HEX_N
If CMC < 48 Or CMC > 57 Then COK = 0: Return
' ---- CONSTNUM DECIMAL NUMBER ----
COK = 1
CVAL = 0
L_CONSTNUM_FA_03:
If CD > Len(N$) Then Return
Gosub L_CHAR_CD_CMC
If CMC < 48 Or CMC > 57 Then Return
CDIG = CMC - 48
If CVAL > 3276 Then Goto L_CONSTNUM_FA_04
If CVAL = 3276 Then If CDIG > 7 Then Goto L_CONSTNUM_FA_04
CVAL = CVAL * 10 + CDIG
CD = CD + 1
Goto L_CONSTNUM_FA_03
L_CONSTNUM_FA_04:
COK = 0
Return
L_CONSTNUM_HEX_N:
' ---- CONSTNUM HEX NUMBER &H0000..&H7FFF ----
If CD + 1 > Len(N$) Then COK = 0: Return
If Mid$(N$, CD + 1, 1) <> "H" Then COK = 0: Return
COK = 1
CD = CD + 2
CVAL = 0
CHEX = 0
L_CONSTNUM_HE_01:
If CD > Len(N$) Then Goto L_CONSTNUM_HE_03
Gosub L_CHAR_CD_CMC
If CMC >= 48 And CMC <= 57 Then CDIG = CMC - 48: Goto L_CONSTNUM_HE_02
If CMC < 65 Or CMC > 70 Then Goto L_CONSTNUM_HE_03
CDIG = CMC - 55
L_CONSTNUM_HE_02:
If CHEX >= 4 Then Goto L_CONSTNUM_HE_04
If CVAL > 2047 Then Goto L_CONSTNUM_HE_04
CVAL = CVAL * 16 + CDIG
CHEX = CHEX + 1
CD = CD + 1
If CVAL > 32767 Then Goto L_CONSTNUM_HE_04
Goto L_CONSTNUM_HE_01
L_CONSTNUM_HE_03:
If CHEX = 0 Then COK = 0: Return
Return
L_CONSTNUM_HE_04:
COK = 0
Return
L_EMIT_LIT_RAWCR:
' ---- EMIT_LITERAL_RAWCRLF2 ----
Gosub L_NEXTSYM
Print #2, "jmp PLX_"; Q$
Print #2, "PLD_"; Q$; ":"
Gosub L_EMITDBL
Print #2, "PLX_"; Q$; ":"
Gosub L_EMIT_REQ_PR
Gosub L_EMIT_REQ_FI
Print #2, "mov si,OFFSET PLD_"; Q$
Print #2, "call WRITE_RAWCRLF2"
Return

' ===============================================================
' INLINE ASSEMBLER AND DO LOOP SUPPORT
' ===============================================================

L_INLINE_ASSEMBL:
' ---------- INLINE ASSEMBLER BLOCK: [ ... ] ----------
If DISPMODE <> 0 Then Goto L_END_02
L_INLINE_ASSE_01:
If Eof(1) <> 0 Then Goto L_END_02
Line Input #1, A$
If SRCMODE <> 0 Then R$ = A$: Goto L_INLINE_ASSE_02
Gosub L_FLSEP
If I = 0 Then Goto L_END_04
D$ = Left$(A$, I - 1)
J = 1
L_INLINE_ASSE_03:
If J > Len(D$) Then Goto L_INLINE_ASSE_04
MC = Asc(Mid$(D$, J, 1))
If MC < 48 Then Goto L_END_04
If MC > 57 Then Goto L_END_04
J = J + 1
Goto L_INLINE_ASSE_03
L_INLINE_ASSE_04:
E = Val(D$)
If E < 1 Then Goto L_END_04
If E > 32767 Then Goto L_END_04
If E <= LNO Then Goto L_END_04
LNO = E
A = E
R$ = Mid$(A$, I + 1, Len(A$) - I)
L_INLINE_ASSE_02:
R$ = Trim$(R$)
If Len(R$) = 0 Then Goto L_INLINE_ASSE_01
If R$ = "]" Then Goto L_CONTINUE_SUB_S
Print #2, R$
Goto L_INLINE_ASSE_01
L_DO_BEGIN:
' ---------- DO BEGIN ----------
If DISPMODE <> 0 Then Goto L_END_02
DOKIND = 0
If B$ = "DO" Then N$ = "": Goto L_DO_BEGIN_01
If Left$(B$, 9) = "DO WHILE " Then DOKIND = 1: N$ = Mid$(B$, 10, Len(B$) - 9): Goto L_DO_BEGIN_00
If Left$(B$, 9) <> "DO UNTIL " Then Goto L_END_02
DOKIND = 2
N$ = Mid$(B$, 10, Len(B$) - 9)
L_DO_BEGIN_00:
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
L_DO_BEGIN_01:
B = B + 1
If B > 4 Then Goto L_END_03
Gosub L_NEXTSYM
LL(B) = V
Gosub L_NEXTSYM
LS(B) = V
LT(B) = 2
V = LL(B)
Gosub L_FORMATQ
Print #2, "DOL_"; Q$; ":"
If Len(N$) = 0 Then Goto L_CONTINUE_SUB_S
If DOKIND = 2 Then Goto L_DO_UNTIL
V = LL(B)
Gosub L_FORMATQ
I$ = Q$
FALSELBL = LS(B)
L$ = N$
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
Goto L_CONTINUE_SUB_S
L_DO_UNTIL:
Gosub L_NEXTSYM
I$ = Q$
Gosub L_NEXTSYM
FALSELBL = V
L$ = N$
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
V = LS(B)
Gosub L_FORMATQ
Print #2, "jmp SKP_"; Q$
V = FALSELBL
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
Goto L_CONTINUE_SUB_S
L_LOOP:
' ---------- LOOP ----------
If DISPMODE <> 0 Then Goto L_END_02
DOKIND = 0
If B$ = "LOOP" Then N$ = "": Goto L_LOOP_01
If Left$(B$, 11) = "LOOP UNTIL " Then DOKIND = 1: N$ = Mid$(B$, 12, Len(B$) - 11): Goto L_LOOP_00
If Left$(B$, 11) <> "LOOP WHILE " Then Goto L_END_02
DOKIND = 2
N$ = Mid$(B$, 12, Len(B$) - 11)
L_LOOP_00:
Gosub L_TRIM_2
If Len(N$) = 0 Then Goto L_END_02
L_LOOP_01:
If B = 0 Then Goto L_END_03
If LT(B) <> 2 Then Goto L_END_03
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
If Len(N$) = 0 Then V = LL(B): Gosub L_FORMATQ: Print #2, "jmp DOL_"; Q$: Goto L_LOOP_02
If DOKIND = 2 Then Goto L_LOOP_WHILE
Gosub L_NEXTSYM
FALSELBL = V
V = LS(B)
Gosub L_FORMATQ
I$ = Q$
L$ = N$
Gosub L_COMP_BOOL_EXPR
V = FALSELBL
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
V = LL(B)
Gosub L_FORMATQ
Print #2, "jmp DOL_"; Q$
V = LS(B)
Gosub L_FORMATQ
Gosub L_EMIT_LBL_THN
Goto L_LOOP_02
L_LOOP_WHILE:
Gosub L_NEXTSYM
I$ = Q$
FALSELBL = LS(B)
L$ = N$
Gosub L_COMP_BOOL_EXPR
Gosub L_EMIT_LBL_THN
V = LL(B)
Gosub L_FORMATQ
Print #2, "jmp DOL_"; Q$
L_LOOP_02:
V = LS(B)
Gosub L_FORMATQ
Gosub L_EMIT_LBL_SKP
B = B - 1
Goto L_CONTINUE_SUB_S
L_EXIT_DO:
' ---------- EXIT DO ----------
If B = 0 Then Goto L_END_03
If LT(B) <> 2 Then Goto L_END_03
V = LS(B)
Gosub L_FORMATQ
Gosub L_EMIT_REQ_BK
Print #2, "call BRKCHK"
Print #2, "jmp SKP_"; Q$
Goto L_CONTINUE_SUB_S

' ===============================================================
' SOURCE STATEMENT SPLITTER
' ===============================================================

L_FIND_STMT:
' ---- FIND_NEXT_STMT: split R$ from P into B$, Q/N and I$ rest ----
Q = P
S = 0
L_FIND_STMT_01:
If Q > Len(R$) Then Goto L_FIND_STMT_04
MC = Asc(Mid$(R$, Q, 1))
If MC <> 34 Then Goto L_FIND_STMT_02
If S = 0 Then S = 1: Goto L_FIND_STMT_03
S = 0
Goto L_FIND_STMT_03
L_FIND_STMT_02:
If MC <> 58 Then Goto L_FIND_STMT_03
If S <> 0 Then Goto L_FIND_STMT_03
I$ = Mid$(R$, P, Q - P)
I$ = Ltrim$(I$)
If Left$(I$, 3) = "IF " Then Goto L_FIND_STMT_05
If Left$(I$, 3) <> "IF(" Then Goto L_FIND_STMT_06
L_FIND_STMT_05:
If Instr(I$, " THEN ") <> 0 Then Q = Q + 1: Goto L_FIND_STMT_01
If Right$(I$, 5) = " THEN" Then Q = Q + 1: Goto L_FIND_STMT_01
L_FIND_STMT_06:
B$ = Mid$(R$, P, Q - P)
N = 1
I$ = Mid$(R$, Q + 1, Len(R$) - Q)
Return
L_FIND_STMT_03:
Q = Q + 1
Goto L_FIND_STMT_01
L_FIND_STMT_04:
If P > Len(R$) Then B$ = "" Else B$ = Mid$(R$, P, Len(R$) - P + 1)
N = 0
I$ = ""
Return

L_ERASE:
' ---------- ERASE ONE NUMERIC OR STRING ARRAY ----------
D$ = Mid$(B$, 7, Len(B$) - 6)
D$ = Trim$(D$)
If Len(D$) = 0 Then Goto L_END_02
E$ = D$
D = 1
Gosub L_READID
If Len(L$) = 0 Then Goto L_END_02
If D <= Len(E$) Then Goto L_END_02
If H <> 0 Then Goto L_ERASE_STR
Z$ = L$
Print #2, "DS "; Z$
Print #2, "mov di,OFFSET S_"; Z$
Gosub L_EMIT_REQ_AR
Print #2, "call ARRFREE_DESC"
Goto L_CONTINUE_SUB_S
L_ERASE_STR:
' ---------- ERASE ONE DYNAMIC STRING ARRAY ----------
SAVEDID$ = L$
Gosub L_NEXTSYM
L$ = Q$
Gosub L_EMIT_REQ_XA
Print #2, "DN XA_"; SAVEDID$
Print #2, "mov ax,[N_XA_"; SAVEDID$; "]"
Print #2, "or ax,ax"
Print #2, "je XAE_"; L$
Print #2, "call XAFREE"
Print #2, "mov WORD [N_XA_"; SAVEDID$; "],0"
Print #2, "XAE_"; L$; ":"
Goto L_CONTINUE_SUB_S
