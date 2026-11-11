#' Print a Delphi data object
#'
#' @param x A `delphi_data` object.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @export
print.delphi_data <- function(x, ...) {
  d <- x$data
  rounds <- sort(unique(d$round))
  items <- x$items
  item_txt <- if (length(items) > 6L) {
    paste0(paste(utils::head(items, 5L), collapse = ", "), ", ..., ", items[length(items)])
  } else {
    paste(items, collapse = ", ")
  }
  ind_txt <- paste0(
    names(x$scales), " (", vapply(x$scales, scale_label, character(1)), ")",
    collapse = ", "
  )
  cat("<delphi_data>\n")
  if (obj_linked(x)) {
    cat("  Experts:    ", length(unique(d$expert)), "\n", sep = "")
  } else {
    per_round <- tapply(d$expert, d$round, function(e) length(unique(e)))
    cat("  Experts:    ", paste0(per_round, " (round ", names(per_round), ")", collapse = ", "),
        "; not linked across rounds\n", sep = "")
  }
  cat("  Rounds:     ", length(rounds), " (", paste(rounds, collapse = ", "), ")\n", sep = "")
  cat("  Items:      ", length(items), " (", item_txt, ")\n", sep = "")
  cat("  Indicators: ", ind_txt, "\n", sep = "")
  cat("  Ratings:    ", sum(!is.na(d$value)), " (", sum(is.na(d$value)), " missing)\n", sep = "")
  cat("Use summary() for descriptive statistics.\n")
  invisible(x)
}


#' Summarise a Delphi data object
#'
#' @description
#' Provides an overview of the panel and, for each indicator, a compact table of
#' item medians and IQRs by round. Items that reach consensus under the IQR
#' rule of [delphi_consensus()] are marked with `*`.
#'
#' @param object A `delphi_data` object.
#' @param type Quantile algorithm, see [delphi_describe()].
#' @param threshold,relative_to Consensus rule, see [delphi_consensus()].
#' @param ... Ignored.
#'
#' @return An object of class `summary.delphi_data`: a list with the panel
#'   table (`panel`, see [delphi_panel()]), the full descriptive table
#'   (`describe`, see [delphi_describe()]), the consensus table
#'   (`consensus`, see [delphi_consensus()]) and the scales (`scales`).
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' s <- summary(x)
#' s
#' s$describe
#' @export
summary.delphi_data <- function(object, type = 7, threshold = 0.20,
                                relative_to = c("points", "range"), ...) {
  relative_to <- match.arg(relative_to)
  structure(
    list(
      panel = delphi_panel(object),
      describe = delphi_describe(object, type = type, relative_to = relative_to),
      consensus = delphi_consensus(object, threshold = threshold,
                                   relative_to = relative_to, type = type),
      scales = object$scales,
      items = object$items
    ),
    class = "summary.delphi_data"
  )
}

#' @export
print.summary.delphi_data <- function(x, digits = 2, ...) {
  cat("Delphi study summary\n\n")
  cat("Panel\n")
  p <- x$panel
  linked <- !identical(attr(p, "linked"), FALSE)
  if (linked) {
    p$retention <- paste0(round(100 * p$retention), "%")
    print(p, row.names = FALSE)
  } else {
    print(p[c("round", "respondents")], row.names = FALSE)
    cat("Experts are not linked across rounds: retention is not computed.\n")
  }

  d <- x$describe
  for (i in names(x$scales)) {
    cat("\nIndicator: ", i, " (scale ", scale_label(x$scales[[i]]), ")\n", sep = "")
    cat("Median [IQR] by round (* = consensus)\n")
    di <- d[d$indicator == i, , drop = FALSE]
    ci <- x$consensus[x$consensus$indicator == i, , drop = FALSE]
    rounds <- sort(unique(di$round))
    items <- x$items[x$items %in% di$item]
    tab <- matrix("", nrow = length(items), ncol = length(rounds),
                  dimnames = list(items, paste0("Round ", rounds)))
    for (k in seq_len(nrow(di))) {
      tab[di$item[k], paste0("Round ", di$round[k])] <- paste0(
        format(round(di$median[k], digits)), " [",
        format(round(di$iqr[k], digits)), "]",
        if (isTRUE(ci$consensus[k])) " *" else ""
      )
    }
    print(noquote(tab))
  }
  rule <- attr(x$consensus, "rule")
  cat("\nConsensus rule: IQR <= ", format(100 * rule$threshold), "% of the scale.\n", sep = "")
  cat("Full tables: delphi_describe(x), delphi_consensus(x).\n")
  invisible(x)
}


#' Convert a Delphi data object to a data frame
#'
#' @description
#' `as.data.frame()` returns the ratings in long format, one row per
#' expert, round, indicator and item. [delphi_wide()] returns them in the
#' wide DelphiR layout.
#'
#' @param x A `delphi_data` object.
#' @param row.names,optional Ignored, kept for compatibility with the
#'   generic.
#' @param ... Ignored.
#' @return A data frame with columns `expert`, `round`, `indicator`, `item`
#'   and `value`.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' head(as.data.frame(x))
#' @export
as.data.frame.delphi_data <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$data
}


#' Ratings in wide format
#'
#' @description
#' Returns the ratings in the DelphiR wide layout, with one row per expert,
#' round and indicator, and one column per item.
#'
#' @param x A `delphi_data` object.
#' @param round Optional round number(s) to keep. `NULL` keeps all rounds.
#' @param indicator Optional indicator label(s) to keep. `NULL` keeps all.
#' @return A data frame with columns `expert`, `round`, `indicator` and one
#'   column per item.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_wide(x, round = 1, indicator = "impact")
#' @export
delphi_wide <- function(x, round = NULL, indicator = NULL) {
  assert_delphi_data(x)
  long <- subset_long(x, round = round, indicator = indicator)
  keys <- unique(long[c("expert", "round", "indicator")])
  keys <- keys[order(match(keys$indicator, names(x$scales)), keys$round, keys$expert), , drop = FALSE]
  key_long <- paste(long$expert, long$round, long$indicator, sep = "\r")
  key_wide <- paste(keys$expert, keys$round, keys$indicator, sep = "\r")
  out <- keys
  for (i in x$items[x$items %in% long$item]) {
    sel <- long$item == i
    out[[i]] <- long$value[sel][match(key_wide, key_long[sel])]
  }
  rownames(out) <- NULL
  out
}
