# Changelog

## DelphiR (development version)

### Interactive application

- [`run_app()`](https://yuricalleo.github.io/DelphiR/reference/run_app.md)
  opens an interactive application that covers the whole workflow
  without writing code: import of the ratings from CSV or Excel files by
  choosing the columns, rounds added one at a time from separate sheets
  or files, comments in the long or wide layout, descriptive statistics,
  consensus, stability and item status with adjustable criteria, figures
  downloadable as PNG or PDF files, the analysis of the comments, the
  round report and the feedback for the experts. The application also
  writes the R code that reproduces the analysis. It requires the
  ‘shiny’, ‘bslib’ and ‘DT’ packages.
- In the application, the rating scale is chosen for each indicator
  among the most common ones (from 1 to 5, 7, 9, 10 or 100, or from 0 to
  10 or 100) or entered freely, and the sidebar shows the resulting
  consensus threshold of each indicator.

### Expert comments

- [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md)
  attaches the written comments of the experts to a `delphi_data`
  object, from a table with one row per comment or from a survey export
  with one comment column per item. Comments can be coded with one or
  more themes.
- `read_delphi(comments_sheet = )` reads the comments from a sheet of
  the same Excel file, and
  [`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md)
  now includes a `comments` sheet.
- [`delphi_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comments.md)
  lists the comments with the rating of their author and its position
  relative to the interquartile range of the panel.
- [`delphi_comment_counts()`](https://yuricalleo.github.io/DelphiR/reference/delphi_comment_counts.md),
  [`delphi_themes()`](https://yuricalleo.github.io/DelphiR/reference/delphi_themes.md)
  and
  [`delphi_words()`](https://yuricalleo.github.io/DelphiR/reference/delphi_words.md)
  count the comments by item, tabulate the themes and compute word
  frequencies, with common English and Italian words removed.
- [`delphi_plot_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_comments.md)
  and `plot(type = "comments")` show the number of comments by item,
  split by the position of their authors.
- [`delphi_report()`](https://yuricalleo.github.io/DelphiR/reference/delphi_report.md)
  includes a section on the comments when they are available; the new
  argument `comments` chooses which comments are listed.
- Example dataset `delphi_example_comments`.

### Feedback for the next round

- [`delphi_feedback()`](https://yuricalleo.github.io/DelphiR/reference/delphi_feedback.md)
  prepares the controlled feedback for the experts: median, quartiles
  and consensus of the items that require a further round, with the
  comments of the panel reported anonymously, as a table or as an HTML
  or Word document.

## DelphiR 0.1.0

First release.

### Data import and validation

- [`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md)
  creates an empty Excel or CSV file in the DelphiR format, with
  instructions and the code needed to import it.
- [`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)
  and
  [`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md)
  import ratings in the DelphiR wide layout, with one row per expert and
  one column per item, from data frames and from CSV, TSV and Excel
  files. Separators and decimal commas are detected automatically, and
  ratings are validated against the rating scale of each indicator.
- [`delphi_data_long()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data_long.md)
  and `read_delphi(layout = "long")` import ratings in long format, with
  one row per rating.
- `read_delphi(header_rows = 2)` reads survey exports in which the first
  header row gives the indicators and the second the item statements.
  Items are coded `E1`, `E2`, … and their statements are stored as
  labels.
- Rows without an expert identifier, such as summary rows with medians
  or quartiles, are ignored with a warning.
- `linked = FALSE` declares that expert identifiers do not denote the
  same person across rounds, as when each round is collected with a
  separate questionnaire. Retention is then not computed, and stability
  is assessed by comparing the rounds as independent samples.
- [`delphi_bind()`](https://yuricalleo.github.io/DelphiR/reference/delphi_bind.md)
  combines tables referring to different rounds or indicators, and
  [`delphi_wide()`](https://yuricalleo.github.io/DelphiR/reference/delphi_wide.md)
  and [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  return the ratings in wide or long format.
- Example dataset `delphi_example`.

### Analysis

- [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md)
  computes descriptive statistics by item, round and indicator,
  including the relative IQR, and
  [`delphi_panel()`](https://yuricalleo.github.io/DelphiR/reference/delphi_panel.md)
  reports panel participation and retention.
- [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md)
  applies the IQR consensus criterion, with an IQR of at most 20% of the
  rating scale by default (von der Gracht, 2012).
- [`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md)
  assesses stability between consecutive rounds with the Wilcoxon test
  (the default: signed-rank for linked experts, rank-sum otherwise),
  with a net-change criterion based on Scheibe, Skutsch and Schofer
  (1975), or with both.
- [`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md)
  combines consensus and stability into four categories (consensus,
  unstable consensus, stable dissent and open) and identifies the items
  to be submitted to a further round.
- [`summary()`](https://rdrr.io/r/base/summary.html) provides an
  overview of the panel and of the median and IQR of each item by round.

### Figures and reports

- [`delphi_plot_distribution()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_distribution.md),
  [`delphi_plot_trend()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_trend.md),
  [`delphi_plot_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_consensus.md)
  and
  [`delphi_plot_map()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_map.md),
  also available through
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), draw
  publication-quality figures with ggplot2.
  [`theme_delphi()`](https://yuricalleo.github.io/DelphiR/reference/theme_delphi.md)
  provides the common theme.
- [`delphi_report()`](https://yuricalleo.github.io/DelphiR/reference/delphi_report.md)
  generates a self-contained round report in HTML or Word format.
- The vignette “Introduction to DelphiR” describes the complete
  workflow.
