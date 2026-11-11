# Combine Delphi data objects

Combines `delphi_data` objects that hold different rounds, different
indicators or both, for example one table per round of the same study.

## Usage

``` r
delphi_bind(...)
```

## Arguments

- ...:

  `delphi_data` objects, or a single list of them.

## Value

A `delphi_data` object.

## Details

Experts are matched by their identifier, so the same expert must have
the same identifier in every table. If any of the objects is not linked
(`linked = FALSE` in
[`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)),
the combined object is not linked either. An indicator that appears in
several objects must have the same scale in all of them. Items are kept
in order of first appearance.

## Examples

``` r
r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(4, 8, 6), E2 = c(2, 9, 5))
r2 <- data.frame(expert = c("A", "B", "C"), E1 = c(6, 7, 6), E2 = c(4, 7, 5))
x <- delphi_bind(
  delphi_data(r1, expert_col = "expert", round = 1),
  delphi_data(r2, expert_col = "expert", round = 2)
)
delphi_panel(x)
#>   round respondents retained dropped joined retention
#> 1     1           3       NA      NA     NA         1
#> 2     2           3        3       0      0         1
```
