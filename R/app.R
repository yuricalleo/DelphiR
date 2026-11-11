#' Interactive application
#'
#' @description
#' Opens the DelphiR application in the web browser. The application covers
#' the whole workflow without writing code:
#'
#' * importing the ratings from CSV or Excel files, in any of the layouts
#'   accepted by [read_delphi()], by choosing which columns hold the
#'   experts, the rounds, the indicators and the items; rounds stored in
#'   separate sheets or files are added one at a time;
#' * adding the comments of the experts, in the long or the wide layout of
#'   [delphi_add_comments()];
#' * descriptive statistics, consensus, stability and item status, with the
#'   criteria chosen in the sidebar;
#' * the figures of DelphiR, which can be downloaded as PNG or PDF files;
#' * the analysis of the comments;
#' * the round report and the feedback for the experts, in Word or HTML
#'   format;
#' * the R code that reproduces the analysis, so that every result obtained
#'   in the application can be documented and repeated.
#'
#' @param x Optional `delphi_data` object to open in the application. If
#'   `NULL` (default), data are imported in the application.
#' @param launch.browser Whether to open the application in the web
#'   browser; passed to [shiny::runApp()].
#' @param ... Further arguments passed to [shiny::runApp()], such as `port`.
#'
#' @details
#' The application requires the \pkg{shiny}, \pkg{bslib} and \pkg{DT}
#' packages; Excel files also require \pkg{readxl}, and reports
#' \pkg{rmarkdown} and Pandoc. Uploaded files are processed in the R
#' session that runs the application and are not sent elsewhere.
#'
#' @return Called for its side effect; returns when the application is
#'   closed.
#' @examples
#' if (interactive()) {
#'   run_app()
#'
#'   # Open a study already imported in R
#'   x <- delphi_data(delphi_example, expert_col = "expert",
#'                    round_col = "round", indicator_col = "indicator",
#'                    scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#'   run_app(x)
#' }
#' @export
run_app <- function(x = NULL, launch.browser = interactive(), ...) {
  missing_pkgs <- c("shiny", "bslib", "DT")[
    !vapply(c("shiny", "bslib", "DT"), requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing_pkgs) > 0L) {
    stop_dr(
      "The application requires the package(s) ", show_values(missing_pkgs),
      ". Install them with install.packages(c(",
      paste0("\"", missing_pkgs, "\"", collapse = ", "), "))."
    )
  }
  if (!is.null(x)) {
    assert_delphi_data(x)
  }
  shiny::runApp(delphi_app(x), launch.browser = launch.browser, ...)
}

# The application object
delphi_app <- function(x = NULL) {
  www <- system.file("app", "www", package = "DelphiR")
  if (nzchar(www)) {
    shiny::addResourcePath("delphir", www)
  }
  shiny::shinyApp(ui = app_ui(), server = app_server(x))
}


# User interface ------------------------------------------------------------

app_ui <- function() {
  theme <- bslib::bs_theme(version = 5, primary = delphi_colours$primary)
  title <- shiny::tags$span(
    shiny::tags$img(src = "delphir/logo.png", height = "34px",
                    style = "margin-right: 10px;", alt = ""),
    "DelphiR"
  )
  settings <- bslib::sidebar(
    title = "Criteria",
    width = 270,
    shiny::numericInput("threshold", "Consensus: IQR at most (% of the scale)",
                        value = 20, min = 1, max = 100, step = 1),
    shiny::selectInput("relative_to", "Scale size for the consensus rule",
                       c("Number of points (max - min + 1)" = "points",
                         "Range (max - min)" = "range")),
    shiny::selectInput("method", "Stability criterion",
                       c("Wilcoxon test" = "wilcoxon",
                         "Net change between distributions" = "scheibe",
                         "Both" = "both")),
    shiny::numericInput("alpha", "Significance level of the test", value = 0.05,
                        min = 0.001, max = 0.5, step = 0.01),
    shiny::numericInput("scheibe", "Net change at most (%)", value = 15,
                        min = 1, max = 100, step = 1),
    shiny::selectInput("type", "Quantile algorithm",
                       c("Type 7 (R default)" = 7, "Type 6 (SPSS, Minitab)" = 6)),
    shiny::helpText("The criteria apply to every table, figure and report."),
    shiny::uiOutput("thresholds")
  )

  bslib::page_navbar(
    title = title,
    window_title = "DelphiR",
    theme = theme,
    bg = "#16233b",
    inverse = TRUE,
    sidebar = settings,
    fillable = FALSE,
    bslib::nav_panel("Data", data_panel()),
    bslib::nav_panel("Overview", shiny::uiOutput("overview")),
    bslib::nav_panel("Descriptives", describe_panel()),
    bslib::nav_panel("Consensus and stability", consensus_panel()),
    bslib::nav_panel("Figures", figures_panel()),
    bslib::nav_panel("Comments", comments_panel()),
    bslib::nav_panel("Report", report_panel()),
    bslib::nav_panel("R code", code_panel())
  )
}

data_panel <- function() {
  shiny::tagList(
    bslib::layout_columns(
      col_widths = c(5, 7),
      bslib::card(
        bslib::card_header("1. Ratings"),
        shiny::radioButtons("source", NULL, inline = TRUE,
                            c("Upload a file" = "file", "Example data" = "example")),
        shiny::conditionalPanel(
          "input.source == 'file'",
          shiny::fileInput("file", "CSV, TSV, TXT or Excel file",
                           accept = c(".csv", ".tsv", ".txt", ".xlsx", ".xls")),
          shiny::uiOutput("sheet_ui"),
          shiny::radioButtons(
            "layout", "Layout",
            c("One row per expert, one column per item" = "wide",
              "As above, with two header rows (indicators, then item statements)" = "wide2",
              "One row per rating (long layout)" = "long")
          ),
          shiny::uiOutput("mapping_ui")
        ),
        shiny::conditionalPanel(
          "input.source == 'example'",
          shiny::helpText(
            "A simulated study with fifteen experts, two rounds, eight items and two ",
            "indicators (impact, from 1 to 10, and plausibility, from 1 to 100), ",
            "with the comments of round 2."
          )
        ),
        shiny::div(
          class = "d-flex gap-2",
          shiny::actionButton("add_part", "Add to the study", class = "btn-primary"),
          shiny::actionButton("clear", "Start again")
        )
      ),
      shiny::tagList(
        bslib::card(
          bslib::card_header("Preview of the file"),
          DT::DTOutput("preview", fill = FALSE)
        ),
        bslib::card(
          bslib::card_header("Study"),
          shiny::uiOutput("parts_ui"),
          shiny::verbatimTextOutput("study_print")
        )
      )
    ),
    bslib::card(
      bslib::card_header("2. Comments (optional)"),
      bslib::layout_columns(
        col_widths = c(5, 7),
        shiny::tagList(
          shiny::fileInput("cfile", "File with the comments (if empty, the ratings file is used)",
                           accept = c(".csv", ".tsv", ".txt", ".xlsx", ".xls")),
          shiny::uiOutput("csheet_ui"),
          shiny::radioButtons(
            "clayout", "Layout",
            c("One row per comment" = "long",
              "One row per expert, one comment column per item" = "wide")
          ),
          shiny::uiOutput("cmapping_ui"),
          shiny::actionButton("add_comments", "Add the comments", class = "btn-primary")
        ),
        DT::DTOutput("cpreview", fill = FALSE)
      )
    )
  )
}

