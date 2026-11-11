#' Add expert comments to a Delphi data object
#'
#' @description
#' Attaches the written comments of the experts to a `delphi_data` object,
#' so that each comment can be read next to the rating of its author and
#' summarised by item, round and theme. Comments can be supplied in two
#' layouts:
#'
#' * long (`layout = "long"`, default): one row per comment, with columns
#'   for the expert, the item and the comment, and optionally the round, the
#'   indicator and the themes; this is the layout of the `comments` sheet of
#'   the template created by [delphi_template()];
#' * wide (`layout = "wide"`): one row per expert and one comment column per
#'   item, as exported by many survey platforms.
#'
#' @param x A `delphi_data` object.
#' @param comments A data frame of comments.
#' @param layout `"long"` (default) or `"wide"`; see Description.
#' @param expert_col Name of the column with the expert identifiers, which
#'   must match those used for the ratings of the same round.
#' @param item_col,comment_col For the long layout, names of the columns with
#'   the item code and the text of the comment. Comments with an empty item
#'   are treated as general comments on the questionnaire.
#' @param round_col,indicator_col,theme_col For the long layout, names of the
#'   optional columns with the round, the indicator to which the comment
#'   refers and the themes coded by the researchers. By default, columns
#'   named `round`, `indicator` and `theme` are used when present (the round
#'   column only when `round` is not given).
#' @param round Round of the comments, used when there is no round column.
#'   It can be omitted when `x` holds a single round.
#' @param comment_cols For the wide layout, the comment columns, by name or
#'   position, one per item and in the same order as `items`.
#' @param items For the wide layout, the items to which the comment columns
#'   refer. By default, all the items of `x`, in their order.
#'
#' @details
#' Empty comments are ignored, and spaces and line breaks within a comment
#' are collapsed into single spaces. Comments are matched to the ratings
#' through the expert identifier and the round, also when the experts are not
#' linked across rounds. A comment whose author has no rating in that round
#' is kept, with a warning, but its position relative to the ratings of the
#' panel cannot be determined.
#'
#' Themes are short labels assigned by the researchers after reading the
#' comments, as in a qualitative content analysis, for example
#' `"regulation"` or `"costs"`. Several themes can be assigned to the same
#' comment by separating them with a semicolon (`"regulation; costs"`). The
#' same theme must be written in the same way throughout. Themes are optional
#' and are summarised by [delphi_themes()].
#'
#' Calling the function again adds further comments, for example those of
#' another round. Comments already stored are not duplicated.
#'
#' @return `x`, with the comments stored in the element `comments`: a data
#'   frame with columns `expert`, `round`, `item` (`NA` for general comments),
#'   `indicator` (`NA` when the comment refers to the item as a whole),
#'   `comment` and `theme` (`NA` when not coded).
#' @seealso [delphi_comments()], [delphi_comment_counts()],
#'   [delphi_themes()], [delphi_words()]; [read_delphi()] reads the comments
#'   from a sheet of the same Excel file.
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C", "D"),
#'                  E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#'
#' # Long layout: one row per comment
#' cm <- data.frame(
#'   expert = c("A", "D", "D", "B"),
#'   item = c("E1", "E1", "E2", NA),
#'   comment = c("Depends on public funding.",
#'               "Unlikely without new regulation.",
#'               "The statement is too broad.",
#'               "Clear questionnaire."),
#'   theme = c("funding", "regulation", "wording", NA)
#' )
#' x <- delphi_add_comments(x, cm)
#' delphi_comments(x)
#'
#' # Wide layout: one comment column per item
#' wide <- data.frame(expert = c("A", "C"),
#'                    c_E1 = c("Depends on public funding.", ""),
#'                    c_E2 = c(NA, "Hard to assess."))
#' y <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#' y <- delphi_add_comments(y, wide, layout = "wide",
#'                          comment_cols = c("c_E1", "c_E2"))
#' y$comments
#' @export
delphi_add_comments <- function(x, comments, layout = c("long", "wide"),
                                expert_col = "expert", item_col = "item",
                                comment_col = "comment", round_col = NULL,
                                indicator_col = NULL, theme_col = NULL,
                                round = NULL, comment_cols = NULL, items = NULL) {
  assert_delphi_data(x)
  layout <- match.arg(layout)
  if (!is.data.frame(comments)) {
    stop_dr("`comments` must be a data frame.")
  }
  comments <- as.data.frame(comments, stringsAsFactors = FALSE)
  nms <- names(comments)
  need_col <- function(col, arg) {
    if (!is_string(col)) {
      stop_dr("`", arg, "` must be a single column name.")
    }
    if (!col %in% nms) {
      stop_dr("`", arg, "`: column '", col, "' not found in `comments`.")
    }
    col
  }
  need_col(expert_col, "expert_col")
  n <- nrow(comments)

  if (layout == "long") {
    if (!is.null(comment_cols) || !is.null(items)) {
      stop_dr("`comment_cols` and `items` apply to the wide layout only.")
    }
    need_col(item_col, "item_col")
    need_col(comment_col, "comment_col")
    optional <- function(col, default, arg, use_default = TRUE) {
      if (is.null(col)) {
        return(if (use_default && default %in% nms) default else NULL)
      }
      need_col(col, arg)
    }
    round_col <- optional(round_col, "round", "round_col", use_default = is.null(round))
    indicator_col <- optional(indicator_col, "indicator", "indicator_col")
    theme_col <- optional(theme_col, "theme", "theme_col")
    if (!is.null(round_col) && !is.null(round)) {
      stop_dr("Use either `round` or `round_col`, not both.")
    }
    expert <- comments[[expert_col]]
    item <- comments[[item_col]]
    text <- comments[[comment_col]]
    rnd <- if (is.null(round_col)) NULL else comments[[round_col]]
    ind <- if (is.null(indicator_col)) rep(NA_character_, n) else comments[[indicator_col]]
    theme <- if (is.null(theme_col)) rep(NA_character_, n) else comments[[theme_col]]
  } else {
    if (!is.null(round_col) || !is.null(indicator_col) || !is.null(theme_col)) {
      stop_dr("`round_col`, `indicator_col` and `theme_col` apply to the long layout only.")
    }
    if (is.null(comment_cols)) {
      stop_dr("With `layout = \"wide\"`, give the comment columns with `comment_cols`.")
    }
    if (is.numeric(comment_cols)) {
      if (any(!is_whole(comment_cols)) || any(comment_cols < 1) ||
          any(comment_cols > ncol(comments))) {
        stop_dr("`comment_cols` must be column positions between 1 and ", ncol(comments), ".")
      }
      pos <- as.integer(comment_cols)
    } else if (is.character(comment_cols) && !anyNA(comment_cols)) {
      unknown <- setdiff(comment_cols, nms)
      if (length(unknown) > 0L) {
        stop_dr("Comment column(s) not found in `comments`: ", show_values(unknown), ".")
      }
      pos <- match(comment_cols, nms)
    } else {
      stop_dr("`comment_cols` must be column names or positions.")
    }
    if (is.null(items)) {
      items <- x$items
    } else {
      if (!is.character(items) || anyNA(items)) {
        stop_dr("`items` must be a character vector of item codes.")
      }
      unknown <- setdiff(items, x$items)
      if (length(unknown) > 0L) {
        stop_dr("Item(s) not in the data: ", show_values(unknown), ".")
      }
    }
    if (length(pos) != length(items)) {
      stop_dr(
        length(pos), " comment column(s) were given for ", length(items),
        " item(s); give one comment column per item, in the order of `items`."
      )
    }
    expert <- rep(comments[[expert_col]], times = length(pos))
    item <- rep(items, each = n)
    text <- unlist(lapply(pos, function(j) as.character(comments[[j]])), use.names = FALSE)
    rnd <- NULL
    ind <- rep(NA_character_, length(text))
    theme <- rep(NA_character_, length(text))
  }

  text <- clean_text(text)
  keep <- !is.na(text)
  if (!any(keep)) {
    warn_dr("No comments found in `comments`.")
    return(x)
  }
  expert <- clean_text(expert)[keep]
  item <- clean_text(item)[keep]
  ind <- clean_text(ind)[keep]
  theme <- clean_theme(theme)[keep]
  text <- text[keep]
  if (!is.null(rnd)) {
    rnd <- rnd[keep]
  }

  no_id <- is.na(expert)
  if (all(no_id)) {
    stop_dr("Column '", expert_col, "' contains no expert identifiers for the comments.")
  }
  if (any(no_id)) {
    warn_dr(sum(no_id), " comment(s) without an expert identifier were ignored.")
    expert <- expert[!no_id]
    item <- item[!no_id]
    ind <- ind[!no_id]
    theme <- theme[!no_id]
    text <- text[!no_id]
    if (!is.null(rnd)) rnd <- rnd[!no_id]
  }

  # Rounds
  data_rounds <- sort(unique(x$data$round))
  if (is.null(rnd)) {
    if (is.null(round)) {
      if (length(data_rounds) > 1L) {
        stop_dr(
          "`x` holds several rounds: give the round of the comments with `round`",
          if (layout == "long") " or a round column" else "", "."
        )
      }
      round <- data_rounds
    }
    if (!is.numeric(round) || length(round) != 1L || !is_whole(round) || round < 1) {
      stop_dr("`round` must be a single positive whole number.")
    }
    rnd <- rep(as.integer(round), length(text))
  } else {
    rnd <- suppressWarnings(as.numeric(as.character(rnd)))
    if (anyNA(rnd) || any(!is_whole(rnd)) || any(rnd < 1)) {
      stop_dr("Column '", round_col, "' must contain positive whole round numbers (1, 2, ...) for every comment.")
    }
    rnd <- as.integer(rnd)
  }
  unknown <- setdiff(unique(rnd), data_rounds)
  if (length(unknown) > 0L) {
    stop_dr("Comments refer to round(s) without ratings: ", show_values(unknown), ".")
  }

  # Items and indicators
  unknown <- setdiff(item[!is.na(item)], x$items)
  if (length(unknown) > 0L) {
    stop_dr(
      "Comments refer to unknown item(s): ", show_values(unknown),
      ". Item codes must match those of the ratings."
    )
  }
  unknown <- setdiff(ind[!is.na(ind)], names(x$scales))
  if (length(unknown) > 0L) {
    stop_dr(
      "Comments refer to unknown indicator(s): ", show_values(unknown),
      ". Indicators must be among ", show_values(names(x$scales)), "."
    )
  }

  # Authors without ratings in the same round
  rated <- x$data[!is.na(x$data$value), c("expert", "round")]
  known <- paste(expert, rnd, sep = "\r") %in% paste(rated$expert, rated$round, sep = "\r")
  if (any(!known)) {
    warn_dr(
      sum(!known), " comment(s) come from expert(s) without ratings in the same round (",
      show_values(expert[!known]), "); their position relative to the panel cannot be determined."
    )
  }

  new <- data.frame(
    expert = expert, round = rnd, item = item, indicator = ind,
    comment = text, theme = theme, stringsAsFactors = FALSE
  )
  old <- obj_comments(x)
  all <- rbind(old, new)
  dup <- duplicated(all[c("expert", "round", "item", "indicator", "comment")])
  if (any(dup)) {
    warn_dr(sum(dup), " duplicated comment(s) were not added again.")
  }
  x$comments <- sort_comments(all[!dup, , drop = FALSE], x$items)
  x
}

