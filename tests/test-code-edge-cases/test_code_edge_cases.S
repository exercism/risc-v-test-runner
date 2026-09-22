.equ STACK_SIZE, 256

.text
.globl is_paired

/* extern int is_paired(const char *value); */
is_paired:
        addi    sp, sp, -STACK_SIZE
        addi    t1, sp, STACK_SIZE      /* stack of expected closing brackets, empty */
        move    t0, a0

.next:
        lb      t2, 0(t0)
        addi    t0, t0, 1
        beqz    t2, .end

        li      t3, 40                  /* ( */
        li      t4, 41                  /* ) */
        beq     t2, t3, .open
        li      t3, 91                  /* [ */
        li      t4, 93                  /* ] */
        beq     t2, t3, .open
        li      t3, 123                 /* { */
        li      t4, 125                 /* } */
        beq     t2, t3, .open

        li      t3, 41                  /* ) */
        beq     t2, t3, .close
        li      t3, 93                  /* ] */
        beq     t2, t3, .close
        li      t3, 125                 /* } */
        beq     t2, t3, .close
        j       .next

.open:
        addi    t1, t1, -1
        sb      t4, 0(t1)
        j       .next

.close:
        addi    t3, sp, STACK_SIZE
        beq     t1, t3, .unpaired       /* nothing is open */

        lb      t3, 0(t1)
        addi    t1, t1, 1
        bne     t2, t3, .unpaired
        j       .next

.end:
        addi    t3, sp, STACK_SIZE
        bne     t1, t3, .unpaired       /* something is still open */

        li      a0, 1
        addi    sp, sp, STACK_SIZE
        ret

.unpaired:
        move    a0, zero
        addi    sp, sp, STACK_SIZE
        ret
