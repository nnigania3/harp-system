/*******************************************************************************
 HARPtools by Chad D. Kersey, Summer 2011
********************************************************************************

 Sample HARP assmebly program.

*******************************************************************************/
/* Matrix multiply: find matrix product */
.def SIZE 64  /* Matrix size*/
.def DIM 8    /*sqrt(SIZE) */
.def LANES 8
.align 4096
.perm x
.entry
.global
entry: /*ldi %r0, #0*/
       addi %r8, %r0, #0;
       muli %r0, %r0, (__WORD);
       addi %r1, %r0, matrix_b;
       addi %r2, %r0, matrix_r;
       addi %r0, %r0, matrix_a;
       jali %r5, matinit;

       ldi %r0, matrix_a;
       ldi %r3, (`DIM);
       jali %r5, matmul;

       subi %r5, %r2, matrix_r;
       ld %r3, %r2, #0;
       ldi %r4, #0
       shli %r4, %r4, (__WORD*8 - 1)
       add %r4, %r4, %r5
       st %r3, %r4, #0

/*
ploop: ld %r7, %r1, #0;
       jali %r5, printdec;
       addi %r1, %r1, ( __WORD * LANES);
       subi %r0, %r0, (LANES);
       rtop @p0, %r0;
 @p0 ? jmpi ploop;
*/

finished:     jmpi finished;
/*       trap;*/

/* Write the matrix product of square matrix at (%r0) and (%r1) to (%r2). The
   size of these matrices is 2^Nx2^N, where N = %r3 */

matinit: ldi %r4, (SIZE);
sloop:  add %r6, %r0, %r3
        add %r7, %r1, %r3
        st   %r8, %r6, #0 	
        st   %r8, %r7, #0 	
        addi %r3, %r3, (__WORD * LANES)
        subi %r4, %r4, (LANES)
        addi %r8, %r8, #1
        rtop @p0, %r4
  @p0 ? jmpi sloop

        jmpr %r5;

matmul: ldi %r4, #1;
        ldi %r10, (`__WORD); /* ` is the log base 2 operator */
        shl %r4, %r4, %r3;
        add %r10, %r10, %r3;
        ldi %r14, #1;
        shl %r14, %r14, %r10;

        ldi %r9, #0; /* result row: %r9 */
rloop:  ldi %r6, #0; /* result col: %r6 */
cloop:  shli %r3, %r6, (`__WORD);
        shl %r15, %r9, %r10;

        add %r11, %r15, %r0;
        add %r12, %r3, %r1;
        ldi %r13, #0;

        ldi %r8, #0 /* dot prod position: %r8 */
iloop:  ld %r7, %r11, #0;
        ld %r15, %r12, #0;
        mul %r7, %r7, %r15
        add %r13, %r13, %r7;

        addi %r8, %r8, #1;
        addi %r11, %r11, __WORD;
        add %r12, %r12, %r14;
        sub %r7, %r8, %r4;
        rtop @p0, %r7;
  @p0 ? jmpi iloop;

        shl %r15, %r9, %r10;

        add %r15, %r15, %r3;
        add %r15, %r15, %r2;
        st %r13, %r15, #0;

        addi %r6, %r6, (LANES);
        sub %r7, %r6, %r4;
        rtop @p0, %r7;
  @p0 ? jmpi cloop;

        addi %r9, %r9, #1;
        sub %r7, %r9, %r4;
        rtop @p0, %r7;
  @p0 ? jmpi rloop;

        jmpr %r5;

printdec:    ldi  %r3, #1; /*Instruction 42, PC=168*/
             shli %r3, %r3, (__WORD*8 - 1);
             and  %r6, %r3, %r7;
             rtop @p0, %r6;
       @p0 ? ldi  %r6, #0x2d;
       @p0 ? st   %r6, %r3, #0;
       @p0 ? neg  %r7, %r7;
             ldi  %r4, #0;
printdec_l1: modi %r6, %r7, #10;
             divi %r7, %r7, #10;
             addi %r6, %r6, #0x30;
             /*addi %r6, %r6, #0x00;*/
             st   %r6, %r4, digstack;
             addi %r4, %r4, __WORD;
             rtop @p0, %r7;
       @p0 ? jmpi printdec_l1;
printdec_l2: subi %r4, %r4, __WORD;
             ld   %r6, %r4, digstack;
             st   %r6, %r3, #0;
             rtop @p0, %r4;
       @p0 ? jmpi printdec_l2;
             ldi  %r6, #0x0a;
             st   %r6, %r3, #0;
             jmpr %r5 /* Instruction 64, PC=256*/

.perm rw
.align 1024
matrix_a: .space 256
matrix_b: .space 256
matrix_r: .space 256

retaddr: .word 0
digstack:    .space 10
