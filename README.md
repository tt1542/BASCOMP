# BASCOMP

BASCOMP is a small, one-segment, single-pass BASIC compiler for DOS-oriented 16-bit assembly output. BASCOMP and its toolchain are optimized to compile BASIC input files as small COM executables for 8086/8088 systems.

BASCOMP translates a BASIC source file into an .ASM file. The generated assembly can then be post-processed with ASMPACK, if desired, and assembled with NASM or the supplied BASM special assembler into machine code. BASCOMP exclusively targets COM files.

BASCOMP is designed for compact BASIC programs with classic line-oriented syntax. It also supports a QB-style source mode with automatic internal line numbering and symbolic labels.

The compiler will generate NASM-compatible assembly code. The code can then be optimizes using the ASMPACK tool, reducing output code size by about 30%. Since NASM will possibly generate near jumps that are not fully 8086 compatible, the supplied BASM special assembler can be used for natively compiling for the earliest x86 compatible cpus.

The development was assisted by a coding AI. 

## Files Required

BASCOMP expects these support files to be present in the working directory:

- HEADER.ASM  
  Assembly header included at the beginning of the generated output.
- RUNTIME.ASM  
  Runtime support code included at the end of the generated output.

Optional helper tools and demos in this project include utilities such as ASMPACK, CONV2QB, RENUMB, FULLTEST, PI, VIDDEM, LZSENC, and LZSDEC. They are not required to compile a BASIC program with BASCOMP itself.

## How It Works

1. Start BASCOMP and pass the source base name either:
   - on the command line, or
   - interactively when prompted with FILE?.
2. BASCOMP opens <name>.BAS and creates <name>.ASM.
3. During compilation, BASCOMP:
   - reads the BASIC source line by line,
   - detects classic line-numbered mode or QB-style source mode,
   - parses statements and expressions,
   - translates them into assembly,
   - emits runtime capability requests only when needed,
   - appends RUNTIME.ASM, and
   - writes the final assembly source.

## Source Modes

BASCOMP 2.0 supports two source code style types.

### Classic Line-Numbered BASIC

```basic
10 LET A = 1
20 PRINT A
30 END
```

### QB-Style Source Mode

In QB-style source mode, ordinary lines without line numbers are accepted. BASCOMP assigns internal line numbers automatically and supports symbolic labels of the form Label:.

```basic
Start:
PRINT "HELLO"
GOTO Start
```

## Version 2.0 Highlights

Version 2.0 keeps the compact DOS-oriented design and extends the language/runtime set used by the test suite and demos:

- DEF SEG, PEEK(), and POKE for simple memory access.
- END FOR as an explicit FOR-loop terminator form in addition to NEXT.
- . as shorthand for program termination (END / STOP).
- Continued support for QB-style labels and automatic internal line numbering.
- Expanded runtime support for date/time, keyboard, EXEC, CPUID, external string arrays, and larger numeric arrays.
- Improved string-expression context handling using the expanded internal string context storage.

## Supported Statements

BASCOMP 2.0 supports the following statements and statement forms:

