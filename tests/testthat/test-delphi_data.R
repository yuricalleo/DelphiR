wide_r1 <- function() {
  data.frame(
    expert = c("A", "B", "C", "D"),
    E1 = c(7, 8, 6, 9),
    E2 = c(3, 5, 4, NA)
  )
}

test_that("a single wide table becomes a delphi_data object", {
  x <- delphi_data(wide_r1(), expert_col = "expert", indicator = "impact")
  expect_s3_class(x, "delphi_data")
  expect_true(is_delphi_data(x))
  expect_equal(x$items, c("E1", "E2"))
  expect_equal(nrow(x$data), 8L)
  expect_equal(names(x$data), c("expert", "round", "indicator", "item", "value"))
  expect_equal(unique(x$data$round), 1L)
  expect_equal(names(x$scales), "impact")
  expect_equal(sum(is.na(x$data$value)), 1L)
})

test_that("experts are numbered when no id column is given", {
  x <- delphi_data(wide_r1()[-1])
  expect_equal(sort(unique(x$data$expert)), c("R1-EXP01", "R1-EXP02", "R1-EXP03", "R1-EXP04"))
  expect_false(x$linked)
})

test_that("an expert column is required for stacked tables", {
  df <- cbind(round = c(1, 1, 2, 2), wide_r1()[-1])
  expect_error(delphi_data(df, round_col = "round"), "expert_col")
})

test_that("ratings outside the scale are caught", {
  df <- wide_r1()
  df$E1[2] <- 12
  expect_error(delphi_data(df, expert_col = "expert", scale = c(1, 10)), "outside the scale")
  expect_warning(
    x <- delphi_data(df, expert_col = "expert", scale = c(1, 10), out_of_scale = "na"),
    "set to NA"
  )
  expect_true(is.na(x$data$value[x$data$expert == "B" & x$data$item == "E1"]))
})

test_that("text ratings with decimal commas are converted", {
  df <- data.frame(expert = c("A", "B"), E1 = c("7,5", " 8 "), E2 = c("", "3"))
  x <- delphi_data(df, expert_col = "expert")
  expect_equal(x$data$value[x$data$item == "E1"], c(7.5, 8))
  expect_true(is.na(x$data$value[x$data$item == "E2" & x$data$expert == "A"]))
})

test_that("non-numeric ratings give a clear error", {
  df <- data.frame(expert = c("A", "B"), E1 = c("high", "3"))
  expect_error(delphi_data(df, expert_col = "expert"), "non-numeric")
})

test_that("duplicated experts are rejected", {
  df <- wide_r1()
  df$expert[2] <- "A"
  expect_error(delphi_data(df, expert_col = "expert"), "more than one rating")
})

test_that("unknown columns and bad scales give errors", {
  expect_error(delphi_data(wide_r1(), expert_col = "id"), "not found")
  expect_error(delphi_data(wide_r1(), expert_col = "expert", items = "E9"), "not found")
  expect_error(delphi_data(wide_r1(), expert_col = "expert", scale = c(10, 1)), "min < max")
  expect_error(delphi_data(wide_r1(), expert_col = "expert", round = 0), "positive")
  expect_error(delphi_data(list(a = 1)), "data frame")
})

test_that("stacked rounds and indicators are read with per-indicator scales", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  expect_equal(sort(unique(x$data$round)), 1:2)
  expect_equal(names(x$scales), c("impact", "plausibility"))
  expect_equal(length(unique(x$data$expert)), 15L)
  expect_error(
    delphi_data(delphi_example, expert_col = "expert", round_col = "round",
                indicator_col = "indicator", scale = list(impact = c(1, 10))),
    "plausibility"
  )
})

test_that("delphi_bind combines rounds and checks scales", {
  r1 <- delphi_data(wide_r1(), expert_col = "expert", round = 1)
  r2 <- delphi_data(wide_r1(), expert_col = "expert", round = 2)
  x <- delphi_bind(r1, r2)
  expect_equal(sort(unique(x$data$round)), 1:2)
  expect_equal(nrow(x$data), 16L)
  expect_s3_class(delphi_bind(list(r1, r2)), "delphi_data")

  r2b <- delphi_data(wide_r1(), expert_col = "expert", round = 2, scale = c(0, 10))
  expect_error(delphi_bind(r1, r2b), "different scales")
  expect_error(delphi_bind(r1, r1), "more than one rating")
})

test_that("wide and long conversions round-trip", {
  x <- delphi_data(wide_r1(), expert_col = "expert", indicator = "impact")
  w <- delphi_wide(x)
  expect_equal(w$E1, wide_r1()$E1)
  expect_equal(w$E2, wide_r1()$E2)
  expect_equal(nrow(as.data.frame(x)), 8L)
})

test_that("print and summary run", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  expect_output(print(x), "Experts:    15")
  s <- summary(x)
  expect_s3_class(s, "summary.delphi_data")
  expect_output(print(s), "Median \\[IQR\\]")
})


test_that("rows without an expert identifier are ignored with a warning", {
  df <- data.frame(expert = c("A", "B", NA, ""), E1 = c(7, 8, 7.5, 1))
  expect_warning(x <- delphi_data(df, expert_col = "expert"), "2 row\\(s\\) without")
  expect_equal(sort(unique(x$data$expert)), c("A", "B"))
  expect_error(delphi_data(data.frame(expert = c(NA, NA), E1 = 1:2), expert_col = "expert"),
               "no expert identifiers")
})

test_that("item labels are stored and combined", {
  x1 <- delphi_data(wide_r1(), expert_col = "expert", item_labels = c(E1 = "First"))
  expect_equal(unname(x1$labels), c("First", NA))
  x2 <- delphi_data(wide_r1(), expert_col = "expert", round = 2,
                    item_labels = c("First", "Second"))
  expect_equal(unname(delphi_bind(x1, x2)$labels), c("First", "Second"))
  expect_error(delphi_data(wide_r1(), expert_col = "expert", item_labels = c(E9 = "x")), "unknown")
  expect_error(delphi_data(wide_r1(), expert_col = "expert", item_labels = "x"), "one label per item")
})

test_that("unlinked panels are flagged and propagated", {
  r1 <- delphi_data(wide_r1(), expert_col = "expert", round = 1, linked = FALSE)
  r2 <- delphi_data(wide_r1(), expert_col = "expert", round = 2)
  x <- delphi_bind(r1, r2)
  expect_false(x$linked)
  p <- delphi_panel(x)
  expect_equal(p$respondents, c(4L, 4L))
  expect_true(all(is.na(p$retention)))
  expect_output(print(x), "not linked across rounds")
  expect_output(print(summary(x)), "retention is not computed")
  expect_error(delphi_data(wide_r1(), linked = NA), "TRUE or FALSE")
})
