# Ratings in wide format

Returns the ratings in the DelphiR wide layout, with one row per expert,
round and indicator, and one column per item.

## Usage

``` r
delphi_wide(x, round = NULL, indicator = NULL)
```

## Arguments

- x:

  A `delphi_data` object.

- round:

  Optional round number(s) to keep. `NULL` keeps all rounds.

- indicator:

  Optional indicator label(s) to keep. `NULL` keeps all.

## Value

A data frame with columns `expert`, `round`, `indicator` and one column
per item.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_wide(x, round = 1, indicator = "impact")
#>    expert round indicator E1 E2 E3 E4 E5 E6 E7 E8
#> 1   EXP01     1    impact  9  7  5 10  3  1  5  6
#> 2   EXP02     1    impact  6  5  7  9  9  7 10  2
#> 3   EXP03     1    impact  8  5  6  7  3 NA  8  8
#> 4   EXP04     1    impact  8  3  7  9  8  3 10  3
#> 5   EXP05     1    impact  7  5  7  8  2  5  5  3
#> 6   EXP06     1    impact  4  4  8  5  8  1  8  2
#> 7   EXP07     1    impact  7  4  7  7  2  6  7  3
#> 8   EXP08     1    impact  6  2  5  6  9  1  8  4
#> 9   EXP09     1    impact  8  7  7  8  2  1  7  6
#> 10  EXP10     1    impact  7  4  5  6  9  3  9  4
#> 11  EXP11     1    impact  7  8  4  7  3  5 10  5
#> 12  EXP12     1    impact  7  7  8  5  9  3  8  5
#> 13  EXP13     1    impact  8  4  4  6  4  2  8  7
#> 14  EXP14     1    impact  8  5  7  8  8  5  7  9
#> 15  EXP15     1    impact  4  7  5  6  3  8 10  3
```
