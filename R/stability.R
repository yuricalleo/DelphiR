#' Stability of ratings between rounds
#'
#' @description
#' Measures, for every item and indicator, how much the ratings change
#' between consecutive rounds, and tests whether they are stable. Two
#' stability criteria are available:
#'
#' * Wilcoxon (default): a Wilcoxon test comparing the two rounds. With
#'   linked experts it is the paired signed-rank test on the experts who
#'   answered both rounds; otherwise it is the rank-sum (Mann-Whitney) test
#'   on the two independent samples. The item is stable when the test is not
#'   significant (`p_value >= alpha`).
#' * Scheibe: the 15% change criterion of Scheibe, Skutsch and Schofer
#'   (1975). The item is stable when the net change between the two rating
#'   distributions is at most `scheibe` (15% by default).
#'
#' @param x A `delphi_data` object with at least two rounds.
#' @param method Stability criterion used for the `stable` column:
#'   `"wilcoxon"`, `"scheibe"` or `"both"` (stable only if both criteria
#'   agree). Both criteria are always reported.
#' @param alpha Significance level of the Wilcoxon test. Default `0.05`.
#' @param scheibe Largest share of net change that still counts as stable
#'   under the Scheibe criterion. Default `0.15`.
#' @param rounds Optional round numbers to compare. Consecutive rounds among
#'   them are compared (for example `c(1, 3)` compares round 1 with round
#'   3). `NULL` compares all consecutive rounds.
#' @param indicator,items Optional subsets of indicators and items.
#' @param bins Number of classes used to build the rating distributions for
#'   the Scheibe criterion on long scales. Scales with up to `bins` points
#'   use one class per scale point; longer scales are split into `bins`
#'   equal classes (for example 1 to 10, 11 to 20, ..., 91 to 100). Default
#'   `10`.
#' @param type Quantile algorithm for medians and IQRs; see
#'   [delphi_describe()].
#' @param exact Passed to [stats::wilcox.test()]. The default `FALSE` uses
#'   the normal approximation with continuity correction, which handles the
#'   ties and zero differences that are common with rating scales.
#' @param paired Whether to compare the rounds expert by expert. By default
#'   (`NULL`) the comparison is paired when the experts are linked across
#'   rounds (`linked = TRUE` in [delphi_data()]) and unpaired otherwise.
#'   `paired = TRUE` is not allowed for unlinked experts.
#'
#' @details
#' Medians and IQRs are always computed on all experts who answered each
#' round (`n_from`, `n_to`), as in [delphi_describe()].
#'
#' In the paired comparison, the test, the share of experts who changed
#' their rating (`changed`) and the Scheibe change are computed on the
#' experts who answered the item in both rounds (`n_paired`), so that
#' drop-outs are not mistaken for changes of opinion. The Scheibe change is
#' half the sum of the absolute differences between the frequencies of the
#' two rating distributions, divided by the number of paired experts: the
#' share of experts who would have to move to turn one distribution into the
#' other.
#'
#' In the unpaired comparison, used when the same expert cannot be
#' identified in both rounds, the test is the Wilcoxon rank-sum test and the
#' Scheibe change is half the sum of the absolute differences between the
#' relative frequencies of the two distributions; `n_paired` and `changed`
#' are `NA`. Since the two samples may include different experts, a
#' difference between rounds reflects both changes of opinion and changes in
#' the composition of the panel.
#'
#' When the two rounds contain exactly the same ratings, the item is stable
#' under both criteria (`p_value = 1`, Scheibe change `0`).
#'
#' @return A data frame of class `delphi_stability` with one row per
#'   indicator, item and pair of rounds, and columns `indicator`, `item`,
#'   `round_from`, `round_to`, `n_from`, `n_to`, `n_paired`, `median_from`,
#'   `median_to`,
#'   `median_change`, `iqr_from`, `iqr_to`, `iqr_change`, `changed`,
#'   `p_value`, `scheibe_change`, `stable_wilcoxon`, `stable_scheibe` and
#'   `stable`. The settings are stored in the `"rule"` attribute.
#'
#' @references
#' Scheibe, M., Skutsch, M. and Schofer, J. (1975). Experiments in Delphi
#' methodology. In H. A. Linstone and M. Turoff (Eds.), *The Delphi Method:
#' Techniques and Applications* (pp. 262-287). Reading, MA: Addison-Wesley.
#'
#' @seealso [delphi_status()] to combine stability with consensus.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_stability(x)
#'
#' # Scheibe criterion only, on the impact ratings
#' delphi_stability(x, method = "scheibe", indicator = "impact")
#' @export
delphi_stability <- function(x, method = c("wilcoxon", "scheibe", "both"),
                             alpha = 0.05, scheibe = 0.15, rounds = NULL,
                             indicator = NULL, items = NULL, bins = 10,
                             type = 7, exact = FALSE, paired = NULL) {
  assert_delphi_data(x)
  method <- match.arg(method)
  if (is.null(paired)) {
    paired <- obj_linked(x)
  }
  if (!is.logical(paired) || length(paired) != 1L || is.na(paired)) {
    stop_dr("`paired` must be TRUE, FALSE or NULL.")
  }
  if (paired && !obj_linked(x)) {
    stop_dr(
      "The experts are not linked across rounds, so a paired comparison is not ",
      "possible. Use `paired = FALSE` (the default for unlinked data)."
    )
  }
  check_prop(alpha, "alpha")
  check_prop(scheibe, "scheibe")
  if (!is.numeric(bins) || length(bins) != 1L || !is_whole(bins) || bins < 2) {
    stop_dr("`bins` must be a whole number of at least 2.")
  }

  long <- subset_long(x, round = rounds, indicator = indicator, items = items)
  rows <- list()
  for (ind in unique(long$indicator)) {
    li <- long[long$indicator == ind, , drop = FALSE]
    rnds <- sort(unique(li$round))
    if (length(rnds) < 2L) {
      next
    }
    breaks <- scheibe_breaks(x$scales[[ind]], bins)
    for (k in seq_len(length(rnds) - 1L)) {
      r0 <- rnds[k]
      r1 <- rnds[k + 1L]
      for (it in x$items[x$items %in% li$item]) {
        a <- li[li$round == r0 & li$item == it, c("expert", "value")]
        b <- li[li$round == r1 & li$item == it, c("expert", "value")]
        rows[[length(rows) + 1L]] <- stability_row(
          a, b, ind, it, r0, r1, breaks, type, exact, paired
        )
      }
    }
  }
  if (length(rows) == 0L) {
    stop_dr("Stability needs at least two rounds of the same indicator.")
  }
  out <- do.call(rbind, rows)
  out$stable_wilcoxon <- out$p_value >= alpha
  tol <- sqrt(.Machine$double.eps)
  out$stable_scheibe <- out$scheibe_change <= scheibe + tol
  out$stable <- switch(method,
    wilcoxon = out$stable_wilcoxon,
    scheibe = out$stable_scheibe,
    both = out$stable_wilcoxon & out$stable_scheibe
  )
  rownames(out) <- NULL
  attr(out, "rule") <- list(method = method, alpha = alpha, scheibe = scheibe,
                            paired = paired)
  class(out) <- c("delphi_stability", "data.frame")
  out
}

