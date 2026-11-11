#' Read Delphi ratings from a file
#'
#' @description
#' Reads a CSV, TSV, TXT or Excel file of expert ratings and returns a
#' validated `delphi_data` object. Three layouts are supported:
#'
#' * wide (`layout = "wide"`, default): the DelphiR wide layout, with one
#'   row per expert and one column per item, as in the template created by
#'   [delphi_template()];
#' * long (`layout = "long"`): one row per rating, with columns for the
#'   expert, the item and the rating, and optionally the round and the
#'   indicator; see [delphi_data_long()];
#' * wide with two header rows (`header_rows = 2`): the layout produced
#'   by many survey platforms when each item is rated on several indicators. The
#'   first row gives the indicator of each column (for example impact,
#'   probability and desirability) and the second row the item statement,
#'   written once above the group of columns that refer to the same item
#'   (as with merged cells). Columns with an empty first-row cell, such as
#'   the expert identifier or demographic variables, are not treated as
#'   items.
#'
#' @param file Path to a `.csv`, `.tsv`, `.txt`, `.xlsx` or `.xls` file.
#' @param ... Arguments passed to [delphi_data()] (wide layout) or to
#'   [delphi_data_long()] (long layout), such as `expert_col`, `round`,
#'   `indicator`, `scale` and `linked`.
#' @param sheet For Excel files, the sheet to read (name or position).
#' @param layout `"wide"` (default) or `"long"`; see Description.
#' @param header_rows Number of header rows of a wide file, `1` or `2`; see
#'   Description.
#' @param items_sheet For Excel files, an optional sheet with the item
#'   statements, in two columns named `item` and `statement`, as in the
#'   template created by [delphi_template()]. The statements are stored as
#'   item labels and used in reports.
#' @param indicator_names For `header_rows = 2`, an optional named character
#'   vector that renames the indicators found in the first header row, for
#'   example `c(IMPATTO = "impact", PROBAB = "probability")`. The names used
#'   in `scale` must be the new ones.
#' @param item_prefix For `header_rows = 2`, the prefix of the item codes.
#'   Items are coded in order of appearance (`E1`, `E2`, ...), and their
#'   statements are kept as item labels.
#' @param sep Field separator for text files. By default it is detected
#'   from the first line: `";"`, `","` or tab.
#' @param dec Decimal mark for text files. By default `","` when the
#'   separator is `";"` (the usual European CSV export), `"."` otherwise.
#' @param encoding File encoding for text files.
#'
#' @details
#' Reading Excel files requires the \pkg{readxl} package. With one header
#' row, column names are preserved exactly as they appear in the file, so
#' that items may be coded `E1`, `E2`, ... or carry full labels. Rows
#' without an expert identifier, such as summary rows with medians or
#' quartiles added below the data, are ignored with a warning.
#'
#' @return A `delphi_data` object.
#' @examples
#' path <- system.file("extdata", "delphi_round1.csv", package = "DelphiR")
#' x <- read_delphi(path, expert_col = "expert", indicator = "impact",
#'                  scale = c(1, 10))
#' x
#'
#' # Two header rows: indicators in the first, item statements in the second
#' tmp <- tempfile(fileext = ".csv")
#' writeLines(c(
#'   ",Impact,Probability,Impact,Probability",
#'   "ID,Remote work becomes the norm,,AI agents manage recruitment,",
#'   "A,8,6,5,4",
#'   "B,9,7,6,6",
#'   "C,7,7,4,5"
#' ), tmp)
#' y <- read_delphi(tmp, header_rows = 2, expert_col = "ID", scale = c(1, 10))
#' y
#' y$labels
#' @export
read_delphi <- function(file, ..., sheet = 1, layout = c("wide", "long"),
                        header_rows = 1, items_sheet = NULL,
                        indicator_names = NULL, item_prefix = "E",
                        sep = NULL, dec = NULL, encoding = "UTF-8") {
  layout <- match.arg(layout)
  if (!is_string(file)) {
    stop_dr("`file` must be a single file path.")
  }
  if (!file.exists(file)) {
    stop_dr("File not found: '", file, "'.")
  }
  if (length(header_rows) != 1L || !header_rows %in% c(1, 2)) {
    stop_dr("`header_rows` must be 1 or 2.")
  }
  if (layout == "long" && header_rows != 1) {
    stop_dr("Files in the long layout must have a single header row.")
  }
  ext <- tolower(tools_file_ext(file))
  header <- header_rows == 1
  dots <- list(...)
  if (!is.null(items_sheet)) {
    if (!ext %in% c("xlsx", "xls")) {
      stop_dr("`items_sheet` can only be used with Excel files.")
    }
    if (header_rows == 2) {
      stop_dr("With `header_rows = 2`, item statements are read from the header; remove `items_sheet`.")
    }
    if (!is.null(dots$item_labels)) {
      stop_dr("Use either `items_sheet` or `item_labels`, not both.")
    }
    dots$item_labels <- read_items_sheet(file, items_sheet)
  }

  raw <- switch(ext,
    csv = ,
    tsv = ,
    txt = read_delim_delphi(file, sep = sep, dec = dec, encoding = encoding,
                            header = header),
    xlsx = ,
    xls = read_excel_delphi(file, sheet = sheet, header = header),
    stop_dr("Unsupported file type '.", ext, "'. Use .csv, .tsv, .txt, .xlsx or .xls.")
  )
  if (layout == "long") {
    return(do.call(delphi_data_long, c(list(raw), dots)))
  }
  if (header) {
    return(do.call(delphi_data, c(list(raw), dots)))
  }

  clash <- intersect(names(dots), c("indicator", "indicator_col", "items", "item_labels"))
  if (length(clash) > 0L) {
    stop_dr(
      "With `header_rows = 2`, indicators and items are read from the header; ",
      "remove ", paste0("`", clash, "`", collapse = ", "), "."
    )
  }
  st <- stack_two_header(raw, indicator_names = indicator_names,
                         item_prefix = item_prefix, expert_col = dots$expert_col)
  do.call(delphi_data, c(
    list(st$data, indicator_col = ".indicator", items = st$items,
         item_labels = st$labels),
    dots
  ))
}

