# Number of comments by item

Counts, for each round and item, the comments received, the experts who
wrote them and the share of the experts who rated the item, and the
comments written by experts whose ratings lie outside the interquartile
range.

## Usage

``` r
delphi_comment_counts(x, round = NULL, indicator = NULL, type = 7)
```

## Arguments

- x:

  A `delphi_data` object with comments; see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md).

- round:

  Optional round number(s) to keep. `NULL` keeps all rounds.

- indicator:

  Optional indicator on which the position of the authors is assessed.
  By default, a comment counts as coming from outside the interquartile
  range when its author lies outside it on at least one indicator.

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A data frame of class `delphi_comment_counts` with one row per round and
item, including the items without comments, and columns `round`, `item`,
`n_comments`, `n_experts` (experts who commented), `n_raters` (experts
who rated the item), `share_experts` (`n_experts / n_raters`) and
`n_outside` (comments from experts outside the interquartile range).
Only rounds with at least one comment are included; general comments are
not counted.

## Examples

``` r
r1 <- data.frame(expert = c("A", "B", "C", "D"),
                 E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
cm <- data.frame(expert = c("A", "D", "D"), item = c("E1", "E1", "E2"),
                 comment = c("Depends on public funding.",
                             "Unlikely without new regulation.",
                             "The statement is too broad."))
x <- delphi_add_comments(x, cm)
delphi_comment_counts(x)
#>  round item n_comments n_experts n_raters share_experts n_outside
#>      1   E1          2         2        4          0.50         1
#>      1   E2          1         1        4          0.25         1
```
