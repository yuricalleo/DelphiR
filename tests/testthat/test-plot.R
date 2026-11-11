example_x <- function() {
  delphi_data(
    delphi_example,
    expert_col = "expert", round_col = "round", indicator_col = "indicator",
    scale = list(impact = c(1, 10), plausibility = c(1, 100))
  )
}

builds <- function(p) {
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
}

test_that("all figures are built without errors", {
  x <- example_x()
  builds(delphi_plot_distribution(x, indicator = "impact"))
  builds(delphi_plot_distribution(x, indicator = "impact", points = FALSE, items = c("E1", "E5")))
  builds(delphi_plot_trend(x, indicator = "plausibility"))
  builds(delphi_plot_consensus(x))
  builds(delphi_plot_consensus(x, indicator = "impact", round = 2))
  builds(delphi_plot_map(x))
  builds(delphi_plot_map(x, round = 1, iqr = FALSE))
  expect_s3_class(theme_delphi(), "theme")
})

test_that("plot() dispatches to the delphi_plot functions", {
  x <- example_x()
  for (tp in c("distribution", "trend", "consensus", "map")) {
    p <- suppressMessages(plot(x, type = tp))
    expect_s3_class(p, "ggplot")
  }
  expect_error(plot(x, type = "pie"))
})

test_that("the indicator is chosen with a message when several exist", {
  x <- example_x()
  expect_message(delphi_plot_distribution(x), "Showing indicator 'impact'")
  expect_error(delphi_plot_trend(x, indicator = "risk"), "must be one of")
})

test_that("the map checks its indicators and round", {
  x <- example_x()
  one <- delphi_data(data.frame(E1 = c(1, 2)))
  expect_error(delphi_plot_map(one), "at least two indicators")
  expect_error(delphi_plot_map(x, x_indicator = "impact", y_indicator = "impact"), "different")
  expect_error(delphi_plot_map(x, round = 3), "both indicators")
})

test_that("figures report the consensus rule and use English labels", {
  x <- example_x()
  p <- delphi_plot_consensus(x, threshold = 0.10)
  expect_match(p$labels$subtitle, "10% of the scale")
  expect_equal(p$labels$title, "Consensus by item and round")
  m <- delphi_plot_map(x)
  expect_match(m$labels$x, "^Impact \\(median")
})

test_that("label colours follow cell luminance", {
  expect_lt(DelphiR:::relative_luminance("#2a78d6"), 0.30)
  expect_gt(DelphiR:::relative_luminance("#f0efec"), 0.30)
})