describe_panel <- function() {
  bslib::card(
    bslib::card_header("Descriptive statistics by item, round and indicator"),
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      shiny::uiOutput("desc_round_ui"),
      shiny::uiOutput("desc_indicator_ui"),
      shiny::div(style = "margin-top: 32px;",
                 shiny::downloadButton("desc_download", "Download (CSV)"))
    ),
    DT::DTOutput("describe", fill = FALSE)
  )
}

consensus_panel <- function() {
  bslib::navset_card_tab(
    bslib::nav_panel(
      "Item status",
      shiny::uiOutput("next_round_txt"),
      DT::DTOutput("status", fill = FALSE),
      shiny::downloadButton("status_download", "Download (CSV)")
    ),
    bslib::nav_panel(
      "Consensus",
      DT::DTOutput("consensus", fill = FALSE),
      shiny::downloadButton("consensus_download", "Download (CSV)")
    ),
    bslib::nav_panel(
      "Stability",
      shiny::uiOutput("stability_note"),
      DT::DTOutput("stability", fill = FALSE),
      shiny::downloadButton("stability_download", "Download (CSV)")
    ),
    bslib::nav_panel(
      "Panel",
      DT::DTOutput("panel", fill = FALSE)
    )
  )
}

figures_panel <- function() {
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 280,
      position = "right",
      shiny::selectInput("fig_type", "Figure",
                         c("Distribution of the ratings" = "distribution",
                           "Median and IQR across rounds" = "trend",
                           "Consensus heat map" = "consensus",
                           "Map of two indicators" = "map",
                           "Comments by item" = "comments")),
      shiny::uiOutput("fig_options"),
      shiny::sliderInput("fig_height", "Height (pixels)", min = 300, max = 1600,
                         value = 600, step = 50),
      shiny::numericInput("fig_width_cm", "Width of the saved figure (cm)", 18,
                          min = 5, max = 50),
      shiny::numericInput("fig_height_cm", "Height of the saved figure (cm)", 14,
                          min = 5, max = 50),
      shiny::div(
        class = "d-flex gap-2",
        shiny::downloadButton("fig_png", "PNG"),
        shiny::downloadButton("fig_pdf", "PDF")
      )
    ),
    shiny::uiOutput("figure_ui")
  )
}

comments_panel <- function() {
  shiny::tagList(
    shiny::uiOutput("comments_none"),
    bslib::navset_card_tab(
      bslib::nav_panel(
        "Comments",
        bslib::layout_columns(
          col_widths = c(4, 8),
          shiny::uiOutput("com_round_ui"),
          shiny::uiOutput("com_items_ui")
        ),
        DT::DTOutput("comments_table", fill = FALSE),
        shiny::downloadButton("comments_download", "Download (CSV)")
      ),
      bslib::nav_panel(
        "By item",
        DT::DTOutput("comment_counts", fill = FALSE),
        shiny::plotOutput("comments_plot", height = "600px")
      ),
      bslib::nav_panel(
        "Themes",
        shiny::radioButtons("theme_by", NULL, inline = TRUE,
                            c("Across items" = "theme", "By item" = "item")),
        DT::DTOutput("themes", fill = FALSE)
      ),
      bslib::nav_panel(
        "Words",
        bslib::layout_columns(
          col_widths = c(4, 4, 4),
          shiny::checkboxGroupInput("word_lang", "Remove common words in",
                                    c("English" = "en", "Italian" = "it"),
                                    selected = c("en", "it"), inline = TRUE),
          shiny::numericInput("word_top", "Number of words", 25, min = 5, max = 200),
          shiny::textInput("word_stop", "Other words to remove, separated by commas")
        ),
        DT::DTOutput("words", fill = FALSE)
      )
    )
  )
}

report_panel <- function() {
  bslib::layout_columns(
    col_widths = c(6, 6),
    bslib::card(
      bslib::card_header("Round report"),
      shiny::p("A complete report of the round, with the criteria adopted, tables, ",
               "figures, the items for the next round and, when available, the ",
               "comments of the experts."),
      shiny::textInput("rep_title", "Title", "Delphi study: round report"),
      shiny::textInput("rep_author", "Author(s)", ""),
      shiny::radioButtons("rep_format", "Format", inline = TRUE,
                          c("Word" = "docx", "HTML" = "html")),
      shiny::radioButtons("rep_comments", "Comments listed in full", inline = TRUE,
                          c("Items for the next round" = "next_round",
                            "All items" = "all", "None" = "none")),
      shiny::downloadButton("report_download", "Create the report", class = "btn-primary")
    ),
    bslib::card(
      bslib::card_header("Feedback for the experts"),
      shiny::p("The controlled feedback to send to the panel before a further round: ",
               "median, quartiles and consensus of each item, with the comments ",
               "reported anonymously."),
      shiny::textInput("fb_title", "Title", "Delphi study: feedback for the next round"),
      shiny::uiOutput("fb_items_ui"),
      shiny::checkboxInput("fb_comments", "Include the comments of the experts", TRUE),
      shiny::radioButtons("fb_format", "Format", inline = TRUE,
                          c("Word" = "docx", "HTML" = "html")),
      shiny::downloadButton("feedback_download", "Create the feedback", class = "btn-primary")
    )
  )
}

