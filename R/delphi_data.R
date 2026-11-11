#' Create a Delphi data object
#'
#' @description
#' Converts expert ratings stored in the DelphiR wide layout (one row per
#' expert, one column per item) into a validated `delphi_data` object.
#' Ratings are checked to be numeric, to lie inside the rating scale and to
#' be unique for each expert, round, indicator and item.
#'
#' @param data A data frame (or tibble) in wide layout.
#' @param expert_col Name of the column with the expert identifiers. Rows
#'   without an identifier, such as summary rows with medians or quartiles
#'   added below the data, are ignored with a warning. If `NULL`, experts are
#'   numbered by row within the round (`"R1-EXP01"`, `"R1-EXP02"`, ...); this
#'   is only allowed when `data` holds a single round and a single indicator,
#'   and the experts are then treated as not linked across rounds.
#' @param round Round number used when `round_col` is `NULL`.
#' @param round_col Name of the column with the round number, if `data`
#'   stacks several rounds.
#' @param indicator Indicator label used when `indicator_col` is `NULL`, for
#'   example `"impact"`.
#' @param indicator_col Name of the column with the indicator label, if
#'   `data` stacks several indicators.
#' @param items Names of the item columns. By default, all columns other
#'   than `expert_col`, `round_col` and `indicator_col`.
#' @param item_labels Optional full statements of the items: a character
#'   vector named by item, or an unnamed vector with one label per item.
#'   Labels are used in reports.
#' @param scale Rating scale: either `c(min, max)` for all indicators, or a
#'   named list with one `c(min, max)` per indicator, such as
#'   `list(impact = c(1, 10), plausibility = c(1, 100))`.
#' @param linked Whether the expert identifiers denote the same person in
#'   every round. Set `linked = FALSE` when they do not, for example when the
#'   rounds were collected with separate questionnaires and the identifiers
#'   are response numbers of each questionnaire. Unlinked panels are analysed
#'   without individual-level comparisons: retention is not computed and
#'   stability is assessed on the distributions of the two rounds (see
#'   [delphi_stability()]).
#' @param out_of_scale What to do with ratings outside the scale: `"error"`
#'   (default) stops with a list of the offending ratings, `"na"` replaces
#'   them with `NA` and warns.
#'
#' @details
#' Empty cells are read as missing ratings (item non-response). Item columns
#' stored as text are converted to numbers; a decimal comma (`"7,5"`) is
#' accepted.
#'
#' @return An object of class `delphi_data`: a list with elements
#' * `data`: long data frame with columns `expert`, `round`, `indicator`,
#'   `item` and `value`;
#' * `items`: item names, in their original order;
#' * `scales`: named list with the scale of each indicator;
#' * `labels`: full item statements, named by item (`NA` when not given);
#' * `linked`: whether experts are linked across rounds;
#' * `comments`: the comments of the experts, when added with
#'   [delphi_add_comments()] or read with [read_delphi()].
#'
#' @seealso [read_delphi()] to import from a file, [delphi_bind()] to combine
#'   rounds or indicators.
#'
#' @examples
#' # One round, one indicator: rows are experts, columns are items
#' r1 <- data.frame(
#'   expert = c("A", "B", "C", "D"),
#'   E1 = c(7, 8, 6, 9),
#'   E2 = c(3, 5, 4, NA)
#' )
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact",
#'                  scale = c(1, 10))
#' x
#'
#' # Several rounds and indicators stacked in one table
#' x <- delphi_data(delphi_example,
#'                  expert_col = "expert",
#'                  round_col = "round",
#'                  indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10),
#'                               plausibility = c(1, 100)))
#' summary(x)
#' @export
delphi_data <- function(data,
                        expert_col = NULL,
                        round = 1L,
                        round_col = NULL,
                        indicator = "score",
                        indicator_col = NULL,
                        items = NULL,
                        item_labels = NULL,
                        scale = c(1, 10),
                        linked = TRUE,
                        out_of_scale = c("error", "na")) {
  out_of_scale <- match.arg(out_of_scale)
  if (!is.logical(linked) || length(linked) != 1L || is.na(linked)) {
    stop_dr("`linked` must be TRUE or FALSE.")
  }

  if (!is.data.frame(data)) {
    stop_dr("`data` must be a data frame.")
  }
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  if (nrow(data) == 0L) {
    stop_dr("`data` has no rows.")
  }
  nms <- names(data)

  check_col <- function(col, arg) {
    if (is.null(col)) {
      return(invisible(NULL))
    }
    if (!is_string(col)) {
      stop_dr("`", arg, "` must be a single column name.")
    }
    if (!col %in% nms) {
      stop_dr("`", arg, "`: column '", col, "' not found in `data`.")
    }
    invisible(NULL)
  }
  check_col(expert_col, "expert_col")
  check_col(round_col, "round_col")
  check_col(indicator_col, "indicator_col")

  id_cols <- c(expert_col, round_col, indicator_col)
  if (anyDuplicated(id_cols)) {
    stop_dr("`expert_col`, `round_col` and `indicator_col` must be different columns.")
  }

  # Rows without an expert identifier (e.g. summary rows)
  if (!is.null(expert_col)) {
    id <- trimws(as.character(data[[expert_col]]))
    no_id <- is.na(id) | !nzchar(id)
    if (all(no_id)) {
      stop_dr("Column '", expert_col, "' contains no expert identifiers.")
    }
    if (any(no_id)) {
      warn_dr(
        sum(no_id), " row(s) without an expert identifier were ignored ",
        "(for example summary rows with medians or quartiles)."
      )
      data <- data[!no_id, , drop = FALSE]
    }
  }

  # Items
  if (is.null(items)) {
    items <- setdiff(nms, id_cols)
  } else {
    if (!is.character(items) || anyNA(items)) {
      stop_dr("`items` must be a character vector of column names.")
    }
    unknown <- setdiff(items, nms)
    if (length(unknown) > 0L) {
      stop_dr("Item column(s) not found in `data`: ", show_values(unknown), ".")
    }
    if (length(intersect(items, id_cols)) > 0L) {
      stop_dr("`items` cannot include the expert, round or indicator column.")
    }
    items <- unique(items)
  }
  if (length(items) == 0L) {
    stop_dr("No item columns found in `data`.")
  }

  # Rounds
  if (is.null(round_col)) {
    if (!is.numeric(round) || length(round) != 1L || !is_whole(round) || round < 1) {
      stop_dr("`round` must be a single positive whole number.")
    }
    rnd <- rep(as.integer(round), nrow(data))
  } else {
    rnd <- data[[round_col]]
    if (is.character(rnd) || is.factor(rnd)) {
      rnd <- suppressWarnings(as.numeric(as.character(rnd)))
    }
    if (!is.numeric(rnd) || any(!is_whole(rnd)) || any(rnd < 1)) {
      stop_dr("Column '", round_col, "' must contain positive whole round numbers (1, 2, ...).")
    }
    rnd <- as.integer(rnd)
  }

  # Indicators
  if (is.null(indicator_col)) {
    if (!is_string(indicator)) {
      stop_dr("`indicator` must be a single non-empty string.")
    }
    ind <- rep(indicator, nrow(data))
  } else {
    ind <- trimws(as.character(data[[indicator_col]]))
    if (anyNA(ind) || any(!nzchar(ind))) {
      stop_dr("Column '", indicator_col, "' contains empty indicator labels.")
    }
  }

  # Experts
  if (is.null(expert_col)) {
    if (!is.null(round_col) || !is.null(indicator_col)) {
      stop_dr(
        "`expert_col` is required when `data` stacks several rounds or ",
        "indicators, so that each expert can be followed across them."
      )
    }
    width <- max(2L, nchar(nrow(data)))
    expert <- sprintf(paste0("R%d-EXP%0", width, "d"), rnd[1L], seq_len(nrow(data)))
    linked <- FALSE
  } else {
    expert <- trimws(as.character(data[[expert_col]]))
  }

  # Long table
  values <- lapply(items, function(i) as_rating(data[[i]], i))
  long <- data.frame(
    expert = rep(expert, times = length(items)),
    round = rep(rnd, times = length(items)),
    indicator = rep(ind, times = length(items)),
    item = rep(items, each = nrow(data)),
    value = unlist(values, use.names = FALSE),
    stringsAsFactors = FALSE
  )

  scales <- resolve_scales(scale, unique(ind))
  long <- check_scale(long, scales, out_of_scale)

  new_delphi_data(long, items = items, scales = scales,
                  labels = resolve_labels(item_labels, items), linked = linked)
}

