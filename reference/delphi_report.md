# Generate a round report

Writes a self-contained report of a Delphi study, in HTML or Word
format, ready to be shared with the research team or attached to the
controlled feedback of the next round. The report contains:

- an overview of the study and, optionally, the list of item statements;

- a methods section stating the consensus and stability criteria, with
  references;

- panel participation and retention across rounds;

- for each indicator, summary statistics, consensus and item status at
  the assessed round, stability between consecutive rounds, and the
  distribution and trend figures;

- the consensus heat map and, with two or more indicators, the
  two-indicator map;

- the items to be submitted to a further round.

## Usage

``` r
delphi_report(
  x,
  file,
  title = "Delphi study: round report",
  author = NULL,
  round = NULL,
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

  Path of the report. The extension sets the format: `.html` for HTML,
  `.docx` for Microsoft Word.

- title, author:

  Title and author(s) shown in the report header. `author` may be
  `NULL`.

- round:

  Round to assess, for each indicator. `NULL` (default) uses the last
  round; see
  [`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md).

- item_labels:

  Optional named character vector with the full statement of each item,
  named by item code, for example
  `c(E1 = "Remote work becomes the norm", E2 = "...")`. By default, the
  labels stored in `x` (see
  [`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)
  and
  [`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md))
  are used.

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- method, alpha, scheibe, paired:

  Stability rule, see
  [`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md).

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

- open:

  Whether to open the report once it has been created.

- quiet:

  Whether to suppress the rendering messages.

## Value

The path of the report, invisibly.

## Details

The report requires the rmarkdown and knitr packages and a Pandoc
installation; Pandoc is included in RStudio. All text is in English.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE) &&
    rmarkdown::pandoc_available()) {
  out <- delphi_report(x, file.path(tempdir(), "report.html"), open = FALSE)
  file.exists(out)
}
#> [1] TRUE
# }
```
