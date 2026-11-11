# Create a data-entry template

Writes an empty file in the DelphiR format, ready to be filled in with
the ratings of a Delphi study and imported with
[`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md).
Excel templates contain four sheets:

- `ratings`, with the column headers of the chosen layout;

- `items`, listing the item codes, next to which the full statements can
  be written;

- `comments`, for the written comments of the experts, one per row (see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md));

- `instructions`, explaining how to fill in the template, with an
  example and the R code to import it.

CSV templates contain the `ratings` table only.

## Usage

``` r
delphi_template(
  file,
  items = 10,
  layout = c("wide", "long"),
  indicators = c("impact", "probability"),
  overwrite = FALSE
)
```

## Arguments

- file:

  Path of the template, ending in `.xlsx` or `.csv`.

- items:

  Number of items, or a character vector of item codes. By default, ten
  items coded `E1` to `E10`.

- layout:

  `"wide"` (default), with one row per expert, round and indicator and
  one column per item, or `"long"`, with one row per rating.

- indicators:

  Indicator labels shown in the instructions, for example
  `c("impact", "probability")`.

- overwrite:

  Whether to replace an existing file.

## Value

The path of the template, invisibly.

## Details

Excel templates require the writexl package. Every row of the `ratings`
sheet must identify the expert and the round; in the wide layout, each
row also names the indicator to which its ratings refer. The same expert
should keep the same identifier in every round, so that individual
opinions can be followed across rounds.

## See also

[`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md)
to import the completed template.

## Examples

``` r
# \donttest{
if (requireNamespace("writexl", quietly = TRUE)) {
  path <- delphi_template(file.path(tempdir(), "delphi_template.xlsx"),
                          items = 8, indicators = c("impact", "probability"))
  path
}
#> [1] "/tmp/Rtmpeb3Zvn/delphi_template.xlsx"
# }
# A CSV template in the long layout
path <- delphi_template(file.path(tempdir(), "delphi_long.csv"), layout = "long")
readLines(path)
#> [1] "\"expert\",\"round\",\"indicator\",\"item\",\"value\""
```
