# Item status from consensus and stability

Combines
[`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md)
and
[`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md)
to classify every item at a given round, and flags the items to submit
again in the next round.

## Usage

``` r
delphi_status(
  x,
  round = NULL,
  threshold = 0.2,
  relative_to = c("points", "range"),
  method = c("wilcoxon", "scheibe", "both"),
  alpha = 0.05,
  scheibe = 0.15,
  type = 7,
  paired = NULL
)
```

## Arguments

- x:

  A `delphi_data` object.

- round:

  Round to assess, for each indicator. `NULL` (default) uses the last
  round of each indicator. Stability is measured between this round and
  the previous one.

- threshold, relative_to:

  Consensus rule, see
  [`delphi_consensus()`](https://yuricalleo.github.io/DelphiR/reference/delphi_consensus.md).

- method, alpha, scheibe, paired:

  Stability rule, see
  [`delphi_stability()`](https://yuricalleo.github.io/DelphiR/reference/delphi_stability.md).

- type:

  Quantile algorithm; see
  [`delphi_describe()`](https://yuricalleo.github.io/DelphiR/reference/delphi_describe.md).

## Value

A data frame of class `delphi_status` with columns `indicator`, `item`,
`round`, `median`, `iqr`, `consensus`, `stable`, `status` and
`next_round`.

## Details

Each item gets one of four statuses:

|                        |           |        |            |
|------------------------|-----------|--------|------------|
| status                 | consensus | stable | next round |
| `"consensus"`          | yes       | yes    | no         |
| `"unstable consensus"` | yes       | no     | yes        |
| `"stable dissent"`     | no        | yes    | no         |
| `"open"`               | no        | no     | yes        |

A stable dissent means that opinions have stopped moving without
converging: another round is unlikely to produce consensus, and the
disagreement is itself a result to report. When only one round is
available, stability cannot be assessed (`stable = NA`); items with
consensus are then `"consensus"` and the others `"open"`.

## Examples

``` r
x <- delphi_data(delphi_example, expert_col = "expert",
                 round_col = "round", indicator_col = "indicator",
                 scale = list(impact = c(1, 10), plausibility = c(1, 100)))
st <- delphi_status(x)
st
#>     indicator item round median iqr consensus stable             status
#>        impact   E1     2      8   1      TRUE   TRUE          consensus
#>        impact   E2     2      5   0      TRUE   TRUE          consensus
#>        impact   E3     2      7   1      TRUE   TRUE          consensus
#>        impact   E4     2      7   1      TRUE   TRUE          consensus
#>        impact   E5     2      4   7     FALSE   TRUE     stable dissent
#>        impact   E6     2      3   2      TRUE   TRUE          consensus
#>        impact   E7     2      8   1      TRUE   TRUE          consensus
#>        impact   E8     2      5   2      TRUE   TRUE          consensus
#>  plausibility   E1     2     78  11      TRUE   TRUE          consensus
#>  plausibility   E2     2     30   8      TRUE   TRUE          consensus
#>  plausibility   E3     2     60  15      TRUE   TRUE          consensus
#>  plausibility   E4     2     66   4      TRUE   TRUE          consensus
#>  plausibility   E5     2     36  66     FALSE   TRUE     stable dissent
#>  plausibility   E6     2     30  16      TRUE   TRUE          consensus
#>  plausibility   E7     2     83  11      TRUE  FALSE unstable consensus
#>  plausibility   E8     2     41  24     FALSE   TRUE     stable dissent
#>  next_round
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>       FALSE
#>        TRUE
#>       FALSE
#> 
#> impact, round 2: 7 consensus, 0 unstable consensus, 1 stable dissent, 0 open
#>   Items for the next round: none
#> 
#> plausibility, round 2: 5 consensus, 1 unstable consensus, 2 stable dissent, 0 open
#>   Items for the next round: E7

# Items to submit again in the next round
subset(st, next_round)
#>     indicator item round median iqr consensus stable             status
#>  plausibility   E7     2     83  11      TRUE  FALSE unstable consensus
#>  next_round
#>        TRUE
#> 
#> plausibility, round 2: 0 consensus, 1 unstable consensus, 0 stable dissent, 0 open
#>   Items for the next round: E7
```
