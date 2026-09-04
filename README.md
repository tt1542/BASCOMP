# BASCOMP

```basic
620 PRINT "__________               _________                        "
630 PRINT "\______   \_____    _____\_   ___ \  ____   _____ ______  "
640 PRINT " |    |  _/\__  \  /  ___/    \  \/ /  _ \ /     \\____ \ "
650 PRINT " |    |   \ / __ \_\___ \\ 3.0 \___(  <_> )  Y Y  \  |_> >"
660 PRINT " |______  /(____  /____  >\______  /\____/|__|_|  /   __/ "
670 PRINT "        \/      \/     \/        \/             \/|__|    "
```

BASCOMP is a small, one-segment, single-pass BASIC compiler for DOS-oriented 16-bit assembly output. BASCOMP and its toolchain are optimized to compile BASIC input files as small COM executables for 8086/8088 systems.

BASCOMP translates a BASIC source file into an .ASM file. The generated assembly can then be post-processed with ASMPACK, if desired, and assembled with NASM or the supplied BASM special assembler into machine code. BASCOMP exclusively targets COM files.

BASCOMP is designed for compact BASIC programs with classic line-oriented syntax. It also supports a QB-style source mode with automatic internal line numbering and symbolic labels.

The compiler will generate NASM-compatible assembly code. The code can then be optimizes using the ASMPACK tool, reducing output code size by about 30%. The supplied BASM special assembler can be used for natively compiling for the earliest x86 compatible CPUs.

The development was assisted by a coding AI. 

Further information can be found in the Wiki: https://github.com/tt1542/BASCOMP/wiki
