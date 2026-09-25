#' Default slot-machine symbols
#'
#' The original machine has four common symbols with probability 0.24 and a
#' rare panda with probability 0.04.
#'
#' @return A data frame with symbol keys, labels, emoji and probabilities.
#' @export
default_symbols <- function() {
  data.frame(
    key = c("shrimp", "scorpion", "pig", "mouse", "panda"),
    label = c("Gamba", "Escorpión", "Cerdo", "Ratón", "Panda"),
    emoji = c("U0001F990", "U0001F982", "U0001F437", "U0001F42D", "U0001F43C"),
    probability = c(0.24, 0.24, 0.24, 0.24, 0.04),
    stringsAsFactors = FALSE
  )
}

#' Default prize table
#'
#' Integer prizes are calibrated for an expected return of 70.000128 percent
#' when each spin costs one euro.
#'
#' @return A data frame describing every mutually exclusive prize rule.
#' @export
default_paytable <- function() {
  data.frame(
    rule = c(
      "four_pandas", "four_common", "three_pandas", "three_common",
      "no_prize"
    ),
    label = c(
      "Cuatro pandas", "Cuatro símbolos comunes iguales",
      "Exactamente tres pandas", "Exactamente tres símbolos comunes iguales",
      "Sin premio"
    ),
    prize = c(126, 26, 75, 2, 0),
    stringsAsFactors = FALSE
  )
}

required_rules <- function() {
  c("four_pandas", "four_common", "three_pandas", "three_common", "no_prize")
}

validate_symbols <- function(symbols) {
  required <- c("key", "label", "emoji", "probability")
  if (!is.data.frame(symbols) || !all(required %in% names(symbols))) {
    stop("`symbols` must be a data frame with columns: ", paste(required, collapse = ", "))
  }
  if (anyDuplicated(symbols$key) || any(!nzchar(symbols$key))) {
    stop("Symbol keys must be non-empty and unique.")
  }
  if (!"panda" %in% symbols$key) {
    stop("The configuration must contain the rare symbol `panda`.")
  }
  if (any(!is.finite(symbols$probability)) || any(symbols$probability <= 0)) {
    stop("Every symbol probability must be finite and greater than zero.")
  }
  if (abs(sum(symbols$probability) - 1) > 1e-12) {
    stop("Symbol probabilities must sum to one.")
  }
  invisible(TRUE)
}

validate_paytable <- function(paytable) {
  required <- c("rule", "label", "prize")
  if (!is.data.frame(paytable) || !all(required %in% names(paytable))) {
    stop("`paytable` must be a data frame with columns: ", paste(required, collapse = ", "))
  }
  if (!setequal(paytable$rule, required_rules()) || anyDuplicated(paytable$rule)) {
    stop("The prize table must contain every rule exactly once.")
  }
  if (any(!is.finite(paytable$prize)) || any(paytable$prize < 0)) {
    stop("Prizes must be finite and non-negative.")
  }
  invisible(TRUE)
}

#' Create a slot-machine configuration
#'
#' @param symbols Symbol data frame, normally from [default_symbols()].
#' @param paytable Prize data frame, normally from [default_paytable()].
#' @param stake Cost in euros of one spin.
#' @param reels Number of reels. The current rules use exactly four.
#'
#' @return An object of class `slot_machine`.
#' @export
create_machine <- function(
    symbols = default_symbols(),
    paytable = default_paytable(),
    stake = 1,
    reels = 4L) {
  validate_symbols(symbols)
  validate_paytable(paytable)
  if (length(stake) != 1L || !is.finite(stake) || stake <= 0) {
    stop("`stake` must be a single positive number.")
  }
  if (length(reels) != 1L || reels != 4L) {
    stop("This probability model requires exactly four reels.")
  }

  structure(
    list(
      symbols = symbols,
      paytable = paytable[match(required_rules(), paytable$rule), ],
      stake = as.numeric(stake),
      reels = as.integer(reels)
    ),
    class = "slot_machine"
  )
}

#' @export
print.slot_machine <- function(x, ...) {
  summary <- theoretical_summary(x)
  cat("Slot machine with", x$reels, "reels and", nrow(x$symbols), "symbols\n")
  cat(sprintf("Stake: EUR %.2f | Theoretical RTP: %.6f%%\n", x$stake, 100 * summary$rtp))
  invisible(x)
}
