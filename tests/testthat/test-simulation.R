test_that("Monte Carlo simulations are reproducible", {
  first <- simulate_spins(machine, n = 5000, seed = 123)
  second <- simulate_spins(machine, n = 5000, seed = 123)

  expect_identical(first, second)
})

test_that("a large simulation approaches the exact model", {
  simulation <- simulate_spins(machine, n = 200000, seed = 2026)
  summary <- simulation_summary(simulation, machine)

  expect_lt(abs(summary$observed_hit_rate - summary$theoretical_hit_rate), 0.005)
  expect_lt(abs(summary$observed_rtp - summary$theoretical_rtp), 0.025)
  expect_equal(sum(summary$categories$observed_count), 200000)
})

test_that("bankroll paths include their starting balance", {
  simulation <- simulate_spins(machine, n = 10, seed = 7)
  path <- bankroll_path(simulation, starting_balance = 50)

  expect_length(path, 11)
  expect_equal(path[1], 50)
  expect_equal(tail(path, 1), 50 + sum(simulation$net))
})
