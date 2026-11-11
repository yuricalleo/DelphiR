# Consensus by item, round and indicator

Applies the interquartile-range (IQR) consensus criterion: an item
reaches consensus when the IQR of the expert ratings is at most a given
share of the rating scale, 20% by default (von der Gracht, 2012).

## Usage

``` r
delphi_consensus(
  x,
  threshold = 0.2,
  relative_to = c("points", "range"),
  round = NULL,
  indicator = NULL,
  items = NULL,
  type = 7
)
```

## Arguments

- x:

  A `delphi_data` object.

- threshold:

  Largest relative IQR that still counts as consensus, as a proportion
  between 0 and 1. Default `0.20`.

- relative_to:

  How the scale is measured: `"points"` (default) uses the number of
  scale points, `max - min + 1`; `"range"` uses `max - min`. See
  Details.

- round, indicator, items:

  Optional subsets: round numbers, indicator labels and item names to
  keep. `NULL` keeps all.

- type:

  Quantile algorithm passed to
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html); see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A data frame of class `delphi_consensus` with one row per indicator,
round and item and columns `indicator`, `round`, `item`, `n`, `median`,
`q1`, `q3`, `iqr`, `iqr_rel`, `iqr_max` (the largest IQR that counts as
consensus on that scale) and `consensus` (`TRUE`, `FALSE`, or `NA` when
there are no ratings). The rule is stored in the `"rule"` attribute.

## Details

The relative IQR is \\(Q_3 - Q_1) / w\\, where \\w\\ is the width of the
scale. With the default `relative_to = "points"`, the 20% threshold
gives the cut-offs commonly reported in the literature reviewed by von
der Gracht (2012): IQR \\\le 1\\ on a five-point scale and IQR \\\le 2\\
on a ten-point scale. With `relative_to = "range"` the cut-offs are
slightly stricter (1.8 on a scale from 1 to 10); this choice is better
suited to continuous scales, such as a scale from 0 to 100.

The rule should be fixed in the study protocol before data collection.

## References

