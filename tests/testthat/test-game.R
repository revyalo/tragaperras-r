test_that("outcomes are assigned to mutually exclusive rules", {
  expect_identical(classify_outcome(rep("panda", 4)), "four_pandas")
  expect_identical(classify_outcome(rep("shrimp", 4)), "four_common")
  expect_identical(
    classify_outcome(c("panda", "panda", "mouse", "panda")),
    "three_pandas"
  )
  expect_identical(
    classify_outcome(c("pig", "mouse", "pig", "pig")),
    "three_common"
  )
  expect_identical(
    classify_outcome(c("pig", "mouse", "panda", "shrimp")),
    "no_prize"
  )
})

test_that("spins are reproducible and use the configured paytable", {
  first <- spin_machine(machine, seed = 42)
  second <- spin_machine(machine, seed = 42)

  expect_identical(first$outcome, second$outcome)
  expect_equal(first$prize, calculate_prize(first$outcome, machine))
  expect_equal(first$net, first$prize - machine$stake)
})

test_that("invalid configurations fail early", {
  invalid_symbols <- default_symbols()
  invalid_symbols$probability[1] <- 0.5
  expect_error(create_machine(symbols = invalid_symbols), "sum to one")
  expect_error(create_machine(stake = 0), "positive")
  expect_error(classify_outcome(c("panda", "pig")), "exactly four")
})
