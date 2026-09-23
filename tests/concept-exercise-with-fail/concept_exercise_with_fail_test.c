#include "vendor/unity.h"

#include <stdint.h>

extern uint8_t extract_higher_bits(uint16_t code);
extern uint8_t extract_lower_bits(uint16_t code);
extern uint8_t extract_redundant_bits(uint16_t code);

void setUp(void) {
}

void tearDown(void) {
}

// TASK: 1
void test_higher_bits_0b1010_0100_1100_0101(void) {
    TEST_ASSERT_EQUAL_UINT8_MESSAGE(164, extract_higher_bits(42181), "The function was called with argument: 0b1010_0100_1100_0101.");
}

void test_higher_bits_0b0000_0000_1111_1111(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT8_MESSAGE(0, extract_higher_bits(255), "The function was called with argument: 0b0000_0000_1111_1111.");
}

// TASK: 2
void test_lower_bits_0b1010_0100_1100_0101(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT8_MESSAGE(197, extract_lower_bits(42181), "The function was called with argument: 0b1010_0100_1100_0101.");
}

void test_lower_bits_0b1111_1111_0000_0000(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT8_MESSAGE(0, extract_lower_bits(65280), "The function was called with argument: 0b1111_1111_0000_0000.");
}

// TASK: 3
void test_redundant_bits_0b1010_0100_1100_0101(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT8_MESSAGE(132, extract_redundant_bits(42181), "The function was called with argument: 0b1010_0100_1100_0101.");
}

void test_redundant_bits_0b0001_1100_0001_1100(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT8_MESSAGE(28, extract_redundant_bits(7196), "The function was called with argument: 0b0001_1100_0001_1100.");
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_higher_bits_0b1010_0100_1100_0101);
    RUN_TEST(test_higher_bits_0b0000_0000_1111_1111);
    RUN_TEST(test_lower_bits_0b1010_0100_1100_0101);
    RUN_TEST(test_lower_bits_0b1111_1111_0000_0000);
    RUN_TEST(test_redundant_bits_0b1010_0100_1100_0101);
    RUN_TEST(test_redundant_bits_0b0001_1100_0001_1100);
    return UNITY_END();
}