stability_row <- function(a, b, ind, it, r0, r1, breaks, type, exact, paired = TRUE) {
  va <- a$value[!is.na(a$value)]
  vb <- b$value[!is.na(b$value)]
  med_iqr <- function(v) {
    if (length(v) == 0L) {
      return(c(NA_real_, NA_real_))
    }
    q <- stats::quantile(v, c(0.25, 0.5, 0.75), type = type, names = FALSE)
    c(q[2L], q[3L] - q[1L])
  }
  ma <- med_iqr(va)
  mb <- med_iqr(vb)

  p <- NA_real_
  changed <- NA_real_
  sch <- NA_real_
  n <- NA_integer_
  freq <- function(v) as.numeric(table(cut(v, breaks, include.lowest = TRUE)))

  if (paired) {
    pr <- merge(a, b, by = "expert", suffixes = c("_from", "_to"))
    pr <- pr[!is.na(pr$value_from) & !is.na(pr$value_to), , drop = FALSE]
    n <- nrow(pr)
    if (n > 0L) {
      d <- pr$value_to - pr$value_from
      changed <- mean(d != 0)
      if (all(d == 0)) {
        p <- 1
      } else {
        p <- suppressWarnings(stats::wilcox.test(
          pr$value_to, pr$value_from,
          paired = TRUE, exact = exact, correct = TRUE
        )$p.value)
      }
      sch <- 0.5 * sum(abs(freq(pr$value_to) - freq(pr$value_from))) / n
    }
  } else if (length(va) > 0L && length(vb) > 0L) {
    if (length(unique(c(va, vb))) == 1L) {
      p <- 1
    } else {
      p <- suppressWarnings(stats::wilcox.test(
        vb, va, paired = FALSE, exact = exact, correct = TRUE
      )$p.value)
    }
    sch <- 0.5 * sum(abs(freq(vb) / length(vb) - freq(va) / length(va)))
  }

  data.frame(
    indicator = ind,
    item = it,
    round_from = r0,
    round_to = r1,
    n_from = length(va),
    n_to = length(vb),
    n_paired = n,
    median_from = ma[1L],
    median_to = mb[1L],
    median_change = mb[1L] - ma[1L],
    iqr_from = ma[2L],
    iqr_to = mb[2L],
    iqr_change = mb[2L] - ma[2L],
    changed = changed,
    p_value = p,
    scheibe_change = sch,
    stringsAsFactors = FALSE
  )
}

