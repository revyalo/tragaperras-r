#' Simulate many slot-machine spins
#'
#' @param machine Slot-machine configuration.
#' @param n Number of spins.
#' @param seed Reproducibility seed.
#' @param keep_outcomes Whether to keep symbol and emoji strings for each spin.
#'
#' @return A data frame with rule, prize and net result for every spin.
#' @export
simulate_spins <- function(
    machine = create_machine(),
    n = 100000L,
    seed = 2026L,
    keep_outcomes = FALSE) {
  if (!inherits(machine, "slot_machine")) {
    stop("`machine` must be created with `create_machine()`.")
  }
  if (length(n) != 1L || !is.finite(n) || n < 1 || n != as.integer(n)) {
    stop("`n` must be a positive integer.")
  }
  n <- as.integer(n)
  set.seed(seed)

  draws <- matrix(
    sample.int(
      nrow(machine$symbols),
      size = n * machine$reels,
      replace = TRUE,
      prob = machine$symbols$probability
    ),
    nrow = n,
    ncol = machine$reels
  )
  panda_index <- match("panda", machine$symbols$key)
  common_indices <- setdiff(seq_len(nrow(machine$symbols)), panda_index)

  all_equal <- draws[, 1L] == draws[, 2L] &
    draws[, 2L] == draws[, 3L] &
    draws[, 3L] == draws[, 4L]
  panda_count <- rowSums(draws == panda_index)
  common_counts <- vapply(
    common_indices,
    function(index) rowSums(draws == index),
    numeric(n)
  )
  if (is.null(dim(common_counts))) {
    common_counts <- matrix(common_counts, nrow = n)
  }
  common_max <- apply(common_counts, 1L, max)

  rule <- rep("no_prize", n)
  rule[panda_count == 3L] <- "three_pandas"
  rule[common_max == 3L] <- "three_common"
  rule[all_equal & panda_count == 4L] <- "four_pandas"
  rule[all_equal & panda_count == 0L] <- "four_common"

  prize_lookup <- setNames(machine$paytable$prize, machine$paytable$rule)
  result <- data.frame(
    spin = seq_len(n),
    rule = rule,
    prize = unname(prize_lookup[rule]),
    stake = machine$stake,
    net = unname(prize_lookup[rule]) - machine$stake,
    stringsAsFactors = FALSE
  )

  if (isTRUE(keep_outcomes)) {
    key_matrix <- matrix(machine$symbols$key[draws], nrow = n, ncol = machine$reels)
    emoji_matrix <- matrix(machine$symbols$emoji[draws], nrow = n, ncol = machine$reels)
    result$outcome <- apply(key_matrix, 1L, paste, collapse = " | ")
    result$emoji <- apply(emoji_matrix, 1L, paste, collapse = " ")
  }

  attr(result, "seed") <- seed
  attr(result, "machine") <- machine
  result
}

#' Summarise a Monte Carlo simulation
#'
#' @param simulation Data frame returned by [simulate_spins()].
#' @param machine Slot-machine configuration. By default it is read from the
#'   simulation attributes.
#'
#' @return Observed and theoretical category frequencies plus RTP metrics.
#' @export
simulation_summary <- function(simulation, machine = attr(simulation, "machine")) {
  if (is.null(machine) || !inherits(machine, "slot_machine")) {
    stop("Supply the machine used to create the simulation.")
  }
  if (!is.data.frame(simulation) || !all(c("rule", "prize", "stake") %in% names(simulation))) {
    stop("`simulation` must be returned by `simulate_spins()`.")
  }

  theoretical <- theoretical_summary(machine)
  observed_counts <- table(factor(
    simulation$rule,
    levels = machine$paytable$rule
  ))
  categories <- theoretical$categories
  categories$observed_count <- as.integer(observed_counts)
  categories$observed_probability <- categories$observed_count / nrow(simulation)
  categories$error <- categories$observed_probability - categories$probability

  reward_mean <- mean(simulation$prize)
  reward_standard_error <- stats::sd(simulation$prize) / sqrt(nrow(simulation))
  observed_rtp <- reward_mean / machine$stake
  margin <- 1.96 * reward_standard_error / machine$stake

  list(
    categories = categories,
    spins = nrow(simulation),
    observed_rtp = observed_rtp,
    theoretical_rtp = theoretical$rtp,
    rtp_confidence_interval = c(observed_rtp - margin, observed_rtp + margin),
    observed_hit_rate = mean(simulation$prize > 0),
    theoretical_hit_rate = theoretical$hit_rate,
    total_staked = sum(simulation$stake),
    total_paid = sum(simulation$prize),
    house_profit = -sum(simulation$net)
  )
}

#' Calculate the player's balance after every simulated spin
#'
#' @param simulation Data frame returned by [simulate_spins()].
#' @param starting_balance Initial balance.
#'
#' @return A numeric vector including the initial balance.
#' @export
bankroll_path <- function(simulation, starting_balance = 100) {
  if (!is.data.frame(simulation) || !"net" %in% names(simulation)) {
    stop("`simulation` must be returned by `simulate_spins()`.")
  }
  c(starting_balance, starting_balance + cumsum(simulation$net))
}