# Convert a table with two header rows (indicator, item statement) into the
# stacked DelphiR layout, one block of rows per indicator.
stack_two_header <- function(raw, indicator_names = NULL, item_prefix = "E",
                             expert_col = NULL) {
  if (nrow(raw) < 3L) {
    stop_dr("A file with two header rows must contain at least one row of ratings.")
  }
  clean <- function(v) {
    v <- trimws(gsub("[[:space:]]+", " ", as.character(v)))
    v[is.na(v)] <- ""
    v
  }
  ind <- clean(unlist(raw[1L, ], use.names = FALSE))
  lab <- clean(unlist(raw[2L, ], use.names = FALSE))
  is_item <- nzchar(ind)
  if (!any(is_item)) {
    stop_dr("No indicator labels found in the first header row.")
  }

  # Item statements are written once per group of columns: carry them forward
  item_lab <- rep(NA_character_, length(ind))
  current <- NA_character_
  for (j in seq_along(ind)) {
    if (!is_item[j]) {
      current <- NA_character_
      next
    }
    if (nzchar(lab[j])) {
      current <- lab[j]
    }
    if (is.na(current)) {
      stop_dr("Column ", j, " has an indicator but no item statement in the second header row.")
    }
    item_lab[j] <- current
  }

  if (!is.null(indicator_names)) {
    if (!is.character(indicator_names) || is.null(names(indicator_names))) {
      stop_dr("`indicator_names` must be a named character vector, for example c(IMPATTO = \"impact\").")
    }
    unknown <- setdiff(names(indicator_names), unique(ind[is_item]))
    if (length(unknown) > 0L) {
      stop_dr("`indicator_names` refers to indicator(s) not in the file: ", show_values(unknown), ".")
    }
    hit <- ind %in% names(indicator_names)
    ind[hit] <- indicator_names[ind[hit]]
  }

  statements <- unique(item_lab[is_item])
  codes <- paste0(item_prefix, seq_along(statements))
  code_of <- stats::setNames(codes, statements)
  indicators <- unique(ind[is_item])

  other <- which(!is_item)
  other_names <- ifelse(nzchar(lab[other]), lab[other], paste0("V", other))
  body <- raw[-(1:2), , drop = FALSE]

  # Drop rows without an expert identifier (e.g. summary rows) once, before
  # stacking, so that they are counted only once
  if (!is.null(expert_col)) {
    if (!is_string(expert_col) || !expert_col %in% other_names) {
      stop_dr(
        "`expert_col`: column '", expert_col, "' not found in the second header row ",
        "among the columns that are not items (", show_values(other_names), ")."
      )
    }
    id <- trimws(as.character(body[[other[match(expert_col, other_names)]]]))
    no_id <- is.na(id) | !nzchar(id)
    if (all(no_id)) {
      stop_dr("Column '", expert_col, "' contains no expert identifiers.")
    }
    if (any(no_id)) {
      warn_dr(
        sum(no_id), " row(s) without an expert identifier were ignored ",
        "(for example summary rows with medians or quartiles)."
      )
      body <- body[!no_id, , drop = FALSE]
    }
  }

  blocks <- lapply(indicators, function(k) {
    cols <- which(is_item & ind == k)
    keys <- code_of[item_lab[cols]]
    if (anyDuplicated(keys)) {
      stop_dr("Item '", names(keys)[duplicated(keys)][1L], "' has more than one column for indicator '", k, "'.")
    }
    out <- body[, other, drop = FALSE]
    names(out) <- other_names
    out$.indicator <- rep(k, nrow(body))
    for (j in seq_along(cols)) {
      out[[keys[j]]] <- body[[cols[j]]]
    }
    out
  })
  all_items <- codes
  blocks <- lapply(blocks, function(b) {
    for (it in setdiff(all_items, names(b))) b[[it]] <- NA
    b[c(other_names, ".indicator", all_items)]
  })
  stacked <- do.call(rbind, blocks)
  rownames(stacked) <- NULL
  list(data = stacked, items = codes, labels = stats::setNames(statements, codes))
}