clean_text <- function(v) {
  v <- trimws(gsub("[[:space:]]+", " ", as.character(v)))
  v[is.na(v) | !nzchar(v)] <- NA_character_
  v
}

# Themes: trimmed, separated by semicolons, empty parts dropped
clean_theme <- function(v) {
  v <- clean_text(v)
  out <- vapply(v, function(s) {
    if (is.na(s)) return(NA_character_)
    parts <- trimws(strsplit(s, ";", fixed = TRUE)[[1L]])
    parts <- unique(parts[nzchar(parts)])
    if (length(parts) == 0L) NA_character_ else paste(parts, collapse = "; ")
  }, character(1), USE.NAMES = FALSE)
  out
}

split_themes <- function(v) {
  lapply(v, function(s) {
    if (is.na(s)) character(0) else strsplit(s, "; ", fixed = TRUE)[[1L]]
  })
}

empty_comments <- function() {
  data.frame(
    expert = character(0), round = integer(0), item = character(0),
    indicator = character(0), comment = character(0), theme = character(0),
    stringsAsFactors = FALSE
  )
}

obj_comments <- function(x) {
  if (is.null(x$comments)) empty_comments() else x$comments
}

has_comments <- function(x) {
  nrow(obj_comments(x)) > 0L
}

sort_comments <- function(cm, items) {
  if (nrow(cm) == 0L) {
    return(empty_comments())
  }
  pos <- match(cm$item, items)
  pos[is.na(pos)] <- length(items) + 1L
  cm <- cm[order(cm$round, pos), , drop = FALSE]
  rownames(cm) <- NULL
  cm
}

