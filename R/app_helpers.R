# Helpers of the interactive application that do not depend on shiny, so
# that they can be tested on their own.

# Deparse a value on one line
code_value <- function(v) {
  paste(deparse(v, width.cutoff = 500L), collapse = "")
}

# Code of a function call, with one argument per line when it is long
code_call <- function(fun, args, assign = NULL) {
  args <- args[!vapply(args, is.null, logical(1))]
  parts <- vapply(seq_along(args), function(k) {
    nm <- names(args)[k]
    v <- args[[k]]
    val <- if (inherits(v, "code_symbol")) as.character(v) else code_value(v)
    if (is.null(nm) || !nzchar(nm)) val else paste0(nm, " = ", val)
  }, character(1))
  lhs <- if (is.null(assign)) "" else paste0(assign, " <- ")
  one <- paste0(lhs, fun, "(", paste(parts, collapse = ", "), ")")
  if (nchar(one) <= 78L) {
    return(one)
  }
  indent <- strrep(" ", nchar(lhs) + nchar(fun) + 1L)
  paste0(lhs, fun, "(", paste(parts, collapse = paste0(",\n", indent)), ")")
}

# A symbol written as is in generated code (an object name)
code_symbol <- function(name) {
  structure(name, class = "code_symbol")
}

# Column names that identify the rows of a file with two header rows: the
# columns whose first header cell is empty, named after the second row
two_header_id_cols <- function(raw) {
  if (nrow(raw) < 2L) {
    return(character(0))
  }
  clean <- function(v) {
    v <- trimws(gsub("[[:space:]]+", " ", as.character(v)))
    v[is.na(v)] <- ""
    v
  }
  ind <- clean(unlist(raw[1L, ], use.names = FALSE))
  lab <- clean(unlist(raw[2L, ], use.names = FALSE))
  other <- which(!nzchar(ind))
  ifelse(nzchar(lab[other]), lab[other], paste0("V", other))
}

# Indicators found in the first header row of a file with two header rows
two_header_indicators <- function(raw) {
  if (nrow(raw) < 1L) {
    return(character(0))
  }
  ind <- trimws(gsub("[[:space:]]+", " ", as.character(unlist(raw[1L, ], use.names = FALSE))))
  unique(ind[!is.na(ind) & nzchar(ind)])
}

# Arguments of read_delphi() from the choices made in the application.
# `spec` is a list with elements layout ("wide", "wide2" or "long"), sheet,
# expert_col, round_col, round, indicator_col, indicator, items, all_items,
# item_col, value_col, scale, linked, items_sheet and indicator_names.
# Empty choices are given as NULL or "".
import_args <- function(spec, excel = FALSE) {
  none <- function(v) is.null(v) || length(v) == 0L || identical(v, "") || all(is.na(v))
  args <- list()
  if (excel && !none(spec$sheet)) {
    args$sheet <- spec$sheet
  }
  if (spec$layout == "long") {
    args$layout <- "long"
    args$expert_col <- spec$expert_col
    if (!identical(spec$item_col, "item")) args$item_col <- spec$item_col
    if (!identical(spec$value_col, "value")) args$value_col <- spec$value_col
  } else {
    if (spec$layout == "wide2") {
      args$header_rows <- 2
    }
    if (!none(spec$expert_col)) {
      args$expert_col <- spec$expert_col
    }
  }
  if (none(spec$round_col)) {
    if (!none(spec$round) && spec$round != 1) args$round <- as.integer(spec$round)
  } else {
    args$round_col <- spec$round_col
  }
  if (spec$layout != "wide2") {
    if (none(spec$indicator_col)) {
      if (!none(spec$indicator) && spec$indicator != "score") args$indicator <- spec$indicator
    } else {
      args$indicator_col <- spec$indicator_col
    }
  }
  if (spec$layout == "wide" && !none(spec$items) && !none(spec$all_items) &&
      !setequal(spec$items, spec$all_items)) {
    args$items <- spec$all_items[spec$all_items %in% spec$items]
  }
  if (spec$layout == "wide2" && !none(spec$indicator_names)) {
    ren <- spec$indicator_names
    ren <- ren[!is.na(ren) & nzchar(ren) & ren != names(ren)]
    if (length(ren) > 0L) args$indicator_names <- ren
  }
  if (!isTRUE(all.equal(as.numeric(spec$scale), c(1, 10)))) {
    args$scale <- as.numeric(spec$scale)
  }
  if (!isTRUE(spec$linked)) {
    args$linked <- FALSE
  }
  if (excel && spec$layout != "wide2" && !none(spec$items_sheet)) {
    args$items_sheet <- spec$items_sheet
  }
  args
}

# Read a file as a table, with one header row or none, for previews and
# column choices
read_raw_table <- function(path, ext, sheet = 1, header = TRUE) {
  if (ext %in% c("xlsx", "xls")) {
    read_excel_delphi(path, sheet = sheet, header = header)
  } else {
    read_delim_delphi(path, sep = NULL, dec = NULL, encoding = "UTF-8", header = header)
  }
}

# Code that reads a table of comments
comments_read_code <- function(name, ext, sheet) {
  if (ext %in% c("xlsx", "xls")) {
    code_call("readxl::read_excel", list(name, sheet = sheet), assign = "comments")
  } else {
    code_call("utils::read.csv", list(name, check.names = FALSE), assign = "comments")
  }
}

# Shorter labels for item choices
item_choices <- function(x) {
  lab <- obj_labels(x)
  txt <- ifelse(is.na(lab), x$items,
                paste0(x$items, ": ", ifelse(nchar(lab) > 60, paste0(substr(lab, 1, 57), "..."), lab)))
  stats::setNames(x$items, txt)
}

# Capture the warnings of an expression, returning its value and the
# warning messages
with_warnings <- function(expr) {
  msgs <- character(0)
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = msgs)
}

# Code for a set of columns: a regular sequence of positions is written as
# a call to seq(), so that long sets of comment columns stay readable
code_columns <- function(cols, all_names, object = "comments") {
  pos <- match(cols, all_names)
  if (length(pos) >= 3L && !anyNA(pos) && !anyDuplicated(all_names[pos])) {
    step <- unique(diff(pos))
    if (length(step) == 1L && step > 0L) {
      return(code_symbol(sprintf("names(%s)[seq(%d, %d, by = %d)]", object,
                                 pos[1L], pos[length(pos)], step)))
    }
  }
  cols
}

# First rows of a table, with long text shortened, for previews
preview_table <- function(df, n = 200, width = 40) {
  df <- utils::head(as.data.frame(df, stringsAsFactors = FALSE), n)
  chr <- vapply(df, is.character, logical(1))
  df[chr] <- lapply(df[chr], function(v) {
    ifelse(!is.na(v) & nchar(v) > width, paste0(substr(v, 1, width - 3), "..."), v)
  })
  df
}

# A dataset of the package
example_data <- function(name) {
  env <- new.env()
  utils::data(list = name, package = "DelphiR", envir = env)
  env[[name]]
}
