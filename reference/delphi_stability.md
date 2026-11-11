# Stability of ratings between rounds

Measures, for every item and indicator, how much the ratings change
between consecutive rounds, and tests whether they are stable. Two
stability criteria are available:

- Wilcoxon (default): a Wilcoxon test comparing the two rounds. With
  linked experts it is the paired signed-rank test on the experts who
  answered both rounds; otherwise it is the rank-sum (Mann-Whitney) test
  on the two independent samples. The item is stable when the test is
  not significant (`p_value >= alpha`).

- Scheibe: the 15% change criterion of Scheibe, Skutsch and Schofer
  (1975). The item is stable when the net change between the two rating
  distributions is at most `scheibe` (15% by default).

## Usage

``` r
delphi_stability(
  x,
  method = c("wilcoxon", "scheibe", "both"),
  alpha = 0.05,
  scheibe = 0.15,
  rounds = NULL,
  indicator = NULL,
  items = NULL,
  bins = 10,
  type = 7,
  exact = FALSE,
  paired = NULL
)
```

## Arguments

- x:

  A `delphi_data` object with at least two rounds.

- method:

  Stability criterion used for the `stable` column: `"wilcoxon"`,
  `"scheibe"` or `"both"` (stable only if both criteria agree). Both
  criteria are always reported.

- alpha:

  Significance level of the Wilcoxon test. Default `0.05`.

- scheibe:

  Largest share of net change that still counts as stable under the
  Scheibe criterion. Default `0.15`.

- rounds:

  Optional round numbers to compare. Consecutive rounds among them are
  compared (for example `c(1, 3)` compares round 1 with round 3). `NULL`
  compares all consecutive rounds.

- indicator, items:

  Optional subsets of indicators and items.

- bins:

  Number of classes used to build the rating distributions for the
  Scheibe criterion on long scales. Scales with up to `bins` points use
  one class per scale point; longer scales are split into `bins` equal
  classes (for example 1 to 10, 11 to 20, ..., 91 to 100). Default `10`.

- type:

  Quantile algorithm for medians and IQRs; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

