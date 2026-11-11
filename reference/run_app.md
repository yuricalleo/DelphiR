# Interactive application

Opens the DelphiR application in the web browser. The application covers
the whole workflow without writing code:

- importing the ratings from CSV or Excel files, in any of the layouts
  accepted by
  [`read_delphi()`](https://yuricalleo.github.io/DelphiR/reference/read_delphi.md),
  by choosing which columns hold the experts, the rounds, the indicators
  and the items; rounds stored in separate sheets or files are added one
  at a time;

- adding the comments of the experts, in the long or the wide layout of
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md);

- descriptive statistics, consensus, stability and item status, with the
  criteria chosen in the sidebar;

- the figures of DelphiR, which can be downloaded as PNG or PDF files;

- the analysis of the comments;

- the round report and the feedback for the experts, in Word or HTML
  format;

- the R code that reproduces the analysis, so that every result obtained
  in the application can be documented and repeated.

## Usage

``` r
run_app(x = NULL, launch.browser = interactive(), ...)
```

## Arguments

- x:

  Optional `delphi_data` object to open in the application. If `NULL`
  (default), data are imported in the application.

- launch.browser:

  Whether to open the application in the web browser; passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

- ...:

  Further arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html), such
  as `port`.

## Value

Called for its side effect; returns when the application is closed.

## Details

The application requires the shiny, bslib and DT packages; Excel files
also require readxl, and reports rmarkdown and Pandoc. Uploaded files
are processed in the R session that runs the application and are not
sent elsewhere.

## Examples

``` r
if (interactive()) {
  run_app()

  # Open a study already imported in R
  x <- delphi_data(delphi_example, expert_col = "expert",
                   round_col = "round", indicator_col = "indicator",
                   scale = list(impact = c(1, 10), plausibility = c(1, 100)))
  run_app(x)
}
```
