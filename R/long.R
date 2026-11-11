#' Create a Delphi data object from a long table
#'
#' @description
#' Converts expert ratings stored in long format, with one row per
#' rating, into a validated `delphi_data` object. Each row gives the expert,
#' the item and the rating, and optionally the round and the indicator. This
#' is the format produced by most statistical software when data are
#' reshaped, and the most convenient one when ratings come from several
#' sources.
#'
#' @param data A data frame (or tibble) in long format.
#' @param expert_col,item_col,value_col Names of the columns with the expert
#'   identifiers, the item names and the ratings.
#' @param round_col Name of the column with the round number. If `NULL`, all
#'   rows belong to round `round`.
#' @param indicator_col Name of the column with the indicator label. If
#'   `NULL`, all rows refer to the indicator `indicator`.
#' @param round Round number used when `round_col` is `NULL`.
#' @param indicator Indicator label used when `indicator_col` is `NULL`.
#' @inheritParams delphi_data
#'
#' @details
#' Rows without an expert identifier are ignored with a warning, and rows
#' with an empty rating are kept as missing ratings. Items are kept in order
#' of first appearance. Each combination of expert, round, indicator and
#' item must appear only once.
#'
#' @return An object of class `delphi_data`; see [delphi_data()].
#' @seealso [delphi_data()] for the wide layout, [read_delphi()] to import
#'   from a file.
#' @examples
#' long <- data.frame(
#'   expert = rep(c("A", "B", "C"), each = 2),
#'   item = rep(c("E1", "E2"), times = 3),
#'   value = c(7, 3, 8, 5, 6, 4)
#' )
#' x <- delphi_data_long(long, indicator = "impact", scale = c(1, 10))
#' x
#'
#' # Back to the long format
#' as.data.frame(x)
#' @export
delphi_data_long <- function(data,
                             expert_col = "expert",
                             item_col = "item",
                             value_col = "value",
                             round_col = NULL,
                             indicator_col = NULL,
                             round = 1L,
                             indicator = "score",
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

  cols <- list(expert_col = expert_col, item_col = item_col, value_col = value_col,
               round_col = round_col, indicator_col = indicator_col)
  for (arg in names(cols)) {
    col <- cols[[arg]]
    if (is.null(col)) {
      next
    }
    if (!is_string(col)) {
      stop_dr("`", arg, "` must be a single column name.")
    }
    if (!col %in% names(data)) {
      stop_dr("`", arg, "`: column '", col, "' not found in `data`.")
    }
  }
  used <- unlist(cols, use.names = FALSE)
  if (anyDuplicated(used)) {
    stop_dr("The expert, item, rating, round and indicator columns must be different.")
  }

  id <- trimws(as.character(data[[expert_col]]))
  no_id <- is.na(id) | !nzchar(id)
  if (all(no_id)) {
    stop_dr("Column '", expert_col, "' contains no expert identifiers.")
  }
  if (any(no_id)) {
    warn_dr(sum(no_id), " row(s) without an expert identifier were ignored.")
    data <- data[!no_id, , drop = FALSE]
    id <- id[!no_id]
  }

  item <- trimws(as.character(data[[item_col]]))
  if (anyNA(item) || any(!nzchar(item))) {
    stop_dr("Column '", item_col, "' contains empty item names.")
  }

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

  long <- data.frame(
    expert = id,
    round = rnd,
    indicator = ind,
    item = item,
    value = as_rating(data[[value_col]], value_col),
    stringsAsFactors = FALSE
  )
  items <- unique(item)
  scales <- resolve_scales(scale, unique(ind))
  long <- check_scale(long, scales, out_of_scale)
  new_delphi_data(long, items = items, scales = scales,
                  labels = resolve_labels(item_labels, items), linked = linked)
}
