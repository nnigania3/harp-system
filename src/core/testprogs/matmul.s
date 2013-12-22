/*******************************************************************************
 HARPtools by Chad D. Kersey, Summer 2011
********************************************************************************

 Sample HARP assmebly program.

*******************************************************************************/
/* Matrix multiply: find matrix product */
.def SIZE 0x1000

.align 4096
.perm x
.entry
.global
entry: ldi %r0, matrix_a;
       ldi %r1, matrix_b;
       ldi %r2, matrix_r;
       ldi %r3, #3;
       jali %r5, matmul;

       ldi %r0, #64;
       ldi %r1, matrix_r;

ploop: ld %r7, %r1, #0;
       jali %r5, printdec;
       addi %r1, %r1, __WORD;
       subi %r0, %r0, #1;
       rtop @p0, %r0;
 @p0 ? jmpi ploop;

finished:     jmpi finished;
/*       trap;*/

/* Write the matrix product of square matrix at (%r0) and (%r1) to (%r2). The
   size of these matrices is 2^Nx2^N, where N = %r3 */
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

        addi %r6, %r6, #1;
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
matrix_a: .word  1  2  3  4  5  6  7  8
          .word  2  3  4  5  6  7  8  9
          .word  3  4  5  6  7  8  9 10
          .word  4  5  6  7  8  9 10 11
          .word  5  6  7  8  9 10 11 12
          .word  6  7  8  9 10 11 12 13
          .word  7  8  9 10 11 12 13 14
          .word  8  9 10 11 12 13 14 15

matrix_b: .word  0 0 0 0 0 0 0 0
          .word  1 1 1 1 1 1 1 1
          .word  2 2 2 2 2 2 2 2
          .word  3 3 3 3 3 3 3 3
          .word  4 4 4 4 4 4 4 4 
          .word  5 5 5 5 5 5 5 5
          .word  6 6 6 6 6 6 6 6
          .word  7 7 7 7 7 7 7 7 

.align 3072
matrix_r: .space 64

retaddr: .word 0
digstack:    .space 10