tools_file_ext <- function(x) {
  pos <- regexpr("\\.([[:alnum:]]+)$", x)
  ifelse(pos > -1L, substring(x, pos + 1L), "")
}

detect_sep <- function(file, encoding) {
  con <- file(file, encoding = encoding)
  on.exit(close(con))
  first <- readLines(con, n = 1L, warn = FALSE)
  if (length(first) == 0L) {
    stop_dr("The file '", file, "' is empty.")
  }
  counts <- c(
    ";" = lengths(regmatches(first, gregexpr(";", first, fixed = TRUE))),
    "," = lengths(regmatches(first, gregexpr(",", first, fixed = TRUE))),
    "\t" = lengths(regmatches(first, gregexpr("\t", first, fixed = TRUE)))
  )
  if (all(counts == 0L)) {
    return(",")
  }
  names(counts)[which.max(counts)]
}

read_delim_delphi <- function(file, sep, dec, encoding, header = TRUE) {
  if (is.null(sep)) {
    sep <- detect_sep(file, encoding)
  }
  if (is.null(dec)) {
    dec <- if (sep == ";") "," else "."
  }
  utils::read.table(
    file,
    header = header,
    sep = sep,
    dec = dec,
    quote = "\"",
    na.strings = c("", "NA"),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    strip.white = TRUE,
    comment.char = "",
    fileEncoding = encoding
  )
}

read_excel_delphi <- function(file, sheet, header = TRUE) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop_dr(
      "Reading Excel files requires the 'readxl' package. ",
      "Install it with install.packages(\"readxl\")."
    )
  }
  if (header) {
    out <- readxl::read_excel(file, sheet = sheet)
  } else {
    out <- readxl::read_excel(file, sheet = sheet, col_names = FALSE,
                              col_types = "text", .name_repair = "minimal")
  }
  as.data.frame(out, stringsAsFactors = FALSE)
}

# Item statements from an Excel sheet with columns `item` and `statement`.
# Rows with an empty statement are skipped.
read_items_sheet <- function(file, sheet) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop_dr(
      "Reading Excel files requires the 'readxl' package. ",
      "Install it with install.packages(\"readxl\")."
    )
  }
  it <- as.data.frame(readxl::read_excel(file, sheet = sheet, col_types = "text"),
                      stringsAsFactors = FALSE)
  names(it) <- tolower(trimws(names(it)))
  if (!all(c("item", "statement") %in% names(it))) {
    stop_dr("The sheet '", sheet, "' must have two columns named 'item' and 'statement'.")
  }
  item <- trimws(it$item)
  statement <- trimws(it$statement)
  keep <- !is.na(item) & nzchar(item) & !is.na(statement) & nzchar(statement)
  if (!any(keep)) {
    return(NULL)
  }
  stats::setNames(statement[keep], item[keep])
}
