#' Item status from consensus and stability
#'
#' @description
#' Combines [delphi_consensus()] and [delphi_stability()] to classify every
#' item at a given round, and flags the items to submit again in the next
#' round.
#'
#' @param x A `delphi_data` object.
#' @param round Round to assess, for each indicator. `NULL` (default) uses
#'   the last round of each indicator. Stability is measured between this
#'   round and the previous one.
#' @param threshold,relative_to Consensus rule, see [delphi_consensus()].
#' @param method,alpha,scheibe,paired Stability rule, see [delphi_stability()].
#' @param type Quantile algorithm; see [delphi_describe()].
#'
#' @details
#' Each item gets one of four statuses:
#'
#' | status | consensus | stable | next round |
#' |---|---|---|---|
#' | `"consensus"` | yes | yes | no |
#' | `"unstable consensus"` | yes | no | yes |
#' | `"stable dissent"` | no | yes | no |
#' | `"open"` | no | no | yes |
#'
#' A stable dissent means that opinions have stopped moving without
#' converging: another round is unlikely to produce consensus, and the
#' disagreement is itself a result to report. When only one round is
#' available, stability cannot be assessed (`stable = NA`); items with
#' consensus are then `"consensus"` and the others `"open"`.
#'
#' @return A data frame of class `delphi_status` with columns `indicator`,
#'   `item`, `round`, `median`, `iqr`, `consensus`, `stable`, `status` and
#'   `next_round`.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' st <- delphi_status(x)
#' st
#'
#' # Items to submit again in the next round
#' subset(st, next_round)
#' @export
delphi_status <- function(x, round = NULL, threshold = 0.20,
                          relative_to = c("points", "range"),
                          method = c("wilcoxon", "scheibe", "both"),
                          alpha = 0.05, scheibe = 0.15, type = 7, paired = NULL) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  method <- match.arg(method)
  if (!is.null(round) && (!is.numeric(round) || length(round) != 1L)) {
    stop_dr("`round` must be a single round number.")
  }

  rows <- list()
  for (ind in names(x$scales)) {
    rnds <- sort(unique(x$data$round[x$data$indicator == ind]))
    if (is.null(round)) {
      r <- max(rnds)
    } else {
      if (!round %in% rnds) {
        next
      }
      r <- round
    }
    cons <- delphi_consensus(x, threshold = threshold, relative_to = relative_to,
                             round = r, indicator = ind, type = type)
    prev <- rnds[rnds < r]
    if (length(prev) > 0L) {
      stab <- delphi_stability(x, method = method, alpha = alpha, scheibe = scheibe,
                               rounds = c(max(prev), r), indicator = ind, type = type,
                               paired = paired)
      stable <- stab$stable[match(cons$item, stab$item)]
    } else {
      stable <- rep(NA, nrow(cons))
    }
    rows[[ind]] <- data.frame(
      indicator = ind,
      item = cons$item,
      round = r,
      median = cons$median,
      iqr = cons$iqr,
      consensus = cons$consensus,
      stable = stable,
      stringsAsFactors = FALSE
    )
  }
  if (length(rows) == 0L) {
    stop_dr("Round ", round, " is not in the data.")
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  st <- ifelse(
    is.na(out$stable),
    ifelse(out$consensus %in% TRUE, "consensus", "open"),
    ifelse(out$consensus %in% TRUE,
           ifelse(out$stable, "consensus", "unstable consensus"),
           ifelse(out$stable, "stable dissent", "open"))
  )
  out$status <- st
  out$next_round <- st %in% c("open", "unstable consensus")
  attr(out, "rule") <- list(threshold = threshold, relative_to = relative_to,
                            method = method, alpha = alpha, scheibe = scheibe,
                            paired = if (is.null(paired)) obj_linked(x) else paired)
  class(out) <- c("delphi_status", "data.frame")
  out
}

#' @export
print.delphi_status <- function(x, digits = 2, ...) {
  if (!all(c("indicator", "item", "round", "status", "next_round") %in% names(x))) {
    # A subset of columns: print as a plain data frame
    df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
    attr(df, "rule") <- NULL
    print(df, ...)
    return(invisible(x))
  }
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  attr(df, "rule") <- NULL
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  print(df, row.names = FALSE, ...)

  levels <- c("consensus", "unstable consensus", "stable dissent", "open")
  for (ind in unique(df$indicator)) {
    di <- df[df$indicator == ind, , drop = FALSE]
    counts <- table(factor(di$status, levels = levels))
    cat("\n", ind, ", round ", di$round[1L], ": ",
        paste0(as.numeric(counts), " ", names(counts), collapse = ", "),
        "\n  Items for the next round: ",
        if (any(di$next_round)) paste(di$item[di$next_round], collapse = ", ") else "none",
        "\n", sep = "")
  }
  invisible(x)
}
