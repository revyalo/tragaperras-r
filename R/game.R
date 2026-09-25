#' Classify one four-reel outcome
#'
#' Rules are mutually exclusive and are evaluated from the most specific to
#' the most general result.
#'
#' @param outcome Character vector containing four symbol keys.
#' @param panda Key used for the rare panda symbol.
#'
#' @return A rule key from [default_paytable()].
#' @export
classify_outcome <- function(outcome, panda = "panda") {
  outcome <- as.character(outcome)
  if (length(outcome) != 4L || anyNA(outcome)) {
    stop("`outcome` must contain exactly four non-missing symbols.")
  }

  counts <- table(outcome)
  panda_count <- unname(counts[panda])
  if (length(panda_count) == 0L || is.na(panda_count)) {
    panda_count <- 0L
  }
  common_counts <- counts[names(counts) != panda]

  if (panda_count == 4L) {
    return("four_pandas")
  }
  if (length(common_counts) && any(common_counts == 4L)) {
    return("four_common")
  }
  if (panda_count == 3L) {
    return("three_pandas")
  }
  if (length(common_counts) && any(common_counts == 3L)) {
    return("three_common")
  }
  "no_prize"
}

#' Calculate the prize for an outcome
#'
#' @param outcome Character vector with four symbol keys.
#' @param machine Slot-machine configuration.
#'
#' @return Prize in euros.
#' @export
calculate_prize <- function(outcome, machine = create_machine()) {
  rule <- classify_outcome(outcome)
  machine$paytable$prize[match(rule, machine$paytable$rule)]
}

#' Perform one random spin
#'
#' @param machine Slot-machine configuration.
#' @param seed Optional reproducibility seed.
#'
#' @return An object of class `slot_spin`.
#' @export
spin_machine <- function(machine = create_machine(), seed = NULL) {
  if (!inherits(machine, "slot_machine")) {
    stop("`machine` must be created with `create_machine()`.")
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }

  outcome <- sample(
    machine$symbols$key,
    size = machine$reels,
    replace = TRUE,
    prob = machine$symbols$probability
  )
  rule <- classify_outcome(outcome)
  row <- machine$paytable[match(rule, machine$paytable$rule), ]
  emoji <- machine$symbols$emoji[match(outcome, machine$symbols$key)]

  structure(
    list(
      outcome = outcome,
      emoji = emoji,
      rule = rule,
      label = row$label,
      prize = row$prize,
      stake = machine$stake,
      net = row$prize - machine$stake
    ),
    class = "slot_spin"
  )
}

#' Format a spin for a terminal or report
#'
#' @param spin Object returned by [spin_machine()].
#'
#' @return A single formatted character string.
#' @export
format_spin <- function(spin) {
  if (!inherits(spin, "slot_spin")) {
    stop("`spin` must be returned by `spin_machine()`.")
  }
  sprintf(
    "%s  |  %s  |  Premio: EUR %.2f",
    paste(spin$emoji, collapse = " "),
    spin$label,
    spin$prize
  )
}

#' @export
print.slot_spin <- function(x, ...) {
  cat(format_spin(x), "\n")
  invisible(x)
}
