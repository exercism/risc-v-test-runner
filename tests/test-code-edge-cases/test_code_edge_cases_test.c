#include "vendor/unity.h"

#include <stddef.h>

extern int is_paired(const char *value);

void setUp(void) {
}

void tearDown(void) {
}

void test_paired_square_brackets(void) {
    TEST_ASSERT_TRUE(is_paired("[]"));
}

void test_empty_string(void) {
    TEST_IGNORE();
    TEST_ASSERT_TRUE(is_paired(""));
}

void test_unpaired_brackets(void) {
    TEST_IGNORE();
    TEST_ASSERT_FALSE(is_paired("[["));
}

void test_paired_with_whitespace(void) {
    TEST_IGNORE();
    TEST_ASSERT_TRUE(is_paired("{ }"));
}

void test_unopened_closing_brackets(void) {
    TEST_IGNORE();
    // A closing brace with nothing to close: }
    TEST_ASSERT_FALSE(is_paired("{]"));
}

void test_brackets_in_quotes_still_count(void) {
    TEST_IGNORE();
    /* The quotes around the braces
       are just more characters: {"{}"} */
    TEST_ASSERT_TRUE(is_paired("\"{}\""));
}

void test_brace_characters(void) {
    TEST_IGNORE();
    char value[3];
    value[0] = '{';
    value[1] = '}';
    value[2] = '\0';
    TEST_ASSERT_TRUE(is_paired(value));
}

void test_nested_blocks_keep_their_indentation(void) {
    TEST_IGNORE();
    const char *pairs[] = {"{}", "[]", "()"};
    for (size_t i = 0; i < 3; i++) {
        if (i != 1) {
            TEST_ASSERT_TRUE(is_paired(pairs[i]));
        }
    }
}

void test_math_expression(void) {
    TEST_IGNORE();
    TEST_ASSERT_TRUE(is_paired("(((185 + 223.85) * 15) - 543)/2"));
}

void test_nothing_to_check(void) {
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_paired_square_brackets);
    RUN_TEST(test_empty_string);
    RUN_TEST(test_unpaired_brackets);
    RUN_TEST(test_paired_with_whitespace);
    RUN_TEST(test_unopened_closing_brackets);
    RUN_TEST(test_brackets_in_quotes_still_count);
    RUN_TEST(test_brace_characters);
    RUN_TEST(test_nested_blocks_keep_their_indentation);
    RUN_TEST(test_math_expression);
    RUN_TEST(test_nothing_to_check);
    return UNITY_END();
}
