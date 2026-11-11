# DelphiR: Statistical Analysis of Delphi Studies

DelphiR imports, validates and summarises the ratings collected in a
Delphi study.

## The DelphiR data format

Input data follow a wide layout: one row per expert, one column per
item, and one numeric rating in each cell. Three optional columns
describe the context of the rows:

- an expert column with a stable identifier, needed to follow the same
  expert across rounds;

- a round column (1, 2, 3, ...);

- an indicator column naming what was rated, for example `"impact"` or
  `"plausibility"`.

When the round or the indicator column is absent, the whole table is
treated as a single round or a single indicator, given by the `round`
and `indicator` arguments of
[`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md).
Tables for different rounds or indicators can also be imported
separately and combined with
[`delphi_bind()`](https://yuricalleo.github.io/DelphiR/reference/delphi_bind.md).

Each indicator has its own rating scale (for example from 1 to 10 or
from 1 to 100), which is used to validate the ratings and to compare
dispersion across scales.

Ratings can also be supplied in long format, with one row per rating
([`delphi_data_long()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data_long.md)),
or read from survey exports with two header rows
([`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md)).
[`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md)
creates an empty file in the required format. When expert identifiers do
not denote the same person in every round, the data should be declared
as not linked (`linked = FALSE`).

## Main functions

- [`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md):
  data-entry template.

- [`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md),
  [`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)
  and
  [`delphi_data_long()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data_long.md):
  import and validation.

- [`delphi_bind()`](https://yuricalleo.github.io/DelphiR/reference/delphi_bind.md):
  combine rounds or indicators.

- [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md):
  descriptive statistics by item, round and indicator.

- [`delphi_panel()`](https://yuricalleo.github.io/DelphiR/reference/delphi_panel.md):
  respondents and retention across rounds.

- [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md):
  IQR consensus rule (IQR at most 20% of the scale by default).

- [`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md):
  stability between rounds (Wilcoxon test or net change between
  distributions, based on Scheibe et al., 1975).

- [`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md):
  consensus and stability together, and the items for the next round.

- [`delphi_plot_distribution()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_distribution.md),
  [`delphi_plot_trend()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_trend.md),
  [`delphi_plot_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_consensus.md)
  and
  [`delphi_plot_map()`](https://yuricalleo.github.io/DelphiR/reference/delphi_plot_map.md),
  or [`plot()`](https://rdrr.io/r/graphics/plot.default.html):
  publication-quality figures built with ggplot2.

- [`delphi_report()`](https://yuricalleo.github.io/DelphiR/reference/delphi_report.md):
  a self-contained round report in HTML or Word format.

- [`delphi_wide()`](https://yuricalleo.github.io/DelphiR/reference/delphi_wide.md)
  and [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html):
  back to wide or long tables.

See
[`vignette("DelphiR")`](https://yuricalleo.github.io/DelphiR/articles/DelphiR.md)
for an introduction to the complete workflow.

## See also

Useful links:

- <https://github.com/yuricalleo/DelphiR>

- <https://yuricalleo.github.io/DelphiR/>

- Report bugs at <https://github.com/yuricalleo/DelphiR/issues>

## Author

**Maintainer**: Yuri Calleo <yuri.calleo@unimercatorum.it> \[copyright
holder\]
