test_that("semicolon CSV with decimal comma is read", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("expert;E1;E2", "A;7,5;3", "B;8;", "C;6;4"), path)
  x <- read_delphi(path, expert_col = "expert", indicator = "impact")
  expect_s3_class(x, "delphi_data")
  expect_equal(x$data$value[x$data$item == "E1"], c(7.5, 8, 6))
  expect_equal(sum(is.na(x$data$value)), 1L)
})

test_that("comma CSV and long item names are read", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("id,Remote work by 2035,AI agents in HR", "1,4,5", "2,5,3"), path)
  x <- read_delphi(path, expert_col = "id")
  expect_equal(x$items, c("Remote work by 2035", "AI agents in HR"))
})

test_that("the bundled example file is read", {
  path <- system.file("extdata", "delphi_round1.csv", package = "DelphiR")
  x <- read_delphi(path, expert_col = "expert", indicator = "impact", scale = c(1, 10))
  expect_equal(length(unique(x$data$expert)), 15L)
  expect_equal(x$items, paste0("E", 1:8))
})

test_that("Excel files are read when readxl is available", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  path <- withr::local_tempfile(fileext = ".xlsx")
  writexl::write_xlsx(data.frame(expert = c("A", "B"), E1 = c(3, 9)), path)
  x <- read_delphi(path, expert_col = "expert")
  expect_equal(x$data$value, c(3, 9))
})

test_that("bad paths and types give errors", {
  expect_error(read_delphi("does-not-exist.csv"), "not found")
  path <- withr::local_tempfile(fileext = ".sav")
  writeLines("x", path)
  expect_error(read_delphi(path), "Unsupported file type")
})


test_that("files with two header rows are read and stacked", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c(
    ";;IMPATTO;PROBAB;IMPATTO;PROBAB",
    "ID;Age;1. First statement;;2. Second statement;",
    "11;30;8;6;5;4",
    "12;40;9;7;6;6",
    "13;50;7;7;4;5",
    ";;Median;;;",
    ";;8;7;5;5"
  ), path)
  expect_warning(
    x <- read_delphi(path, header_rows = 2, expert_col = "ID", scale = c(1, 10),
                     indicator_names = c(IMPATTO = "impact", PROBAB = "probability")),
    "2 row\\(s\\) without"
  )
  expect_equal(x$items, c("E1", "E2"))
  expect_equal(unname(x$labels), c("1. First statement", "2. Second statement"))
  expect_equal(names(x$scales), c("impact", "probability"))
  w <- delphi_wide(x, indicator = "probability")
  expect_equal(w$E1, c(6, 7, 7))
  expect_equal(w$E2, c(4, 6, 5))
  expect_error(read_delphi(path, header_rows = 2, expert_col = "ID", indicator = "a"),
               "read from the header")
  expect_error(read_delphi(path, header_rows = 2, expert_col = "Name"), "not found")
  expect_error(read_delphi(path, header_rows = 3), "1 or 2")
  expect_error(suppressWarnings(read_delphi(path, header_rows = 2, expert_col = "ID",
                                            indicator_names = c(RISK = "risk"))),
               "not in the file")
})

test_that("two header rows are read from Excel files", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  path <- withr::local_tempfile(fileext = ".xlsx")
  df <- data.frame(
    a = c(NA, "ID", "1", "2"),
    b = c("Impact", "Item one", "8", "9"),
    c = c("Probability", NA, "6", "7")
  )
  writexl::write_xlsx(df, path, col_names = FALSE)
  x <- read_delphi(path, header_rows = 2, expert_col = "ID", scale = c(1, 10))
  expect_equal(names(x$scales), c("Impact", "Probability"))
  expect_equal(unname(x$labels), "Item one")
  expect_equal(nrow(x$data), 4L)
})
