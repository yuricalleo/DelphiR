# Themes of the comments

Tabulates the themes assigned by the researchers to the comments (see
[`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md)),
by item or across items, so that the arguments raised by the panel can
be compared between items and rounds.

## Usage

``` r
delphi_themes(
  x,
  round = NULL,
  by = c("item", "theme"),
  indicator = NULL,
  type = 7
)
```

## Arguments

- x:

  A `delphi_data` object with comments; see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md).

- round:

  Optional round number(s) to keep. `NULL` keeps all rounds.

- by:

  `"item"` (default) counts each theme within each item; `"theme"`
  counts each theme across all items.

- indicator:

  Optional indicator on which the position of the authors is assessed.
  By default, a comment counts as coming from outside the interquartile
  range when its author lies outside it on at least one indicator.

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A data frame with columns `round`, `item` (only when `by = "item"`),
`theme`, `n_comments`, `n_experts` (experts who raised the theme),
`n_outside` (comments from experts outside the interquartile range) and,
when `by = "theme"`, `n_items` and `items` (the items on which the theme
was raised). Rows are ordered by round and by decreasing number of
comments.

## Details

A comment coded with several themes counts once for each of them.
General comments are included when `by = "theme"`, with item `NA` when
`by = "item"`.

## Examples

``` r
r1 <- data.frame(expert = c("A", "B", "C", "D"),
                 E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
cm <- data.frame(
  expert = c("A", "D", "D", "C"),
  item = c("E1", "E1", "E2", "E2"),
  comment = c("Depends on public funding.", "Unlikely without new rules.",
              "Too broad, and costly.", "Rules will change soon."),
  theme = c("funding", "regulation", "wording; funding", "regulation")
)
x <- delphi_add_comments(x, cm)
delphi_themes(x)
#>   round item      theme n_comments n_experts n_outside
#> 1     1   E1    funding          1         1         0
#> 2     1   E1 regulation          1         1         1
#> 3     1   E2    funding          1         1         1
#> 4     1   E2 regulation          1         1         0
#> 5     1   E2    wording          1         1         1
delphi_themes(x, by = "theme")
#>   round      theme n_comments n_experts n_outside n_items  items
#> 1     1    funding          2         2         1       2 E1, E2
#> 2     1 regulation          2         2         1       2 E1, E2
#> 3     1    wording          1         1         1       1     E2
```