assert_comments <- function(x) {
  if (!has_comments(x)) {
    stop_dr(
      "`x` contains no comments; add them with delphi_add_comments() or ",
      "read_delphi(comments_sheet = ...)."
    )
  }
  invisible(x)
}

subset_comments <- function(x, round = NULL, items = NULL, general = TRUE) {
  cm <- obj_comments(x)
  if (!is.null(round)) {
    unknown <- setdiff(round, unique(x$data$round))
    if (length(unknown) > 0L) {
      stop_dr("Round(s) not in the data: ", show_values(unknown), ".")
    }
    cm <- cm[cm$round %in% round, , drop = FALSE]
  }
  if (!is.null(items)) {
    unknown <- setdiff(items, x$items)
    if (length(unknown) > 0L) {
      stop_dr("Item(s) not in the data: ", show_values(unknown), ".")
    }
    cm <- cm[cm$item %in% items | (general & is.na(cm$item)), , drop = FALSE]
  }
  if (!general) {
    cm <- cm[!is.na(cm$item), , drop = FALSE]
  }
  rownames(cm) <- NULL
  cm
}

position_labels <- c("below Q1", "within IQR", "above Q3")

# Rating of the author and its position relative to the quartiles of the
# panel, for each comment and indicator
comment_positions <- function(x, cm, type = 7) {
  inds <- names(x$scales)
  out <- list()
  if (nrow(cm) == 0L) {
    for (i in inds) {
      out[[paste0(i, "_rating")]] <- numeric(0)
      out[[paste0(i, "_position")]] <- character(0)
    }
    out$outside_iqr <- logical(0)
    return(as.data.frame(out, stringsAsFactors = FALSE))
  }
  d <- delphi_describe(x, type = type)
  long <- x$data
  key_long <- paste(long$expert, long$round, long$indicator, long$item, sep = "\r")
  key_desc <- paste(d$round, d$indicator, d$item, sep = "\r")
  outside <- rep(NA, nrow(cm))
  for (i in inds) {
    rating <- long$value[match(paste(cm$expert, cm$round, i, cm$item, sep = "\r"), key_long)]
    k <- match(paste(cm$round, i, cm$item, sep = "\r"), key_desc)
    q1 <- d$q1[k]
    q3 <- d$q3[k]
    pos <- ifelse(rating < q1, position_labels[1L],
                  ifelse(rating > q3, position_labels[3L], position_labels[2L]))
    pos[is.na(rating) | is.na(q1)] <- NA_character_
    out[[paste0(i, "_rating")]] <- rating
    out[[paste0(i, "_position")]] <- pos
    o <- pos != position_labels[2L]
    outside <- ifelse(is.na(outside), o, outside | (o %in% TRUE))
  }
  out$outside_iqr <- outside
  as.data.frame(out, stringsAsFactors = FALSE)
}


