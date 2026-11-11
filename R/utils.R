# Internal helpers
stop_dr <- function(...) {
  stop(paste0(...), call. = FALSE)
}

warn_dr <- function(...) {
  warning(paste0(...), call. = FALSE)
}

is_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}

is_whole <- function(x, tol = sqrt(.Machine$double.eps)) {
  is.numeric(x) & !is.na(x) & abs(x - round(x)) < tol
}

# Show at most `n` elements of a vector, in quotes.
show_values <- function(x, n = 5L) {
  x <- unique(x)
  out <- paste0("'", utils::head(x, n), "'", collapse = ", ")
  if (length(x) > n) out <- paste0(out, ", ...")
  out
}

# Convert a column to numeric. Character columns are accepted when they
# hold numbers, also with a decimal comma ("7,5"), as in many Italian or
# European spreadsheet exports.
as_rating <- function(x, name) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }
  if (is.logical(x) && all(is.na(x))) {
    return(as.numeric(x))
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (is.character(x)) {
    y <- trimws(x)
    y[y %in% c("", "NA", "na", "N/A", "n/a")] <- NA_character_
    y <- gsub(",", ".", y, fixed = TRUE)
    num <- suppressWarnings(as.numeric(y))
    bad <- !is.na(y) & is.na(num)
    if (any(bad)) {
      stop_dr(
        "Column '", name, "' contains non-numeric ratings: ",
        show_values(x[bad]), "."
      )
    }
    return(num)
  }
  stop_dr(
    "Column '", name, "' has class '", class(x)[1L],
    "'; ratings must be numeric."
  )
}

# Turn the `scale` argument into a named list, one c(min, max) per
# indicator.
resolve_scales <- function(scale, indicators) {
  check_one <- function(s, label) {
    if (!is.numeric(s) || length(s) != 2L || anyNA(s) || any(!is.finite(s))) {
      stop_dr("The scale for ", label, " must be two finite numbers, c(min, max).")
    }
    if (s[1L] >= s[2L]) {
      stop_dr("The scale for ", label, " must have min < max.")
    }
    as.numeric(s)
  }
  if (is.numeric(scale)) {
    s <- check_one(scale, "the ratings")
    return(stats::setNames(rep(list(s), length(indicators)), indicators))
  }
  if (is.list(scale) && !is.null(names(scale)) && all(nzchar(names(scale)))) {
    missing <- setdiff(indicators, names(scale))
    if (length(missing) > 0L) {
      stop_dr("`scale` has no entry for indicator(s) ", show_values(missing), ".")
    }
    out <- lapply(indicators, function(i) check_one(scale[[i]], paste0("indicator '", i, "'")))
    return(stats::setNames(out, indicators))
  }
  stop_dr(
    "`scale` must be c(min, max) or a named list such as ",
    "list(impact = c(1, 10), plausibility = c(1, 100))."
  )
}

# Width of a rating scale used to express the IQR as a share of the scale.
# "points": number of scale points, max - min + 1 (1-10 -> 10, 1-5 -> 5);
# "range": max - min (1-10 -> 9).
scale_width <- function(s, relative_to = "points") {
  if (relative_to == "points") s[2L] - s[1L] + 1 else s[2L] - s[1L]
}

scale_label <- function(s) {
  paste0("from ", format(s[1L]), " to ", format(s[2L]))
}
