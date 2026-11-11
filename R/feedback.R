#' Controlled feedback for the next round
#'
#' @description
#' Prepares the controlled feedback that the experts receive before a further
#' round: for each item to be rated again, the statistical response of the
#' panel in the current round (median, quartiles and consensus) and, when
#' available, the comments of the experts, reported anonymously. The
#' feedback can be returned as a table or written to a document to be sent
#' to the panel, in HTML or Word format.
#'
#' @param x A `delphi_data` object.
#' @param file Optional path of the feedback document, ending in `.html` or
#'   `.docx`. If `NULL` (default), no document is written.
#' @param round Round on which the feedback is based. `NULL` (default) uses
#'   the last round; see [delphi_status()].
#' @param items Items to include. By default, the items that require a
#'   further round on at least one indicator, according to
#'   [delphi_status()].
#' @param comments Whether to include the comments of the experts on the
#'   selected items, when `x` contains comments (see
#'   [delphi_add_comments()]).
#' @param title Title of the document.
#' @param item_labels Optional named character vector with the full
#'   statement of each item. By default, the labels stored in `x` are used.
#' @param threshold,relative_to Consensus rule, see [delphi_consensus()].
#' @param method,alpha,scheibe,paired Stability rule, used to select the
#'   items for the next round; see [delphi_stability()].
#' @param type Quantile algorithm; see [delphi_describe()].
#' @param open Whether to open the document once it has been created.
#' @param quiet Whether to suppress the rendering messages.
#'
#' @details
#' The document is written for the experts: it explains the median and the
#' interquartile range in plain words and contains no expert identifiers, no
#' individual ratings and no information on the position of the authors of
#' the comments. Comments are reproduced as written, so any detail that
#' could identify their authors should be removed from the data beforehand.
#' Writing a document requires the \pkg{rmarkdown} and \pkg{knitr} packages
#' and Pandoc.
#'
#' @return A data frame of class `delphi_feedback`, invisibly when `file` is
#'   given, with one row per item and indicator and columns `item`,
#'   `statement`, `indicator`, `round`, `n`, `median`, `q1`, `q3`, `iqr`,
#'   `consensus` and `status`. The comments are stored in the attribute
#'   `comments`, a data frame with columns `round`, `item` and `comment`.
#' @seealso [delphi_status()], [delphi_comments()], [delphi_report()].
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' fb <- delphi_feedback(x, round = 1)
#' head(fb)
#' \donttest{
#' if (requireNamespace("rmarkdown", quietly = TRUE) &&
#'     rmarkdown::pandoc_available()) {
#'   out <- delphi_feedback(x, file.path(tempdir(), "feedback.html"),
#'                          round = 1, open = FALSE)
#' }
#' }
#' @export
delphi_feedback <- function(x, file = NULL, round = NULL, items = NULL,
                            comments = TRUE,
                            title = "Delphi study: feedback for the next round",
                            item_labels = NULL,
                            threshold = 0.20, relative_to = c("points", "range"),
                            method = c("wilcoxon", "scheibe", "both"),
                            alpha = 0.05, scheibe = 0.15, type = 7, paired = NULL,
                            open = interactive(), quiet = TRUE) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  method <- match.arg(method)
  if (!is.logical(comments) || length(comments) != 1L || is.na(comments)) {
    stop_dr("`comments` must be TRUE or FALSE.")
  }
  if (!is_string(title)) {
    stop_dr("`title` must be a single string.")
  }
  st <- delphi_status(x, round = round, threshold = threshold,
                      relative_to = relative_to, method = method, alpha = alpha,
                      scheibe = scheibe, type = type, paired = paired)
  if (is.null(items)) {
    items <- x$items[x$items %in% st$item[st$next_round]]
    if (length(items) == 0L) {
      stop_dr(
        "No item requires a further round under the criteria adopted; ",
        "choose the items to include with `items`."
      )
    }
  } else {
    if (!is.character(items) || anyNA(items)) {
      stop_dr("`items` must be a character vector of item codes.")
    }
    unknown <- setdiff(items, x$items)
    if (length(unknown) > 0L) {
      stop_dr("Item(s) not in the data: ", show_values(unknown), ".")
    }
    items <- x$items[x$items %in% items]
  }

  labels <- obj_labels(x)
  if (!is.null(item_labels)) {
    if (!is.character(item_labels) || is.null(names(item_labels))) {
      stop_dr("`item_labels` must be a named character vector, for example c(E1 = \"...\").")
    }
    unknown <- setdiff(names(item_labels), x$items)
    if (length(unknown) > 0L) {
      stop_dr("`item_labels` refers to unknown item(s): ", show_values(unknown), ".")
    }
    labels[names(item_labels)] <- item_labels
  }

  rows <- lapply(names(x$scales), function(ind) {
    sti <- st[st$indicator == ind & st$item %in% items, , drop = FALSE]
    if (nrow(sti) == 0L) {
      return(NULL)
    }
    d <- delphi_describe(x, round = sti$round[1L], indicator = ind, items = sti$item,
                         type = type, relative_to = relative_to)
    k <- match(sti$item, d$item)
    data.frame(
      item = sti$item, statement = unname(labels[sti$item]), indicator = ind,
      round = sti$round, n = d$n[k], median = d$median[k], q1 = d$q1[k],
      q3 = d$q3[k], iqr = d$iqr[k], consensus = sti$consensus, status = sti$status,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out <- out[order(match(out$item, x$items), match(out$indicator, names(x$scales))), ,
             drop = FALSE]
  rownames(out) <- NULL

  cm <- data.frame(round = integer(0), item = character(0), comment = character(0),
                   stringsAsFactors = FALSE)
  if (comments && has_comments(x)) {
    r_fb <- max(out$round)
    all <- obj_comments(x)
    all <- all[all$round == r_fb & all$item %in% items, , drop = FALSE]
    cm <- all[c("round", "item", "comment")]
    rownames(cm) <- NULL
  }
  attr(out, "comments") <- cm
  attr(out, "scales") <- x$scales
  class(out) <- c("delphi_feedback", "data.frame")

  if (is.null(file)) {
    return(out)
  }
  check_render()
  if (!is_string(file)) {
    stop_dr("`file` must be the path of the document, ending in .html or .docx.")
  }
  ext <- tolower(tools_file_ext(file))
  format <- switch(ext,
    html = rmarkdown::html_document(toc = FALSE),
    docx = rmarkdown::word_document(),
    stop_dr("`file` must end in .html or .docx.")
  )
  cfg <- list(feedback = out, relative_to = relative_to, threshold = threshold)
  render_template("delphi_feedback.Rmd", x = x, cfg = cfg, file = file,
                  format = format, title = title, open = open, quiet = quiet)
  invisible(out)
}

#' @export
print.delphi_feedback <- function(x, digits = 2, ...) {
  df <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  attr(df, "comments") <- NULL
  attr(df, "scales") <- NULL
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], round, digits = digits)
  # Statements are long: they are shown in the document, not in the console
  df$statement <- NULL
  df$iqr <- NULL
  print(df, row.names = FALSE, ...)
  cm <- attr(x, "comments")
  if (!is.null(cm) && nrow(cm) > 0L) {
    cat(nrow(cm), " comment(s) included; see attr(, \"comments\").\n", sep = "")
  }
  invisible(x)
}
