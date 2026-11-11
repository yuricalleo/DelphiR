test_that("the four statuses are assigned correctly", {
  r1 <- data.frame(
    expert = paste0("X", 1:10),
    A = c(7, 7, 8, 7, 8, 7, 8, 7, 8, 7),   # consensus, unchanged -> consensus
    B = c(2, 3, 4, 5, 3, 2, 4, 3, 5, 4),   # moves to consensus -> unstable consensus
    C = c(1, 10, 1, 10, 1, 10, 1, 10, 1, 10), # split, unchanged -> stable dissent
    D = c(1, 3, 5, 7, 9, 2, 4, 6, 8, 10)   # dispersed, moves -> open
  )
  r2 <- r1
  r2$B <- c(6, 7, 7, 7, 6, 7, 7, 7, 7, 6)
  r2$D <- c(4, 6, 7, 9, 10, 5, 6, 8, 10, 10)
  x <- delphi_bind(
    delphi_data(r1, expert_col = "expert", round = 1),
    delphi_data(r2, expert_col = "expert", round = 2)
  )
  st <- delphi_status(x)
  expect_s3_class(st, "delphi_status")
  expect_equal(st$status, c("consensus", "unstable consensus", "stable dissent", "open"))
  expect_equal(st$next_round, c(FALSE, TRUE, FALSE, TRUE))
  expect_output(print(st), "Items for the next round: B, D")
})

test_that("with a single round stability is NA", {
  x <- delphi_data(data.frame(E1 = c(5, 5, 6), E2 = c(1, 5, 10)))
  st <- delphi_status(x)
  expect_true(all(is.na(st$stable)))
  expect_equal(st$status, c("consensus", "open"))
})

test_that("a specific round can be assessed", {
  x <- delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
  st1 <- delphi_status(x, round = 1)
  expect_true(all(st1$round == 1))
  expect_true(all(is.na(st1$stable)))
  st2 <- delphi_status(x)
  expect_true(all(st2$round == 2))
  expect_equal(st2$status[st2$item == "E5"], c("stable dissent", "stable dissent"))
  expect_error(delphi_status(x, round = 5), "not in the data")
})
