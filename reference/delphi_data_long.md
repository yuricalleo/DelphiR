# Create a Delphi data object from a long table

Converts expert ratings stored in long format, with one row per rating,
into a validated `delphi_data` object. Each row gives the expert, the
item and the rating, and optionally the round and the indicator. This is
the format produced by most statistical software when data are reshaped,
and the most convenient one when ratings come from several sources.

## Usage

``` r
delphi_data_long(
  data,
  expert_col = "expert",
  item_col = "item",
  value_col = "value",
  round_col = NULL,
  indicator_col = NULL,
  round = 1L,
  indicator = "score",
  item_labels = NULL,
  scale = c(1, 10),
  linked = TRUE,
  out_of_scale = c("error", "na")
)
```

## Arguments

- data:

  A data frame (or tibble) in long format.

- expert_col, item_col, value_col:

  Names of the columns with the expert identifiers, the item names and
  the ratings.

- round_col:

  Name of the column with the round number. If `NULL`, all rows belong
  to round `round`.

- indicator_col:

  Name of the column with the indicator label. If `NULL`, all rows refer
  to the indicator `indicator`.

- round:

  Round number used when `round_col` is `NULL`.

- indicator:

  Indicator label used when `indicator_col` is `NULL`.

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

An object of class `delphi_data`; see
[`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md).

## Details

Rows without an expert identifier are ignored with a warning, and rows
with an empty rating are kept as missing ratings. Items are kept in
order of first appearance. Each combination of expert, round, indicator
and item must appear only once.

## See also

[`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)
for the wide layout,
[`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md)
to import from a file.

## Examples

``` r
long <- data.frame(
  expert = rep(c("A", "B", "C"), each = 2),
  item = rep(c("E1", "E2"), times = 3),
  value = c(7, 3, 8, 5, 6, 4)
)
x <- delphi_data_long(long, indicator = "impact", scale = c(1, 10))
x
#> <delphi_data>
#>   Experts:    3
#>   Rounds:     1 (1)
#>   Items:      2 (E1, E2)
#>   Indicators: impact (from 1 to 10)
#>   Ratings:    6 (0 missing)
#> Use summary() for descriptive statistics.

# Back to the long format
as.data.frame(x)
#>   expert round indicator item value
#> 1      A     1    impact   E1     7
#> 2      B     1    impact   E1     8
#> 3      C     1    impact   E1     6
#> 4      A     1    impact   E2     3
#> 5      B     1    impact   E2     5
#> 6      C     1    impact   E2     4
```
