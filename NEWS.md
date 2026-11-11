# DelphiR (development version)

# DelphiR 0.1.0

First release.

## Data import and validation

* `delphi_template()` creates an empty Excel or CSV file in the DelphiR
  format, with instructions and the code needed to import it.
* `delphi_data()` and `read_delphi()` import ratings in the DelphiR wide
  layout, with one row per expert and one column per item, from data frames
  and from CSV, TSV and Excel files. Separators and decimal commas are
  detected automatically, and ratings are validated against the rating scale
  of each indicator.
* `delphi_data_long()` and `read_delphi(layout = "long")` import ratings in
  long format, with one row per rating.
* `read_delphi(header_rows = 2)` reads survey exports in which the first
  header row gives the indicators and the second the item statements. Items
  are coded `E1`, `E2`, ... and their statements are stored as labels.
* Rows without an expert identifier, such as summary rows with medians or
  quartiles, are ignored with a warning.
* `linked = FALSE` declares that expert identifiers do not denote the same
  person across rounds, as when each round is collected with a separate
  questionnaire. Retention is then not computed, and stability is assessed
  by comparing the rounds as independent samples.
* `delphi_bind()` combines tables referring to different rounds or
  indicators, and `delphi_wide()` and `as.data.frame()` return the ratings
  in wide or long format.
* Example dataset `delphi_example`.

## Analysis

* `delphi_describe()` computes descriptive statistics by item, round and
  indicator, including the relative IQR, and `delphi_panel()` reports panel
  participation and retention.
* `delphi_consensus()` applies the IQR consensus criterion, with an IQR of
  at most 20% of the rating scale by default (von der Gracht, 2012).
* `delphi_stability()` assesses stability between consecutive rounds with
  the Wilcoxon test (the default: signed-rank for linked experts, rank-sum
  otherwise), with a net-change criterion based on Scheibe, Skutsch and
  Schofer (1975), or with both.
* `delphi_status()` combines consensus and stability into four categories
  (consensus, unstable consensus, stable dissent and open) and identifies
  the items to be submitted to a further round.
* `summary()` provides an overview of the panel and of the median and IQR
  of each item by round.

## Figures and reports

* `delphi_plot_distribution()`, `delphi_plot_trend()`,
  `delphi_plot_consensus()` and `delphi_plot_map()`, also available through
  `plot()`, draw publication-quality figures with ggplot2. `theme_delphi()`
  provides the common theme.
* `delphi_report()` generates a self-contained round report in HTML or Word
  format.
* The vignette "Introduction to DelphiR" describes the complete workflow.
