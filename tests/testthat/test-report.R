example_x <- function() {
  delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
}

test_that("arguments are validated before rendering", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available())
  x <- example_x()
  expect_error(delphi_report(x, file.path(tempdir(), "r.pdf"), open = FALSE), "html or .docx")
  expect_error(delphi_report(x, file.path(tempdir(), "r.html"), item_labels = c(E99 = "x"),
                             open = FALSE), "unknown item")
  expect_error(delphi_report(x, file.path(tempdir(), "r.html"), item_labels = "x",
                             open = FALSE), "named character")
  expect_error(delphi_report(x, file.path(tempdir(), "r.html"), threshold = 2,
                             open = FALSE), "proportion")
  expect_error(delphi_report(x, file.path(tempdir(), "no-such-dir", "r.html"),
                             open = FALSE), "does not exist")
})

test_that("HTML and Word reports are created", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available())
  x <- example_x()
  dir <- withr::local_tempdir()

  html <- delphi_report(x, file.path(dir, "report.html"), author = "A. Author",
                        item_labels = c(E1 = "First statement"), open = FALSE)
  expect_true(file.exists(html))
  txt <- paste(readLines(html, warn = FALSE), collapse = "\n")
  expect_match(txt, "Items for the next round")
  expect_match(txt, "von der Gracht")
  expect_match(txt, "First statement")

  docx <- delphi_report(x, file.path(dir, "report.docx"), open = FALSE)
  expect_true(file.exists(docx))

  # a single round and a single indicator
  one <- delphi_data(data.frame(E1 = c(5, 6, 6, 7), E2 = c(1, 4, 8, 10)),
                     indicator = "impact")
  html1 <- delphi_report(one, file.path(dir, "one.html"), open = FALSE)
  txt1 <- paste(readLines(html1, warn = FALSE), collapse = "\n")
  expect_match(txt1, "stability\\s+cannot\\s+yet\\s+be\\s+assessed")

  # unlinked panel with stored item labels
  u <- delphi_bind(
    delphi_data(data.frame(E1 = c(5, 6, 6, 7)), item_labels = "Stored statement"),
    delphi_data(data.frame(E1 = c(6, 6, 7, 7, 8)), round = 2)
  )
  html2 <- delphi_report(u, file.path(dir, "unlinked.html"), open = FALSE)
  txt2 <- paste(readLines(html2, warn = FALSE), collapse = " ")
  expect_match(txt2, "Stored statement")
  expect_match(txt2, "rank-sum")
  expect_match(txt2, "not\\s+linked")
})
