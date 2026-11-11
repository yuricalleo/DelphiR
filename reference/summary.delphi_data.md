# Summarise a Delphi data object

Provides an overview of the panel and, for each indicator, a compact
table of item medians and IQRs by round. Items that reach consensus
under the IQR rule of
[`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md)
are marked with `*`.

## Usage

``` r
# S3 method for class 'delphi_data'
summary(
  object,
  type = 7,
  threshold = 0.2,
  relative_to = c("points", "range"),
  ...
)
```

## Arguments

- object:

  A `delphi_data` object.

- type:

  Quantile algorithm, see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- ...:

  Ignored.

## Value

An object of class `summary.delphi_data`: a list with the panel table
(`panel`, see
[`delphi_panel()`](https://yuricalleo.github.io/DelphiR/reference/delphi_panel.md)),
the full descriptive table (`describe`, see
[`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md)),
the consensus table (`consensus`, see
[`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md))
and the scales (`scales`).

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
s <- summary(x)
s
#> Delphi study summary
#> 
#> Panel
#>  round respondents retained dropped joined retention
#>      1          15       NA      NA     NA      100%
#>      2          13       13       2      0       87%
#> 
#> Indicator: impact (scale from 1 to 10)
#> Median [IQR] by round (* = consensus)
#>    Round 1   Round 2
#> E1 7 [1.5] * 8 [1] *
#> E2 5 [3]     5 [0] *
#> E3 7 [2] *   7 [1] *
#> E4 7 [2] *   7 [1] *
#> E5 4 [5.5]   4 [7]  
#> E6 3 [3.75]  3 [2] *
#> E7 8 [2.5]   8 [1] *
#> E8 4 [3]     5 [2] *
#> 
#> Indicator: plausibility (scale from 1 to 100)
#> Median [IQR] by round (* = consensus)
#>    Round 1     Round 2  
#> E1 77 [18.5] * 78 [11] *
#> E2 28 [21.75]  30 [8] * 
#> E3 62 [19] *   60 [15] *
#> E4 63 [24]     66 [4] * 
#> E5 30 [73]     36 [66]  
#> E6 30 [23.5]   30 [16] *
#> E7 80 [24.5]   83 [11] *
#> E8 40 [27]     41 [24]  
#> 
#> Consensus rule: IQR <= 20% of the scale.
#> Full tables: delphi_describe(x), delphi_consensus(x).
s$describe
#>     indicator round item  n missing  mean    sd median    q1    q3   iqr
#>        impact     1   E1 15       0  6.93  1.44      7  6.50  8.00  1.50
#>        impact     1   E2 15       0  5.13  1.73      5  4.00  7.00  3.00
#>        impact     1   E3 15       0  6.13  1.36      7  5.00  7.00  2.00
#>        impact     1   E4 15       0  7.13  1.51      7  6.00  8.00  2.00
#>        impact     1   E5 15       0  5.47  3.07      4  3.00  8.50  5.50
#>        impact     1   E6 14       1  3.64  2.37      3  1.25  5.00  3.75
#>        impact     1   E7 15       0  8.00  1.65      8  7.00  9.50  2.50
#>        impact     1   E8 15       0  4.67  2.16      4  3.00  6.00  3.00
#>        impact     2   E1 13       0  7.38  0.96      8  7.00  8.00  1.00
#>        impact     2   E2 13       0  5.15  0.55      5  5.00  5.00  0.00
#>        impact     2   E3 13       0  6.54  0.88      7  6.00  7.00  1.00
#>        impact     2   E4 13       0  6.77  0.93      7  6.00  7.00  1.00
#>        impact     2   E5 13       0  5.54  3.41      4  2.00  9.00  7.00
#>        impact     2   E6 13       0  3.31  1.44      3  2.00  4.00  2.00
#>        impact     2   E7 13       0  7.85  1.14      8  7.00  8.00  1.00
#>        impact     2   E8 12       1  4.83  1.27      5  4.00  6.00  2.00
#>  plausibility     1   E1 15       0 79.40 13.73     77 71.00 89.50 18.50
#>  plausibility     1   E2 14       1 32.29 16.13     28 19.50 41.25 21.75
#>  plausibility     1   E3 15       0 57.13 16.61     62 48.50 67.50 19.00
#>  plausibility     1   E4 15       0 67.53 15.68     63 58.00 82.00 24.00
#>  plausibility     1   E5 15       0 49.93 38.50     30 14.00 87.00 73.00
#>  plausibility     1   E6 15       0 27.73 17.89     30 15.50 39.00 23.50
#>  plausibility     1   E7 15       0 75.47 16.07     80 64.00 88.50 24.50
#>  plausibility     1   E8 15       0 41.33 18.85     40 27.00 54.00 27.00
#>  plausibility     2   E1 13       0 78.69  9.84     78 73.00 84.00 11.00
#>  plausibility     2   E2 13       0 30.38  7.72     30 26.00 34.00  8.00
#>  plausibility     2   E3 13       0 57.00 10.87     60 49.00 64.00 15.00
#>  plausibility     2   E4 13       0 65.23  8.81     66 62.00 66.00  4.00
#>  plausibility     2   E5 13       0 51.08 36.25     36 18.00 84.00 66.00
#>  plausibility     2   E6 13       0 27.69 13.29     30 19.00 35.00 16.00
#>  plausibility     2   E7 13       0 82.54  9.73     83 77.00 88.00 11.00
#>  plausibility     2   E8 13       0 38.15 13.61     41 26.00 50.00 24.00
#>  iqr_rel min max   cv
#>     0.15   4   9 0.21
#>     0.30   2   8 0.34
#>     0.20   4   8 0.22
#>     0.20   5  10 0.21
#>     0.55   2   9 0.56
#>     0.38   1   8 0.65
#>     0.25   5  10 0.21
#>     0.30   2   9 0.46
#>     0.10   6   9 0.13
#>     0.00   4   6 0.11
#>     0.10   5   8 0.13
#>     0.10   5   8 0.14
#>     0.70   2  10 0.62
#>     0.20   1   6 0.43
#>     0.10   6  10 0.15
#>     0.20   3   7 0.26
#>     0.18  54 100 0.17
#>     0.22  12  64 0.50
#>     0.19  23  82 0.29
#>     0.24  45  91 0.23
#>     0.73   5  98 0.77
#>     0.23   1  56 0.64
#>     0.24  42 100 0.21
#>     0.27   8  75 0.46
#>     0.11  66  99 0.13
#>     0.08  16  46 0.25
#>     0.15  38  75 0.19
#>     0.04  52  80 0.14
#>     0.66   8  96 0.71
#>     0.16   5  48 0.48
#>     0.11  63 100 0.12
#>     0.24  16  56 0.36
```