- REM and apostrophe comments (' comment)
- LET and implicit assignment without LET
- INPUT var
- INPUT "prompt", var
- INPUT var$
- INPUT "prompt", var$
- ! var as shorthand for INPUT var
- LINE INPUT #channel, var$
- PRINT
- ? as shorthand for PRINT
- PRINT #channel, ...
- IF ... THEN ...
- IF ... THEN ... ELSE ...
- multi-line IF ... THEN, ELSEIF ... THEN, ELSE, END IF
- GOTO
- GOSUB
- RETURN
- FOR ... TO ... [STEP ...] / NEXT, END FOR
- WHILE ... / WEND
- DIM
- OPEN ... FOR INPUT AS #channel
- OPEN ... FOR OUTPUT AS #channel
- CLOSE #channel
- KILL
- GET #channel, [position,] variable
- PUT #channel, [position,] variable
- CLS
- LOCATE row, column
- COLOR foreground, background
- DEF SEG
- POKE address, value
- SELECT CASE, CASE, CASE ELSE, END SELECT
- RANDOMIZE
- RANDOMIZE TIMER / numeric-expression
- XSET handle, index, string-expression
- XFREE handle
- END / STOP / . as shorthand

## Supported Control Structures

### IF / ELSE

BASCOMP supports single-line and multi-line IF forms.

Single-line form:

```basic
IF A > 10 THEN PRINT "HIGH" ELSE PRINT "LOW"
```

Multi-line form:

```basic
IF A > 10 THEN
  PRINT "HIGH"
ELSEIF A = 10 THEN
  PRINT "TEN"
ELSE
  PRINT "LOW"
END IF
```

Boolean IF expressions support AND, OR, and NOT in supported comparison contexts.

### SELECT CASE

SELECT CASE supports numeric selection logic:

```basic
SELECT CASE A
  CASE 1
    PRINT "ONE"
  CASE 2
    PRINT "TWO"
  CASE ELSE
    PRINT "OTHER"
END SELECT
```

### FOR / NEXT / END FOR

Counted loops are supported, including nested loops and optional STEP values.

```basic
FOR I = 1 TO 10 STEP 2
  PRINT I
NEXT I
```

END FOR is also recognized as an explicit loop terminator form.

### WHILE / WEND

```basic
WHILE A < 10
  A = A + 1
WEND
```

### Subroutines

Subroutines are supported through GOSUB and RETURN.

## Supported Data Types

### Numeric Variables

Numeric variables store signed 16-bit integer-style values.

### String Variables

String identifiers end with $ and use counted string representation in the runtime.

### Indexed Numeric Arrays

DIM creates indexed numeric arrays using syntax such as A(I). Small arrays are stored internally; larger arrays can be backed by external DOS memory through the runtime array support.

```basic
DIM A(10)
LET A(1) = 5
LET X = A(1)
```

### External String Arrays

External string arrays are available through:

- XALLOC(count)
- XALLOC(count, maxLength)
- XSET handle, index, string-expression
- XGET$(handle, index)
- XFREE handle

## Supported Expressions

### Numeric Expressions

Numeric expressions support:

- decimal constants and variables
- hexadecimal constants with &H...
- numeric array elements such as A(I)
- parentheses
- unary + and unary -
- +, -, *, /, \
- MOD
- XOR
- AND
- OR
- exponentiation with ^
- numeric function calls

### String Expressions

String expressions support:

- string variables
- string literals
- string concatenation with +
- string function calls
- DATE$, TIME$, INKEY$, and INPUT$

BASCOMP 2.0 continues the expanded internal string-expression handling introduced before version 2.0. The compiler uses a larger internal string context stack and additional temporary string buffers for nested string functions and concatenations.

## Supported Comparisons

The following comparison operators are supported in IF expressions: =, <>, <, >, <=, >=.

Comparisons work for both numeric values and supported string expressions, depending on context.

## Supported Functions

### Numeric and Conversion Functions

- LEN(string)  
  Returns the length of a string.
- VAL(string)  
  Converts a string to a numeric value.
- ASC(string)  
  Returns the character code of the first character.
- EOF(channel)  
  Returns the end-of-file state for a file channel.
- EXIST(string)  
  Tests whether a file exists.
- INSTR(string, pattern)  
  Searches for a substring and returns its position.
- INSTR(start, string, pattern)  
  Searches for a substring starting at a specific position.
- ABS(number)  
  Returns the absolute value.
- SGN(number)  
  Returns -1, 0, or 1 depending on the sign of the value.
- RND(number)  
  Returns a pseudo-random number in the supported runtime range.
- INT(number)  
  Returns the integer value.
- SQR(number)  
  Returns the integer square root.
- MIN(a, b)  
  Returns the smaller value.
- MAX(a, b)  
  Returns the larger value.
- TIMER()  
  Returns the number of seconds since midnight modulo 65536.
- EXEC(program$, args$)  
  Starts a DOS child program and returns 0 on success or a DOS error code.
- CPUID()  
  Detects the CPU class and returns the runtime CPU identifier.
- PEEK(address)  
  Reads a byte from the active DEF SEG segment.
- XALLOC(count) / XALLOC(count, maxLength)  
  Allocates an external string array and returns a handle.

### String-Producing Functions

- CHR$(number)  
  Builds a one-character string from a character code.
- LEFT$(string, count)  
  Returns the left part of a string.
- MID$(string, start, count)  
  Returns a substring.
- RIGHT$(string, count)  
  Returns the right part of a string.
- LTRIM$(string)  
  Removes leading spaces.
- RTRIM$(string)  
  Removes trailing spaces.
- TRIM$(string)  
  Removes leading and trailing spaces.
- UCASE$(string)  
  Converts ASCII lowercase letters a to z to uppercase.
- STR$(number)  
  Converts a numeric value to a string.
- XGET$(handle, index)  
  Reads a string from an external string array.
- DATE$  
  Returns the DOS date in mm-dd-yyyy format.
- TIME$  
  Returns the DOS time in hh:mm:ss format.
- INKEY$  
  Returns a non-blocking keyboard input string.
- INPUT$  
  Reads a string from standard input.

## File I/O

Text file I/O is supported through:

- OPEN
- CLOSE
- PRINT #
- LINE INPUT #

Binary file I/O is supported through:

- GET
- PUT

File channels 1 to 9 are supported.

OPEN supports:

- FOR INPUT
- FOR OUTPUT

KILL deletes a file. EXIST() checks whether a file is present.

The runtime retains buffered byte output for PUT; buffered binary output is flushed when required by handle changes, seek operations, close operations, and mixed text/binary output paths.

## Screen Output

Standard text output is supported through PRINT.

Additional screen control is provided by:

- CLS
- LOCATE
- COLOR

When screen output support is active, runtime text output to the console can use BIOS text output with the active COLOR attribute.

## Memory Access

BASCOMP 2.0 supports a compact BASIC-style memory access subset:

- DEF SEG = expression sets the active segment used by PEEK and POKE.
- DEF SEG resets the active segment to the program segment.
- PEEK(address) returns the byte at the active segment and offset.
- POKE address, value writes a byte to the active segment and offset.

Values written by POKE must fit into a byte (0..255).

## Date, Time, Keyboard, EXEC, and CPU Support

BASCOMP 2.0 includes runtime support for:

- DATE$ using DOS date services,
- TIME$ and TIMER() using DOS time services,
- INKEY$ using enhanced BIOS keyboard calls where available,
- EXEC() for launching DOS child programs,
- CPUID() for CPU-class detection.

## Typical Build Flow

1. Write BASIC source as <name>.BAS.
2. Run BASCOMP with <name> as the base name.
3. BASCOMP generates <name>.ASM.
4. Post-process the assembler output with ASMPACK, creating an .AS2 file.
5. Assemble the .AS2 file with NASM or the supplied special assembler BASM, generating a COM file.
6. Use the final DOS program.

## Notes and Limitations

- BASCOMP targets compact 16-bit DOS-style programs.
- Numeric values use signed 16-bit integer-style arithmetic.
- String values use counted strings with runtime-managed temporary buffers.
- Some runtime modules are included only when the compiler emits the matching runtime capability request.
- Identifier names are limited by the compiler's identifier reader; keep user identifiers short and compatible with classic BASIC style.
- Deeply nested expressions are supported within fixed internal context-stack limits.
- GET and PUT operate on byte values through the runtime binary I/O support.
