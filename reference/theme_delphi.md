# ggplot2 theme for DelphiR figures

A restrained theme for publication figures: white background, light
horizontal grid, no panel border, and dark grey text. All plotting
functions in DelphiR use it; it can also be added to any ggplot.

## Usage

``` r
theme_delphi(base_size = 11, base_family = "")
```

## Arguments

- base_size:

  Base font size, in points.

- base_family:

  Base font family.

## Value

A
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_delphi()
```