von der Gracht, H. A. (2012). Consensus measurement in Delphi studies:
Review and implications for future quality assurance. *Technological
Forecasting and Social Change*, 79(8), 1525-1536.
[doi:10.1016/j.techfore.2012.04.013](https://doi.org/10.1016/j.techfore.2012.04.013)

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
cons <- delphi_consensus(x)
cons
#> Consensus rule: IQR <= 20% of the scale (number of points)
#> 
#>     indicator round item  n median    q1    q3   iqr iqr_rel iqr_max consensus
#>        impact     1   E1 15      7  6.50  8.00  1.50    0.15       2      TRUE
#>        impact     1   E2 15      5  4.00  7.00  3.00    0.30       2     FALSE
#>        impact     1   E3 15      7  5.00  7.00  2.00    0.20       2      TRUE
#>        impact     1   E4 15      7  6.00  8.00  2.00    0.20       2      TRUE
#>        impact     1   E5 15      4  3.00  8.50  5.50    0.55       2     FALSE
#>        impact     1   E6 14      3  1.25  5.00  3.75    0.38       2     FALSE
#>        impact     1   E7 15      8  7.00  9.50  2.50    0.25       2     FALSE
#>        impact     1   E8 15      4  3.00  6.00  3.00    0.30       2     FALSE
#>        impact     2   E1 13      8  7.00  8.00  1.00    0.10       2      TRUE
#>        impact     2   E2 13      5  5.00  5.00  0.00    0.00       2      TRUE
#>        impact     2   E3 13      7  6.00  7.00  1.00    0.10       2      TRUE
#>        impact     2   E4 13      7  6.00  7.00  1.00    0.10       2      TRUE
#>        impact     2   E5 13      4  2.00  9.00  7.00    0.70       2     FALSE
#>        impact     2   E6 13      3  2.00  4.00  2.00    0.20       2      TRUE
#>        impact     2   E7 13      8  7.00  8.00  1.00    0.10       2      TRUE
#>        impact     2   E8 12      5  4.00  6.00  2.00    0.20       2      TRUE
#>  plausibility     1   E1 15     77 71.00 89.50 18.50    0.18      20      TRUE
#>  plausibility     1   E2 14     28 19.50 41.25 21.75    0.22      20     FALSE
#>  plausibility     1   E3 15     62 48.50 67.50 19.00    0.19      20      TRUE
#>  plausibility     1   E4 15     63 58.00 82.00 24.00    0.24      20     FALSE
#>  plausibility     1   E5 15     30 14.00 87.00 73.00    0.73      20     FALSE
#>  plausibility     1   E6 15     30 15.50 39.00 23.50    0.23      20     FALSE
#>  plausibility     1   E7 15     80 64.00 88.50 24.50    0.24      20     FALSE
#>  plausibility     1   E8 15     40 27.00 54.00 27.00    0.27      20     FALSE
#>  plausibility     2   E1 13     78 73.00 84.00 11.00    0.11      20      TRUE
#>  plausibility     2   E2 13     30 26.00 34.00  8.00    0.08      20      TRUE
#>  plausibility     2   E3 13     60 49.00 64.00 15.00    0.15      20      TRUE
#>  plausibility     2   E4 13     66 62.00 66.00  4.00    0.04      20      TRUE
#>  plausibility     2   E5 13     36 18.00 84.00 66.00    0.66      20     FALSE
#>  plausibility     2   E6 13     30 19.00 35.00 16.00    0.16      20      TRUE
#>  plausibility     2   E7 13     83 77.00 88.00 11.00    0.11      20      TRUE
#>  plausibility     2   E8 13     41 26.00 50.00 24.00    0.24      20     FALSE
#> 
#> Items with consensus:
#>   impact, round 1: 3 of 8
#>   impact, round 2: 7 of 8
#>   plausibility, round 1: 2 of 8
#>   plausibility, round 2: 6 of 8

# Items with consensus in round 2
subset(cons, round == 2 & consensus)
#>     indicator round item  n median q1 q3 iqr iqr_rel iqr_max consensus
#>        impact     2   E1 13      8  7  8   1    0.10       2      TRUE
#>        impact     2   E2 13      5  5  5   0    0.00       2      TRUE
#>        impact     2   E3 13      7  6  7   1    0.10       2      TRUE
#>        impact     2   E4 13      7  6  7   1    0.10       2      TRUE
#>        impact     2   E6 13      3  2  4   2    0.20       2      TRUE
#>        impact     2   E7 13      8  7  8   1    0.10       2      TRUE
#>        impact     2   E8 12      5  4  6   2    0.20       2      TRUE
#>  plausibility     2   E1 13     78 73 84  11    0.11      20      TRUE
#>  plausibility     2   E2 13     30 26 34   8    0.08      20      TRUE
#>  plausibility     2   E3 13     60 49 64  15    0.15      20      TRUE
#>  plausibility     2   E4 13     66 62 66   4    0.04      20      TRUE
#>  plausibility     2   E6 13     30 19 35  16    0.16      20      TRUE
#>  plausibility     2   E7 13     83 77 88  11    0.11      20      TRUE
#> 
#> Items with consensus:
#>   impact, round 2: 7 of 7
#>   plausibility, round 2: 6 of 6

# A stricter rule: IQR at most 10% of the scale
delphi_consensus(x, threshold = 0.10, round = 2)
#> Consensus rule: IQR <= 10% of the scale (number of points)
#> 
#>     indicator round item  n median q1 q3 iqr iqr_rel iqr_max consensus
#>        impact     2   E1 13      8  7  8   1    0.10       1      TRUE
#>        impact     2   E2 13      5  5  5   0    0.00       1      TRUE
#>        impact     2   E3 13      7  6  7   1    0.10       1      TRUE
#>        impact     2   E4 13      7  6  7   1    0.10       1      TRUE
#>        impact     2   E5 13      4  2  9   7    0.70       1     FALSE
#>        impact     2   E6 13      3  2  4   2    0.20       1     FALSE
#>        impact     2   E7 13      8  7  8   1    0.10       1      TRUE
#>        impact     2   E8 12      5  4  6   2    0.20       1     FALSE
#>  plausibility     2   E1 13     78 73 84  11    0.11      10     FALSE
#>  plausibility     2   E2 13     30 26 34   8    0.08      10      TRUE
#>  plausibility     2   E3 13     60 49 64  15    0.15      10     FALSE
#>  plausibility     2   E4 13     66 62 66   4    0.04      10      TRUE
#>  plausibility     2   E5 13     36 18 84  66    0.66      10     FALSE
#>  plausibility     2   E6 13     30 19 35  16    0.16      10     FALSE
#>  plausibility     2   E7 13     83 77 88  11    0.11      10     FALSE
#>  plausibility     2   E8 13     41 26 50  24    0.24      10     FALSE
#> 
#> Items with consensus:
#>   impact, round 2: 5 of 8
#>   plausibility, round 2: 2 of 8
```
