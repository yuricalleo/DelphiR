# Create a Delphi data object

Converts expert ratings stored in the DelphiR wide layout (one row per
expert, one column per item) into a validated `delphi_data` object.
Ratings are checked to be numeric, to lie inside the rating scale and to
be unique for each expert, round, indicator and item.

## Usage

``` r
delphi_data(
  data,
  expert_col = NULL,
  round = 1L,
  round_col = NULL,
  indicator = "score",
  indicator_col = NULL,
  items = NULL,
  item_labels = NULL,
  scale = c(1, 10),
  linked = TRUE,
  out_of_scale = c("error", "na")
)
```

## Arguments

- data:

  A data frame (or tibble) in wide layout.

- expert_col:

  Name of the column with the expert identifiers. Rows without an
  identifier, such as summary rows with medians or quartiles added below
  the data, are ignored with a warning. If `NULL`, experts are numbered
  by row within the round (`"R1-EXP01"`, `"R1-EXP02"`, ...); this is
  only allowed when `data` holds a single round and a single indicator,
  and the experts are then treated as not linked across rounds.

- round:

  Round number used when `round_col` is `NULL`.

- round_col:

  Name of the column with the round number, if `data` stacks several
  rounds.

- indicator:

  Indicator label used when `indicator_col` is `NULL`, for example
  `"impact"`.

- indicator_col:

  Name of the column with the indicator label, if `data` stacks several
  indicators.

- items:

  Names of the item columns. By default, all columns other than
  `expert_col`, `round_col` and `indicator_col`.

- item_labels:

  Optional full statements of the items: a character vector named by
  item, or an unnamed vector with one label per item. Labels are used in
  reports.

- scale:

  Rating scale: either `c(min, max)` for all indicators, or a named list
  with one `c(min, max)` per indicator, such as
  `list(impact = c(1, 10), plausibility = c(1, 100))`.

- linked:

  Whether the expert identifiers denote the same person in every round.
  Set `linked = FALSE` when they do not, for example when the rounds
  were collected with separate questionnaires and the identifiers are
  response numbers of each questionnaire. Unlinked panels are analysed
  without individual-level comparisons: retention is not computed and
  stability is assessed on the distributions of the two rounds (see
  [`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md)).

- out_of_scale:

  What to do with ratings outside the scale: `"error"` (default) stops
  with a list of the offending ratings, `"na"` replaces them with `NA`
  and warns.

## Value

An object of class `delphi_data`: a list with elements

- `data`: long data frame with columns `expert`, `round`, `indicator`,
  `item` and `value`;

- `items`: item names, in their original order;

- `scales`: named list with the scale of each indicator;

- `labels`: full item statements, named by item (`NA` when not given);

- `linked`: whether experts are linked across rounds.

## Details

Empty cells are read as missing ratings (item non-response). Item
columns stored as text are converted to numbers; a decimal comma
(`"7,5"`) is accepted.

## See also

[`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md)
to import from a file,
[`delphi_bind()`](https://yuricalleo.github.io/DelphiR/reference/delphi_bind.md)
to combine rounds or indicators.

## Examples

``` r
# One round, one indicator: rows are experts, columns are items
r1 <- data.frame(
  expert = c("A", "B", "C", "D"),
  E1 = c(7, 8, 6, 9),
  E2 = c(3, 5, 4, NA)
)
x <- delphi_data(r1, expert_col = "expert", indicator = "impact",
                 scale = c(1, 10))
x
#> <delphi_data>
#>   Experts:    4
#>   Rounds:     1 (1)
#>   Items:      2 (E1, E2)
#>   Indicators: impact (from 1 to 10)
#>   Ratings:    7 (1 missing)
#> Use summary() for descriptive statistics.

# Several rounds and indicators stacked in one table
x <- delphi_data(delphi_example,
                 expert_col = "expert",
                 round_col = "round",
                 indicator_col = "indicator",
                 scale = list(impact = c(1, 10),
                              plausibility = c(1, 100)))
summary(x)
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
```
