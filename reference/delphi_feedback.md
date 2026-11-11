# Controlled feedback for the next round

Prepares the controlled feedback that the experts receive before a
further round: for each item to be rated again, the statistical response
of the panel in the current round (median, quartiles and consensus) and,
when available, the comments of the experts, reported anonymously. The
feedback can be returned as a table or written to a document to be sent
to the panel, in HTML or Word format.

## Usage

``` r
delphi_feedback(
  x,
  file = NULL,
  round = NULL,
  items = NULL,
  comments = TRUE,
  title = "Delphi study: feedback for the next round",
  item_labels = NULL,
  threshold = 0.2,
  relative_to = c("points", "range"),
  method = c("wilcoxon", "scheibe", "both"),
  alpha = 0.05,
  scheibe = 0.15,
  type = 7,
  paired = NULL,
  open = interactive(),
  quiet = TRUE
)
```

## Arguments

- x:

  A `delphi_data` object.

- file:

  Optional path of the feedback document, ending in `.html` or `.docx`.
  If `NULL` (default), no document is written.

- round:

  Round on which the feedback is based. `NULL` (default) uses the last
  round; see
  [`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md).

- items:

  Items to include. By default, the items that require a further round
  on at least one indicator, according to
  [`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md).

- comments:

  Whether to include the comments of the experts on the selected items,
  when `x` contains comments (see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md)).

- title:

  Title of the document.

- item_labels:

  Optional named character vector with the full statement of each item.
  By default, the labels stored in `x` are used.

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- method, alpha, scheibe, paired:

  Stability rule, used to select the items for the next round; see
  [`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md).

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

- open:

  Whether to open the document once it has been created.

- quiet:

  Whether to suppress the rendering messages.

## Value

A data frame of class `delphi_feedback`, invisibly when `file` is given,
with one row per item and indicator and columns `item`, `statement`,
`indicator`, `round`, `n`, `median`, `q1`, `q3`, `iqr`, `consensus` and
`status`. The comments are stored in the attribute `comments`, a data
frame with columns `round`, `item` and `comment`.

## Details

The document is written for the experts: it explains the median and the
interquartile range in plain words and contains no expert identifiers,
no individual ratings and no information on the position of the authors
of the comments. Comments are reproduced as written, so any detail that
could identify their authors should be removed from the data beforehand.
Writing a document requires the rmarkdown and knitr packages and Pandoc.

## See also

[`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md),
[`delphi_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comments.md),
[`delphi_report()`](https://yuricalleo.github.io/DelphiR/reference/delphi_report.md).

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
fb <- delphi_feedback(x, round = 1)
head(fb)
#>  item    indicator round  n median   q1    q3 consensus    status
#>    E2       impact     1 15      5  4.0  7.00     FALSE      open
#>    E2 plausibility     1 14     28 19.5 41.25     FALSE      open
#>    E4       impact     1 15      7  6.0  8.00      TRUE consensus
#>    E4 plausibility     1 15     63 58.0 82.00     FALSE      open
#>    E5       impact     1 15      4  3.0  8.50     FALSE      open
#>    E5 plausibility     1 15     30 14.0 87.00     FALSE      open
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE) &&
    rmarkdown::pandoc_available()) {
  out <- delphi_feedback(x, file.path(tempdir(), "feedback.html"),
                         round = 1, open = FALSE)
}
# }
```
