#' Descriptive statistics of a Delphi study
#'
#' @description
#' Computes, for every item, round and indicator, the number of ratings and
#' the usual Delphi summaries: mean, standard deviation, median, quartiles,
#' interquartile range (IQR), range and coefficient of variation.
#'
#' @param x A `delphi_data` object.
#' @param round,indicator,items Optional subsets: round numbers, indicator
#'   labels and item names to keep. `NULL` keeps all.
#' @param type Quantile algorithm passed to [stats::quantile()]. The default
#'   `7` is R's default; use `6` to match SPSS and Minitab, which many Delphi
#'   studies report.
#' @param relative_to How the relative IQR (`iqr_rel`) is computed:
#'   `"points"` (default) divides the IQR by the number of points of the
#'   scale, `max - min + 1`; `"range"` divides it by `max - min`. See
#'   [delphi_consensus()].
#'
#' @details
#' `iqr_rel` is the IQR as a share of the rating scale, so that dispersion
#' can be compared between indicators rated on different scales (for example
#' from 1 to 10 and from 1 to 100). `cv` is the standard deviation divided by the mean.
#'
#' @return A data frame of class `delphi_describe` with one row per
#'   indicator, round and item and columns `indicator`, `round`, `item`,
#'   `n`, `missing`, `mean`, `sd`, `median`, `q1`, `q3`, `iqr`, `iqr_rel`,
#'   `min`, `max` and `cv`.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' d <- delphi_describe(x)
#' head(d)
#'
#' # Only the impact ratings of round 2, with SPSS-style quartiles
#' delphi_describe(x, round = 2, indicator = "impact", type = 6)
#' @export
delphi_describe <- function(x, round = NULL, indicator = NULL, items = NULL,
                            type = 7, relative_to = c("points", "range")) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  long <- subset_long(x, round = round, indicator = indicator, items = items)

  groups <- unique(long[c("indicator", "round", "item")])
  rows <- lapply(seq_len(nrow(groups)), function(g) {
    sel <- long$indicator == groups$indicator[g] &
      long$round == groups$round[g] &
      long$item == groups$item[g]
    v <- long$value[sel]
    s <- x$scales[[groups$indicator[g]]]
    describe_values(v, width = scale_width(s, relative_to), type = type)
  })
  stats_df <- do.call(rbind, rows)

  out <- cbind(groups, stats_df)
  rownames(out) <- NULL
  class(out) <- c("delphi_describe", "data.frame")
  out
}

describe_values <- function(v, width, type) {
  n_missing <- sum(is.na(v))
  v <- v[!is.na(v)]
  n <- length(v)
  if (n == 0L) {
    na <- NA_real_
    return(data.frame(
      n = 0L, missing = n_missing, mean = na, sd = na, median = na,
      q1 = na, q3 = na, iqr = na, iqr_rel = na, min = na, max = na, cv = na
    ))
  }
  q <- stats::quantile(v, probs = c(0.25, 0.5, 0.75), type = type, names = FALSE)
  m <- mean(v)
  s <- if (n > 1L) stats::sd(v) else NA_real_
  data.frame(
    n = n,
    missing = n_missing,
    mean = m,
    sd = s,
    median = q[2L],
    q1 = q[1L],
    q3 = q[3L],
    iqr = q[3L] - q[1L],
    iqr_rel = (q[3L] - q[1L]) / width,
    min = min(v),
    max = max(v),
    cv = if (m != 0) s / m else NA_real_
  )
}

subset_long <- function(x, round = NULL, indicator = NULL, items = NULL) {
  long <- x$data
  if (!is.null(round)) {
    unknown <- setdiff(round, unique(long$round))
    if (length(unknown) > 0L) {
      stop_dr("Round(s) not in the data: ", show_values(unknown), ".")
    }
    long <- long[long$round %in% round, , drop = FALSE]
  }
  if (!is.null(indicator)) {
    unknown <- setdiff(indicator, unique(long$indicator))
    if (length(unknown) > 0L) {
      stop_dr("Indicator(s) not in the data: ", show_values(unknown), ".")
    }
    long <- long[long$indicator %in% indicator, , drop = FALSE]
  }
  if (!is.null(items)) {
    unknown <- setdiff(items, x$items)
    if (length(unknown) > 0L) {
      stop_dr("Item(s) not in the data: ", show_values(unknown), ".")
    }
    long <- long[long$item %in% items, , drop = FALSE]
  }
  if (nrow(long) == 0L) {
    stop_dr("No ratings left after subsetting.")
  }
  long
}

#' @export
print.delphi_describe <- function(x, digits = 2, ...) {
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  print(df, row.names = FALSE, ...)
  invisible(x)
}


#' Panel participation across rounds
#'
#' @description
#' Counts the experts who answered each round and how many of them are
#' retained from round to round. An expert counts as a respondent in a round
#' if they gave at least one rating, on any item and indicator.
#'
#' @param x A `delphi_data` object.
#'
#' @return A data frame with one row per round and columns:
#' * `round`;
#' * `respondents`: experts with at least one rating;
#' * `retained`: respondents who also answered the previous round;
#' * `dropped`: respondents of the previous round who did not answer;
#' * `joined`: respondents who did not answer the previous round;
#' * `retention`: share of first-round respondents still answering.
#'
#' When the experts are not linked across rounds (`linked = FALSE` in
#' [delphi_data()]), only the number of respondents can be computed; the
#' other columns are `NA`.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_panel(x)
#' @export
delphi_panel <- function(x) {
  assert_delphi_data(x)
  long <- x$data[!is.na(x$data$value), , drop = FALSE]
  rounds <- sort(unique(x$data$round))
  resp <- lapply(rounds, function(r) unique(long$expert[long$round == r]))
  first <- resp[[1L]]

  rows <- lapply(seq_along(rounds), function(k) {
    now <- resp[[k]]
    prev <- if (k > 1L) resp[[k - 1L]] else NULL
    data.frame(
      round = rounds[k],
      respondents = length(now),
      retained = if (k > 1L) length(intersect(now, prev)) else NA_integer_,
      dropped = if (k > 1L) length(setdiff(prev, now)) else NA_integer_,
      joined = if (k > 1L) length(setdiff(now, prev)) else NA_integer_,
      retention = if (length(first) > 0L) length(intersect(now, first)) / length(first) else NA_real_
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  if (!obj_linked(x)) {
    out$retained <- NA_integer_
    out$dropped <- NA_integer_
    out$joined <- NA_integer_
    out$retention <- NA_real_
  }
  attr(out, "linked") <- obj_linked(x)
  out
}
