#include "vendor/unity.h"

extern long square_of_sum(long number);
extern long sum_of_squares(long number);

void setUp(void) {
}

void tearDown(void) {
}

void test_square_of_sum_1(void) {
    TEST_ASSERT_EQUAL_INT(1, square_of_sum(1));
}

void test_square_of_sum_5(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_INT(225, square_of_sum(5));
}

void test_sum_of_squares_5(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_INT(55, sum_of_squares(5));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_square_of_sum_1);
    RUN_TEST(test_square_of_sum_5);
    RUN_TEST(test_sum_of_squares_5);
    return UNITY_END();
}
