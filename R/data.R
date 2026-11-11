#' Example Delphi study
#'
#' @description
#' A synthetic two-round Delphi study in the DelphiR wide layout. Fifteen
#' experts rated eight items (`E1` to `E8`) on two indicators: impact, on a
#' scale from 1 to 10, and plausibility, on a scale from 1 to 100. Two
#' experts did not participate in round 2, and a few ratings are missing.
#'
#' Ratings converge towards the group median in round 2 for most items;
#' item `E5` remains polarised, with the panel divided into two groups.
#'
#' @format A data frame with 56 rows and 11 columns:
#' \describe{
#'   \item{expert}{Expert identifier, `"EXP01"` to `"EXP15"`.}
#'   \item{round}{Round number, 1 or 2.}
#'   \item{indicator}{`"impact"` or `"plausibility"`.}
#'   \item{E1, E2, E3, E4, E5, E6, E7, E8}{Ratings of the eight items.}
#' }
#' @source Simulated data; see `data-raw/delphi_example.R` in the package
#'   sources.
#' @examples
#' head(delphi_example)
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' x
"delphi_example"
