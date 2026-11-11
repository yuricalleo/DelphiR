#' Create a data-entry template
#'
#' @description
#' Writes an empty file in the DelphiR format, ready to be filled in with the
#' ratings of a Delphi study and imported with [read_delphi()]. Excel
#' templates contain three sheets:
#'
#' * `ratings`, with the column headers of the chosen layout;
#' * `items`, listing the item codes, next to which the full statements can
#'   be written;
#' * `instructions`, explaining how to fill in the template, with an example
#'   and the R code to import it.
#'
#' CSV templates contain the `ratings` table only.
#'
#' @param file Path of the template, ending in `.xlsx` or `.csv`.
#' @param items Number of items, or a character vector of item codes. By
#'   default, ten items coded `E1` to `E10`.
#' @param layout `"wide"` (default), with one row per expert, round and
#'   indicator and one column per item, or `"long"`, with one row per
#'   rating.
#' @param indicators Indicator labels shown in the instructions, for example
#'   `c("impact", "probability")`.
#' @param overwrite Whether to replace an existing file.
#'
#' @details
#' Excel templates require the \pkg{writexl} package. Every row of the
#' `ratings` sheet must identify the expert and the round; in the wide
#' layout, each row also names the indicator to which its ratings refer.
#' The same expert should keep the same identifier in every round, so that
#' individual opinions can be followed across rounds.
#'
#' @return The path of the template, invisibly.
#' @seealso [read_delphi()] to import the completed template.
#' @examples
#' \donttest{
#' if (requireNamespace("writexl", quietly = TRUE)) {
#'   path <- delphi_template(file.path(tempdir(), "delphi_template.xlsx"),
#'                           items = 8, indicators = c("impact", "probability"))
#'   path
#' }
#' }
#' # A CSV template in the long layout
#' path <- delphi_template(file.path(tempdir(), "delphi_long.csv"), layout = "long")
#' readLines(path)
#' @export
delphi_template <- function(file, items = 10,
                            layout = c("wide", "long"),
                            indicators = c("impact", "probability"),
                            overwrite = FALSE) {
  layout <- match.arg(layout)
  if (missing(file) || !is_string(file)) {
    stop_dr("`file` must be the path of the template, ending in .xlsx or .csv.")
  }
  ext <- tolower(tools_file_ext(file))
  if (!ext %in% c("xlsx", "csv")) {
    stop_dr("`file` must end in .xlsx or .csv.")
  }
  if (file.exists(file) && !isTRUE(overwrite)) {
    stop_dr("The file '", file, "' already exists; use `overwrite = TRUE` to replace it.")
  }
  if (!dir.exists(dirname(file))) {
    stop_dr("The folder '", dirname(file), "' does not exist.")
  }
  if (is.numeric(items) && length(items) == 1L && is_whole(items) && items >= 1) {
    codes <- paste0("E", seq_len(items))
  } else if (is.character(items) && length(items) >= 1L && !anyNA(items) &&
             all(nzchar(trimws(items)))) {
    codes <- trimws(items)
    if (anyDuplicated(codes)) {
      stop_dr("Item codes must be unique.")
    }
  } else {
    stop_dr("`items` must be a positive whole number or a character vector of item codes.")
  }
  if (!is.character(indicators) || length(indicators) < 1L || anyNA(indicators) ||
      any(!nzchar(trimws(indicators)))) {
    stop_dr("`indicators` must be a character vector of indicator labels.")
  }
  indicators <- trimws(indicators)

  ratings <- template_ratings(codes, layout)

  if (ext == "csv") {
    utils::write.csv(ratings, file, row.names = FALSE, na = "")
    return(invisible(file))
  }

  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop_dr(
      "Excel templates require the 'writexl' package. ",
      "Install it with install.packages(\"writexl\"), or create a .csv template."
    )
  }
  sheets <- list(
    ratings = ratings,
    items = data.frame(item = codes, statement = rep("", length(codes)),
                       stringsAsFactors = FALSE),
    instructions = template_instructions(codes, layout, indicators, basename(file))
  )
  writexl::write_xlsx(sheets, file)
  invisible(file)
}

template_ratings <- function(codes, layout) {
  if (layout == "wide") {
    cols <- c("expert", "round", "indicator", codes)
  } else {
    cols <- c("expert", "round", "indicator", "item", "value")
  }
  out <- as.data.frame(matrix(character(0), nrow = 0, ncol = length(cols)),
                       stringsAsFactors = FALSE)
  names(out) <- cols
  out
}

template_instructions <- function(codes, layout, indicators, file) {
  ex_items <- utils::head(codes, 3L)
  ex_ind <- utils::head(indicators, 2L)
  if (layout == "wide") {
    k <- seq_along(ex_items)
    row <- function(expert, ind, vals) {
      paste(c(expert, "1", ind, vals[k]), collapse = " | ")
    }
    example <- c(
      paste(c("expert", "round", "indicator", ex_items), collapse = " | "),
      row("EXP01", ex_ind[1L], c("8", "6", "9")),
      row("EXP02", ex_ind[1L], c("7", "", "8"))
    )
    if (length(ex_ind) > 1L) {
      example <- c(example, row("EXP01", ex_ind[2L], c("5", "7", "6")))
    }
    rules <- c(
      "Each row contains the ratings given by one expert, in one round, on one indicator.",
      "Columns E1, E2, ... contain the ratings of the items, one item per column.",
      "Write the round as a whole number (1, 2, ...) and the indicator as a short label without spaces, for example impact.",
      "If the items are rated on several indicators, use one row per indicator for each expert."
    )
    code <- paste0(
      "x <- read_delphi(\"", file, "\", sheet = \"ratings\", items_sheet = \"items\", ",
      "expert_col = \"expert\", round_col = \"round\", indicator_col = \"indicator\", ",
      "scale = c(1, 10))"
    )
  } else {
    example <- c(
      "expert | round | indicator | item | value",
      paste("EXP01 | 1 |", ex_ind[1L], "|", ex_items[1L], "| 8"),
      paste("EXP01 | 1 |", ex_ind[1L], "|", utils::tail(ex_items, 1L), "| 6"),
      paste("EXP02 | 1 |", ex_ind[1L], "|", ex_items[1L], "| 7")
    )
    rules <- c(
      "Each row contains one rating: the expert, the round, the indicator, the item and the value.",
      "Write the round as a whole number (1, 2, ...) and the indicator as a short label without spaces, for example impact.",
      "Item codes must match those listed in the sheet items."
    )
    code <- paste0(
      "x <- read_delphi(\"", file, "\", sheet = \"ratings\", layout = \"long\", ",
      "items_sheet = \"items\", round_col = \"round\", indicator_col = \"indicator\", ",
      "scale = c(1, 10))"
    )
  }
  text <- c(
    "DelphiR data-entry template",
    "",
    "Sheet ratings",
    rules,
    paste0("Indicators of this study: ", paste(indicators, collapse = ", "), "."),
    "Use the same expert identifier in every round, so that individual opinions can be followed across rounds.",
    "Leave a cell empty when a rating is missing. Do not add summary rows (medians, quartiles) below the data.",
    "Ratings must be numbers within the rating scale of the indicator, for example from 1 to 10.",
    "",
    "Sheet items",
    "Write the full statement of each item next to its code. Statements are optional and are used in reports.",
    "Item codes can be changed, provided that the same codes are used in the sheet ratings.",
    "",
    "Example (columns separated by |)",
    example,
    "",
    "Import in R (adapt the scale to your study)",
    "library(DelphiR)",
    code,
    "summary(x)"
  )
  data.frame(instructions = text, stringsAsFactors = FALSE)
}
