test_that("generated code is valid R and keeps the arguments", {
  code <- code_call("read_delphi", list("my file.xlsx", sheet = "ROUND_1",
                                        header_rows = 2, linked = FALSE),
                    assign = "part1")
  expect_match(code, "^part1 <- read_delphi\\(\"my file.xlsx\"")
  expect_silent(parse(text = code))
  long <- code_call("f", list(a = paste(rep("x", 40), collapse = ""),
                              b = paste(rep("y", 40), collapse = "")))
  expect_match(long, ",\n  b = ")
  expect_equal(code_call("f", list(code_symbol("x"), n = 2L)), "f(x, n = 2L)")
  expect_equal(code_columns(c("c2", "c4", "c6"), c("id", "c2", "x", "c4", "y", "c6")),
               code_symbol("names(comments)[seq(2, 6, by = 2)]"))
  expect_equal(code_columns(c("c2", "c6"), c("id", "c2", "c6")), c("c2", "c6"))
})

test_that("the choices of the application become read_delphi() arguments", {
  spec <- list(layout = "wide", sheet = "ratings", expert_col = "expert",
               round_col = "round", round = 1, indicator_col = "indicator",
               indicator = "score", items = c("E1", "E2"), all_items = c("E1", "E2"),
               scale = c(1, 10), linked = TRUE, items_sheet = "items")
  args <- import_args(spec, excel = TRUE)
  expect_equal(args, list(sheet = "ratings", expert_col = "expert", round_col = "round",
                          indicator_col = "indicator", items_sheet = "items"))
  expect_null(import_args(spec, excel = FALSE)$sheet)

  spec2 <- list(layout = "wide", expert_col = "", round_col = "", round = 2,
                indicator_col = "", indicator = "impact", items = "E1",
                all_items = c("E1", "E2"), scale = c(1, 100), linked = FALSE)
  args2 <- import_args(spec2)
  expect_equal(args2$round, 2L)
  expect_equal(args2$indicator, "impact")
  expect_equal(args2$items, "E1")
  expect_equal(args2$scale, c(1, 100))
  expect_false(args2$linked)
  expect_null(args2$expert_col)

  spec3 <- list(layout = "wide2", sheet = "R1", expert_col = "ID", round_col = "",
                round = 1, indicator_names = c(IMPATTO = "impact", PROB = "PROB"),
                scale = c(1, 10), linked = FALSE, items_sheet = "items")
  args3 <- import_args(spec3, excel = TRUE)
  expect_equal(args3$header_rows, 2)
  expect_equal(args3$indicator_names, c(IMPATTO = "impact"))
  expect_null(args3$items_sheet)
  expect_null(args3[["indicator"]])

  spec4 <- list(layout = "long", expert_col = "who", item_col = "item", value_col = "score",
                round_col = "", round = 1, indicator_col = "", indicator = "score",
                scale = c(1, 10), linked = TRUE)
  args4 <- import_args(spec4)
  expect_equal(args4, list(layout = "long", expert_col = "who", value_col = "score"))
})

test_that("files with two header rows are described for the column choices", {
  raw <- data.frame(
    a = c(NA, "ID", "A", "B"), b = c(NA, NA, "40", "50"),
    c = c("IMPACT", "Statement 1", "8", "7"), d = c("PROB", NA, "6", "5"),
    stringsAsFactors = FALSE
  )
  expect_equal(two_header_id_cols(raw), c("ID", "V2"))
  expect_equal(two_header_indicators(raw), c("IMPACT", "PROB"))
  expect_equal(guess_scale(c(2, 9)), "From 1 to 10")
  expect_equal(guess_scale(c(1, 4)), "From 1 to 5")
  expect_equal(guess_scale(c(0, 7)), "From 0 to 10")
  expect_equal(guess_scale(c(3, 95)), "From 1 to 100")
  expect_equal(guess_scale(c(1, 500)), "other")
  expect_equal(observed_range(data.frame(a = c("7,5", "2"), b = c(NA, "x"))), c(2, 7.5))
  expect_equal(scale_arg(list(a = c(1, 5), b = c(1, 5))), c(1, 5))
  expect_equal(scale_arg(list(a = c(1, 5), b = c(1, 9))), list(a = c(1, 5), b = c(1, 9)))
  p <- preview_table(data.frame(t = strrep("a", 50)), width = 10)
  expect_equal(p$t, "aaaaaaa...")
})

