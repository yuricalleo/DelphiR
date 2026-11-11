#' DelphiR: Statistical Analysis of Delphi Studies
#'
#' @description
#' DelphiR imports, validates and summarises the ratings collected in a
#' Delphi study.
#'
#' @section The DelphiR data format:
#' Input data follow a wide layout: one row per expert, one column per
#' item, and one numeric rating in each cell. Three optional columns
#' describe the context of the rows:
#'
#' * an expert column with a stable identifier, needed to follow the same
#'   expert across rounds;
#' * a round column (1, 2, 3, ...);
#' * an indicator column naming what was rated, for example `"impact"` or
#'   `"plausibility"`.
#'
#' When the round or the indicator column is absent, the whole table is
#' treated as a single round or a single indicator, given by the `round`
#' and `indicator` arguments of [delphi_data()]. Tables for different rounds
#' or indicators can also be imported separately and combined with
#' [delphi_bind()].
#'
#' Each indicator has its own rating scale (for example from 1 to 10 or
#' from 1 to 100), which is used to validate the ratings and to compare
#' dispersion across scales.
#'
#' Ratings can also be supplied in long format, with one row per rating
#' ([delphi_data_long()]), or read from survey exports with two header rows
#' ([read_delphi()]). [delphi_template()] creates an empty file in the
#' required format. When expert identifiers do not denote the same person
#' in every round, the data should be declared as not linked
#' (`linked = FALSE`).
#'
#' @section Main functions:
#' * [delphi_template()]: data-entry template.
#' * [read_delphi()], [delphi_data()] and [delphi_data_long()]: import and
#'   validation.
#' * [delphi_bind()]: combine rounds or indicators.
#' * [delphi_describe()]: descriptive statistics by item, round and
#'   indicator.
#' * [delphi_panel()]: respondents and retention across rounds.
#' * [delphi_consensus()]: IQR consensus rule (IQR at most 20% of the scale
#'   by default).
#' * [delphi_stability()]: stability between rounds (Wilcoxon test or
#'   net change between distributions, based on Scheibe et al., 1975).
#' * [delphi_status()]: consensus and stability together, and the items for
#'   the next round.
#' * [delphi_plot_distribution()], [delphi_plot_trend()],
#'   [delphi_plot_consensus()] and [delphi_plot_map()], or `plot()`:
#'   publication-quality figures built with \pkg{ggplot2}.
#' * [delphi_report()]: a self-contained round report in HTML or Word format.
#' * [delphi_wide()] and `as.data.frame()`: back to wide or long tables.
#'
#' See `vignette("DelphiR")` for an introduction to the complete workflow.
#'
#' @keywords internal
#' @importFrom ggplot2 .data
#' @importFrom graphics plot
"_PACKAGE"
