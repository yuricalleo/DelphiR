#' Generate a round report
#'
#' @description
#' Writes a self-contained report of a Delphi study, in HTML or Word format,
#' ready to be shared with the research team or attached to the controlled
#' feedback of the next round. The report contains:
#'
#' * an overview of the study and, optionally, the list of item statements;
#' * a methods section stating the consensus and stability criteria, with
#'   references;
#' * panel participation and retention across rounds;
#' * for each indicator, summary statistics, consensus and item status at
#'   the assessed round, stability between consecutive rounds, and the
#'   distribution and trend figures;
#' * the consensus heat map and, with two or more indicators, the
#'   two-indicator map;
#' * the items to be submitted to a further round.
#'
#' @param x A `delphi_data` object.
#' @param file Path of the report. The extension sets the format: `.html`
#'   for HTML, `.docx` for Microsoft Word.
#' @param title,author Title and author(s) shown in the report header.
#'   `author` may be `NULL`.
#' @param round Round to assess, for each indicator. `NULL` (default) uses
#'   the last round; see [delphi_status()].
#' @param item_labels Optional named character vector with the full
#'   statement of each item, named by item code, for example
#'   `c(E1 = "Remote work becomes the norm", E2 = "...")`. By default, the
#'   labels stored in `x` (see [delphi_data()] and [read_delphi()]) are used.
#' @param threshold,relative_to Consensus rule, see [delphi_consensus()].
#' @param method,alpha,scheibe,paired Stability rule, see [delphi_stability()].
#' @param type Quantile algorithm; see [delphi_describe()].
#' @param open Whether to open the report once it has been created.
#' @param quiet Whether to suppress the rendering messages.
#'
#' @details
#' The report requires the \pkg{rmarkdown} and \pkg{knitr} packages and a
#' Pandoc installation; Pandoc is included in RStudio. All text is in
#' English.
#'
#' @return The path of the report, invisibly.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' \donttest{
#' if (requireNamespace("rmarkdown", quietly = TRUE) &&
#'     rmarkdown::pandoc_available()) {
#'   out <- delphi_report(x, file.path(tempdir(), "report.html"), open = FALSE)
#'   file.exists(out)
#' }
#' }
#' @export
delphi_report <- function(x, file,
                          title = "Delphi study: round report", author = NULL,
                          round = NULL, item_labels = NULL,
                          threshold = 0.20, relative_to = c("points", "range"),
                          method = c("wilcoxon", "scheibe", "both"),
                          alpha = 0.05, scheibe = 0.15, type = 7, paired = NULL,
                          open = interactive(), quiet = TRUE) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  method <- match.arg(method)
  for (pkg in c("rmarkdown", "knitr")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop_dr("Reports require the '", pkg, "' package. Install it with install.packages(\"", pkg, "\").")
    }
  }
  if (!rmarkdown::pandoc_available()) {
    stop_dr("Reports require Pandoc, which is included in RStudio (https://pandoc.org).")
  }
  if (missing(file) || !is_string(file)) {
    stop_dr("`file` must be the path of the report, ending in .html or .docx.")
  }
  ext <- tolower(tools_file_ext(file))
  format <- switch(ext,
    html = rmarkdown::html_document(toc = TRUE, number_sections = TRUE),
    docx = rmarkdown::word_document(),
    stop_dr("`file` must end in .html or .docx.")
  )
  if (!is_string(title)) {
    stop_dr("`title` must be a single string.")
  }
  if (!is.null(author) && (!is.character(author) || anyNA(author))) {
    stop_dr("`author` must be a character vector or NULL.")
  }
  if (!is.null(item_labels)) {
    if (!is.character(item_labels) || is.null(names(item_labels))) {
      stop_dr("`item_labels` must be a named character vector, for example c(E1 = \"...\").")
    }
    unknown <- setdiff(names(item_labels), x$items)
    if (length(unknown) > 0L) {
      stop_dr("`item_labels` refers to unknown item(s): ", show_values(unknown), ".")
    }
  }
  if (is.null(item_labels)) {
    lab <- obj_labels(x)
    item_labels <- if (all(is.na(lab))) NULL else lab[!is.na(lab)]
  }
  if (is.null(paired)) {
    paired <- obj_linked(x)
  }
  # Fail early, with a clear message, on invalid rules
  delphi_status(x, round = round, threshold = threshold, relative_to = relative_to,
                method = method, alpha = alpha, scheibe = scheibe, type = type,
                paired = paired)

  template <- system.file("report", "delphi_report.Rmd", package = "DelphiR")
  if (!nzchar(template)) {
    stop_dr("The report template could not be found; please reinstall DelphiR.")
  }
  work <- tempfile("delphi_report_")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  rmd <- file.path(work, "report.Rmd")
  header <- c(
    "---",
    paste0("title: ", yaml_string(title)),
    if (!is.null(author)) paste0("author: ", yaml_string(paste(author, collapse = ", "))),
    paste0("date: ", yaml_string(format(Sys.Date(), "%d %B %Y"))),
    "---",
    ""
  )
  body <- readLines(template, encoding = "UTF-8", warn = FALSE)
  writeLines(enc2utf8(c(header, body)), rmd, useBytes = TRUE)

  cfg <- list(
    round = round, item_labels = item_labels, threshold = threshold,
    relative_to = relative_to, method = method, alpha = alpha,
    scheibe = scheibe, type = type, paired = paired, linked = obj_linked(x)
  )
  env <- new.env(parent = asNamespace("DelphiR"))
  env$x <- x
  env$cfg <- cfg

  out_dir <- dirname(file)
  if (!dir.exists(out_dir)) {
    stop_dr("The folder '", out_dir, "' does not exist.")
  }
  out <- rmarkdown::render(
    rmd,
    output_format = format,
    output_file = basename(file),
    output_dir = normalizePath(out_dir),
    intermediates_dir = work,
    envir = env,
    quiet = quiet
  )
  if (isTRUE(open)) {
    utils::browseURL(out)
  }
  invisible(out)
}

yaml_string <- function(s) {
  paste0("\"", gsub("\"", "\\\\\"", gsub("\\\\", "\\\\\\\\", s)), "\"")
}
