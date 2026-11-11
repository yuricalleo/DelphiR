# DelphiR <img src="man/figures/logo.png" align="right" height="139" alt="DelphiR logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/yuricalleo/DelphiR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yuricalleo/DelphiR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

DelphiR is an R package for the statistical analysis of Delphi studies. It
imports and validates the expert ratings, computes descriptive statistics by
item, round and indicator, assesses consensus and stability, identifies the
items to be submitted to a further round, analyses the written comments of
the experts, draws publication-quality figures, and generates a complete
round report in HTML or Word format and the controlled feedback for the next
round.

## Installation

The development version can be installed from GitHub:

```r
# install.packages("remotes")
remotes::install_github("yuricalleo/DelphiR")
```

## Data format

Ratings are arranged with one row per expert, one column per item and one
numeric rating in each cell:

| expert | round | indicator | E1 | E2 | E3 |
|--------|-------|-----------|----|----|----|
| EXP01  | 1     | impact    | 9  | 7  | 5  |
| EXP02  | 1     | impact    | 6  | 5  | 7  |
| EXP03  | 1     | impact    | 8  |    | 6  |

* Empty cells denote missing ratings.
* The expert identifier is required to follow the same expert across rounds.
* The round and indicator columns are optional. Without them, each table is
  treated as a single round and a single indicator, and tables can be
  combined with `delphi_bind()`.
* Each indicator has its own rating scale, for example from 1 to 10 or from
  1 to 100.

`delphi_template()` creates an empty Excel or CSV file in this format, with
instructions and the code needed to import it. Ratings in long format, with
one row per rating, are imported with `delphi_data_long()` or
`read_delphi(layout = "long")`, and survey exports with two header rows
(indicators in the first row, item statements in the second) with
`read_delphi(header_rows = 2)`. When identifiers do not denote the same
expert in every round, as with response numbers of separate questionnaires,
the data should be declared with `linked = FALSE`, so that rounds are
compared as independent samples.

## Example

```r
library(DelphiR)

# Empty template to be filled in
delphi_template("my_delphi.xlsx", items = 12)

# Example data: two rounds, two indicators
x <- delphi_data(
  delphi_example,
  expert_col = "expert", round_col = "round", indicator_col = "indicator",
  scale = list(impact = c(1, 10), plausibility = c(1, 100))
)

x                    # overview
summary(x)           # panel and median [IQR] by item and round
delphi_describe(x)   # descriptive statistics
delphi_consensus(x)  # consensus: IQR at most 20% of the rating scale
delphi_stability(x)  # stability between consecutive rounds
delphi_status(x)     # item status and items for the next round

# Figures, returned as ggplot objects
plot(x, type = "distribution", indicator = "impact")
plot(x, type = "trend", indicator = "impact")
plot(x, type = "consensus")
plot(x, type = "map")

# Expert comments, next to the rating of their author
x <- delphi_add_comments(x, delphi_example_comments)
delphi_comments(x)
delphi_themes(x, by = "theme")

# Round report and feedback for the experts, in Word or HTML format
delphi_report(x, "round2_report.docx")
delphi_feedback(x, "feedback_round3.docx")
```

See `vignette("DelphiR")` for an introduction to the complete workflow.

## Interactive application

`run_app()` opens an application in the web browser that covers the same
workflow without writing code: import of the ratings and comments by
choosing the columns of the file, tables, figures, the analysis of the
comments, the round report and the feedback for the experts. The
application also writes the R code that reproduces the analysis.

```r
# install.packages(c("shiny", "bslib", "DT"))
run_app()
```

## Consensus and stability

By default, an item reaches consensus when its interquartile range (IQR) does
not exceed 20% of the rating scale (von der Gracht, 2012). The scale is
measured by its number of points, so that the threshold corresponds to an IQR
of at most 1 on a five-point scale and at most 2 on a ten-point scale.

Stability between consecutive rounds is assessed with the Wilcoxon test
(signed-rank for linked experts, rank-sum otherwise), with a criterion based
on Scheibe, Skutsch and Schofer (1975), which considers an item stable when
the net change between the rating distributions of two rounds does not exceed
15%, or with both. Consensus and
stability are then combined into four categories:

| Status             | Consensus | Stable | Further round |
|--------------------|-----------|--------|---------------|
| Consensus          | yes       | yes    | no            |
| Unstable consensus | yes       | no     | yes           |
| Stable dissent     | no        | yes    | no            |
| Open               | no        | no     | yes           |

## Citation

To cite DelphiR in publications, use `citation("DelphiR")`.

## References

Scheibe, M., Skutsch, M. and Schofer, J. (1975). Experiments in Delphi
methodology. In H. A. Linstone and M. Turoff (Eds.), *The Delphi Method:
Techniques and Applications* (pp. 262-287). Reading, MA: Addison-Wesley.

von der Gracht, H. A. (2012). Consensus measurement in Delphi studies: Review
and implications for future quality assurance. *Technological Forecasting and
Social Change*, 79(8), 1525-1536. https://doi.org/10.1016/j.techfore.2012.04.013

## License

GPL (>= 3)
