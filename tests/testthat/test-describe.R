test_that("descriptive statistics match base R", {
  df <- data.frame(expert = LETTERS[1:6], E1 = c(2, 4, 4, 5, 7, 9), E2 = c(1, 1, 2, NA, 10, 10))
  x <- delphi_data(df, expert_col = "expert", scale = c(1, 10))
  d <- delphi_describe(x)

  expect_s3_class(d, "delphi_describe")
  expect_equal(nrow(d), 2L)
  e1 <- d[d$item == "E1", ]
  v <- df$E1
  expect_equal(e1$n, 6L)
  expect_equal(e1$mean, mean(v))
  expect_equal(e1$sd, sd(v))
  expect_equal(e1$median, median(v))
  expect_equal(e1$iqr, unname(diff(quantile(v, c(0.25, 0.75)))))
  expect_equal(e1$iqr_rel, e1$iqr / 10)
  expect_equal(delphi_describe(x, relative_to = "range")$iqr_rel[1], e1$iqr / 9)
  expect_equal(e1$cv, sd(v) / mean(v))

  e2 <- d[d$item == "E2", ]
  expect_equal(e2$n, 5L)
  expect_equal(e2$missing, 1L)
})

test_that("quantile type can be changed", {
  df <- data.frame(expert = LETTERS[1:6], E1 = c(2, 4, 4, 5, 7, 9))
  x <- delphi_data(df, expert_col = "expert")
  d6 <- delphi_describe(x, type = 6)
  expect_equal(d6$q1, unname(quantile(df$E1, 0.25, type = 6)))
})

test_that("subsets work and unknown values are reported", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  d <- delphi_describe(x, round = 2, indicator = "impact", items = c("E1", "E5"))
  expect_equal(nrow(d), 2L)
  expect_equal(unique(d$round), 2L)
  expect_error(delphi_describe(x, round = 3), "not in the data")
  expect_error(delphi_describe(x, indicator = "risk"), "not in the data")
  expect_error(delphi_describe(x, items = "E99"), "not in the data")
  expect_output(print(d), "median")
})

test_that("items with a single or no rating do not fail", {
  df <- data.frame(expert = c("A", "B"), E1 = c(5, NA), E2 = c(NA, NA))
  x <- delphi_data(df, expert_col = "expert")
  d <- delphi_describe(x)
  expect_true(is.na(d$sd[d$item == "E1"]))
  expect_equal(d$n[d$item == "E2"], 0L)
})

test_that("panel retention is computed across rounds", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  p <- delphi_panel(x)
  expect_equal(p$respondents, c(15L, 13L))
  expect_equal(p$dropped[2], 2L)
  expect_equal(p$joined[2], 0L)
  expect_equal(p$retention, c(1, 13 / 15))
})
