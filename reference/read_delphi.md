# Read Delphi ratings from a file

Reads a CSV, TSV, TXT or Excel file of expert ratings and returns a
validated `delphi_data` object. Three layouts are supported:

- wide (`layout = "wide"`, default): the DelphiR wide layout, with one
  row per expert and one column per item, as in the template created by
  [`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md);

- long (`layout = "long"`): one row per rating, with columns for the
  expert, the item and the rating, and optionally the round and the
  indicator; see
  [`delphi_data_long()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data_long.md);

- wide with two header rows (`header_rows = 2`): the layout produced by
  many survey platforms when each item is rated on several indicators.
  The first row gives the indicator of each column (for example impact,
  probability and desirability) and the second row the item statement,
  written once above the group of columns that refer to the same item
  (as with merged cells). Columns with an empty first-row cell, such as
  the expert identifier or demographic variables, are not treated as
  items.

## Usage

``` r
read_delphi(
  file,
  ...,
  sheet = 1,
  layout = c("wide", "long"),
  header_rows = 1,
  items_sheet = NULL,
  indicator_names = NULL,
  item_prefix = "E",
  sep = NULL,
  dec = NULL,
  encoding = "UTF-8"
)
```

## Arguments

- file:

  Path to a `.csv`, `.tsv`, `.txt`, `.xlsx` or `.xls` file.

- ...:

  Arguments passed to
  [`delphi_data()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data.md)
  (wide layout) or to
  [`delphi_data_long()`](https://yuricalleo.github.io/DelphiR/reference/delphi_data_long.md)
  (long layout), such as `expert_col`, `round`, `indicator`, `scale` and
  `linked`.

- sheet:

  For Excel files, the sheet to read (name or position).

- layout:

  `"wide"` (default) or `"long"`; see Description.

- header_rows:

  Number of header rows of a wide file, `1` or `2`; see Description.

- items_sheet:

  For Excel files, an optional sheet with the item statements, in two
  columns named `item` and `statement`, as in the template created by
  [`delphi_template()`](https://yuricalleo.github.io/DelphiR/reference/delphi_template.md).
  The statements are stored as item labels and used in reports.

- indicator_names:

  For `header_rows = 2`, an optional named character vector that renames
  the indicators found in the first header row, for example
  `c(IMPATTO = "impact", PROBAB = "probability")`. The names used in
  `scale` must be the new ones.

- item_prefix:

  For `header_rows = 2`, the prefix of the item codes. Items are coded
  in order of appearance (`E1`, `E2`, ...), and their statements are
  kept as item labels.

- sep:

  Field separator for text files. By default it is detected from the
  first line: `";"`, `","` or tab.

- dec:

  Decimal mark for text files. By default `","` when the separator is
  `";"` (the usual European CSV export), `"."` otherwise.

- encoding:

  File encoding for text files.

## Value

A `delphi_data` object.

## Details

Reading Excel files requires the readxl package. With one header row,
column names are preserved exactly as they appear in the file, so that
items may be coded `E1`, `E2`, ... or carry full labels. Rows without an
expert identifier, such as summary rows with medians or quartiles added
below the data, are ignored with a warning.

## Examples

``` r
path <- system.file("extdata", "delphi_round1.csv", package = "DelphiR")
x <- read_delphi(path, expert_col = "expert", indicator = "impact",
                 scale = c(1, 10))
x
#> <delphi_data>
#>   Experts:    15
#>   Rounds:     1 (1)
#>   Items:      8 (E1, E2, E3, E4, E5, ..., E8)
#>   Indicators: impact (from 1 to 10)
#>   Ratings:    119 (1 missing)
#> Use summary() for descriptive statistics.

# Two header rows: indicators in the first, item statements in the second
tmp <- tempfile(fileext = ".csv")
writeLines(c(
  ",Impact,Probability,Impact,Probability",
  "ID,Remote work becomes the norm,,AI agents manage recruitment,",
  "A,8,6,5,4",
  "B,9,7,6,6",
  "C,7,7,4,5"
), tmp)
y <- read_delphi(tmp, header_rows = 2, expert_col = "ID", scale = c(1, 10))
y
#> <delphi_data>
#>   Experts:    3
#>   Rounds:     1 (1)
#>   Items:      2 (E1, E2)
#>   Indicators: Impact (from 1 to 10), Probability (from 1 to 10)
#>   Ratings:    12 (0 missing)
#> Use summary() for descriptive statistics.
y$labels
#>                             E1                             E2 
#> "Remote work becomes the norm" "AI agents manage recruitment" 
```
