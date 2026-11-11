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
      items = paste0("E", 1:8), scale_min = 1, scale_max = 10, linked = TRUE
    )
    session$setInputs(add_part = 1)
    x <- study()
    expect_equal(names(x$scales), "impact")
    expect_equal(x$items, paste0("E", 1:8))
    code <- code_txt()
    expect_true(any(grepl("read_delphi(\"delphi_round1.csv\"", code, fixed = TRUE)))
    expect_true(any(grepl("indicator = \"impact\"", code, fixed = TRUE)))
    expect_false(any(grepl("delphi_stability", code)))
  })
})