#' Expert comments next to their ratings
#'
#' @description
#' Lists the comments of the experts with the rating that their author gave
#' to the same item in the same round, on every indicator, and the position
#' of that rating relative to the ratings of the whole panel: below the
#' first quartile, within the interquartile range or above the third
#' quartile. Comments from experts whose ratings lie outside the
#' interquartile range are the arguments of the minority, which the Delphi
#' method asks the panel to consider in the next round.
#'
#' @param x A `delphi_data` object with comments; see [delphi_add_comments()].
#' @param round,items Optional subsets of rounds and items.
#' @param general Whether to include general comments, not referring to a
#'   specific item.
#' @param type Quantile algorithm; see [delphi_describe()].
#'
#' @details
#' A rating equal to a quartile counts as within the interquartile range.
#' Positions are `NA` for general comments and when the author did not rate
#' the item on that indicator.
#'
#' @return A data frame of class `delphi_comments` with one row per comment
#'   and columns `round`, `item`, `expert`, `indicator`, `comment`, `theme`,
#'   then, for each indicator, the rating of the author (`<indicator>_rating`)
#'   and its position (`<indicator>_position`), and finally `outside_iqr`:
#'   whether the rating of the author lies outside the interquartile range on
#'   at least one indicator.
#' @seealso [delphi_comment_counts()], [delphi_themes()], [delphi_words()],
#'   [delphi_feedback()].
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C", "D"),
#'                  E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#' cm <- data.frame(expert = c("A", "D"), item = c("E1", "E1"),
#'                  comment = c("Depends on public funding.",
#'                              "Unlikely without new regulation."))
#' x <- delphi_add_comments(x, cm)
#' delphi_comments(x)
#' @export
delphi_comments <- function(x, round = NULL, items = NULL, general = TRUE, type = 7) {
  assert_delphi_data(x)
  assert_comments(x)
  cm <- subset_comments(x, round = round, items = items, general = general)
  out <- cbind(
    cm[c("round", "item", "expert", "indicator", "comment", "theme")],
    comment_positions(x, cm, type = type)
  )
  rownames(out) <- NULL
  class(out) <- c("delphi_comments", "data.frame")
  out
}