resolve_labels <- function(item_labels, items) {
  out <- stats::setNames(rep(NA_character_, length(items)), items)
  if (is.null(item_labels)) {
    return(out)
  }
  if (!is.character(item_labels)) {
    stop_dr("`item_labels` must be a character vector.")
  }
  if (is.null(names(item_labels))) {
    if (length(item_labels) != length(items)) {
      stop_dr("Unnamed `item_labels` must have one label per item (", length(items), ").")
    }
    names(item_labels) <- items
  }
  unknown <- setdiff(names(item_labels), items)
  if (length(unknown) > 0L) {
    stop_dr("`item_labels` refers to unknown item(s): ", show_values(unknown), ".")
  }
  out[names(item_labels)] <- item_labels
  out
}


# Constructor and validator (internal)
new_delphi_data <- function(long, items, scales, labels = NULL, linked = TRUE,
                            comments = NULL) {
  if (is.null(labels)) {
    labels <- stats::setNames(rep(NA_character_, length(items)), items)
  }
  long$item <- as.character(long$item)
  ord <- order(
    match(long$indicator, names(scales)),
    long$round,
    match(long$item, items),
    long$expert
  )
  long <- long[ord, c("expert", "round", "indicator", "item", "value"), drop = FALSE]
  rownames(long) <- NULL
  check_duplicates(long)
  out <- list(data = long, items = items, scales = scales,
              labels = labels[items], linked = linked)
  if (!is.null(comments) && nrow(comments) > 0L) {
    out$comments <- sort_comments(comments, items)
  }
  structure(out, class = "delphi_data")
}

