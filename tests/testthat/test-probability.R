test_that("the complete outcome space is exhaustive", {
  outcomes <- enumerate_outcomes(machine)

  expect_equal(nrow(outcomes), 625)
  expect_equal(sum(outcomes$probability), 1, tolerance = 1e-12)
  expect_false(anyNA(outcomes$rule))
})

test_that("exact category probabilities match the analytical model", {
  categories <- theoretical_summary(machine)$categories
  probability <- setNames(categories$probability, categories$rule)

  expect_equal(probability[["four_pandas"]], 0.04^4)
  expect_equal(probability[["four_common"]], 4 * 0.24^4)
  expect_equal(probability[["three_pandas"]], choose(4, 3) * 0.04^3 * 0.96)
  expect_equal(
    probability[["three_common"]],
    4 * choose(4, 3) * 0.24^3 * 0.76
  )
  expect_equal(sum(probability), 1)
})

test_that("the default prize table reaches the target RTP", {
  summary <- theoretical_summary(machine)

  expect_equal(summary$rtp, 0.70000128, tolerance = 1e-12)
  expect_equal(summary$house_edge, 0.29999872, tolerance = 1e-12)
  expect_equal(summary$hit_rate, 0.1816192, tolerance = 1e-12)
})

test_that("the integer optimizer finds ordered candidate tables", {
  candidates <- find_integer_paytable(machine, target_rtp = 0.70)

  expect_gt(nrow(candidates), 0)
  expect_true(all(candidates$four_pandas > candidates$three_pandas))
  expect_true(all(candidates$three_pandas > candidates$four_common))
  expect_true(all(candidates$four_common > candidates$three_common))
  expect_lte(min(candidates$distance), 2e-6)
})
