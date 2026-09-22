.text
.globl square_of_sum
.globl sum_of_squares

/* extern long square_of_sum(long number); */
square_of_sum:
        addi    t0, a0, 1               /* number + 1 */
        mul     a0, a0, t0              /* number (number + 1) */
        srli    a0, a0, 1               /* number (number + 1) / 2 */
        mul     a0, a0, a0
        return

/* extern long sum_of_squares(long number); */
sum_of_squares:
        addi    t0, a0, 1               /* number + 1 */
        add     t1, a0, t0              /* 2 number + 1 */
        mul     a0, a0, t0              /* number (number + 1) */
        mul     a0, a0, t1              /* number (number + 1) (2 number + 1) */
        li      t2, 6
        div     a0, a0, t2              /* number (number + 1) (2 number + 1) / 6 */
        ret
