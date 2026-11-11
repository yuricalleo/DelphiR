make_x <- function() {
  r1 <- data.frame(expert = c("A", "B", "C", "D"),
                   E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
  delphi_data(r1, expert_col = "expert", indicator = "impact")
}

make_cm <- function() {
  data.frame(
    expert = c("A", "D", "D", "B", "B"),
    item = c("E1", "E1", "E2", "E2", ""),
    comment = c("Depends on public funding.", "Unlikely without new regulation.",
                "The statement is  too\nbroad.", "Public funding is scarce.",
                "Clear questionnaire."),
    theme = c("funding", "regulation", "wording; funding ;", " funding", NA),
    stringsAsFactors = FALSE
  )
}

test_that("comments in the long layout are validated and stored", {
  x <- delphi_add_comments(make_x(), make_cm())
  cm <- x$comments
  expect_equal(nrow(cm), 5)
  expect_named(cm, c("expert", "round", "item", "indicator", "comment", "theme"))
  expect_true(is.na(cm$item[nrow(cm)]))
  expect_equal(cm$comment[cm$expert == "D" & cm$item %in% "E2"], "The statement is too broad.")
  expect_equal(cm$theme[cm$expert == "D" & cm$item %in% "E2"], "wording; funding")
  expect_equal(cm$theme[cm$expert == "B" & cm$item %in% "E2"], "funding")
  expect_true(all(cm$round == 1L))
  expect_output(print(x), "Comments:   5 \\(round 1\\); coded with themes")
})

test_that("invalid comments give clear errors and warnings", {
  x <- make_x()
  cm <- make_cm()
  bad <- cm
  bad$item[1] <- "E9"
  expect_error(delphi_add_comments(x, bad), "unknown item")
  expect_error(delphi_add_comments(x, cm, round = 2), "without ratings")
  expect_error(delphi_add_comments(x, cm, item_col = "nope"), "not found")
  bad <- cm
  bad$expert[1] <- "Z"
  expect_warning(delphi_add_comments(x, bad), "without ratings in the same round")
  bad <- cm
  bad$expert[1] <- ""
  expect_warning(delphi_add_comments(x, bad), "without an expert identifier")
  empty <- cm
  empty$comment <- ""
  expect_warning(y <- delphi_add_comments(x, empty), "No comments found")
  expect_null(y$comments)
  y <- delphi_add_comments(x, cm)
  expect_warning(y <- delphi_add_comments(y, cm), "duplicated")
  expect_equal(nrow(y$comments), 5)
})

test_that("the round of the comments is required with several rounds", {
  r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(4, 8, 6))
  r2 <- data.frame(expert = c("A", "B", "C"), E1 = c(6, 7, 6))
  x <- delphi_bind(delphi_data(r1, expert_col = "expert", round = 1),
                   delphi_data(r2, expert_col = "expert", round = 2))
  cm <- data.frame(expert = "A", item = "E1", comment = "Too optimistic.")
  expect_error(delphi_add_comments(x, cm), "several rounds")
  y <- delphi_add_comments(x, cm, round = 2)
  expect_equal(y$comments$round, 2L)
  cm$round <- 1
  y <- delphi_add_comments(x, cm)
  expect_equal(y$comments$round, 1L)
  expect_error(delphi_add_comments(x, cm, round = 2, round_col = "round"), "not both")
})

test_that("comments in the wide layout are converted", {
  x <- make_x()
  wide <- data.frame(id = c("A", "C", "D"),
                     age = c(40, 50, 60),
                     c1 = c("Depends on public funding.", "", NA),
                     c2 = c(NA, "Hard to assess.", "Too broad."),
                     stringsAsFactors = FALSE)
  y <- delphi_add_comments(x, wide, layout = "wide", expert_col = "id",
                           comment_cols = c("c1", "c2"))
  expect_equal(nrow(y$comments), 3)
  expect_equal(y$comments$item, c("E1", "E2", "E2"))
  z <- delphi_add_comments(x, wide, layout = "wide", expert_col = "id",
                           comment_cols = 3:4)
  expect_equal(z$comments, y$comments)
  expect_error(delphi_add_comments(x, wide, layout = "wide", expert_col = "id",
                                   comment_cols = 3),
               "one comment column per item")
  w <- delphi_add_comments(x, wide, layout = "wide", expert_col = "id",
                           comment_cols = 4, items = "E2")
  expect_equal(unique(w$comments$item), "E2")
  expect_error(delphi_add_comments(x, wide, layout = "wide", expert_col = "id"),
               "comment_cols")
})

