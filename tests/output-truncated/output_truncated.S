.section .rodata
format: .string "%u\n"

.text
.globl sieve

/* extern size_t sieve(uint32_t *primes, uint32_t limit); */
sieve:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        move    s0, a0                  /* output array */
        move    s1, a1                  /* limit */
        move    s2, zero                /* number of primes found */
        li      s3, 2                   /* candidate */

.candidate:
        bgtu    s3, s1, .done

        li      t0, 2                   /* divisor */

.divisor:
        mul     t1, t0, t0
        bgtu    t1, s3, .prime          /* no divisor up to the square root */

        remu    t1, s3, t0
        beqz    t1, .next

        addi    t0, t0, 1
        j       .divisor

.prime:
        slli    t1, s2, 2
        add     t1, s0, t1
        sw      s3, 0(t1)
        addi    s2, s2, 1

        la      a0, format              /* print each prime as it is found */
        move    a1, s3
        call    printf

.next:
        addi    s3, s3, 1
        j       .candidate

.done:
        move    a0, s2
        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        lw      s3, 12(sp)
        addi    sp, sp, 32
        ret
