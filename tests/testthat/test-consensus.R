make_x <- function(values, scale = c(1, 10)) {
  df <- data.frame(expert = paste0("X", seq_along(values[[1]])))
  for (i in names(values)) df[[i]] <- values[[i]]
  delphi_data(df, expert_col = "expert", scale = scale)
}

test_that("the 20% rule gives IQR <= 2 on a 1-10 scale", {
  # quantile type 7: IQR(E1) = 2, IQR(E2) = 3
  x <- make_x(list(E1 = c(4, 5, 6, 6, 7, 8, 6, 5, 7),
                   E2 = c(1, 3, 4, 5, 6, 7, 8, 2, 6)))
  iq <- c(IQR(c(4, 5, 6, 6, 7, 8, 6, 5, 7)), IQR(c(1, 3, 4, 5, 6, 7, 8, 2, 6)))
  expect_equal(iq, c(2, 3))
  cons <- delphi_consensus(x)
  expect_s3_class(cons, "delphi_consensus")
  expect_equal(cons$iqr_max, c(2, 2))
  expect_equal(cons$consensus, c(TRUE, FALSE))
  expect_equal(cons$iqr_rel, iq / 10)
})

test_that("the 20% rule gives IQR <= 1 on a 1-5 scale", {
  x <- make_x(list(E1 = c(3, 3, 4, 4, 4, 5, 5)), scale = c(1, 5))
  expect_equal(IQR(c(3, 3, 4, 4, 4, 5, 5)), 1)
  expect_true(delphi_consensus(x)$consensus)
  # with max - min as reference the cut-off is 0.8
  expect_false(delphi_consensus(x, relative_to = "range")$consensus)
})

test_that("each indicator uses its own scale", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  cons <- delphi_consensus(x)
  expect_equal(unique(cons$iqr_max[cons$indicator == "impact"]), 2)
  expect_equal(unique(cons$iqr_max[cons$indicator == "plausibility"]), 20)
  # the polarised item never reaches consensus
  expect_false(any(cons$consensus[cons$item == "E5"]))
  expect_equal(attr(cons, "rule")$threshold, 0.20)
  expect_output(print(cons), "Items with consensus")
  expect_output(print(summary(x)), "\\* = consensus")
})

test_that("threshold is validated and items without ratings give NA", {
  x <- make_x(list(E1 = c(5, 6, 7), E2 = c(NA, NA, NA)))
  expect_error(delphi_consensus(x, threshold = 20), "proportion")
  expect_error(delphi_consensus(x, threshold = c(0.1, 0.2)), "proportion")
  expect_true(is.na(delphi_consensus(x)$consensus[2]))
  expect_true(all(delphi_consensus(x, threshold = 1)$consensus[1]))
})
