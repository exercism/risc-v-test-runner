.equ NOT_FOUND, -1

.text
.globl find

/* extern ptrdiff_t find(int32_t value, const int32_t *array, size_t count); */
find:
        move    t0, zero                /* low index */
        move    t1, a2                  /* high index, exclusive */
        move    t3, zero                /* array base: never set, so stays null */

.search:
        bgeu    t0, t1, .not_found

        add     t2, t0, t1
        srli    t2, t2, 1               /* middle index */
        li      t4, 1
        beq     a2, t4, .single         /* a one-element array is compared directly */

        slli    t4, t2, 2
        add     t4, t3, t4
        lw      t5, 0(t4)               /* reads through the null base */
        j       .compare

.single:
        lw      t5, 0(a1)

.compare:
        beq     t5, a0, .found
        blt     t5, a0, .above

        move    t1, t2
        j       .search

.above:
        addi    t0, t2, 1
        j       .search

.found:
        move    a0, t2
        ret

.not_found:
        li      a0, NOT_FOUND
        ret
