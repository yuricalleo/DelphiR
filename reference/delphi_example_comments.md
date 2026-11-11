# Comments of the example Delphi study

Synthetic comments written by the experts of
[`delphi_example`](https://yuricalleo.github.io/DelphiR/reference/delphi_example.md)
in round 2, in the long layout read by
[`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md).
Each comment has been coded with one or more themes, separated by a
semicolon. The last comment is a general comment on the questionnaire
and refers to no item.

## Usage

``` r
delphi_example_comments
```

## Format

A data frame with 11 rows and 5 columns:

- expert:

  Expert identifier, as in
  [`delphi_example`](https://yuricalleo.github.io/DelphiR/reference/delphi_example.md).

- round:

  Round number (2).

- item:

  Item code, `NA` for the general comment.

- comment:

  Text of the comment.

- theme:

  Themes assigned by the researchers.

## Source

Simulated data; see `data-raw/delphi_example_comments.R` in the package
sources.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
x <- delphi_add_comments(x, delphi_example_comments)
delphi_comments(x, items = "E7", general = FALSE)
#> <delphi_comments> 3 comment(s)
#> 
#> Round 2, item E7
#>   [EXP01]: impact below Q1, plausibility below Q1 (theme: skills; time horizon)
#>     Adoption will be slower than expected, because most firms lack the
#>     necessary skills.
#>   [EXP10]: impact above Q3, plausibility above Q3 (theme: costs)
#>     The technology is already available, and its costs are falling
#>     quickly.
#>   [EXP13]: impact within IQR, plausibility above Q3 (theme: regulation)
#>     New regulation in the European Union will accelerate this change.
```
