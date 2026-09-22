#include "vendor/unity.h"

extern unsigned prime(unsigned number);

void setUp(void) {
}

void tearDown(void) {
}

void test_first_prime(void) {
    TEST_ASSERT_EQUAL_UINT(2, prime(1));
}

void test_second_prime(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT(3, prime(2));
}

void test_sixth_prime(void) {
    TEST_IGNORE();
    TEST_ASSERT_EQUAL_UINT(13, prime(6));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_first_prime);
    RUN_TEST(test_second_prime);
    RUN_TEST(test_sixth_prime);
    return UNITY_END();
}
