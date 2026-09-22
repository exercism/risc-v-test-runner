.equ INVALID_NUMBER, -1

.section .rodata
format: .string "%ld\n"

.text
.globl steps

/* extern int steps(long number); */
steps:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)
        move    s0, a0                  /* current value */
        move    s1, zero                /* steps so far */
        blez    s0, .invalid

.loop:
        li      t0, 1
        beq     s0, t0, .done

        la      a0, format              /* print the value at each step */
        move    a1, s0
        call    printf

        andi    t0, s0, 1
        bnez    t0, .odd

        srli    s0, s0, 1
        j       .step

.odd:
        slli    t0, s0, 1
        add     s0, s0, t0
        addi    s0, s0, 1

.step:
        addi    s1, s1, 1
        j       .loop

.invalid:
        li      s1, INVALID_NUMBER

.done:
        move    a0, s1
        lw      ra, 12(sp)
        lw      s0, 8(sp)
        lw      s1, 4(sp)
        addi    sp, sp, 16
        ret
