@echo off
echo BACKUP: COPYING BASCOMP TO BASCOMPN
copy bascomp.com bascompn.com
echo TRYING TO BUILD BASCOMP FROM NATIVE TO NATIVE
timeit bascomp bascomp
IF ERRORLEVEL 1 GOTO BASCOMP_ERROR
echo NOW PACKING AND OPTIMIZING ASM CODE...
timeit asmpack bascomp.asm bascomp.as2
echo PACKING DONE.
echo NOW STARTING ASSEMBLY...
timeit basm bascomp /R -DBCBANNER
echo DONE.
dir bascomp.com
GOTO END

:BASCOMP_ERROR
ECHO.
ECHO COMPILE ERROR OCCURRED. BATCH PROCESSING STOPPED.
GOTO END

:END