#include "vendor/unity.h"

#include <stddef.h>

#define BUFFER_SIZE 24

extern void convert(char *buffer, size_t number);

void setUp(void) {
}

void tearDown(void) {
}

void test_the_sound_for_1_is_1(void) {
    char buffer[BUFFER_SIZE];

    convert(buffer, 1);
    TEST_ASSERT_EQUAL_STRING("1", buffer);
}

void test_the_sound_for_3_is_pling(void) {
    TEST_IGNORE();
    char buffer[BUFFER_SIZE];

    convert(buffer, 3);
    TEST_ASSERT_EQUAL_STRING("Pling", buffer);
}

void test_the_sound_for_5_is_plang(void) {
    TEST_IGNORE();
    char buffer[BUFFER_SIZE];

    convert(buffer, 5);
    TEST_ASSERT_EQUAL_STRING("Plang", buffer);
}

void test_the_sound_for_7_is_plong(void) {
    TEST_IGNORE();
    char buffer[BUFFER_SIZE];

    convert(buffer, 7);
    TEST_ASSERT_EQUAL_STRING("Plong", buffer);
}

void test_the_sound_for_105_is_plingplangplong_as_it_has_factors_3_5_and_7(void) {
    TEST_IGNORE();
    char buffer[BUFFER_SIZE];

    convert(buffer, 105);
    TEST_ASSERT_EQUAL_STRING("PlingPlangPlong", buffer);
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_the_sound_for_1_is_1);
    RUN_TEST(test_the_sound_for_3_is_pling);
    RUN_TEST(test_the_sound_for_5_is_plang);
    RUN_TEST(test_the_sound_for_7_is_plong);
    RUN_TEST(test_the_sound_for_105_is_plingplangplong_as_it_has_factors_3_5_and_7);
    return UNITY_END();
}
