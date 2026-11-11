# Median and interquartile range across rounds

Shows, for each item, the median rating (point) and the interquartile
range (vertical bar, from the first to the third quartile) in every
round. Filled points mark the rounds in which the item reaches consensus
under the rule of
[`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md);
hollow points mark the rounds in which it does not.

## Usage

``` r
delphi_plot_trend(
  x,
  indicator = NULL,
  items = NULL,
  ncol = NULL,
  threshold = 0.2,
  relative_to = c("points", "range"),
  type = 7
)
```

## Arguments

- x:

  A `delphi_data` object.

- indicator:

  Indicator to plot. If `NULL`, the first indicator is used.

- items:

  Optional subset of items.

- ncol:

  Number of columns of the panel grid.

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A ggplot object.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_plot_trend(x, indicator = "impact")
```
