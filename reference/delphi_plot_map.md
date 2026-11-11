# Two-indicator map of the items

Places every item according to its median rating on two indicators, for
example impact (horizontal axis) and plausibility (vertical axis), as in
the impact-plausibility matrices used in foresight studies. Thin bars
show the interquartile range on each indicator, and dashed lines mark
the midpoints of the two scales, dividing the plane into four quadrants.
Filled points mark items that reach consensus on both indicators. Items
with the same medians on both indicators share a single label.

## Usage

``` r
delphi_plot_map(
  x,
  x_indicator = NULL,
  y_indicator = NULL,
  round = NULL,
  items = NULL,
  threshold = 0.2,
  relative_to = c("points", "range"),
  type = 7,
  iqr = TRUE
)
```

## Arguments

- x:

  A `delphi_data` object with at least two indicators.

- x_indicator, y_indicator:

  Indicators on the horizontal and vertical axes. By default, the first
  and the second indicator.

- round:

  Round to plot. By default, the last round in which both indicators
  were rated.

- items:

  Optional subset of items.

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

- iqr:

  Whether to draw the interquartile-range bars.

## Value

A ggplot object.

## Details

Item labels are placed with ggrepel when it is installed, which avoids
overlaps; otherwise they are drawn next to the points.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_plot_map(x, x_indicator = "impact", y_indicator = "plausibility")
```
