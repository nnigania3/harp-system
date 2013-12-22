/* Harp example program 1: Sum 1-100, first writing the numbers to RAM */

.perm rwx
.entry
entry:  ldi  %r0, #0
sloop:  muli %r2, %r0, __WORD
        addi %r0, %r0, #1
        subi %r3, %r0, #240
        st   %r0, %r2, array
        rtop @p0, %r3
  @p0 ? jmpi sloop

        ldi  %r1, #0
        ldi  %r0, #0
lloop:  ld   %r2, %r1, array
        subi %r3, %r1, (__WORD*239)
        addi %r1, %r1, __WORD
        add  %r0, %r0, %r2
        rtop @p0, %r3
  @p0 ? jmpi lloop

        ldi %r4, #1; 
        shli %r4, %r4, (__WORD*8 - 1);
        st %r0, %r4, #0;

finish: jmpi finish

.global
.perm rw
.align 1024
array: .space 240
