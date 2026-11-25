#include "vendor/unity.h"

#include <stdint.h>

extern void raise_low_mu(int32_t *values, int32_t count, int32_t limit,
                         int32_t amount);
extern void raise_low_ma(int32_t *values, int32_t count, int32_t limit,
                         int32_t amount);

void setUp(void) {}

void tearDown(void) {}

// TASK: 1
void test_mask_undisturbed_keeps_inactive_elements(void) {
  int32_t values[] = {1, 50, 3, 60, 5};
  const int32_t expected[] = {11, 50, 13, 60, 15};
  raise_low_mu(values, 5, 10, 10);
  TEST_ASSERT_EQUAL_INT32_ARRAY(expected, values, 5);
}

// TASK: 2
void test_mask_agnostic_may_lose_inactive_elements(void) {
  int32_t values[] = {1, 50, 3, 60, 5};
  const int32_t expected[] = {11, 50, 13, 60, 15};
  raise_low_ma(values, 5, 10, 10);
  TEST_ASSERT_EQUAL_INT32_ARRAY(expected, values, 5);
}

int main(void) {
  UNITY_BEGIN();
  RUN_TEST(test_mask_undisturbed_keeps_inactive_elements);
  RUN_TEST(test_mask_agnostic_may_lose_inactive_elements);
  return UNITY_END();
}
