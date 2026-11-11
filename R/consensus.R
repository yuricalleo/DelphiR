#' Consensus by item, round and indicator
#'
#' @description
#' Applies the interquartile-range (IQR) consensus criterion: an item reaches
#' consensus when the IQR of the expert ratings is at most a given share of
#' the rating scale, 20% by default (von der Gracht, 2012).
#'
#' @param x A `delphi_data` object.
#' @param threshold Largest relative IQR that still counts as consensus, as
#'   a proportion between 0 and 1. Default `0.20`.
#' @param relative_to How the scale is measured: `"points"` (default) uses
#'   the number of scale points, `max - min + 1`; `"range"` uses
#'   `max - min`. See Details.
#' @param round,indicator,items Optional subsets: round numbers, indicator
#'   labels and item names to keep. `NULL` keeps all.
#' @param type Quantile algorithm passed to [stats::quantile()]; see
#'   [delphi_describe()].
#'
#' @details
#' The relative IQR is \eqn{(Q_3 - Q_1) / w}, where \eqn{w} is the width of
#' the scale. With the default `relative_to = "points"`, the 20% threshold
#' gives the cut-offs commonly reported in the literature reviewed by von
#' der Gracht (2012): IQR \eqn{\le 1} on a five-point scale and
#' IQR \eqn{\le 2} on a ten-point scale. With `relative_to = "range"` the
#' cut-offs are slightly stricter (1.8 on a scale from 1 to 10); this choice
#' is better suited to continuous scales, such as a scale from 0 to 100.
#'
#' The rule should be fixed in the study protocol before data collection.
#'
#' @return A data frame of class `delphi_consensus` with one row per
#'   indicator, round and item and columns `indicator`, `round`, `item`,
#'   `n`, `median`, `q1`, `q3`, `iqr`, `iqr_rel`, `iqr_max` (the largest IQR
#'   that counts as consensus on that scale) and `consensus` (`TRUE`,
#'   `FALSE`, or `NA` when there are no ratings). The rule is stored in the
#'   `"rule"` attribute.
#'
#' @references
#' von der Gracht, H. A. (2012). Consensus measurement in Delphi studies:
#' Review and implications for future quality assurance. *Technological
#' Forecasting and Social Change*, 79(8), 1525-1536.
#' \doi{10.1016/j.techfore.2012.04.013}
#'
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' cons <- delphi_consensus(x)
#' cons
#'
#' # Items with consensus in round 2
#' subset(cons, round == 2 & consensus)
#'
#' # A stricter rule: IQR at most 10% of the scale
#' delphi_consensus(x, threshold = 0.10, round = 2)
#' @export
delphi_consensus <- function(x, threshold = 0.20,
                             relative_to = c("points", "range"),
                             round = NULL, indicator = NULL, items = NULL,
                             type = 7) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold) ||
      threshold < 0 || threshold > 1) {
    stop_dr("`threshold` must be a single proportion between 0 and 1, for example 0.20.")
  }

  d <- delphi_describe(x, round = round, indicator = indicator, items = items,
                       type = type, relative_to = relative_to)
  width <- vapply(x$scales, scale_width, numeric(1), relative_to = relative_to)
  iqr_max <- threshold * unname(width[d$indicator])

  # Small tolerance so that, e.g., IQR = 2 on a 10-point scale is consensus
  # despite floating-point error
  tol <- sqrt(.Machine$double.eps)
  out <- data.frame(
    indicator = d$indicator,
    round = d$round,
    item = d$item,
    n = d$n,
    median = d$median,
    q1 = d$q1,
    q3 = d$q3,
    iqr = d$iqr,
    iqr_rel = d$iqr_rel,
    iqr_max = iqr_max,
    consensus = d$iqr <= iqr_max + tol,
    stringsAsFactors = FALSE
  )
  attr(out, "rule") <- list(
    criterion = "iqr",
    threshold = threshold,
    relative_to = relative_to,
    type = type
  )
  class(out) <- c("delphi_consensus", "data.frame")
  out
}

#' @export
print.delphi_consensus <- function(x, digits = 2, ...) {
  if (!all(c("indicator", "round", "item", "consensus") %in% names(x))) {
    # A subset of columns: print as a plain data frame
    df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
    attr(df, "rule") <- NULL
    print(df, ...)
    return(invisible(x))
  }
  rule <- attr(x, "rule")
  if (!is.null(rule)) {
    cat(
      "Consensus rule: IQR <= ", format(100 * rule$threshold), "% of the scale (",
      if (rule$relative_to == "points") "number of points" else "max - min", ")\n\n",
      sep = ""
    )
  }
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  attr(df, "rule") <- NULL
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  print(df, row.names = FALSE, ...)

  groups <- unique(df[c("indicator", "round")])
  cat("\nItems with consensus:\n")
  for (k in seq_len(nrow(groups))) {
    sel <- df$indicator == groups$indicator[k] & df$round == groups$round[k]
    cat("  ", groups$indicator[k], ", round ", groups$round[k], ": ",
        sum(df$consensus[sel], na.rm = TRUE), " of ", sum(sel), "\n", sep = "")
  }
  invisible(x)
}
