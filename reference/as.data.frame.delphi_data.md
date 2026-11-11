# Convert a Delphi data object to a data frame

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the ratings in long format, one row per expert, round, indicator and
item.
[`delphi_wide()`](https://yuricalleo.github.io/DelphiR/reference/delphi_wide.md)
returns them in the wide DelphiR layout.

## Usage

``` r
# S3 method for class 'delphi_data'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A `delphi_data` object.

- row.names, optional:

  Ignored, kept for compatibility with the generic.

- ...:

  Ignored.

## Value

A data frame with columns `expert`, `round`, `indicator`, `item` and
`value`.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
head(as.data.frame(x))
#>   expert round indicator item value
#> 1  EXP01     1    impact   E1     9
#> 2  EXP02     1    impact   E1     6
#> 3  EXP03     1    impact   E1     8
#> 4  EXP04     1    impact   E1     8
#> 5  EXP05     1    impact   E1     7
#> 6  EXP06     1    impact   E1     4
```