#' @export
print.delphi_comments <- function(x, n = 20, width = getOption("width"), ...) {
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  if (!all(c("round", "item", "expert", "comment") %in% names(df))) {
    print(df, ...)
    return(invisible(x))
  }
  cat("<delphi_comments> ", nrow(df), " comment(s)\n", sep = "")
  if (nrow(df) == 0L) {
    return(invisible(x))
  }
  inds <- sub("_position$", "", grep("_position$", names(df), value = TRUE))
  shown <- utils::head(df, n)
  group <- paste(shown$round, ifelse(is.na(shown$item), "", shown$item))
  for (g in unique(group)) {
    sel <- shown[group == g, , drop = FALSE]
    it <- sel$item[1L]
    cat("\nRound ", sel$round[1L], ", ",
        if (is.na(it)) "general comments" else paste("item", it), "\n", sep = "")
    for (k in seq_len(nrow(sel))) {
      pos <- vapply(inds, function(i) {
        p <- sel[[paste0(i, "_position")]][k]
        if (is.na(p)) NA_character_ else paste0(i, " ", p)
      }, character(1))
      pos <- pos[!is.na(pos)]
      line <- paste0("  [", sel$expert[k], "]",
                     if (!is.na(sel$indicator[k])) paste0(" on ", sel$indicator[k]) else "",
                     if (length(pos) > 0L) paste0(": ", paste(pos, collapse = ", ")) else "",
                     if (!is.na(sel$theme[k])) paste0(" (theme: ", sel$theme[k], ")") else "")
      cat(line, "\n", sep = "")
      cat(strwrap(sel$comment[k], width = max(30, width - 6), indent = 4, exdent = 4),
          sep = "\n")
    }
  }
  if (nrow(df) > n) {
    cat("\n... and ", nrow(df) - n, " more comment(s). ",
        "Use print(n = ) to show more, or as.data.frame() for the table.\n", sep = "")
  }
  invisible(x)
}


