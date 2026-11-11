# Comments by item

Shows, for each item, the number of comments received in a round, split
by the position of their authors: within the interquartile range or
outside it. Items with many comments from outside the interquartile
range are those on which the minority has argued its position.

## Usage

``` r
delphi_plot_comments(x, round = NULL, indicator = NULL, type = 7)
```

## Arguments

- x:

  A `delphi_data` object with comments; see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md).

- round:

  Optional round number(s) to show. `NULL` shows all rounds with
  comments, in separate panels.

- indicator:

  Optional indicator on which the position of the authors is assessed.
  By default, a comment counts as coming from outside the interquartile
  range when its author lies outside it on at least one indicator.

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A ggplot object.

## See also

[`delphi_comment_counts()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comment_counts.md).

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
delphi_plot_comments(x)
```
