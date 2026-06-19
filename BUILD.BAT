@echo off
echo COMPILING %1...
timeit bascomp %1
IF ERRORLEVEL 1 GOTO BASCOMP_ERROR
echo NOW PACKING AND OPTIMIZING ASM CODE...
timeit asmpack %1.asm %1.as2
echo PACKING DONE.
echo NOW STARTING ASSEMBLY...
timeit basm %1
echo DONE.
dir %1.com
del %1.pre
del %1.asm
del %1.as2
GOTO END

:BASCOMP_ERROR
ECHO.
ECHO COMPILE ERROR OCCURRED. BATCH PROCESSING STOPPED.
GOTO END

:END