test_that("long tables are converted and validated", {
  long <- data.frame(
    expert = c("A", "A", "B", "B", NA),
    item = c("E1", "E2", "E1", "E2", "E1"),
    value = c("7", "3", "8,5", "", "9"),
    round = c(1, 1, 1, 1, 1)
  )
  expect_warning(x <- delphi_data_long(long, round_col = "round", indicator = "impact"),
                 "1 row\\(s\\) without")
  expect_s3_class(x, "delphi_data")
  expect_equal(x$items, c("E1", "E2"))
  w <- delphi_wide(x)
  expect_equal(w$E1, c(7, 8.5))
  expect_equal(w$E2, c(3, NA))

  dup <- data.frame(expert = c("A", "A"), item = c("E1", "E1"), value = c(1, 2))
  expect_error(delphi_data_long(dup), "more than one rating")
  expect_error(delphi_data_long(long[1:4, ], item_col = "question"), "not found")
  expect_error(delphi_data_long(data.frame(expert = "A", item = "", value = 1)), "empty item")
  expect_error(delphi_data_long(data.frame(expert = "A", item = "E1", value = 12)),
               "outside the scale")
  expect_error(delphi_data_long(data.frame(expert = "A", item = "E1", value = "high")),
               "non-numeric")
})

test_that("long and wide inputs give the same object", {
  x_wide <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  long <- as.data.frame(x_wide)
  x_long <- delphi_data_long(long, round_col = "round", indicator_col = "indicator",
                             scale = list(impact = c(1, 10), plausibility = c(1, 100)))
  expect_equal(x_long$data, x_wide$data)
  expect_equal(x_long$items, x_wide$items)
})

test_that("read_delphi reads long files", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines(c("expert,round,item,value", "A,1,E1,7", "A,1,E2,3", "B,1,E1,8", "B,1,E2,5"), path)
  x <- read_delphi(path, layout = "long", round_col = "round", indicator = "impact")
  expect_equal(nrow(x$data), 4L)
  expect_error(read_delphi(path, layout = "long", header_rows = 2), "single header row")
})

test_that("CSV templates have the expected columns", {
  dir <- withr::local_tempdir()
  wide <- delphi_template(file.path(dir, "wide.csv"), items = 3)
  expect_equal(readLines(wide), "\"expert\",\"round\",\"indicator\",\"E1\",\"E2\",\"E3\"")
  long <- delphi_template(file.path(dir, "long.csv"), layout = "long")
  expect_equal(readLines(long), "\"expert\",\"round\",\"indicator\",\"item\",\"value\"")
  codes <- delphi_template(file.path(dir, "codes.csv"), items = c("Q1", "Q2"))
  expect_match(readLines(codes), "\"Q1\",\"Q2\"")
  expect_error(delphi_template(wide), "already exists")
  expect_silent(delphi_template(wide, overwrite = TRUE))
  expect_error(delphi_template(file.path(dir, "t.txt")), "xlsx or .csv")
  expect_error(delphi_template(file.path(dir, "x.csv"), items = 0), "positive whole number")
  expect_error(delphi_template(file.path(dir, "y.csv"), items = c("A", "A")), "unique")
  expect_error(delphi_template(file.path(dir, "no-dir", "z.csv")), "does not exist")
  expect_error(delphi_template(), "path of the template")
})

test_that("Excel templates can be filled in and imported", {
  skip_if_not_installed("writexl")
  skip_if_not_installed("readxl")
  dir <- withr::local_tempdir()
  path <- delphi_template(file.path(dir, "template.xlsx"), items = 3,
                          indicators = c("impact", "probability"))
  expect_equal(readxl::excel_sheets(path), c("ratings", "items", "instructions"))
  expect_equal(names(readxl::read_excel(path, "ratings")),
               c("expert", "round", "indicator", "E1", "E2", "E3"))
  ins <- readxl::read_excel(path, "instructions")$instructions
  expect_true(any(grepl("read_delphi(", ins, fixed = TRUE)))
  expect_false(any(grepl("—", ins, fixed = TRUE)))

  filled <- file.path(dir, "filled.xlsx")
  writexl::write_xlsx(list(
    ratings = data.frame(
      expert = c("EXP01", "EXP02", "EXP01", "EXP02"),
      round = c(1, 1, 1, 1),
      indicator = c("impact", "impact", "probability", "probability"),
      E1 = c(8, 7, 5, 6), E2 = c(6, NA, 7, 7), E3 = c(9, 8, 6, 5)
    ),
    items = data.frame(item = c("E1", "E2", "E3"),
                       statement = c("First statement", "Second statement", ""))
  ), filled)
  x <- read_delphi(filled, sheet = "ratings", items_sheet = "items",
                   expert_col = "expert", round_col = "round",
                   indicator_col = "indicator", scale = c(1, 10))
  expect_equal(unname(x$labels), c("First statement", "Second statement", NA))
  expect_equal(names(x$scales), c("impact", "probability"))
  expect_error(read_delphi(filled, sheet = "ratings", items_sheet = "ratings",
                           expert_col = "expert", round_col = "round",
                           indicator_col = "indicator"), "'item' and 'statement'")
  expect_error(read_delphi(filled, items_sheet = "items", item_labels = c(E1 = "x"),
                           sheet = "ratings", expert_col = "expert", round_col = "round",
                           indicator_col = "indicator"), "not both")
})
