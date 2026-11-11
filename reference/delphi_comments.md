# Expert comments next to their ratings

Lists the comments of the experts with the rating that their author gave
to the same item in the same round, on every indicator, and the position
of that rating relative to the ratings of the whole panel: below the
first quartile, within the interquartile range or above the third
quartile. Comments from experts whose ratings lie outside the
interquartile range are the arguments of the minority, which the Delphi
method asks the panel to consider in the next round.

## Usage

``` r
delphi_comments(x, round = NULL, items = NULL, general = TRUE, type = 7)
```

## Arguments

- x:

  A `delphi_data` object with comments; see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md).

- round, items:

  Optional subsets of rounds and items.

- general:

  Whether to include general comments, not referring to a specific item.

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A data frame of class `delphi_comments` with one row per comment and
columns `round`, `item`, `expert`, `indicator`, `comment`, `theme`,
then, for each indicator, the rating of the author
(`<indicator>_rating`) and its position (`<indicator>_position`), and
finally `outside_iqr`: whether the rating of the author lies outside the
interquartile range on at least one indicator.

## Details

A rating equal to a quartile counts as within the interquartile range.
Positions are `NA` for general comments and when the author did not rate
the item on that indicator.

## See also

[`delphi_comment_counts()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comment_counts.md),
[`delphi_themes()`](https://yuricalleo.github.io/DelphiR/reference/delphi_themes.md),
[`delphi_words()`](https://yuricalleo.github.io/DelphiR/reference/delphi_words.md),
[`delphi_feedback()`](https://yuricalleo.github.io/DelphiR/reference/delphi_feedback.md).

## Examples

``` r
r1 <- data.frame(expert = c("A", "B", "C", "D"),
                 E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
cm <- data.frame(expert = c("A", "D"), item = c("E1", "E1"),
                 comment = c("Depends on public funding.",
                             "Unlikely without new regulation."))
x <- delphi_add_comments(x, cm)
delphi_comments(x)
#> <delphi_comments> 2 comment(s)
#> 
#> Round 1, item E1
#>   [A]: impact within IQR
#>     Depends on public funding.
#>   [D]: impact below Q1
#>     Unlikely without new regulation.
```
