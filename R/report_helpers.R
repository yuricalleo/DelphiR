# Helpers for the R Markdown templates of inst/report

# Pipe table with explicit relative column widths. Each column is at least
# as wide as the longest word of its header and its longest entry, and the
# separator line is made longer than Pandoc's 72 columns so that the table
# spans the text width in both HTML and Word.
md_table <- function(df, digits = 2) {
  cells <- lapply(df, function(v) {
    if (is.double(v)) {
      out <- formatC(round(v, digits), format = "f", digits = digits)
      out <- sub("\\.?0+$", "", out)
    } else {
      out <- as.character(v)
    }
    out[is.na(v)] <- ""
    out
  })
  hdr <- names(df)
  right <- vapply(df, is.numeric, logical(1))
  w <- mapply(function(h, v) {
    max(c(nchar(strsplit(h, " ", fixed = TRUE)[[1]]), nchar(v), 4)) + 3
  }, hdr, cells)
  # Long statements wrap inside their cell instead of squeezing the short
  # columns: when the table is too wide, only columns wider than 14
  # characters are narrowed
  w <- pmin(w, 40)
  if (sum(w) > 78) {
    big <- w > 14
    room <- sum(w[big] - 14)
    if (room > 0) {
      w[big] <- w[big] - (w[big] - 14) * min(1, (sum(w) - 78) / room)
    }
  }
  w <- ceiling(w)
  if (sum(w + 3) < 80) w <- ceiling(w * 80 / sum(w + 3))
  sep <- ifelse(right, paste0(strrep("-", w - 1), ":"),
                paste0(":", strrep("-", w - 1)))
  row <- function(v) paste0("| ", paste(v, collapse = " | "), " |")
  rows <- vapply(seq_len(nrow(df)), function(i) {
    row(vapply(cells, `[`, character(1), i))
  }, character(1))
  c("", row(hdr), row(sep), rows, "")
}

# Escape the characters that Markdown would interpret in free text, and a
# leading number or dash that would start a list
md_escape <- function(s) {
  s <- gsub("([\\\\`*_{}<>#|~^]|\\[|\\])", "\\\\\\1", s)
  s <- sub("^([0-9]+)([.)])", "\\1\\\\\\2", s)
  sub("^([-+])", "\\\\\\1", s)
}
