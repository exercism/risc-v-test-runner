#include "vendor/unity.h"

#include <stddef.h>
#include <stdint.h>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

extern ptrdiff_t find(int32_t value, const int32_t *array, size_t count);

void setUp(void) {
}

void tearDown(void) {
}

void test_finds_a_value_in_an_array_with_one_element(void) {
    const int32_t array[] = {6};
    TEST_ASSERT_EQUAL_INT(0, find(6, array, ARRAY_SIZE(array)));
}

void test_finds_a_value_in_the_middle_of_an_array(void) {
    TEST_IGNORE();
    const int32_t array[] = {1, 3, 4, 6, 8, 9, 11};
    TEST_ASSERT_EQUAL_INT(3, find(6, array, ARRAY_SIZE(array)));
}

void test_finds_a_value_at_the_beginning_of_an_array(void) {
    TEST_IGNORE();
    const int32_t array[] = {1, 3, 4, 6, 8, 9, 11};
    TEST_ASSERT_EQUAL_INT(0, find(1, array, ARRAY_SIZE(array)));
}

void test_finds_a_value_at_the_end_of_an_array(void) {
    TEST_IGNORE();
    const int32_t array[] = {1, 3, 4, 6, 8, 9, 11};
    TEST_ASSERT_EQUAL_INT(6, find(11, array, ARRAY_SIZE(array)));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_finds_a_value_in_an_array_with_one_element);
    RUN_TEST(test_finds_a_value_in_the_middle_of_an_array);
    RUN_TEST(test_finds_a_value_at_the_beginning_of_an_array);
    RUN_TEST(test_finds_a_value_at_the_end_of_an_array);
    return UNITY_END();
}
