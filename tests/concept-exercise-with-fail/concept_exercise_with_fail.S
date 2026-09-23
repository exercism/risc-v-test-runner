.text
.globl extract_higher_bits
.globl extract_lower_bits
.globl extract_redundant_bits

/* extern uint8_t extract_higher_bits(uint16_t code); */
extract_higher_bits:
        srli    a0, a0, 8
        ret

/* extern uint8_t extract_lower_bits(uint16_t code); */
extract_lower_bits:
        andi    a0, a0, 0xff
        ret

/* extern uint8_t extract_redundant_bits(uint16_t code); */
extract_redundant_bits:
        srli    t0, a0, 8
        or      a0, a0, t0              /* should keep only the bits set in both halves */
        andi    a0, a0, 0xff
        ret
