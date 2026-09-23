#include "vendor/unity.h"

extern int leap_year(long year);

void setUp(void) {
}

void tearDown(void) {
}

void test_year_not_divisible_by_4_in_common_year(void) {
    TEST_ASSERT_FALSE(leap_year(2015));
}

void test_year_divisible_by_4_not_divisible_by_100_in_leap_year(void) {
    TEST_IGNORE();
    TEST_ASSERT_TRUE(leap_year(1996));
}

void test_year_divisible_by_100_not_divisible_by_400_in_common_year(void) {
    TEST_IGNORE();
    TEST_ASSERT_FALSE(leap_year(2100));
}

void test_year_divisible_by_400_is_leap_year(void) {
    TEST_IGNORE();
    TEST_ASSERT_TRUE(leap_year(2000));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_year_not_divisible_by_4_in_common_year);
    RUN_TEST(test_year_divisible_by_4_not_divisible_by_100_in_leap_year);
    RUN_TEST(test_year_divisible_by_100_not_divisible_by_400_in_common_year);
    RUN_TEST(test_year_divisible_by_400_is_leap_year);
    return UNITY_END();
}
