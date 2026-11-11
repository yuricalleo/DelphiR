two_rounds <- function(r1, r2, scale = c(1, 10), ids2 = NULL) {
  e1 <- paste0("X", seq_along(r1[[1]]))
  e2 <- if (is.null(ids2)) paste0("X", seq_along(r2[[1]])) else ids2
  d1 <- data.frame(expert = e1, r1)
  d2 <- data.frame(expert = e2, r2)
  delphi_bind(
    delphi_data(d1, expert_col = "expert", round = 1, scale = scale),
    delphi_data(d2, expert_col = "expert", round = 2, scale = scale)
  )
}

test_that("unchanged ratings are stable under both criteria", {
  v <- c(3, 5, 7, 7, 8, 2)
  x <- two_rounds(list(E1 = v), list(E1 = v))
  s <- delphi_stability(x, method = "both")
  expect_s3_class(s, "delphi_stability")
  expect_equal(s$p_value, 1)
  expect_equal(s$scheibe_change, 0)
  expect_equal(s$changed, 0)
  expect_true(s$stable)
})

test_that("the Wilcoxon p-value matches stats::wilcox.test", {
  a <- c(2, 3, 4, 5, 3, 2, 4, 3, 5, 4)
  b <- c(6, 7, 8, 8, 6, 7, 8, 7, 9, 8)
  x <- two_rounds(list(E1 = a), list(E1 = b))
  s <- delphi_stability(x)
  p <- suppressWarnings(wilcox.test(b, a, paired = TRUE, exact = FALSE)$p.value)
  expect_equal(s$p_value, p)
  expect_false(s$stable)
  expect_equal(s$median_change, median(b) - median(a))
})

test_that("the Scheibe change counts net person-changes", {
  # 10 experts; 3 move from 4 to 6, the rest stay -> net change 30%
  a <- c(4, 4, 4, 5, 5, 5, 6, 6, 7, 7)
  b <- c(6, 6, 6, 5, 5, 5, 6, 6, 7, 7)
  x <- two_rounds(list(E1 = a), list(E1 = b))
  s <- delphi_stability(x, method = "scheibe")
  expect_equal(s$scheibe_change, 0.3)
  expect_false(s$stable)
  # swaps between experts leave the distribution unchanged
  x2 <- two_rounds(list(E1 = a), list(E1 = rev(a)))
  expect_equal(delphi_stability(x2)$scheibe_change, 0)
  expect_true(delphi_stability(x2, method = "scheibe")$stable)
  expect_equal(delphi_stability(x, scheibe = 0.30, method = "scheibe")$stable, TRUE)
})

test_that("long scales are grouped into classes for the Scheibe criterion", {
  expect_equal(length(DelphiR:::scheibe_breaks(c(1, 10), 10)), 11L)
  expect_equal(length(DelphiR:::scheibe_breaks(c(1, 100), 10)), 11L)
  a <- c(12, 14, 16, 52, 54)
  b <- c(13, 15, 17, 53, 55)
  x <- two_rounds(list(E1 = a), list(E1 = b), scale = c(1, 100))
  expect_equal(delphi_stability(x)$scheibe_change, 0)
})

test_that("only experts present in both rounds are paired", {
  x <- two_rounds(list(E1 = c(5, 6, 7, 8)), list(E1 = c(5, 6, 7)), ids2 = c("X1", "X2", "X9"))
  s <- delphi_stability(x)
  expect_equal(s$n_paired, 2L)
})

test_that("stability needs two rounds and valid settings", {
  x <- delphi_data(data.frame(E1 = c(1, 2, 3)))
  expect_error(delphi_stability(x), "two rounds")
  y <- two_rounds(list(E1 = c(1, 2)), list(E1 = c(1, 2)))
  expect_error(delphi_stability(y, alpha = 5), "proportion")
  expect_error(delphi_stability(y, bins = 1), "bins")
})

test_that("stability works on the example data with several indicators", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  s <- delphi_stability(x)
  expect_equal(nrow(s), 16L)
  expect_equal(attr(s, "rule")$method, "wilcoxon")
  expect_output(print(s), "Stable items")
})


test_that("unlinked rounds are compared as independent samples", {
  a <- c(2, 3, 4, 5, 3, 2, 4, 3, 5, 4)
  b <- c(6, 7, 8, 8, 6, 7, 8, 7)
  r1 <- delphi_data(data.frame(E1 = a))
  r2 <- delphi_data(data.frame(E1 = b), round = 2)
  x <- delphi_bind(r1, r2)
  expect_false(x$linked)
  s <- delphi_stability(x)
  expect_false(attr(s, "rule")$paired)
  p <- suppressWarnings(wilcox.test(b, a, exact = FALSE)$p.value)
  expect_equal(s$p_value, p)
  expect_equal(c(s$n_from, s$n_to), c(10L, 8L))
  expect_true(is.na(s$n_paired))
  expect_true(is.na(s$changed))
  # distributions do not overlap: the whole sample has moved
  expect_equal(s$scheibe_change, 1)
  expect_error(delphi_stability(x, paired = TRUE), "not linked")
  expect_output(print(s), "Unpaired comparison")
  st <- delphi_status(x)
  expect_equal(st$stable, FALSE)
})

test_that("linked data can be compared without pairing on request", {
  a <- c(2, 3, 4, 5, 3, 2, 4, 3, 5, 4)
  x <- two_rounds(list(E1 = a), list(E1 = rev(a)))
  s <- delphi_stability(x, paired = FALSE)
  expect_equal(s$scheibe_change, 0)
  expect_equal(s$p_value, 1)
})
