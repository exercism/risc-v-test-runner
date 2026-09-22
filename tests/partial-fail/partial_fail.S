.section .rodata
pling: .string "Pling"
plang: .string "Plang"

.text
.globl convert

/* extern void convert(char *buffer, size_t number); */
convert:
        move    t5, a0                  /* start of buffer */

        la      a2, pling
        li      a3, 3
        jal     t6, sound               /* subroutine call */

        la      a2, plang
        li      a3, 5
        jal     t6, sound               /* subroutine call */

        sb      zero, 0(a0)             /* store null terminator */
        bne     a0, t5, .done           /* a sound was written */

        li      t4, 10
        move    t1, a1
        move    t2, a0

.count:                                 /* one byte per decimal digit */
        addi    t2, t2, 1
        divu    t1, t1, t4
        bnez    t1, .count

        sb      zero, 0(t2)             /* store null terminator */

.digits:                                /* fill in from the right */
        addi    t2, t2, -1
        remu    t1, a1, t4
        addi    t1, t1, 48              /* ASCII '0' */
        sb      t1, 0(t2)
        divu    a1, a1, t4
        bnez    a1, .digits

.done:
        ret

/* append the string at a2 when a1 is divisible by a3 */
sound:
        remu    t0, a1, a3
        bnez    t0, .silent

.copy:
        lb      t0, 0(a2)
        beqz    t0, .silent

        sb      t0, 0(a0)
        addi    a0, a0, 1
        addi    a2, a2, 1
        j       .copy

.silent:
        jalr    zero, 0(t6)             /* return */