test_that("delphi_comments places each author relative to the quartiles", {
  x <- delphi_add_comments(make_x(), make_cm())
  co <- delphi_comments(x)
  expect_s3_class(co, "delphi_comments")
  # E1 ratings 2, 6, 7, 8: Q1 = 5, Q3 = 7.25 (type 7)
  e1 <- co[co$item %in% "E1", ]
  expect_equal(e1$impact_rating[e1$expert == "A"], 7)
  expect_equal(e1$impact_position[e1$expert == "A"], "within IQR")
  expect_equal(e1$impact_position[e1$expert == "D"], "below Q1")
  # E2 ratings 3, 4, 5, 9: Q1 = 3.75, Q3 = 6
  e2 <- co[co$item %in% "E2", ]
  expect_equal(e2$impact_position[e2$expert == "D"], "above Q3")
  expect_equal(e2$impact_position[e2$expert == "B"], "within IQR")
  expect_true(is.na(co$impact_position[is.na(co$item)]))
  expect_equal(co$outside_iqr, c(FALSE, TRUE, TRUE, FALSE, NA))
  expect_equal(nrow(delphi_comments(x, general = FALSE)), 4)
  expect_equal(nrow(delphi_comments(x, items = "E2", general = FALSE)), 2)
  expect_output(print(co), "Round 1, item E1")
  expect_output(print(co, n = 1), "more comment")
  expect_error(delphi_comments(make_x()), "no comments")
})

test_that("comment counts include items without comments", {
  r1 <- data.frame(expert = c("A", "B", "C", "D"),
                   E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9), E3 = c(5, 5, 5, NA))
  x <- delphi_data(r1, expert_col = "expert", indicator = "impact")
  x <- delphi_add_comments(x, make_cm())
  cnt <- delphi_comment_counts(x)
  expect_equal(cnt$item, c("E1", "E2", "E3"))
  expect_equal(cnt$n_comments, c(2, 2, 0))
  expect_equal(cnt$n_raters, c(4, 4, 3))
  expect_equal(cnt$share_experts, c(0.5, 0.5, 0))
  expect_equal(cnt$n_outside, c(1, 1, 0))
  expect_error(delphi_comment_counts(x, indicator = "nope"), "must be one of")
})

test_that("positions can refer to one indicator", {
  r1 <- data.frame(expert = rep(c("A", "B", "C", "D"), 2),
                   indicator = rep(c("impact", "probability"), each = 4),
                   E1 = c(7, 8, 6, 2, 5, 5, 5, 5))
  x <- delphi_data(r1, expert_col = "expert", indicator_col = "indicator")
  x <- delphi_add_comments(x, data.frame(expert = "D", item = "E1", comment = "No."))
  co <- delphi_comments(x)
  expect_equal(co$probability_position, "within IQR")
  expect_true(co$outside_iqr)
  expect_equal(delphi_comment_counts(x)$n_outside, 1)
  expect_equal(delphi_comment_counts(x, indicator = "probability")$n_outside, 0)
})

test_that("themes are tabulated by item and across items", {
  x <- delphi_add_comments(make_x(), make_cm())
  th <- delphi_themes(x)
  expect_equal(th$item, c("E1", "E1", "E2", "E2"))
  e2 <- th[th$item == "E2", ]
  expect_equal(e2$theme, c("funding", "wording"))
  expect_equal(e2$n_comments, c(2, 1))
  expect_equal(e2$n_outside, c(1, 1))
  tt <- delphi_themes(x, by = "theme")
  expect_equal(tt$theme[1], "funding")
  expect_equal(tt$n_comments[1], 3)
  expect_equal(tt$n_items[1], 2)
  expect_equal(tt$items[1], "E1, E2")
  y <- make_cm()
  y$theme <- NULL
  expect_error(delphi_themes(delphi_add_comments(make_x(), y)), "No themes")
})

test_that("word frequencies remove common words", {
  x <- make_x()
  cm <- data.frame(
    expert = c("A", "B", "C"), item = "E1",
    comment = c("Public funding is essential, and funding matters.",
                "Senza finanziamenti pubblici, l'impatto sar\u00e0 pi\u00f9 basso.",
                "The impact of 2030 targets."),
    stringsAsFactors = FALSE
  )
  x <- delphi_add_comments(x, cm)
  w <- delphi_words(x)
  expect_equal(w$word[1], "funding")
  expect_equal(w$n[1], 2)
  expect_equal(w$n_comments[1], 1)
  expect_false(any(c("the", "and", "senza", "sar\u00e0", "pi\u00f9", "2030") %in% w$word))
  expect_true("impatto" %in% w$word)
  expect_true("the" %in% delphi_words(x, language = NULL, top = NULL)$word)
  expect_false("public" %in% delphi_words(x, stopwords = "Public")$word)
  expect_equal(nrow(delphi_words(x, top = 2)), 2)
  expect_error(delphi_words(x, language = "fr"), "language")
})

test_that("comments survive delphi_bind and are plotted", {
  r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(4, 8, 6))
  r2 <- data.frame(expert = c("A", "B", "C"), E1 = c(6, 7, 6))
  x1 <- delphi_add_comments(delphi_data(r1, expert_col = "expert", round = 1),
                            data.frame(expert = "A", item = "E1", comment = "First."))
  x2 <- delphi_add_comments(delphi_data(r2, expert_col = "expert", round = 2),
                            data.frame(expert = "B", item = "E1", comment = "Second."))
  x <- delphi_bind(x1, x2)
  expect_equal(x$comments$round, c(1L, 2L))
  p <- delphi_plot_comments(x)
  expect_s3_class(p, "ggplot")
  expect_s3_class(plot(x, type = "comments", round = 2), "ggplot")
})