test_that("run_app() checks its argument", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("DT")
  expect_error(run_app(1), "delphi_data")
  expect_s3_class(delphi_app(), "shiny.appobj")
})

test_that("the application imports data and reproduces the analysis", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("DT")
  criteria <- list(threshold = 20, relative_to = "points", method = "wilcoxon",
                   alpha = 0.05, scheibe = 15, type = "7")

  shiny::testServer(app_server(), {
    do.call(session$setInputs, criteria)
    session$setInputs(source = "example", add_part = 1)
    x <- study()
    expect_s3_class(x, "delphi_data")
    expect_equal(nrow(x$comments), nrow(delphi_example_comments))
    code <- code_txt()
    expect_true(any(grepl("delphi_example_comments", code)))
    expect_silent(parse(text = code))
    # The code reproduces the object of the application
    env <- new.env()
    eval(parse(text = code[seq_len(grep("^x$", code)[1L])]), envir = env)
    expect_equal(env$x$data, x$data)
    expect_equal(env$x$comments, x$comments)
    session$setInputs(threshold = 10)
    expect_true(any(grepl("threshold = 0.1", code_txt(), fixed = TRUE)))
    session$setInputs(clear = 1)
    expect_null(study())
  })

  path <- system.file("extdata", "delphi_round1.csv", package = "DelphiR")
  shiny::testServer(app_server(), {
    do.call(session$setInputs, criteria)
    session$setInputs(
      source = "file",
      file = data.frame(name = "delphi_round1.csv", size = 1, type = "text/csv",
                        datapath = path, stringsAsFactors = FALSE),
      layout = "wide", expert_col = "expert", round_col = "", round = 1,
      indicator_col = "", indicator = "impact",
      items = paste0("E", 1:8), scale_preset_1 = "From 1 to 10", linked = TRUE
    )
    session$setInputs(add_part = 1)
    x <- study()
    expect_equal(names(x$scales), "impact")
    expect_equal(x$items, paste0("E", 1:8))
    code <- code_txt()
    expect_true(any(grepl("read_delphi(\"delphi_round1.csv\"", code, fixed = TRUE)))
    expect_true(any(grepl("indicator = \"impact\"", code, fixed = TRUE)))
    expect_false(any(grepl("delphi_stability", code)))
    expect_false(any(grepl("scale =", code)))
    session$setInputs(clear = 1)
    session$setInputs(scale_preset_1 = "other", scale_min_1 = 0, scale_max_1 = 20, add_part = 2)
    expect_equal(study()$scales$impact, c(0, 20))
    expect_true(any(grepl("scale = c(0, 20)", code_txt(), fixed = TRUE)))
  })

  # Two indicators in the same table, with different scales
  ratings <- data.frame(expert = rep(c("A", "B", "C"), 2),
                        indicator = rep(c("impact", "plausibility"), each = 3),
                        E1 = c(7, 8, 6, 70, 85, 90), E2 = c(3, 5, 4, 20, 35, 40))
  csv <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(ratings, csv, row.names = FALSE)
  shiny::testServer(app_server(), {
    do.call(session$setInputs, criteria)
    session$setInputs(
      source = "file",
      file = data.frame(name = "two.csv", size = 1, type = "text/csv", datapath = csv,
                        stringsAsFactors = FALSE),
      layout = "wide", expert_col = "expert", round_col = "", round = 1,
      indicator_col = "indicator", indicator = "score", items = c("E1", "E2"),
      linked = TRUE
    )
    groups <- indicator_groups()
    expect_equal(vapply(groups, `[[`, character(1), "label"), c("impact", "plausibility"))
    expect_equal(groups[[2]]$range, c(20, 90))
    session$setInputs(scale_preset_1 = "From 1 to 10", scale_preset_2 = "From 1 to 100",
                      add_part = 1)
    expect_equal(study()$scales, list(impact = c(1, 10), plausibility = c(1, 100)))
    expect_true(any(grepl("scale = list(impact = c(1, 10), plausibility = c(1, 100))",
                          code_txt(), fixed = TRUE)))
  })
})
