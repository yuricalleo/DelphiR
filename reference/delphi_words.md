# Word frequencies in the comments

Counts the words used in the comments, after removing common words
(articles, prepositions, pronouns and auxiliary verbs) in English and
Italian. Word frequencies give a first, descriptive view of the content
of the comments; they do not replace a qualitative reading of the
comments.

## Usage

``` r
delphi_words(
  x,
  round = NULL,
  items = NULL,
  language = c("en", "it"),
  stopwords = NULL,
  min_length = 3,
  top = 20
)
```

## Arguments

- x:

  A `delphi_data` object with comments; see
  [`delphi_add_comments()`](https://yuricalleo.github.io/DelphiR/reference/delphi_add_comments.md).

- round, items:

  Optional subsets of rounds and items.

- language:

  Languages whose common words are removed: any of `"en"` (English) and
  `"it"` (Italian), or `NULL` to keep all words.

- stopwords:

  Additional words to remove, for example the words used in every item
  statement.

- min_length:

  Minimum number of letters of the words to count.

- top:

  Number of words to return; `NULL` returns all of them.

## Value

A data frame with columns `word`, `n` (number of occurrences) and
`n_comments` (number of comments in which the word appears), ordered by
decreasing frequency.

## Details

Comments are converted to lower case and split into words at every
character that is not a letter, so that numbers and punctuation are
discarded and elided forms such as `dell'impatto` are split into two
words. No stemming is applied: "policy" and "policies" are counted as
different words.

## Examples

``` r
r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(7, 8, 6))
x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
cm <- data.frame(expert = c("A", "B", "C"), item = "E1",
                 comment = c("Public funding is essential.",
                             "Without public funding, no impact.",
                             "Regulation matters more than funding."))
x <- delphi_add_comments(x, cm)
delphi_words(x)
#>         word n n_comments
#> 1    funding 3          3
#> 2     public 2          2
#> 3  essential 1          1
#> 4     impact 1          1
#> 5    matters 1          1
#> 6 regulation 1          1
```