test_that("comments are read from an Excel sheet and the template", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  path <- withr::local_tempfile(fileext = ".xlsx")
  delphi_template(path, items = 2, indicators = "impact")
  sheets <- readxl::excel_sheets(path)
  expect_true("comments" %in% sheets)
  ratings <- data.frame(expert = c("A", "B", "C", "D"), round = 1, indicator = "impact",
                        E1 = c(7, 8, 6, 2), E2 = c(3, 5, 4, 9))
  cm <- make_cm()
  cm$item[cm$item == ""] <- NA
  writexl::write_xlsx(list(ratings = ratings, comments = cm,
                           comments_empty = data.frame(expert = NA, item = NA, comment = NA)),
                      path)
  x <- read_delphi(path, sheet = "ratings", expert_col = "expert", round_col = "round",
                   indicator_col = "indicator", comments_sheet = "comments")
  expect_equal(nrow(x$comments), 5)
  expect_equal(sum(!is.na(x$comments$theme)), 4)
  y <- read_delphi(path, sheet = "ratings", expert_col = "expert", round_col = "round",
                   indicator_col = "indicator", comments_sheet = "comments_empty")
  expect_null(y$comments)
  expect_error(read_delphi(path, sheet = "ratings", expert_col = "expert",
                           round_col = "round", indicator_col = "indicator",
                           comments_sheet = "ratings"),
               "columns named")
  csv <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(ratings, csv, row.names = FALSE)
  expect_error(read_delphi(csv, comments_sheet = "comments"), "Excel")
})

test_that("delphi_feedback selects the items for the next round", {
  x <- delphi_data(delphi_example, expert_col = "expert",
                   round_col = "round", indicator_col = "indicator",
                   scale = list(impact = c(1, 10), plausibility = c(1, 100)))
  st <- delphi_status(x)
  fb <- delphi_feedback(x)
  expect_s3_class(fb, "delphi_feedback")
  expect_setequal(unique(fb$item), unique(st$item[st$next_round]))
  expect_named(fb, c("item", "statement", "indicator", "round", "n", "median",
                     "q1", "q3", "iqr", "consensus", "status"))
  fb2 <- delphi_feedback(x, items = c("E2", "E1"))
  expect_equal(unique(fb2$item), c("E1", "E2"))
  expect_equal(nrow(attr(fb2, "comments")), 0)
  expect_output(print(fb2), "impact")

  cm <- data.frame(expert = unique(x$data$expert)[1:2], item = "E1",
                   comment = c("Too optimistic.", "Agree."))
  y <- delphi_add_comments(x, cm, round = max(x$data$round))
  fb3 <- delphi_feedback(y, items = "E1")
  expect_equal(attr(fb3, "comments")$comment, c("Too optimistic.", "Agree."))
  expect_equal(nrow(attr(delphi_feedback(y, items = "E1", comments = FALSE), "comments")), 0)
  expect_error(delphi_feedback(x, items = "E99"), "not in the data")

  r1 <- data.frame(expert = c("A", "B", "C"), E1 = c(5, 5, 5))
  z <- delphi_data(r1, expert_col = "expert")
  expect_error(delphi_feedback(z), "No item requires a further round")
})

test_that("feedback documents and reports with comments are rendered", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())
  x <- delphi_data(delphi_example, expert_col = "expert",
                   round_col = "round", indicator_col = "indicator",
                   scale = list(impact = c(1, 10), plausibility = c(1, 100)))
  r <- max(x$data$round)
  ex <- unique(x$data$expert)
  cm <- data.frame(expert = ex[1:3], item = c("E1", "E1", NA),
                   comment = c("3. A *bold* claim [sic].", "Agree.", "Clear survey."),
                   theme = c("costs", "costs; time", NA))
  x <- delphi_add_comments(x, cm, round = r)
  dir <- withr::local_tempdir()
  out <- delphi_feedback(x, file.path(dir, "fb.html"), items = "E1", open = FALSE)
  expect_s3_class(out, "delphi_feedback")
  html <- paste(readLines(file.path(dir, "fb.html"), warn = FALSE), collapse = "\n")
  expect_match(html, "Comments from the panel")
  expect_match(html, "A \\*bold\\* claim \\[sic\\]|A [*]bold[*] claim")
  out <- delphi_report(x, file.path(dir, "rep.html"), comments = "all", open = FALSE)
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_match(html, "Expert comments")
  expect_match(html, "Themes")
  expect_match(html, "General comments")
  delphi_feedback(x, file.path(dir, "fb.docx"), items = "E1", open = FALSE)
  expect_true(file.exists(file.path(dir, "fb.docx")))
})
