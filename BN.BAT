@echo BACKUP: COPYING BASCOMP TO BASCOMPN
@copy bascomp.com bascompn.com
@echo TRYING TO BUILD BASCOMP FROM NATIVE TO NATIVE
@timeit bascomp bascomp
@echo NOW PACKING AND OPTIMIZING ASM CODE...
@timeit asmpack bascomp.asm bascomp.as2
@echo PACKING DONE.
@echo NOW STARTING ASSEMBLY...
@timeit basm bascomp /R -DBCBANNER
@echo DONE.
@dir bascomp.com
