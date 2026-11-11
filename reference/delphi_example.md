# Example Delphi study

A synthetic two-round Delphi study in the DelphiR wide layout. Fifteen
experts rated eight items (`E1` to `E8`) on two indicators: impact, on a
scale from 1 to 10, and plausibility, on a scale from 1 to 100. Two
experts did not participate in round 2, and a few ratings are missing.

Ratings converge towards the group median in round 2 for most items;
item `E5` remains polarised, with the panel divided into two groups.

## Usage

``` r
delphi_example
```

## Format

A data frame with 56 rows and 11 columns:

- expert:

  Expert identifier, `"EXP01"` to `"EXP15"`.

- round:

  Round number, 1 or 2.

- indicator:

  `"impact"` or `"plausibility"`.

- E1, E2, E3, E4, E5, E6, E7, E8:

  Ratings of the eight items.

## Source

Simulated data; see `data-raw/delphi_example.R` in the package sources.

## Examples

``` r
head(delphi_example)
#>   expert round indicator E1 E2 E3 E4 E5 E6 E7 E8
#> 1  EXP01     1    impact  9  7  5 10  3  1  5  6
#> 2  EXP02     1    impact  6  5  7  9  9  7 10  2
#> 3  EXP03     1    impact  8  5  6  7  3 NA  8  8
#> 4  EXP04     1    impact  8  3  7  9  8  3 10  3
#> 5  EXP05     1    impact  7  5  7  8  2  5  5  3
#> 6  EXP06     1    impact  4  4  8  5  8  1  8  2
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
x
#> <delphi_data>
#>   Experts:    15
#>   Rounds:     2 (1, 2)
#>   Items:      8 (E1, E2, E3, E4, E5, ..., E8)
#>   Indicators: impact (from 1 to 10), plausibility (from 1 to 100)
#>   Ratings:    445 (3 missing)
#> Use summary() for descriptive statistics.
```