#' Number of comments by item
#'
#' @description
#' Counts, for each round and item, the comments received, the experts who
#' wrote them and the share of the experts who rated the item, and the
#' comments written by experts whose ratings lie outside the interquartile
#' range.
#'
#' @inheritParams delphi_comments
#' @param round Optional round number(s) to keep. `NULL` keeps all rounds.
#' @param indicator Optional indicator on which the position of the authors
#'   is assessed. By default, a comment counts as coming from outside the
#'   interquartile range when its author lies outside it on at least one
#'   indicator.
#'
#' @return A data frame of class `delphi_comment_counts` with one row per
#'   round and item, including the items
#'   without comments, and columns `round`, `item`, `n_comments`,
#'   `n_experts` (experts who commented), `n_raters` (experts who rated the
#'   item), `share_experts` (`n_experts / n_raters`) and `n_outside`
#'   (comments from experts outside the interquartile range). Only rounds
#'   with at least one comment are included; general comments are not
#'   counted.
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C", "D"),
#'                  E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#' cm <- data.frame(expert = c("A", "D", "D"), item = c("E1", "E1", "E2"),
#'                  comment = c("Depends on public funding.",
#'                              "Unlikely without new regulation.",
#'                              "The statement is too broad."))
#' x <- delphi_add_comments(x, cm)
#' delphi_comment_counts(x)
#' @export
delphi_comment_counts <- function(x, round = NULL, indicator = NULL, type = 7) {
  assert_delphi_data(x)
  assert_comments(x)
  if (!is.null(indicator) && (!is_string(indicator) || !indicator %in% names(x$scales))) {
    stop_dr("`indicator` must be one of ", show_values(names(x$scales)), ".")
  }
  cm <- delphi_comments(x, round = round, general = FALSE, type = type)
  rounds <- sort(unique(obj_comments(x)$round))
  if (!is.null(round)) {
    rounds <- intersect(rounds, round)
  }
  outside <- if (is.null(indicator)) {
    cm$outside_iqr
  } else {
    p <- cm[[paste0(indicator, "_position")]]
    ifelse(is.na(p), NA, p != position_labels[2L])
  }
  rated <- x$data[!is.na(x$data$value), c("expert", "round", "item")]
  rows <- lapply(rounds, function(r) {
    its <- x$items[x$items %in% rated$item[rated$round == r]]
    do.call(rbind, lapply(its, function(i) {
      sel <- cm$round == r & cm$item == i
      raters <- length(unique(rated$expert[rated$round == r & rated$item == i]))
      authors <- length(unique(cm$expert[sel]))
      data.frame(
        round = r, item = i, n_comments = sum(sel), n_experts = authors,
        n_raters = raters,
        share_experts = if (raters > 0L) authors / raters else NA_real_,
        n_outside = sum(outside[sel] %in% TRUE),
        stringsAsFactors = FALSE
      )
    }))
  })
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    out <- data.frame(round = integer(0), item = character(0), n_comments = integer(0),
                      n_experts = integer(0), n_raters = integer(0),
                      share_experts = numeric(0), n_outside = integer(0))
  }
  rownames(out) <- NULL
  class(out) <- c("delphi_comment_counts", "data.frame")
  out
}

#' @export
print.delphi_comment_counts <- function(x, digits = 2, ...) {
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  print(df, row.names = FALSE, ...)
  invisible(x)
}


#' Themes of the comments
#'
#' @description
#' Tabulates the themes assigned by the researchers to the comments (see
#' [delphi_add_comments()]), by item or across items, so that the arguments
#' raised by the panel can be compared between items and rounds.
#'
#' @inheritParams delphi_comment_counts
#' @param round Optional round number(s) to keep. `NULL` keeps all rounds.
#' @param by `"item"` (default) counts each theme within each item;
#'   `"theme"` counts each theme across all items.
#'
#' @details
#' A comment coded with several themes counts once for each of them.
#' General comments are included when `by = "theme"`, with item `NA` when
#' `by = "item"`.
#'
#' @return A data frame with columns `round`, `item` (only when
#'   `by = "item"`), `theme`, `n_comments`, `n_experts` (experts who raised
#'   the theme), `n_outside` (comments from experts outside the
#'   interquartile range) and, when `by = "theme"`, `n_items` and `items`
#'   (the items on which the theme was raised). Rows are ordered by round
#'   and by decreasing number of comments.
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C", "D"),
#'                  E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#' cm <- data.frame(
#'   expert = c("A", "D", "D", "C"),
#'   item = c("E1", "E1", "E2", "E2"),
#'   comment = c("Depends on public funding.", "Unlikely without new rules.",
#'               "Too broad, and costly.", "Rules will change soon."),
#'   theme = c("funding", "regulation", "wording; funding", "regulation")
#' )
#' x <- delphi_add_comments(x, cm)
#' delphi_themes(x)
#' delphi_themes(x, by = "theme")
#' @export
delphi_themes <- function(x, round = NULL, by = c("item", "theme"),
                          indicator = NULL, type = 7) {
  assert_delphi_data(x)
  assert_comments(x)
  by <- match.arg(by)
  if (!is.null(indicator) && (!is_string(indicator) || !indicator %in% names(x$scales))) {
    stop_dr("`indicator` must be one of ", show_values(names(x$scales)), ".")
  }
  cm <- delphi_comments(x, round = round, type = type)
  if (all(is.na(cm$theme))) {
    stop_dr(
      "No themes found. Code the comments in a `theme` column (see ",
      "delphi_add_comments()) to tabulate them."
    )
  }
  cm$outside <- if (is.null(indicator)) {
    cm$outside_iqr
  } else {
    p <- cm[[paste0(indicator, "_position")]]
    ifelse(is.na(p), NA, p != position_labels[2L])
  }
  th <- split_themes(cm$theme)
  idx <- rep(seq_len(nrow(cm)), lengths(th))
  ex <- data.frame(
    round = cm$round[idx], item = cm$item[idx], expert = cm$expert[idx],
    theme = unlist(th, use.names = FALSE), outside = cm$outside[idx],
    stringsAsFactors = FALSE
  )
  keys <- if (by == "item") c("round", "item", "theme") else c("round", "theme")
  grp <- unique(ex[keys])
  rows <- lapply(seq_len(nrow(grp)), function(g) {
    sel <- ex$round == grp$round[g] & ex$theme == grp$theme[g]
    if (by == "item") {
      sel <- sel & ((is.na(ex$item) & is.na(grp$item[g])) | ex$item %in% grp$item[g])
    }
    out <- data.frame(
      n_comments = sum(sel),
      n_experts = length(unique(ex$expert[sel])),
      n_outside = sum(ex$outside[sel] %in% TRUE)
    )
    if (by == "theme") {
      its <- unique(ex$item[sel & !is.na(ex$item)])
      its <- x$items[x$items %in% its]
      out$n_items <- length(its)
      out$items <- paste(its, collapse = ", ")
    }
    out
  })
  out <- cbind(grp, do.call(rbind, rows))
  if (by == "item") {
    pos <- match(out$item, x$items)
    pos[is.na(pos)] <- length(x$items) + 1L
    out <- out[order(out$round, pos, -out$n_comments, out$theme), , drop = FALSE]
  } else {
    out <- out[order(out$round, -out$n_comments, out$theme), , drop = FALSE]
  }
  rownames(out) <- NULL
  out
}


