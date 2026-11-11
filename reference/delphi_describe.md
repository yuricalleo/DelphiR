# Descriptive statistics of a Delphi study

Computes, for every item, round and indicator, the number of ratings and
the usual Delphi summaries: mean, standard deviation, median, quartiles,
interquartile range (IQR), range and coefficient of variation.

## Usage

``` r
delphi_describe(
  x,
  round = NULL,
  indicator = NULL,
  items = NULL,
  type = 7,
  relative_to = c("points", "range")
)
```

## Arguments

- x:

  A `delphi_data` object.

- round, indicator, items:

  Optional subsets: round numbers, indicator labels and item names to
  keep. `NULL` keeps all.

- type:

  Quantile algorithm passed to
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html). The
  default `7` is R's default; use `6` to match SPSS and Minitab, which
  many Delphi studies report.

- relative_to:

  How the relative IQR (`iqr_rel`) is computed: `"points"` (default)
  divides the IQR by the number of points of the scale, `max - min + 1`;
  `"range"` divides it by `max - min`. See
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

## Value

A data frame of class `delphi_describe` with one row per indicator,
round and item and columns `indicator`, `round`, `item`, `n`, `missing`,
`mean`, `sd`, `median`, `q1`, `q3`, `iqr`, `iqr_rel`, `min`, `max` and
`cv`.

## Details

`iqr_rel` is the IQR as a share of the rating scale, so that dispersion
can be compared between indicators rated on different scales (for
example from 1 to 10 and from 1 to 100). `cv` is the standard deviation
divided by the mean.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
d <- delphi_describe(x)
head(d)
#>  indicator round item  n missing mean   sd median   q1  q3  iqr iqr_rel min max
#>     impact     1   E1 15       0 6.93 1.44      7 6.50 8.0 1.50    0.15   4   9
#>     impact     1   E2 15       0 5.13 1.73      5 4.00 7.0 3.00    0.30   2   8
#>     impact     1   E3 15       0 6.13 1.36      7 5.00 7.0 2.00    0.20   4   8
#>     impact     1   E4 15       0 7.13 1.51      7 6.00 8.0 2.00    0.20   5  10
#>     impact     1   E5 15       0 5.47 3.07      4 3.00 8.5 5.50    0.55   2   9
#>     impact     1   E6 14       1 3.64 2.37      3 1.25 5.0 3.75    0.38   1   8
#>    cv
#>  0.21
#>  0.34
#>  0.22
#>  0.21
#>  0.56
#>  0.65

# Only the impact ratings of round 2, with SPSS-style quartiles
delphi_describe(x, round = 2, indicator = "impact", type = 6)
#>  indicator round item  n missing mean   sd median  q1  q3 iqr iqr_rel min max
#>     impact     2   E1 13       0 7.38 0.96      8 6.5 8.0 1.5    0.15   6   9
#>     impact     2   E2 13       0 5.15 0.55      5 5.0 5.5 0.5    0.05   4   6
#>     impact     2   E3 13       0 6.54 0.88      7 6.0 7.0 1.0    0.10   5   8
#>     impact     2   E4 13       0 6.77 0.93      7 6.0 7.5 1.5    0.15   5   8
#>     impact     2   E5 13       0 5.54 3.41      4 2.0 9.0 7.0    0.70   2  10
#>     impact     2   E6 13       0 3.31 1.44      3 2.0 4.5 2.5    0.25   1   6
#>     impact     2   E7 13       0 7.85 1.14      8 7.0 8.5 1.5    0.15   6  10
#>     impact     2   E8 12       1 4.83 1.27      5 4.0 6.0 2.0    0.20   3   7
#>    cv
#>  0.13
#>  0.11
#>  0.13
#>  0.14
#>  0.62
#>  0.43
#>  0.15
#>  0.26
```