code_panel <- function() {
  bslib::card(
    bslib::card_header("R code that reproduces the analysis"),
    shiny::p("The code repeats the import and the analyses with the criteria chosen ",
             "in the application. Replace the file names with the paths of the files ",
             "on your computer."),
    shiny::verbatimTextOutput("code"),
    shiny::downloadButton("code_download", "Download the R script")
  )
}


# Server ----------------------------------------------------------------------

app_server <- function(initial = NULL) {
  function(input, output, session) {
    rv <- shiny::reactiveValues(
      parts = if (is.null(initial)) list() else
        list(list(obj = initial,
                  code = "part1 <- my_study  # the object passed to run_app()",
                  label = "Object passed to run_app()")),
      comments = list()
    )

    notify_warnings <- function(msgs) {
      for (m in unique(msgs)) shiny::showNotification(m, type = "warning", duration = 8)
    }
    fail <- function(e) {
      shiny::showNotification(conditionMessage(e), type = "error", duration = 10)
      NULL
    }
    need_x <- function() {
      x <- study()
      shiny::validate(shiny::need(!is.null(x), "Import the ratings in the Data tab first."))
      x
    }
    # Run an analysis and show its error message in place of the output
    safely <- function(expr) {
      tryCatch(expr, error = function(e) {
        shiny::validate(shiny::need(FALSE, conditionMessage(e)))
      })
    }

    # Criteria
    crit <- shiny::reactive({
      list(
        threshold = max(0.01, min(1, (if (is.na(input$threshold)) 20 else input$threshold) / 100)),
        relative_to = input$relative_to,
        method = input$method,
        alpha = if (is.na(input$alpha)) 0.05 else input$alpha,
        scheibe = max(0.01, min(1, (if (is.na(input$scheibe)) 15 else input$scheibe) / 100)),
        type = as.integer(input$type)
      )
    })

    output$thresholds <- shiny::renderUI({
      x <- study()
      if (is.null(x)) return(NULL)
      cr <- crit()
      rows <- vapply(names(x$scales), function(i) {
        s <- x$scales[[i]]
        cut <- round(cr$threshold * scale_width(s, cr$relative_to), 2)
        paste0(i, " (", scale_label(s), "): IQR at most ", format(cut))
      }, character(1))
      shiny::div(
        class = "small",
        shiny::strong("Consensus in this study"),
        shiny::tags$ul(class = "ps-3", lapply(rows, shiny::tags$li))
      )
    })

    # Ratings file ----------------------------------------------------------
    file_ext <- shiny::reactive({
      shiny::req(input$file)
      tolower(tools_file_ext(input$file$name))
    })
    is_excel <- shiny::reactive(file_ext() %in% c("xlsx", "xls"))
    sheets <- shiny::reactive({
      shiny::req(input$file, is_excel())
      readxl::excel_sheets(input$file$datapath)
    })
    output$sheet_ui <- shiny::renderUI({
      shiny::req(input$file)
      if (!is_excel()) return(NULL)
      shiny::selectInput("sheet", "Sheet", sheets())
    })

    raw <- shiny::reactive({
      shiny::req(input$file)
      sheet <- if (is_excel()) shiny::req(input$sheet) else 1
      header <- input$layout != "wide2"
      tryCatch(
        read_raw_table(input$file$datapath, file_ext(), sheet = sheet, header = header),
        error = function(e) {
          shiny::validate(shiny::need(FALSE, paste("The file could not be read:", conditionMessage(e))))
        }
      )
    })

    output$preview <- DT::renderDT({
      if (identical(input$source, "example")) {
        df <- example_data("delphi_example")
      } else {
        df <- raw()
      }
      DT::datatable(preview_table(df), rownames = FALSE,
                    options = list(pageLength = 8, scrollX = TRUE, dom = "tip"))
    })

    id_choices <- shiny::reactive({
      if (input$layout == "wide2") two_header_id_cols(raw()) else names(raw())
    })

    output$mapping_ui <- shiny::renderUI({
      shiny::req(input$file)
      cols <- id_choices()
      none <- c("(none)" = "")
      guess <- function(pattern) {
        hit <- grep(pattern, cols, ignore.case = TRUE, value = TRUE)
        if (length(hit) > 0L) hit[1L] else ""
      }
      expert_default <- guess("expert|^id$|respon|code|codice")
      ui <- list()
      if (input$layout == "long") {
        ui <- c(ui, list(
          shiny::selectInput("expert_col", "Expert identifier", cols,
                             selected = if (nzchar(expert_default)) expert_default else cols[1L]),
          shiny::selectInput("item_col", "Item", cols, selected = guess("^item")),
          shiny::selectInput("value_col", "Rating", cols, selected = guess("value|rating|score|voto"))
        ))
      } else {
        lab <- if (input$layout == "wide") {
          "Expert identifier (none: experts are numbered by row)"
        } else {
          "Expert identifier"
        }
        ui <- c(ui, list(shiny::selectInput("expert_col", lab, c(none, cols), selected = expert_default)))
      }
      ui <- c(ui, list(
        bslib::layout_columns(
          col_widths = c(7, 5),
          shiny::selectInput("round_col", "Round column", c(none, cols), selected = guess("^round$|^round")),
          shiny::numericInput("round", "or round number", 1, min = 1, step = 1)
        )
      ))
      if (input$layout == "wide2") {
        inds <- two_header_indicators(raw())
        ui <- c(ui, list(
          shiny::tags$label("Indicators found in the first header row, renamed as"),
          lapply(seq_along(inds), function(k) {
            shiny::textInput(paste0("ind_name_", k), inds[k], value = tolower(inds[k]))
          })
        ))
      } else {
        ui <- c(ui, list(
          bslib::layout_columns(
            col_widths = c(7, 5),
            shiny::selectInput("indicator_col", "Indicator column", c(none, cols),
                               selected = guess("indicator|indicatore")),
            shiny::textInput("indicator", "or indicator name", "score")
          )
        ))
      }
      if (input$layout == "wide") {
        ui <- c(ui, list(shiny::uiOutput("items_ui")))
      }
      ui <- c(ui, list(
        shiny::uiOutput("scales_ui"),
        shiny::checkboxInput(
          "linked", "The same identifier denotes the same expert in every round", TRUE
        )
      ))
      if (is_excel() && input$layout != "wide2") {
        ui <- c(ui, list(
          shiny::selectInput("items_sheet", "Sheet with the item statements (optional)",
                             c(none, setdiff(sheets(), input$sheet)),
                             selected = if ("items" %in% sheets()) "items" else "")
        ))
      }
      shiny::tagList(ui)
    })

    output$items_ui <- shiny::renderUI({
      cols <- names(raw())
      used <- c(input$expert_col, input$round_col, input$indicator_col)
      cand <- setdiff(cols, used[nzchar(used)])
      shiny::selectizeInput("items", "Item columns", choices = cand, selected = cand,
                            multiple = TRUE, options = list(plugins = list("remove_button")))
    })

    # Indicators found in the file, with the range of their ratings, so that
    # a rating scale can be chosen for each of them
    indicator_groups <- shiny::reactive({
      df <- raw()
      lay <- input$layout
      if (lay == "wide2") {
        clean <- function(v) {
          v <- trimws(gsub("[[:space:]]+", " ", as.character(v)))
          v[is.na(v)] <- ""
          v
        }
        first <- clean(unlist(df[1L, ], use.names = FALSE))
        inds <- two_header_indicators(df)
        body <- df[-(1:2), , drop = FALSE]
        return(lapply(inds, function(k) {
          list(label = k, range = observed_range(body[, first == k, drop = FALSE]))
        }))
      }
      value_cols <- if (lay == "long") {
        shiny::req(input$value_col)
      } else {
        used <- c(input$expert_col, input$round_col, input$indicator_col)
        cand <- setdiff(names(df), used[nzchar(used)])
        if (length(input$items) > 0L) intersect(input$items, cand) else cand
      }
      value_cols <- intersect(value_cols, names(df))
      ind_col <- input$indicator_col
      if (!is.null(ind_col) && nzchar(ind_col) && ind_col %in% names(df)) {
        lev <- trimws(as.character(df[[ind_col]]))
        inds <- unique(lev[!is.na(lev) & nzchar(lev)])
        return(lapply(inds, function(k) {
          list(label = k, range = observed_range(df[lev %in% k, value_cols, drop = FALSE]))
        }))
      }
      list(list(label = NA_character_, range = observed_range(df[, value_cols, drop = FALSE])))
    })

    output$scales_ui <- shiny::renderUI({
      groups <- indicator_groups()
      choices <- c(names(scale_presets), "Other" = "other")
      shiny::tagList(lapply(seq_along(groups), function(k) {
        g <- groups[[k]]
        r <- g$range
        lab <- if (is.na(g$label)) "Rating scale" else paste0("Rating scale: ", g$label)
        hint <- if (is.null(r)) NULL else {
          paste0("Choose the scale of the questionnaire. The ratings in the file range from ",
                 format(r[1L]), " to ", format(r[2L]), ".")
        }
        guess <- guess_scale(r)
        shiny::div(
          class = "mb-3",
          shiny::selectInput(paste0("scale_preset_", k), lab, choices, selected = guess),
          shiny::conditionalPanel(
            sprintf("input.scale_preset_%d == 'other'", k),
            bslib::layout_columns(
              col_widths = c(6, 6),
              shiny::numericInput(paste0("scale_min_", k), "Lowest rating",
                                  if (is.null(r)) 1 else floor(r[1L])),
              shiny::numericInput(paste0("scale_max_", k), "Highest rating",
                                  if (is.null(r)) 10 else ceiling(r[2L]))
            )
          ),
          if (!is.null(hint)) shiny::helpText(hint)
        )
      }))
    })

    # Chosen scales, named by the indicator names used in the data
    chosen_scales <- shiny::reactive({
      groups <- indicator_groups()
      sc <- lapply(seq_along(groups), function(k) {
        preset <- input[[paste0("scale_preset_", k)]]
        if (is.null(preset)) {
          return(scale_presets[[guess_scale(groups[[k]]$range)]] %||% c(1, 10))
        }
        if (preset == "other") {
          c(input[[paste0("scale_min_", k)]], input[[paste0("scale_max_", k)]])
        } else {
          scale_presets[[preset]]
        }
      })
      if (length(sc) == 1L) {
        return(sc[[1L]])
      }
      nms <- vapply(groups, `[[`, character(1), "label")
      if (input$layout == "wide2") {
        nms <- vapply(seq_along(nms), function(k) {
          v <- input[[paste0("ind_name_", k)]]
          if (is.null(v) || !nzchar(trimws(v))) nms[k] else trimws(v)
        }, character(1))
      }
      stats::setNames(sc, nms)
    })

    import_spec <- shiny::reactive({
      inds <- if (input$layout == "wide2") two_header_indicators(raw()) else character(0)
      ren <- if (length(inds) > 0L) {
        stats::setNames(vapply(seq_along(inds), function(k) {
          v <- input[[paste0("ind_name_", k)]]
          if (is.null(v)) inds[k] else trimws(v)
        }, character(1)), inds)
      } else {
        NULL
      }
      all_items <- if (input$layout == "wide") {
        used <- c(input$expert_col, input$round_col, input$indicator_col)
        setdiff(names(raw()), used[nzchar(used)])
      } else {
        NULL
      }
      list(
        layout = input$layout, sheet = input$sheet, expert_col = input$expert_col,
        round_col = input$round_col, round = input$round,
        indicator_col = input$indicator_col, indicator = trimws(input$indicator %||% ""),
        items = input$items, all_items = all_items,
        item_col = input$item_col, value_col = input$value_col,
        scale = chosen_scales(), linked = input$linked,
        items_sheet = input$items_sheet, indicator_names = ren
      )
    })

    shiny::observeEvent(input$add_part, {
      n <- length(rv$parts) + 1L
      name <- paste0("part", n)
      if (identical(input$source, "example")) {
        res <- tryCatch(with_warnings(delphi_data(
          example_data("delphi_example"), expert_col = "expert", round_col = "round",
          indicator_col = "indicator",
          scale = list(impact = c(1, 10), plausibility = c(1, 100))
        )), error = fail)
        if (is.null(res)) return()
        code <- code_call("delphi_data", list(
          code_symbol("delphi_example"), expert_col = "expert", round_col = "round",
          indicator_col = "indicator",
          scale = code_symbol("list(impact = c(1, 10), plausibility = c(1, 100))")
        ), assign = name)
        rv$parts[[n]] <- list(obj = res$value, code = code, label = "Example data")
        rv$comments[[length(rv$comments) + 1L]] <- list(
          data = example_data("delphi_example_comments"), args = list(),
          code = code_call("delphi_add_comments", list(code_symbol("x"), code_symbol("delphi_example_comments")),
                           assign = "x"),
          label = "Example comments"
        )
        return()
      }
      shiny::req(input$file)
      spec <- import_spec()
      bad <- vapply(as.list(if (is.list(spec$scale)) spec$scale else list(spec$scale)),
                    function(v) length(v) != 2L || anyNA(v) || v[1L] >= v[2L], logical(1))
      if (any(bad)) {
        shiny::showNotification(
          "Give the lowest and the highest rating of each scale, with the lowest first.",
          type = "error"
        )
        return()
      }
      args <- tryCatch(import_args(spec, excel = is_excel()), error = fail)
      if (is.null(args)) return()
      res <- tryCatch(
        with_warnings(do.call(read_delphi, c(list(input$file$datapath), args))),
        error = fail
      )
      if (is.null(res)) return()
      notify_warnings(res$warnings)
      code <- code_call("read_delphi", c(list(input$file$name), args), assign = name)
      rounds <- paste(sort(unique(res$value$data$round)), collapse = ", ")
      label <- paste0(input$file$name, if (is_excel()) paste0(", sheet ", input$sheet) else "",
                      " (round ", rounds, ")")
      rv$parts[[n]] <- list(obj = res$value, code = code, label = label)
      shiny::showNotification(paste("Added:", label), type = "message")
    })

    shiny::observeEvent(input$clear, {
      rv$parts <- list()
      rv$comments <- list()
    })

    # The study: all parts combined, with the comments added
    study <- shiny::reactive({
      if (length(rv$parts) == 0L) return(NULL)
      x <- tryCatch(
        if (length(rv$parts) == 1L) rv$parts[[1L]]$obj else delphi_bind(lapply(rv$parts, `[[`, "obj")),
        error = function(e) {
          shiny::showNotification(conditionMessage(e), type = "error", duration = 10)
          NULL
        }
      )
      if (is.null(x)) return(NULL)
      for (cm in rv$comments) {
        x <- tryCatch(
          suppressWarnings(do.call(delphi_add_comments, c(list(x, cm$data), cm$args))),
          error = function(e) x
        )
      }
      x
    })

    output$parts_ui <- shiny::renderUI({
      if (length(rv$parts) == 0L) {
        return(shiny::p("No ratings imported yet. Choose the file and the columns, then ",
                        "select 'Add to the study'. Rounds stored in separate sheets or ",
                        "files can be added one at a time."))
      }
      items <- c(vapply(rv$parts, `[[`, character(1), "label"),
                 vapply(rv$comments, `[[`, character(1), "label"))
      shiny::tags$ul(lapply(items, shiny::tags$li))
    })
    output$study_print <- shiny::renderPrint({
      x <- study()
      if (!is.null(x)) print(x)
    })

    # Comments file ---------------------------------------------------------
    cfile <- shiny::reactive({
      if (!is.null(input$cfile)) {
        list(path = input$cfile$datapath, name = input$cfile$name)
      } else if (!is.null(input$file)) {
        list(path = input$file$datapath, name = input$file$name)
      } else {
        NULL
      }
    })
    cext <- shiny::reactive({
      shiny::req(cfile())
      tolower(tools_file_ext(cfile()$name))
    })
    output$csheet_ui <- shiny::renderUI({
      shiny::req(cfile())
      if (!cext() %in% c("xlsx", "xls")) return(NULL)
      sh <- readxl::excel_sheets(cfile()$path)
      shiny::selectInput("csheet", "Sheet", sh,
                         selected = if ("comments" %in% sh) "comments" else sh[1L])
    })
    craw <- shiny::reactive({
      shiny::req(cfile())
      sheet <- if (cext() %in% c("xlsx", "xls")) shiny::req(input$csheet) else 1
      tryCatch(
        read_raw_table(cfile()$path, cext(), sheet = sheet, header = TRUE),
        error = function(e) shiny::validate(shiny::need(FALSE, conditionMessage(e)))
      )
    })
    output$cpreview <- DT::renderDT({
      DT::datatable(preview_table(craw(), width = 120), rownames = FALSE,
                    options = list(pageLength = 6, scrollX = TRUE, dom = "tip"))
    })
    output$cmapping_ui <- shiny::renderUI({
      cols <- names(craw())
      none <- c("(none)" = "")
      pick <- function(name, alt = "") if (name %in% cols) name else alt
      if (input$clayout == "long") {
        shiny::tagList(
          shiny::selectInput("c_expert", "Expert identifier", cols, selected = pick("expert", cols[1L])),
          shiny::selectInput("c_item", "Item (empty cells: general comments)", cols, selected = pick("item")),
          shiny::selectInput("c_comment", "Comment", cols, selected = pick("comment")),
          bslib::layout_columns(
            col_widths = c(7, 5),
            shiny::selectInput("c_round_col", "Round column", c(none, cols), selected = pick("round")),
            shiny::numericInput("c_round", "or round number", 1, min = 1)
          ),
          shiny::selectInput("c_theme", "Themes (optional)", c(none, cols), selected = pick("theme")),
          shiny::selectInput("c_indicator", "Indicator (optional)", c(none, cols), selected = pick("indicator"))
        )
      } else {
        x <- study()
        n_items <- if (is.null(x)) NA else length(x$items)
        sets <- lapply(c("^commenti", "^comment", "comment|commenti|note"), grep, x = cols,
                       ignore.case = TRUE, value = TRUE)
        fit <- vapply(sets, length, integer(1)) == n_items
        guess <- if (any(fit %in% TRUE)) sets[[which(fit)[1L]]] else {
          sets <- sets[lengths(sets) > 0L]
          if (length(sets) > 0L) sets[[1L]] else character(0)
        }
        id_guess <- grep("expert|^id$|respon|code|codice", cols, ignore.case = TRUE, value = TRUE)
        last_round <- if (is.null(x)) 1 else max(x$data$round)
        shiny::tagList(
          shiny::selectInput("c_expert", "Expert identifier", cols,
                             selected = if (length(id_guess)) id_guess[1L] else cols[1L]),
          shiny::selectizeInput("c_cols", "Comment columns, one per item and in the order of the items",
                                cols, selected = guess, multiple = TRUE,
                                options = list(plugins = list("remove_button"))),
          shiny::helpText(if (is.null(x)) "Import the ratings first." else
            paste0("The study has ", length(x$items), " items (", x$items[1L], " to ",
                   x$items[length(x$items)], ").")),
          shiny::numericInput("c_round", "Round", last_round, min = 1)
        )
      }
    })

    shiny::observeEvent(input$add_comments, {
      x <- study()
      if (is.null(x)) {
        shiny::showNotification("Import the ratings before the comments.", type = "error")
        return()
      }
      df <- craw()
      if (input$clayout == "long") {
        args <- list(expert_col = input$c_expert, item_col = input$c_item,
                     comment_col = input$c_comment)
        if (nzchar(input$c_round_col)) {
          args$round_col <- input$c_round_col
        } else {
          args$round <- as.integer(input$c_round)
        }
        if (nzchar(input$c_theme)) args$theme_col <- input$c_theme
        if (nzchar(input$c_indicator)) args$indicator_col <- input$c_indicator
        # Columns named as the defaults are found automatically: keep the
        # explicit names anyway, so that the code is self-explanatory
      } else {
        if (length(input$c_cols) == 0L) {
          shiny::showNotification("Choose the comment columns.", type = "error")
          return()
        }
        args <- list(layout = "wide", expert_col = input$c_expert,
                     comment_cols = input$c_cols, round = as.integer(input$c_round))
      }
      res <- tryCatch(with_warnings(do.call(delphi_add_comments, c(list(x, df), args))),
                      error = fail)
      if (is.null(res)) return()
      notify_warnings(res$warnings)
      sheet <- if (cext() %in% c("xlsx", "xls")) input$csheet else NULL
      code_args <- args
      if (!is.null(code_args$comment_cols)) {
        code_args$comment_cols <- code_columns(code_args$comment_cols, names(df))
      }
      code <- paste(
        comments_read_code(cfile()$name, cext(), sheet),
        code_call("delphi_add_comments", c(list(code_symbol("x"), code_symbol("comments")), code_args),
                  assign = "x"),
        sep = "\n"
      )
      n_new <- nrow(obj_comments(res$value)) - nrow(obj_comments(x))
      label <- paste0("Comments from ", cfile()$name,
                      if (!is.null(sheet)) paste0(", sheet ", sheet) else "",
                      " (", n_new, ")")
      rv$comments[[length(rv$comments) + 1L]] <- list(data = df, args = args, code = code,
                                                     label = label)
      shiny::showNotification(paste("Added:", label), type = "message")
    })

    # Overview ----------------------------------------------------------------
    output$overview <- shiny::renderUI({
      x <- need_x()
      d <- x$data
      per_round <- tapply(d$expert[!is.na(d$value)], d$round[!is.na(d$value)],
                          function(e) length(unique(e)))
      cm <- obj_comments(x)
      boxes <- bslib::layout_column_wrap(
        width = 1 / 5,
        bslib::value_box("Experts", paste(per_round, collapse = " / "),
                         paste("by round", paste(names(per_round), collapse = " / "))),
        bslib::value_box("Rounds", length(per_round)),
        bslib::value_box("Items", length(x$items)),
        bslib::value_box("Indicators", length(x$scales), paste(names(x$scales), collapse = ", ")),
        bslib::value_box("Comments", nrow(cm))
      )
      lab <- obj_labels(x)
      shiny::tagList(
        boxes,
        bslib::card(
          bslib::card_header("Summary"),
          shiny::verbatimTextOutput("summary_print")
        ),
        if (any(!is.na(lab))) bslib::card(
          bslib::card_header("Items"),
          shiny::tableOutput("labels_table")
        )
      )
    })
    output$summary_print <- shiny::renderPrint({
      x <- need_x()
      cr <- crit()
      print(summary(x, type = cr$type, threshold = cr$threshold, relative_to = cr$relative_to))
    })
    output$labels_table <- shiny::renderTable({
      x <- need_x()
      lab <- obj_labels(x)
      data.frame(Item = x$items, Statement = ifelse(is.na(lab), "", lab))
    })

    # Descriptives --------------------------------------------------------------
    output$desc_round_ui <- shiny::renderUI({
      x <- need_x()
      r <- sort(unique(x$data$round))
      shiny::selectInput("desc_round", "Rounds", r, selected = r, multiple = TRUE)
    })
    output$desc_indicator_ui <- shiny::renderUI({
      x <- need_x()
      shiny::selectInput("desc_indicator", "Indicators", names(x$scales),
                         selected = names(x$scales), multiple = TRUE)
    })
    describe_tab <- shiny::reactive({
      x <- need_x()
      cr <- crit()
      safely(as.data.frame(unclass(delphi_describe(
        x, round = as.integer(shiny::req(input$desc_round)),
        indicator = shiny::req(input$desc_indicator),
        type = cr$type, relative_to = cr$relative_to
      ))))
    })
    output$describe <- DT::renderDT(dt_table(describe_tab()))
    output$desc_download <- csv_download("delphi_descriptives.csv", describe_tab)

    # Consensus and stability -------------------------------------------------------
    status_tab <- shiny::reactive({
      x <- need_x()
      cr <- crit()
      safely(delphi_status(x, threshold = cr$threshold, relative_to = cr$relative_to,
                           method = cr$method, alpha = cr$alpha, scheibe = cr$scheibe,
                           type = cr$type))
    })
    output$next_round_txt <- shiny::renderUI({
      st <- status_tab()
      nr <- unique(st$item[st$next_round])
      txt <- if (length(nr) == 0L) {
        "No item requires a further round under the criteria adopted."
      } else {
        paste0("Items for the next round: ", paste(nr, collapse = ", "), ".")
      }
      shiny::p(shiny::strong(txt))
    })
    output$status <- DT::renderDT(dt_table(as.data.frame(unclass(status_tab()))))
    output$status_download <- csv_download("delphi_status.csv", shiny::reactive(as.data.frame(unclass(status_tab()))))

    consensus_tab <- shiny::reactive({
      x <- need_x()
      cr <- crit()
      safely(as.data.frame(unclass(delphi_consensus(
        x, threshold = cr$threshold, relative_to = cr$relative_to, type = cr$type
      ))))
    })
    output$consensus <- DT::renderDT(dt_table(consensus_tab()))
    output$consensus_download <- csv_download("delphi_consensus.csv", consensus_tab)

    stability_tab <- shiny::reactive({
      x <- need_x()
      shiny::validate(shiny::need(length(unique(x$data$round)) > 1L,
                                  "Stability requires at least two rounds."))
      cr <- crit()
      safely(as.data.frame(unclass(delphi_stability(
        x, method = cr$method, alpha = cr$alpha, scheibe = cr$scheibe, type = cr$type
      ))))
    })
    output$stability_note <- shiny::renderUI({
      x <- need_x()
      shiny::p(if (obj_linked(x)) {
        "Experts are linked across rounds: rounds are compared on the experts who answered both."
      } else {
        "Experts are not linked across rounds: rounds are compared as independent samples."
      })
    })
    output$stability <- DT::renderDT(dt_table(stability_tab()))
    output$stability_download <- csv_download("delphi_stability.csv", stability_tab)
    output$panel <- DT::renderDT({
      x <- need_x()
      dt_table(as.data.frame(delphi_panel(x)))
    })

    # Figures ---------------------------------------------------------------------
    output$fig_options <- shiny::renderUI({
      x <- need_x()
      inds <- names(x$scales)
      rounds <- sort(unique(x$data$round))
      all_r <- c("All rounds" = "")
      type <- input$fig_type
      ui <- list()
      if (type %in% c("distribution", "trend")) {
        ui <- c(ui, list(shiny::selectInput("fig_ind", "Indicator", inds)))
      }
      if (type == "consensus") {
        ui <- c(ui, list(shiny::selectInput("fig_inds", "Indicators", inds, selected = inds,
                                            multiple = TRUE)))
      }
      if (type == "map") {
        ui <- c(ui, list(
          shiny::selectInput("fig_x", "Horizontal axis", inds, selected = inds[1L]),
          shiny::selectInput("fig_y", "Vertical axis", inds, selected = inds[min(2L, length(inds))])
        ))
      }
      if (type == "comments") {
        ui <- c(ui, list(shiny::selectInput("fig_cind", "Position of the authors on",
                                            c("At least one indicator" = "", inds))))
      }
      if (type %in% c("distribution", "consensus", "comments")) {
        ui <- c(ui, list(shiny::selectInput("fig_round", "Round", c(all_r, rounds))))
      }
      if (type == "map") {
        ui <- c(ui, list(shiny::selectInput("fig_round", "Round", c("Last round" = "", rounds))))
      }
      if (type != "comments") {
        ui <- c(ui, list(shiny::selectizeInput("fig_items", "Items (all if empty)",
                                               item_choices(x), multiple = TRUE)))
      }
      shiny::tagList(ui)
    })
    figure <- shiny::reactive({
      x <- need_x()
      cr <- crit()
      type <- input$fig_type
      rnd <- if (is.null(input$fig_round) || !nzchar(input$fig_round)) NULL else as.integer(input$fig_round)
      items <- if (length(input$fig_items) == 0L) NULL else input$fig_items
      safely(switch(type,
        distribution = delphi_plot_distribution(x, indicator = shiny::req(input$fig_ind),
                                                round = rnd, items = items),
        trend = delphi_plot_trend(x, indicator = shiny::req(input$fig_ind), items = items,
                                  threshold = cr$threshold, relative_to = cr$relative_to,
                                  type = cr$type),
        consensus = delphi_plot_consensus(x, indicator = shiny::req(input$fig_inds), round = rnd,
                                          items = items, threshold = cr$threshold,
                                          relative_to = cr$relative_to, type = cr$type),
        map = delphi_plot_map(x, x_indicator = shiny::req(input$fig_x),
                              y_indicator = shiny::req(input$fig_y), round = rnd, items = items,
                              threshold = cr$threshold, relative_to = cr$relative_to,
                              type = cr$type),
        comments = {
          shiny::validate(shiny::need(has_comments(x), "The study has no comments."))
          ind <- if (is.null(input$fig_cind) || !nzchar(input$fig_cind)) NULL else input$fig_cind
          delphi_plot_comments(x, round = rnd, indicator = ind, type = cr$type)
        }
      ))
    })
    output$figure_ui <- shiny::renderUI({
      shiny::plotOutput("figure", height = paste0(input$fig_height, "px"))
    })
    output$figure <- shiny::renderPlot(print(figure()), res = 96)
    save_fig <- function(device) {
      shiny::downloadHandler(
        filename = function() paste0("delphi_", input$fig_type, ".", device),
        content = function(file) {
          ggplot2::ggsave(file, figure(), width = input$fig_width_cm, height = input$fig_height_cm,
                          units = "cm", dpi = 300, device = device)
        }
      )
    }
    output$fig_png <- save_fig("png")
    output$fig_pdf <- save_fig("pdf")

    # Comments ---------------------------------------------------------------------
    output$comments_none <- shiny::renderUI({
      x <- study()
      if (is.null(x) || !has_comments(x)) {
        shiny::div(class = "alert alert-info",
                   "The study has no comments. Add them in the Data tab.")
      }
    })
    need_comments <- function() {
      x <- need_x()
      shiny::validate(shiny::need(has_comments(x), "The study has no comments."))
      x
    }
    output$com_round_ui <- shiny::renderUI({
      x <- need_comments()
      r <- sort(unique(obj_comments(x)$round))
      shiny::selectInput("com_round", "Round", c("All rounds" = "", r))
    })
    output$com_items_ui <- shiny::renderUI({
      x <- need_comments()
      shiny::selectizeInput("com_items", "Items (all if empty)", item_choices(x), multiple = TRUE)
    })
    comments_tab <- shiny::reactive({
      x <- need_comments()
      rnd <- if (is.null(input$com_round) || !nzchar(input$com_round)) NULL else as.integer(input$com_round)
      items <- if (length(input$com_items) == 0L) NULL else input$com_items
      safely(as.data.frame(unclass(delphi_comments(x, round = rnd, items = items,
                                                   general = is.null(items),
                                                   type = crit()$type))))
    })
    output$comments_table <- DT::renderDT({
      df <- comments_tab()
      df <- df[, !grepl("_rating$", names(df)), drop = FALSE]
      dt_table(df, page = 10)
    })
    output$comments_download <- csv_download("delphi_comments.csv", comments_tab)
    output$comment_counts <- DT::renderDT({
      x <- need_comments()
      dt_table(as.data.frame(unclass(safely(delphi_comment_counts(x, type = crit()$type)))))
    })
    output$comments_plot <- shiny::renderPlot({
      x <- need_comments()
      print(safely(delphi_plot_comments(x, type = crit()$type)))
    }, res = 96)
    output$themes <- DT::renderDT({
      x <- need_comments()
      dt_table(safely(delphi_themes(x, by = input$theme_by, type = crit()$type)))
    })
    output$words <- DT::renderDT({
      x <- need_comments()
      extra <- trimws(strsplit(input$word_stop %||% "", ",", fixed = TRUE)[[1L]])
      extra <- extra[nzchar(extra)]
      lang <- if (length(input$word_lang) == 0L) NULL else input$word_lang
      top <- if (is.na(input$word_top)) 25 else input$word_top
      dt_table(safely(delphi_words(x, language = lang,
                                   stopwords = if (length(extra)) extra else NULL,
                                   top = top)))
    })

    # Report and feedback ----------------------------------------------------------------
    output$fb_items_ui <- shiny::renderUI({
      x <- need_x()
      st <- status_tab()
      nr <- x$items[x$items %in% st$item[st$next_round]]
      shiny::selectizeInput("fb_items", "Items (by default, those for the next round)",
                            item_choices(x), selected = nr, multiple = TRUE)
    })
    output$report_download <- shiny::downloadHandler(
      filename = function() paste0("delphi_report.", input$rep_format),
      content = function(file) {
        x <- study()
        cr <- crit()
        tmp <- tempfile(fileext = paste0(".", input$rep_format))
        author <- if (nzchar(trimws(input$rep_author))) input$rep_author else NULL
        out <- tryCatch(
          shiny::withProgress(message = "Creating the report", value = 0.5, {
            delphi_report(x, tmp, title = input$rep_title, author = author,
                          threshold = cr$threshold, relative_to = cr$relative_to,
                          method = cr$method, alpha = cr$alpha, scheibe = cr$scheibe,
                          type = cr$type, comments = input$rep_comments, open = FALSE)
          }),
          error = function(e) {
            shiny::showNotification(conditionMessage(e), type = "error", duration = 10)
            NULL
          }
        )
        if (!is.null(out)) file.copy(out, file)
      }
    )
    output$feedback_download <- shiny::downloadHandler(
      filename = function() paste0("delphi_feedback.", input$fb_format),
      content = function(file) {
        x <- study()
        cr <- crit()
        tmp <- tempfile(fileext = paste0(".", input$fb_format))
        items <- if (length(input$fb_items) == 0L) NULL else input$fb_items
        ok <- tryCatch({
          shiny::withProgress(message = "Creating the feedback", value = 0.5, {
            delphi_feedback(x, tmp, items = items, comments = input$fb_comments,
                            title = input$fb_title, threshold = cr$threshold,
                            relative_to = cr$relative_to, method = cr$method,
                            alpha = cr$alpha, scheibe = cr$scheibe, type = cr$type,
                            open = FALSE)
          })
          TRUE
        }, error = function(e) {
          shiny::showNotification(conditionMessage(e), type = "error", duration = 10)
          FALSE
        })
        if (ok) file.copy(tmp, file)
      }
    )

    # R code ----------------------------------------------------------------------------
    code_txt <- shiny::reactive({
      if (length(rv$parts) == 0L) {
        return("# Import the ratings in the Data tab: the code will appear here.")
      }
      cr <- crit()
      parts <- vapply(rv$parts, `[[`, character(1), "code")
      bind <- if (length(parts) == 1L) {
        "x <- part1"
      } else {
        code_call("delphi_bind", lapply(paste0("part", seq_along(parts)), code_symbol), assign = "x")
      }
      com <- vapply(rv$comments, `[[`, character(1), "code")
      rule <- list(threshold = cr$threshold, relative_to = cr$relative_to,
                   method = cr$method, alpha = cr$alpha, scheibe = cr$scheibe, type = cr$type)
      defaults <- list(threshold = 0.2, relative_to = "points", method = "wilcoxon",
                       alpha = 0.05, scheibe = 0.15, type = 7L)
      keep <- !mapply(function(a, b) isTRUE(all.equal(a, b)), rule, defaults[names(rule)])
      rule <- rule[keep]
      cons_rule <- rule[intersect(names(rule), c("threshold", "relative_to", "type"))]
      x <- study()
      c(
        "library(DelphiR)",
        "",
        "# Ratings",
        parts,
        bind,
        if (length(com) > 0L) c("", "# Comments", com),
        "x",
        "",
        "# Descriptive statistics, consensus, stability and item status",
        code_call("summary", c(list(code_symbol("x")), cons_rule)),
        code_call("delphi_describe", c(list(code_symbol("x")),
                                       rule[intersect(names(rule), c("type", "relative_to"))])),
        code_call("delphi_consensus", c(list(code_symbol("x")), cons_rule)),
        if (!is.null(x) && length(unique(x$data$round)) > 1L) {
          code_call("delphi_stability", c(list(code_symbol("x")),
                                          rule[intersect(names(rule), c("method", "alpha", "scheibe", "type"))]))
        },
        code_call("delphi_status", c(list(code_symbol("x")), rule), assign = "st"),
        "st",
        "subset(st, next_round)",
        "",
        "# Figures",
        "plot(x, type = \"distribution\")",
        if (!is.null(x) && length(unique(x$data$round)) > 1L) "plot(x, type = \"trend\")",
        "plot(x, type = \"consensus\")",
        if (!is.null(x) && length(x$scales) > 1L) "plot(x, type = \"map\")",
        if (!is.null(x) && has_comments(x)) c(
          "",
          "# Comments",
          "delphi_comments(x)",
          "delphi_comment_counts(x)",
          if (any(!is.na(obj_comments(x)$theme))) "delphi_themes(x, by = \"theme\")",
          "delphi_words(x)",
          "plot(x, type = \"comments\")"
        ),
        "",
        "# Report and feedback",
        code_call("delphi_report", c(list(code_symbol("x"), "delphi_report.docx"), rule)),
        code_call("delphi_feedback", c(list(code_symbol("x"), "delphi_feedback.docx"), rule))
      )
    })
    output$code <- shiny::renderText(paste(code_txt(), collapse = "\n"))
    output$code_download <- shiny::downloadHandler(
      filename = function() "delphi_analysis.R",
      content = function(file) writeLines(code_txt(), file)
    )
  }
}

# Interactive table with rounded numbers
dt_table <- function(df, page = 15) {
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], function(v) round(v, 3))
  DT::datatable(df, rownames = FALSE,
                options = list(pageLength = page, scrollX = TRUE, dom = "ftip"))
}

csv_download <- function(name, data) {
  shiny::downloadHandler(
    filename = function() name,
    content = function(file) utils::write.csv(data(), file, row.names = FALSE, na = "")
  )
}

`%||%` <- function(a, b) if (is.null(a)) b else a
