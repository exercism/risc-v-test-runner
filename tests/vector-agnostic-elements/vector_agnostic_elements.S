.option arch, +v

.text
.global raise_low_mu
.global raise_low_ma

# extern void raise_low_mu(int32_t *values, int32_t count, int32_t limit, int32_t amount);
# Adds amount to every value below limit, leaving the others unchanged.
raise_low_mu:
.Lmu_loop:
    blez a1, .Lmu_done
    vsetvli t0, a1, e32, m1, ta, mu
    vle32.v v8, (a0)
    vmslt.vx v0, v8, a2
    vadd.vx v8, v8, a3, v0.t
    vse32.v v8, (a0)
    slli t1, t0, 2
    add a0, a0, t1
    sub a1, a1, t0
    j .Lmu_loop
.Lmu_done:
    ret

# The same, but mask-agnostic: the values not below limit may be lost.
raise_low_ma:
.Lma_loop:
    blez a1, .Lma_done
    vsetvli t0, a1, e32, m1, ta, ma
    vle32.v v8, (a0)
    vmslt.vx v0, v8, a2
    vadd.vx v8, v8, a3, v0.t
    vse32.v v8, (a0)
    slli t1, t0, 2
    add a0, a0, t1
    sub a1, a1, t0
    j .Lma_loop
.Lma_done:
    ret
