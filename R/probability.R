#' Enumerate the complete outcome space
#'
#' With five symbols and four reels the machine has 5^4 = 625 ordered
#' outcomes. Enumerating all of them provides an exact check independent of a
#' Monte Carlo simulation.
#'
#' @param machine Slot-machine configuration.
#'
#' @return A data frame with each outcome, probability, rule and prize.
#' @export
enumerate_outcomes <- function(machine = create_machine()) {
  if (!inherits(machine, "slot_machine")) {
    stop("`machine` must be created with `create_machine()`.")
  }

  grids <- rep(list(machine$symbols$key), machine$reels)
  outcomes <- expand.grid(grids, stringsAsFactors = FALSE)
  names(outcomes) <- paste0("reel_", seq_len(machine$reels))
  outcome_matrix <- as.matrix(outcomes)

  probability_matrix <- matrix(
    machine$symbols$probability[
      match(as.vector(outcome_matrix), machine$symbols$key)
    ],
    nrow = nrow(outcome_matrix),
    ncol = machine$reels
  )
  probability <- apply(probability_matrix, 1L, prod)
  rule <- apply(outcome_matrix, 1L, classify_outcome)
  prize <- machine$paytable$prize[match(rule, machine$paytable$rule)]
  emoji_matrix <- matrix(
    machine$symbols$emoji[match(as.vector(outcome_matrix), machine$symbols$key)],
    nrow = nrow(outcome_matrix),
    ncol = machine$reels
  )

  data.frame(
    outcomes,
    outcome = apply(outcome_matrix, 1L, paste, collapse = " | "),
    emoji = apply(emoji_matrix, 1L, paste, collapse = " "),
    probability = probability,
    rule = rule,
    prize = prize,
    net = prize - machine$stake,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

#' Calculate exact theoretical metrics
#'
#' @param machine Slot-machine configuration.
#'
#' @return A list with category probabilities, RTP, house edge and variance.
#' @export
theoretical_summary <- function(machine = create_machine()) {
  outcomes <- enumerate_outcomes(machine)
  paytable <- machine$paytable

  category_probability <- vapply(
    paytable$rule,
    function(rule) sum(outcomes$probability[outcomes$rule == rule]),
    numeric(1)
  )
  categories <- data.frame(
    rule = paytable$rule,
    label = paytable$label,
    probability = category_probability,
    percentage = 100 * category_probability,
    expected_per_million = 1e6 * category_probability,
    prize = paytable$prize,
    expected_contribution = category_probability * paytable$prize,
    stringsAsFactors = FALSE
  )

  expected_payout <- sum(outcomes$probability * outcomes$prize)
  variance <- sum(outcomes$probability * (outcomes$prize - expected_payout)^2)
  no_prize_probability <- categories$probability[categories$rule == "no_prize"]

  list(
    categories = categories,
    expected_payout = expected_payout,
    expected_net = expected_payout - machine$stake,
    rtp = expected_payout / machine$stake,
    house_edge = 1 - expected_payout / machine$stake,
    hit_rate = 1 - no_prize_probability,
    variance = variance,
    standard_deviation = sqrt(variance),
    probability_sum = sum(outcomes$probability),
    outcomes = nrow(outcomes)
  )
}

#' Search for integer prize tables near a target RTP
#'
#' The search calculates the jackpot required for each combination of the
#' other three prizes, instead of evaluating every possible four-dimensional
#' combination. Only tables satisfying
#' `four pandas > three pandas > four common > three common` are retained.
#'
#' @param machine Slot-machine configuration used for category probabilities.
#' @param target_rtp Desired expected return as a proportion.
#' @param ranges Named list of integer prize ranges.
#' @param max_results Maximum number of candidate tables returned.
#'
#' @return A data frame ordered by absolute distance from the requested RTP.
#' @export
find_integer_paytable <- function(
    machine = create_machine(),
    target_rtp = 0.70,
    ranges = list(
      four_pandas = 50:250,
      three_pandas = 30:100,
      four_common = 10:40,
      three_common = 1:5
    ),
    max_results = 10L) {
  if (length(target_rtp) != 1L || !is.finite(target_rtp) || target_rtp <= 0) {
    stop("`target_rtp` must be a positive finite number.")
  }
  prize_rules <- c("four_pandas", "three_pandas", "four_common", "three_common")
  if (!all(prize_rules %in% names(ranges))) {
    stop("`ranges` must define: ", paste(prize_rules, collapse = ", "))
  }
  ranges <- lapply(ranges[prize_rules], function(x) sort(unique(as.integer(x))))
  if (any(vapply(ranges, length, integer(1)) == 0L)) {
    stop("Every prize range must contain at least one integer.")
  }

  categories <- theoretical_summary(machine)$categories
  category_probability <- setNames(categories$probability, categories$rule)
  combinations <- expand.grid(
    three_pandas = ranges$three_pandas,
    four_common = ranges$four_common,
    three_common = ranges$three_common,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  combinations <- combinations[
    combinations$three_pandas > combinations$four_common &
      combinations$four_common > combinations$three_common,
    ,
    drop = FALSE
  ]

  partial_payout <-
    combinations$three_pandas * category_probability[["three_pandas"]] +
    combinations$four_common * category_probability[["four_common"]] +
    combinations$three_common * category_probability[["three_common"]]
  required_jackpot <-
    (target_rtp * machine$stake - partial_payout) /
    category_probability[["four_pandas"]]

  jackpot_candidates <- lapply(required_jackpot, function(x) unique(c(floor(x), ceiling(x))))
  rows <- vector("list", length(jackpot_candidates))
  for (i in seq_along(jackpot_candidates)) {
    jackpots <- jackpot_candidates[[i]]
    jackpots <- jackpots[
      jackpots %in% ranges$four_pandas & jackpots > combinations$three_pandas[i]
    ]
    if (length(jackpots)) {
      rows[[i]] <- data.frame(
        four_pandas = jackpots,
        three_pandas = combinations$three_pandas[i],
        four_common = combinations$four_common[i],
        three_common = combinations$three_common[i]
      )
    }
  }
  candidates <- do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
  if (is.null(candidates) || !nrow(candidates)) {
    stop("No prize table in the supplied ranges can reach the target RTP.")
  }

  candidates$rtp <- (
    candidates$four_pandas * category_probability[["four_pandas"]] +
      candidates$three_pandas * category_probability[["three_pandas"]] +
      candidates$four_common * category_probability[["four_common"]] +
      candidates$three_common * category_probability[["three_common"]]
  ) / machine$stake
  candidates$distance <- abs(candidates$rtp - target_rtp)
  candidates <- candidates[order(candidates$distance, candidates$four_pandas), ]
  rownames(candidates) <- NULL
  head(candidates, as.integer(max_results))
}
