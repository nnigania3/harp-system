/* Harp example program 1: Sum 1-100, first writing the numbers to RAM */
.def SIZE 10

.perm rwx
.entry
entry:  ldi  %r1, SIZE
        muli %r5, %r0, (__WORD)
        addi %r6, %r0, #0
 	muli %r0, %r0, (__WORD * SIZE)
        addi %r3, %r0, #0

sloop:  add %r4, %r6, %r1
        st   %r4, %r3, array 	
        addi %r3, %r3, (__WORD)
        subi %r1, %r1, #1
        rtop @p0, %r1
  @p0 ? jmpi sloop
    
	ldi  %r1, SIZE
        ldi  %r3, #0

        ldi %r4, #1
        shli %r4, %r4, #14	/*address offset to clash with same index*/
lloop:  ld %r2, %r0, array
        subi %r1, %r1, #1
        add %r3, %r3, %r2
        add %r7, %r0, %r4
        st  %r3, %r7, array
        addi %r0, %r0, (__WORD)
        rtop @p0, %r1
  @p0 ? jmpi lloop

        ldi  %r3, #0
        ld  %r3, %r7, array
        ldi %r4, #1
        shli %r4, %r4, (__WORD*8 - 1)
        add %r4, %r4, %r5
        st %r3, %r4, #0
        
finish: jmpi finish

.global
.perm rw
.align 1024
array:.space 320
out:.space 32