#' Word frequencies in the comments
#'
#' @description
#' Counts the words used in the comments, after removing common words
#' (articles, prepositions, pronouns and auxiliary verbs) in English and
#' Italian. Word frequencies give a first, descriptive view of the content of
#' the comments; they do not replace a qualitative reading of the comments.
#'
#' @inheritParams delphi_comments
#' @param language Languages whose common words are removed: any of `"en"`
#'   (English) and `"it"` (Italian), or `NULL` to keep all words.
#' @param stopwords Additional words to remove, for example the words used in
#'   every item statement.
#' @param min_length Minimum number of letters of the words to count.
#' @param top Number of words to return; `NULL` returns all of them.
#'
#' @details
#' Comments are converted to lower case and split into words at every
#' character that is not a letter, so that numbers and punctuation are
#' discarded and elided forms such as `dell'impatto` are split into two
#' words. No stemming is applied: "policy" and "policies" are counted as
#' different words.
#'
#' @return A data frame with columns `word`, `n` (number of occurrences) and
#'   `n_comments` (number of comments in which the word appears), ordered by
#'   decreasing frequency.
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(7, 8, 6))
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#' cm <- data.frame(expert = c("A", "B", "C"), item = "E1",
#'                  comment = c("Public funding is essential.",
#'                              "Without public funding, no impact.",
#'                              "Regulation matters more than funding."))
#' x <- delphi_add_comments(x, cm)
#' delphi_words(x)
#' @export
delphi_words <- function(x, round = NULL, items = NULL, language = c("en", "it"),
                         stopwords = NULL, min_length = 3, top = 20) {
  assert_delphi_data(x)
  assert_comments(x)
  if (!is.null(language)) {
    if (!is.character(language) || anyNA(language) ||
        !all(language %in% c("en", "it"))) {
      stop_dr("`language` must be \"en\", \"it\", both, or NULL.")
    }
  }
  if (!is.null(stopwords) && (!is.character(stopwords) || anyNA(stopwords))) {
    stop_dr("`stopwords` must be a character vector.")
  }
  if (!is.numeric(min_length) || length(min_length) != 1L || !is_whole(min_length) ||
      min_length < 1) {
    stop_dr("`min_length` must be a positive whole number.")
  }
  if (!is.null(top) && (!is.numeric(top) || length(top) != 1L || !is_whole(top) || top < 1)) {
    stop_dr("`top` must be a positive whole number or NULL.")
  }
  cm <- subset_comments(x, round = round, items = items)
  stop_list <- unique(c(unlist(stopword_lists[language], use.names = FALSE),
                        tolower(stopwords)))
  tokens <- lapply(cm$comment, function(s) {
    w <- strsplit(tolower(enc2utf8(s)), "[^\\p{L}]+", perl = TRUE)[[1L]]
    w <- w[nchar(w) >= min_length]
    w[!w %in% stop_list]
  })
  all_w <- unlist(tokens, use.names = FALSE)
  if (length(all_w) == 0L) {
    return(data.frame(word = character(0), n = integer(0), n_comments = integer(0),
                      stringsAsFactors = FALSE))
  }
  n <- table(all_w)
  docs <- table(unlist(lapply(tokens, unique), use.names = FALSE))
  out <- data.frame(
    word = names(n), n = as.integer(n), n_comments = as.integer(docs[names(n)]),
    stringsAsFactors = FALSE
  )
  out <- out[order(-out$n, -out$n_comments, out$word), , drop = FALSE]
  if (!is.null(top)) {
    out <- utils::head(out, top)
  }
  rownames(out) <- NULL
  out
}