check_duplicates <- function(long) {
  key <- long[c("expert", "round", "indicator", "item")]
  dup <- duplicated(key)
  if (any(dup)) {
    d <- long[dup, , drop = FALSE][1L, ]
    stop_dr(
      "Expert '", d$expert, "' has more than one rating for item '", d$item,
      "' (round ", d$round, ", indicator '", d$indicator, "'). ",
      "Each expert must appear once per round and indicator."
    )
  }
  invisible(TRUE)
}

check_scale <- function(long, scales, out_of_scale) {
  lo <- vapply(scales, `[`, numeric(1), 1L)[long$indicator]
  hi <- vapply(scales, `[`, numeric(1), 2L)[long$indicator]
  bad <- !is.na(long$value) & (long$value < lo | long$value > hi)
  if (!any(bad)) {
    return(long)
  }
  b <- long[bad, , drop = FALSE]
  desc <- sprintf(
    "%s/%s (expert %s, round %d, %s)",
    b$item, format(b$value), b$expert, b$round, b$indicator
  )
  msg <- paste0(
    sum(bad), " rating(s) outside the scale: ",
    paste(utils::head(desc, 5L), collapse = "; "),
    if (sum(bad) > 5L) "; ..." else ""
  )
  if (out_of_scale == "error") {
    stop_dr(msg, ". Check the data or the `scale` argument.")
  }
  warn_dr(msg, ". They have been set to NA.")
  long$value[bad] <- NA_real_
  long
}


#' Check whether an object is a Delphi data object
#'
#' @param x Any R object.
#' @return `TRUE` if `x` inherits from `delphi_data`, `FALSE` otherwise.
#' @examples
#' is_delphi_data(delphi_example)
#' @export
is_delphi_data <- function(x) {
  inherits(x, "delphi_data")
}

assert_delphi_data <- function(x) {
  if (!is_delphi_data(x)) {
    stop_dr("`x` must be a `delphi_data` object; create one with delphi_data() or read_delphi().")
  }
  invisible(x)
}


#' Combine Delphi data objects
#'
#' @description
#' Combines `delphi_data` objects that hold different rounds, different
#' indicators or both, for example one table per round of the same study.
#'
#' @param ... `delphi_data` objects, or a single list of them.
#'
#' @details
#' Experts are matched by their identifier, so the same expert must have the
#' same identifier in every table. If any of the objects is not linked
#' (`linked = FALSE` in [delphi_data()]), the combined object is not linked
#' either. An indicator that appears in several
#' objects must have the same scale in all of them. Items are kept in order
#' of first appearance.
#'
#' @return A `delphi_data` object.
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(4, 8, 6), E2 = c(2, 9, 5))
#' r2 <- data.frame(expert = c("A", "B", "C"), E1 = c(6, 7, 6), E2 = c(4, 7, 5))
#' x <- delphi_bind(
#'   delphi_data(r1, expert_col = "expert", round = 1),
#'   delphi_data(r2, expert_col = "expert", round = 2)
#' )
#' delphi_panel(x)
#' @export
delphi_bind <- function(...) {
  objs <- list(...)
  if (length(objs) == 1L && is.list(objs[[1L]]) && !is_delphi_data(objs[[1L]])) {
    objs <- objs[[1L]]
  }
  if (length(objs) == 0L) {
    stop_dr("Nothing to combine.")
  }
  ok <- vapply(objs, is_delphi_data, logical(1))
  if (!all(ok)) {
    stop_dr("All arguments to delphi_bind() must be `delphi_data` objects.")
  }

  scales <- list()
  for (o in objs) {
    for (i in names(o$scales)) {
      if (is.null(scales[[i]])) {
        scales[[i]] <- o$scales[[i]]
      } else if (!isTRUE(all.equal(scales[[i]], o$scales[[i]]))) {
        stop_dr(
          "Indicator '", i, "' has different scales in the objects to combine (",
          scale_label(scales[[i]]), " and ", scale_label(o$scales[[i]]), ")."
        )
      }
    }
  }
  items <- unique(unlist(lapply(objs, `[[`, "items"), use.names = FALSE))
  labels <- stats::setNames(rep(NA_character_, length(items)), items)
  for (o in objs) {
    lab <- obj_labels(o)
    fill <- is.na(labels[names(lab)]) & !is.na(lab)
    labels[names(lab)[fill]] <- lab[fill]
  }
  linked <- all(vapply(objs, obj_linked, logical(1)))
  long <- do.call(rbind, lapply(objs, `[[`, "data"))
  comments <- do.call(rbind, lapply(objs, obj_comments))
  comments <- comments[!duplicated(comments[c("expert", "round", "item", "indicator", "comment")]), ,
                       drop = FALSE]
  new_delphi_data(long, items = items, scales = scales, labels = labels,
                  linked = linked, comments = comments)
}


# Accessors robust to objects created by earlier development versions
obj_linked <- function(x) {
  if (is.null(x$linked)) TRUE else isTRUE(x$linked)
}

obj_labels <- function(x) {
  if (is.null(x$labels)) {
    stats::setNames(rep(NA_character_, length(x$items)), x$items)
  } else {
    x$labels
  }
}
