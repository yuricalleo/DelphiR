# Consensus heat map

Shows the relative interquartile range of every item (rows) in every
round (columns). The colour scale is centred on the consensus threshold:
blue cells fall below it (consensus), red cells above it (no consensus),
and grey cells lie close to it. Each cell reports the IQR on the
original scale; an asterisk marks consensus. Indicators are shown side
by side, since the relative IQR is comparable across rating scales.

## Usage

``` r
delphi_plot_consensus(
  x,
  indicator = NULL,
  round = NULL,
  items = NULL,
  threshold = 0.2,
  relative_to = c("points", "range"),
  type = 7,
  digits = 1
)
```

## Arguments

- x:

  A `delphi_data` object.

- indicator:

  Indicators to plot. `NULL` plots all of them.

- round, items:

  Optional subsets of rounds and items.

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

- digits:

  Number of decimals of the IQR labels.

## Value

A ggplot object.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_plot_consensus(x)
```
