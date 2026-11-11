# Add expert comments to a Delphi data object

Attaches the written comments of the experts to a `delphi_data` object,
so that each comment can be read next to the rating of its author and
summarised by item, round and theme. Comments can be supplied in two
layouts:

- long (`layout = "long"`, default): one row per comment, with columns
  for the expert, the item and the comment, and optionally the round,
  the indicator and the themes; this is the layout of the `comments`
  sheet of the template created by
  [`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md);

- wide (`layout = "wide"`): one row per expert and one comment column
  per item, as exported by many survey platforms.

## Usage

``` r
delphi_add_comments(
  x,
  comments,
  layout = c("long", "wide"),
  expert_col = "expert",
  item_col = "item",
  comment_col = "comment",
  round_col = NULL,
  indicator_col = NULL,
  theme_col = NULL,
  round = NULL,
  comment_cols = NULL,
  items = NULL
)
```

## Arguments

- x:

  A `delphi_data` object.

- comments:

  A data frame of comments.

- layout:

  `"long"` (default) or `"wide"`; see Description.

- expert_col:

  Name of the column with the expert identifiers, which must match those
  used for the ratings of the same round.

- item_col, comment_col:

  For the long layout, names of the columns with the item code and the
  text of the comment. Comments with an empty item are treated as
  general comments on the questionnaire.

- round_col, indicator_col, theme_col:

  For the long layout, names of the optional columns with the round, the
  indicator to which the comment refers and the themes coded by the
  researchers. By default, columns named `round`, `indicator` and
  `theme` are used when present (the round column only when `round` is
  not given).

- round:

  Round of the comments, used when there is no round column. It can be
  omitted when `x` holds a single round.

- comment_cols:

  For the wide layout, the comment columns, by name or position, one per
  item and in the same order as `items`.

- items:

  For the wide layout, the items to which the comment columns refer. By
  default, all the items of `x`, in their order.

## Value

`x`, with the comments stored in the element `comments`: a data frame
with columns `expert`, `round`, `item` (`NA` for general comments),
`indicator` (`NA` when the comment refers to the item as a whole),
`comment` and `theme` (`NA` when not coded).

## Details

Empty comments are ignored, and spaces and line breaks within a comment
are collapsed into single spaces. Comments are matched to the ratings
through the expert identifier and the round, also when the experts are
not linked across rounds. A comment whose author has no rating in that
round is kept, with a warning, but its position relative to the ratings
of the panel cannot be determined.

Themes are short labels assigned by the researchers after reading the
comments, as in a qualitative content analysis, for example
`"regulation"` or `"costs"`. Several themes can be assigned to the same
comment by separating them with a semicolon (`"regulation; costs"`). The
same theme must be written in the same way throughout. Themes are
optional and are summarised by
[`delphi_themes()`](https://yuricalleo.github.io/DelphiR/reference/delphi_themes.md).

Calling the function again adds further comments, for example those of
another round. Comments already stored are not duplicated.

## See also

[`delphi_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comments.md),
[`delphi_comment_counts()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comment_counts.md),
[`delphi_themes()`](https://yuricalleo.github.io/DelphiR/reference/delphi_themes.md),
[`delphi_words()`](https://yuricalleo.github.io/DelphiR/reference/delphi_words.md);
[`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md)
reads the comments from a sheet of the same Excel file.

## Examples

``` r
r1 <- data.frame(expert = c("A", "B", "C", "D"),
                 E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
x <- delphi_data(r1, expert_col = "expert", indicator = "impact")

# Long layout: one row per comment
cm <- data.frame(
  expert = c("A", "D", "D", "B"),
  item = c("E1", "E1", "E2", NA),
  comment = c("Depends on public funding.",
              "Unlikely without new regulation.",
              "The statement is too broad.",
              "Clear questionnaire."),
  theme = c("funding", "regulation", "wording", NA)
)
x <- delphi_add_comments(x, cm)
delphi_comments(x)
#> <delphi_comments> 4 comment(s)
#> 
#> Round 1, item E1
#>   [A]: impact within IQR (theme: funding)
#>     Depends on public funding.
#>   [D]: impact below Q1 (theme: regulation)
#>     Unlikely without new regulation.
#> 
#> Round 1, item E2
#>   [D]: impact above Q3 (theme: wording)
#>     The statement is too broad.
#> 
#> Round 1, general comments
#>   [B]
#>     Clear questionnaire.

# Wide layout: one comment column per item
wide <- data.frame(expert = c("A", "C"),
                   c_E1 = c("Depends on public funding.", ""),
                   c_E2 = c(NA, "Hard to assess."))
y <- delphi_data(r1, expert_col = "expert", indicator = "impact")
y <- delphi_add_comments(y, wide, layout = "wide",
                         comment_cols = c("c_E1", "c_E2"))
y$comments
#>   expert round item indicator                    comment theme
#> 1      A     1   E1      <NA> Depends on public funding.  <NA>
#> 2      C     1   E2      <NA>            Hard to assess.  <NA>
```
