.equ EXPECTED_MINUTES_IN_OVEN, 40
.equ TIME_PER_LAYER, 2

.text
.globl expected_minutes_in_oven
.globl remaining_minutes_in_oven
.globl preparation_time_in_minutes
.globl elapsed_time_in_minutes

/* extern int expected_minutes_in_oven(void); */
expected_minutes_in_oven:
        li      a0, EXPECTED_MINUTES_IN_OVEN
        ret

/* extern int remaining_minutes_in_oven(int actual_minutes_in_oven); */
remaining_minutes_in_oven:
        li      t0, EXPECTED_MINUTES_IN_OVEN
        sub     a0, t0, a0
        ret

/* extern int preparation_time_in_minutes(int number_of_layers); */
preparation_time_in_minutes:
        li      t0, TIME_PER_LAYER
        mul     a0, a0, t0
        ret

/* extern int elapsed_time_in_minutes(int number_of_layers, int actual_minutes_in_oven); */
elapsed_time_in_minutes:
        li      t0, TIME_PER_LAYER
        mul     a0, a0, t0
        add     a0, a0, a1
        ret