# Class limits for the Scheibe distributions: one class per scale point on
# short scales, `bins` equal-width classes on long ones. Limits sit half a
# point outside the scale, so that a 1-100 scale gives the classes 1-10,
# 11-20, ..., 91-100.
scheibe_breaks <- function(s, bins) {
  n_points <- s[2L] - s[1L] + 1
  if (n_points <= bins) {
    seq(s[1L] - 0.5, s[2L] + 0.5, by = 1)
  } else {
    seq(s[1L] - 0.5, s[2L] + 0.5, length.out = bins + 1L)
  }
}

check_prop <- function(v, arg) {
  if (!is.numeric(v) || length(v) != 1L || is.na(v) || v < 0 || v > 1) {
    stop_dr("`", arg, "` must be a single proportion between 0 and 1.")
  }
  invisible(v)
}

#' @export
print.delphi_stability <- function(x, digits = 2, ...) {
  if (!all(c("indicator", "item", "round_from", "round_to", "stable") %in% names(x))) {
    # A subset of columns: print as a plain data frame
    df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
    attr(df, "rule") <- NULL
    print(df, ...)
    return(invisible(x))
  }
  rule <- attr(x, "rule")
  if (!is.null(rule)) {
    test <- if (isFALSE(rule$paired)) "Wilcoxon rank-sum test" else "Wilcoxon signed-rank test"
    crit <- switch(rule$method,
      wilcoxon = paste0(test, ", stable if p >= ", format(rule$alpha)),
      scheibe = paste0("Scheibe et al. (1975), stable if change <= ", format(100 * rule$scheibe), "%"),
      both = paste0("Wilcoxon (p >= ", format(rule$alpha), ") and Scheibe (change <= ",
                    format(100 * rule$scheibe), "%)")
    )
    cat("Stability criterion: ", crit, "\n", sep = "")
    cat(if (isFALSE(rule$paired)) "Unpaired comparison of the two rounds.\n\n" else
      "Paired comparison on the experts who answered both rounds.\n\n")
  }
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  attr(df, "rule") <- NULL
  show <- if (isFALSE(rule$paired)) {
    c("indicator", "item", "round_from", "round_to", "n_from", "n_to",
      "median_from", "median_to", "iqr_from", "iqr_to",
      "p_value", "scheibe_change", "stable")
  } else {
    c("indicator", "item", "round_from", "round_to", "n_paired",
      "median_from", "median_to", "iqr_from", "iqr_to", "changed",
      "p_value", "scheibe_change", "stable")
  }
  df <- df[show]
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  print(df, row.names = FALSE, ...)

  groups <- unique(df[c("indicator", "round_from", "round_to")])
  cat("\nStable items:\n")
  for (k in seq_len(nrow(groups))) {
    sel <- df$indicator == groups$indicator[k] &
      df$round_from == groups$round_from[k] & df$round_to == groups$round_to[k]
    cat("  ", groups$indicator[k], ", round ", groups$round_from[k], " to ",
        groups$round_to[k], ": ", sum(df$stable[sel], na.rm = TRUE), " of ",
        sum(sel), "\n", sep = "")
  }
  cat("All columns: as.data.frame(x).\n")
  invisible(x)
}
