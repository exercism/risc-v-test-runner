#include "vendor/unity.h"

#define UNEQUAL_LENGTHS -1

extern int distance(const char *strand1, const char *strand2);

void setUp(void) {
}

void tearDown(void) {
}

void test_empty_strands(void) {
    TEST_ASSERT_EQUAL_INT(0, distance("", ""));
}

void test_single_letter_identical_strands(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_INT(0, distance("A", "A"));
}

void test_long_different_strands(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_INT(9, distance("GGACGGATTCTG", "AGGACGGATTCT"));
}

void test_disallow_first_strand_longer(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_INT(UNEQUAL_LENGTHS, distance("AATG", "AAA"));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_empty_strands);
    RUN_TEST(test_single_letter_identical_strands);
    RUN_TEST(test_long_different_strands);
    RUN_TEST(test_disallow_first_strand_longer);
    return UNITY_END();
}
