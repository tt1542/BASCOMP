C$ = COMMAND$
L = LEN(C$)
I = 1
' Skip leading spaces
SKIPLEAD:
IF I > L THEN GOTO USAGE
X$ = MID$(C$, I, 1)
IF X$ <> " " THEN GOTO HAVEPROG
I = I + 1
GOTO SKIPLEAD
' Read program name
HAVEPROG:
P$ = ""
HASDOT = 0
COPYPROG:
IF I > L THEN GOTO ENDPROG
X$ = MID$(C$, I, 1)
IF X$ = " " THEN GOTO ENDPROG
P$ = P$ + X$
' Detect extension only for the last path component
IF X$ = "." THEN HASDOT = 1
IF X$ = ":" THEN HASDOT = 0
IF X$ = "\" THEN HASDOT = 0
IF X$ = "/" THEN HASDOT = 0
I = I + 1
GOTO COPYPROG
' Append .COM if no extension was detected
ENDPROG:
IF HASDOT = 0 THEN P$ = P$ + ".COM"
' Skip spaces between program name and remaining arguments
SKIPREST:
IF I > L THEN GOTO NOARGS
X$ = MID$(C$, I, 1)
IF X$ <> " " THEN GOTO HAVEARGS
I = I + 1
GOTO SKIPREST
NOARGS:
A$ = ""
GOTO RUNPROG
' Copy remaining arguments
HAVEARGS:
A$ = ""
COPYARGS:
IF I > L THEN GOTO RUNPROG
X$ = MID$(C$, I, 1)
A$ = A$ + X$
I = I + 1
GOTO COPYARGS
' Measure time and start child program
RUNPROG:
T = TIMER()
E = EXEC(P$, A$)
IF E <> 0 THEN GOTO EXECERR
D = TIMER() - T
PRINT "TIME: "; D; " SECONDS"
END
USAGE:
PRINT "USAGE: TIMEIT PROGRAM [ARGS]"
END
EXECERR:
PRINT "ERROR: EXEC FAILED. RETURN VALUE="; E
END