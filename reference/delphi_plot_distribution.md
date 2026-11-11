# Distribution of the ratings by round

Shows, for each item, the distribution of the expert ratings in every
round: a box plot (median, quartiles and whiskers) with the individual
ratings overlaid. This is the most direct view of how the panel
converges or remains divided across rounds.

## Usage

``` r
delphi_plot_distribution(
  x,
  indicator = NULL,
  round = NULL,
  items = NULL,
  ncol = NULL,
  points = TRUE
)
```

## Arguments

- x:

  A `delphi_data` object.

- indicator:

  Indicator to plot. If `NULL`, the first indicator is used.

- round, items:

  Optional subsets of rounds and items.

- ncol:

  Number of columns of the panel grid.

- points:

  Whether to overlay the individual ratings. Ratings are spread
  horizontally only, so their values are not altered.

## Value

A ggplot object, which can be further modified with ggplot2.

## See also

[`delphi_plot_trend()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_trend.md),
[`delphi_plot_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_consensus.md),
[`delphi_plot_map()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_map.md),
[`plot.delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/plot.delphi_data.md).

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_plot_distribution(x, indicator = "impact")
```
