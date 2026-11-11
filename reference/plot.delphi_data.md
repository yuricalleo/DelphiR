# Plot a Delphi data object

Draws one of the DelphiR figures. This is a shortcut for the
`delphi_plot_*()` functions:

- `"distribution"`:
  [`delphi_plot_distribution()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_distribution.md);

- `"trend"`:
  [`delphi_plot_trend()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_trend.md);

- `"consensus"`:
  [`delphi_plot_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_consensus.md);

- `"map"`:
  [`delphi_plot_map()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_map.md);

- `"comments"`:
  [`delphi_plot_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_comments.md),
  for objects with comments.

## Usage

``` r
# S3 method for class 'delphi_data'
plot(x, type = c("distribution", "trend", "consensus", "map", "comments"), ...)
```

## Arguments

- x:

  A `delphi_data` object.

- type:

  Type of figure.

- ...:

  Further arguments passed to the corresponding function.

## Value

A ggplot object.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
plot(x, type = "consensus")

plot(x, type = "trend", indicator = "plausibility")
```
