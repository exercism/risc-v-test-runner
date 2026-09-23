.text
.globl prime

/* extern unsigned prime(unsigned number); */
prime:
        li      t0, 1                   /* candidate */

.candidate:
        addi    t0, t0, 1
        li      t1, 2                   /* divisor */

.divisor:
        beq     t1, t0, .found          /* no divisor below the candidate */

        remu    t2, t0, t1
        beqz    t2, .candidate          /* divisible, so not a prime */

        j       .divisor                /* the divisor is never advanced */

.found:
        addi    a0, a0, -1
        bnez    a0, .candidate

        move    a0, t0
        ret