- exact:

  Passed to
  [`stats::wilcox.test()`](https://rdrr.io/r/stats/wilcox.test.html).
  The default `FALSE` uses the normal approximation with continuity
  correction, which handles the ties and zero differences that are
  common with rating scales.

- paired:

  Whether to compare the rounds expert by expert. By default (`NULL`)
  the comparison is paired when the experts are linked across rounds
  (`linked = TRUE` in
  [`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md))
  and unpaired otherwise. `paired = TRUE` is not allowed for unlinked
  experts.

## Value

A data frame of class `delphi_stability` with one row per indicator,
item and pair of rounds, and columns `indicator`, `item`, `round_from`,
`round_to`, `n_from`, `n_to`, `n_paired`, `median_from`, `median_to`,
`median_change`, `iqr_from`, `iqr_to`, `iqr_change`, `changed`,
`p_value`, `scheibe_change`, `stable_wilcoxon`, `stable_scheibe` and
`stable`. The settings are stored in the `"rule"` attribute.

## Details

Medians and IQRs are always computed on all experts who answered each
round (`n_from`, `n_to`), as in
[`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

In the paired comparison, the test, the share of experts who changed
their rating (`changed`) and the Scheibe change are computed on the
experts who answered the item in both rounds (`n_paired`), so that
drop-outs are not mistaken for changes of opinion. The Scheibe change is
half the sum of the absolute differences between the frequencies of the
two rating distributions, divided by the number of paired experts: the
share of experts who would have to move to turn one distribution into
the other.

In the unpaired comparison, used when the same expert cannot be
identified in both rounds, the test is the Wilcoxon rank-sum test and
the Scheibe change is half the sum of the absolute differences between
the relative frequencies of the two distributions; `n_paired` and
`changed` are `NA`. Since the two samples may include different experts,
a difference between rounds reflects both changes of opinion and changes
in the composition of the panel.

When the two rounds contain exactly the same ratings, the item is stable
under both criteria (`p_value = 1`, Scheibe change `0`).

## References

Scheibe, M., Skutsch, M. and Schofer, J. (1975). Experiments in Delphi
methodology. In H. A. Linstone and M. Turoff (Eds.), *The Delphi Method:
Techniques and Applications* (pp. 262-287). Reading, MA: Addison-Wesley.

## See also

[`delphi_status()`](https://yuricalleo.github.io/DelphiR/reference/delphi_status.md)
to combine stability with consensus.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
delphi_stability(x)
#> Stability criterion: Wilcoxon signed-rank test, stable if p >= 0.05
#> Paired comparison on the experts who answered both rounds.
#> 
#>     indicator item round_from round_to n_paired median_from median_to iqr_from
#>        impact   E1          1        2       13           7         8     1.50
#>        impact   E2          1        2       13           5         5     3.00
#>        impact   E3          1        2       13           7         7     2.00
#>        impact   E4          1        2       13           7         7     2.00
#>        impact   E5          1        2       13           4         4     5.50
#>        impact   E6          1        2       12           3         3     3.75
#>        impact   E7          1        2       13           8         8     2.50
#>        impact   E8          1        2       12           4         5     3.00
#>  plausibility   E1          1        2       13          77        78    18.50
#>  plausibility   E2          1        2       12          28        30    21.75
#>  plausibility   E3          1        2       13          62        60    19.00
#>  plausibility   E4          1        2       13          63        66    24.00
#>  plausibility   E5          1        2       13          30        36    73.00
#>  plausibility   E6          1        2       13          30        30    23.50
#>  plausibility   E7          1        2       13          80        83    24.50
#>  plausibility   E8          1        2       13          40        41    27.00
#>  iqr_to changed p_value scheibe_change stable
#>       1    0.62    0.10           0.23   TRUE
#>       0    0.69    0.85           0.62   TRUE
#>       1    0.46    0.13           0.31   TRUE
#>       1    0.62    0.41           0.23   TRUE
#>       7    0.23    0.77           0.15   TRUE
#>       2    0.67    0.52           0.42   TRUE
#>       1    0.62    0.53           0.31   TRUE
#>       2    0.83    0.64           0.33   TRUE
#>      11    1.00    0.97           0.31   TRUE
#>       8    1.00    0.36           0.42   TRUE
#>      15    0.92    0.48           0.23   TRUE
#>       4    0.85    0.89           0.31   TRUE
#>      66    0.77    0.21           0.15   TRUE
#>      16    1.00    0.48           0.23   TRUE
#>      11    0.92    0.02           0.38  FALSE
#>      24    0.92    0.27           0.31   TRUE
#> 
#> Stable items:
#>   impact, round 1 to 2: 8 of 8
#>   plausibility, round 1 to 2: 7 of 8
#> All columns: as.data.frame(x).

# Scheibe criterion only, on the impact ratings
delphi_stability(x, method = "scheibe", indicator = "impact")
#> Stability criterion: Scheibe et al. (1975), stable if change <= 15%
#> Paired comparison on the experts who answered both rounds.
#> 
#>  indicator item round_from round_to n_paired median_from median_to iqr_from
#>     impact   E1          1        2       13           7         8     1.50
#>     impact   E2          1        2       13           5         5     3.00
#>     impact   E3          1        2       13           7         7     2.00
#>     impact   E4          1        2       13           7         7     2.00
#>     impact   E5          1        2       13           4         4     5.50
#>     impact   E6          1        2       12           3         3     3.75
#>     impact   E7          1        2       13           8         8     2.50
#>     impact   E8          1        2       12           4         5     3.00
#>  iqr_to changed p_value scheibe_change stable
#>       1    0.62    0.10           0.23  FALSE
#>       0    0.69    0.85           0.62  FALSE
#>       1    0.46    0.13           0.31  FALSE
#>       1    0.62    0.41           0.23  FALSE
#>       7    0.23    0.77           0.15  FALSE
#>       2    0.67    0.52           0.42  FALSE
#>       1    0.62    0.53           0.31  FALSE
#>       2    0.83    0.64           0.33  FALSE
#> 
#> Stable items:
#>   impact, round 1 to 2: 0 of 8
#> All columns: as.data.frame(x).
```