#' Comments by item
#'
#' @description
#' Shows, for each item, the number of comments received in a round, split
#' by the position of their authors: within the interquartile range or
#' outside it. Items with many comments from outside the interquartile range
#' are those on which the minority has argued its position.
#'
#' @inheritParams delphi_comment_counts
#' @param round Optional round number(s) to show. `NULL` shows all rounds
#'   with comments, in separate panels.
#'
#' @return A ggplot object.
#' @seealso [delphi_comment_counts()].
#' @examples
#' r1 <- data.frame(expert = c("A", "B", "C", "D"),
#'                  E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
#' x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
#' cm <- data.frame(expert = c("A", "D", "D"), item = c("E1", "E1", "E2"),
#'                  comment = c("Depends on public funding.",
#'                              "Unlikely without new regulation.",
#'                              "The statement is too broad."))
#' x <- delphi_add_comments(x, cm)
#' delphi_plot_comments(x)
#' @export
delphi_plot_comments <- function(x, round = NULL, indicator = NULL, type = 7) {
  assert_delphi_data(x)
  assert_comments(x)
  if (!is.null(indicator) && (!is_string(indicator) || !indicator %in% names(x$scales))) {
    stop_dr("`indicator` must be one of ", show_values(names(x$scales)), ".")
  }
  cm <- delphi_comments(x, round = round, general = FALSE, type = type)
  if (nrow(cm) == 0L) {
    stop_dr("No comments on the items in the selected round(s).")
  }
  outside <- if (is.null(indicator)) {
    cm$outside_iqr
  } else {
    p <- cm[[paste0(indicator, "_position")]]
    ifelse(is.na(p), NA, p != position_labels[2L])
  }
  lev <- c("Within the IQR", "Outside the IQR", "Position not available")
  cm$group <- factor(ifelse(is.na(outside), lev[3L], ifelse(outside, lev[2L], lev[1L])),
                     levels = lev)
  cm$item <- item_factor(cm$item, x$items, reverse = TRUE)
  rounds <- sort(unique(cm$round))
  cm$round_f <- factor(round_labels(cm$round), levels = round_labels(rounds))
  cols <- stats::setNames(c(delphi_colours$primary, delphi_colours$rounds[2L], "#b8b7b2"), lev)
  used <- lev[lev %in% as.character(cm$group)]
  where <- if (is.null(indicator)) {
    "Position of the author's rating: outside the IQR on at least one indicator"
  } else {
    paste0("Position of the author's rating on ", indicator)
  }

  p <- ggplot2::ggplot(cm, ggplot2::aes(y = .data$item, fill = .data$group)) +
    ggplot2::geom_bar(width = 0.7, colour = "#ffffff", linewidth = 0.5,
                      position = ggplot2::position_stack(reverse = TRUE)) +
    ggplot2::scale_fill_manual(values = cols[used], breaks = used, name = "Author's rating") +
    ggplot2::scale_x_continuous(breaks = scales::breaks_pretty(), expand = ggplot2::expansion(mult = c(0, 0.05))) +
    ggplot2::labs(
      title = "Comments by item",
      subtitle = where,
      x = "Number of comments", y = NULL
    ) +
    theme_delphi() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = delphi_colours$grid, linewidth = 0.3)
    )
  if (length(rounds) > 1L) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$round_f), nrow = 1)
  }
  p
}
