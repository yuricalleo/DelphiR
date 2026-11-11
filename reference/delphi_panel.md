# Panel participation across rounds

Counts the experts who answered each round and how many of them are
retained from round to round. An expert counts as a respondent in a
round if they gave at least one rating, on any item and indicator.

## Usage

``` r
delphi_panel(x)
```

## Arguments

- x:

  A `delphi_data` object.

## Value

A data frame with one row per round and columns:

- `round`;

- `respondents`: experts with at least one rating;

- `retained`: respondents who also answered the previous round;

- `dropped`: respondents of the previous round who did not answer;

- `joined`: respondents who did not answer the previous round;

- `retention`: share of first-round respondents still answering.

When the experts are not linked across rounds (`linked = FALSE` in
[`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)),
only the number of respondents can be computed; the other columns are
`NA`.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_panel(x)
#>   round respondents retained dropped joined retention
#> 1     1          15       NA      NA     NA 1.0000000
#> 2     2          13       13       2      0 0.8666667
```
