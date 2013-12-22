/* Bubble Sort */

.align 4096
.perm x
.global
entry:    ldi %r1, InitArray;
          ldi %r2, Array;
initloop: ld %r3, %r1, #0;
          st %r3, %r2, #0;
          addi %r2, %r2, __WORD;
          addi %r1, %r1, __WORD;
          subi %r3, %r2, ArrayEnd;
          rtop @p0, %r3;
    @p0 ? jmpi initloop;

        ldi %r1, Array;          /* p = array;               */
        ldi %r6, ArrayEnd;       /* lim = array+N-1          */
        subi %r6, %r6, __WORD;

oloop:                           /* do {                     */
        ldi %r2, Array;          /*   q = array;             */
        ldi %r7, #1;             /*   sorted = 1;            */
iloop:
        sub %r3, %r2, %r6;       /*   while (q != lim) {     */
        iszero @p0, %r3;
  @p0 ? jmpi onext;
        
        ld %r3, %r2, #0;         /*     if (*q > *(q + 1)) { */
        ld %r4, %r2, __WORD;     /*       temp = *(q + 1);   */
        sub %r5, %r4, %r3;
        isneg @p0, %r5;
        notp @p0, @p0;
  @p0 ? jmpi inext;
        st %r3, %r2, __WORD;     /*       *(q + 1) = *q;     */
        st %r4, %r2, #0;         /*       *q = temp;         */
        ldi %r7, #0;             /*       sorted = 0;        */
                                 /*     }                    */
inext:  addi %r2, %r2, __WORD;   /*     q++;                 */
        jmpi iloop;              /*   }                      */
onext:  addi %r1, %r1, __WORD;   /*   p++;                   */
        subi %r6, %r6, __WORD;   /*   lim--;                 */
        rtop @p0, %r7;           /* } while (!sorted && p != array+N)   */
  @p0 ? jmpi printresults;
        subi %r3, %r1, ArrayEnd;
        rtop @p0, %r3;
  @p0 ? jmpi oloop;

/* p = array; do { printdec(*p); p++; } while(p != array+N); */
printresults: ldi %r1, Array;
printloop:    ld %r7, %r1, #0;
              jali %r5, printdec;
              addi %r1, %r1, __WORD;
              subi %r2, %r1, ArrayEnd;
              rtop @p0, %r2;
        @p0 ? jmpi printloop;
finished:     jmpi finished;

printdec:    ldi  %r3, #1;
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
             jmpr %r5

InitArray:
  .word 3 1 4 5 9 2 6 7 8 0

.perm rw
.align 1024
digstack: .space 10
Array: .space 10
ArrayEnd: .word 0
