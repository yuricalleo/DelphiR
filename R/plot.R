# Colours
#
# All text drawn in figures is plain ASCII, so that figures render
# correctly on every graphics device, including pdf() with its default
# Type 1 fonts.
#
# Rounds use a fixed categorical order (blue, orange, aqua, ...), validated
# for colour-vision deficiency on the first three slots. Rounds are also
# named on the axis or in the legend, so colour is never the only cue.
# Dispersion relative to the consensus threshold uses a diverging blue-red
# scale with a neutral grey midpoint at the threshold.

delphi_colours <- list(
  rounds = c("#2a78d6", "#eb6834", "#1baf7a", "#eda100",
             "#e87ba4", "#008300", "#6250d6", "#e34948"),
  primary = "#2a78d6",
  low = "#2a78d6",
  mid = "#f0efec",
  high = "#e34948",
  ink = "#0b0b0b",
  ink_secondary = "#52514e",
  grid = "#e4e3df"
)

round_palette <- function(n) {
  pal <- delphi_colours$rounds
  if (n > length(pal)) {
    pal <- rep_len(pal, n)
  }
  pal[seq_len(n)]
}


#' ggplot2 theme for DelphiR figures
#'
#' @description
#' A restrained theme for publication figures: white background, light
#' horizontal grid, no panel border, and dark grey text. All plotting
#' functions in DelphiR use it; it can also be added to any ggplot.
#'
#' @param base_size Base font size, in points.
#' @param base_family Base font family.
#' @return A [ggplot2::theme()] object.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_delphi()
#' @export
theme_delphi <- function(base_size = 11, base_family = "") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = delphi_colours$ink),
      plot.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.1)),
      plot.subtitle = ggplot2::element_text(colour = delphi_colours$ink_secondary),
      plot.caption = ggplot2::element_text(colour = delphi_colours$ink_secondary, hjust = 0),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      axis.text = ggplot2::element_text(colour = delphi_colours$ink_secondary),
      axis.title = ggplot2::element_text(colour = delphi_colours$ink_secondary),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = delphi_colours$grid, linewidth = 0.3),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0),
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_text(colour = delphi_colours$ink_secondary)
    )
}


# Helpers
# Choose one indicator for plots that need a single rating scale.
pick_indicator <- function(x, indicator) {
  inds <- names(x$scales)
  if (is.null(indicator)) {
    if (length(inds) > 1L) {
      message(
        "Showing indicator '", inds[1L], "'. Use `indicator` to select another (",
        paste(inds, collapse = ", "), ")."
      )
    }
    return(inds[1L])
  }
  if (!is_string(indicator) || !indicator %in% inds) {
    stop_dr("`indicator` must be one of ", show_values(inds), ".")
  }
  indicator
}

round_labels <- function(r) {
  paste("Round", r)
}

scale_subtitle <- function(indicator, s) {
  paste0("Indicator: ", indicator, " (rating scale from ", s[1L], " to ", s[2L], ")")
}

# Order items as in the data, first item at the top of a vertical axis.
item_factor <- function(item, items, reverse = FALSE) {
  lev <- items[items %in% item]
  if (reverse) lev <- rev(lev)
  factor(item, levels = lev)
}


#' Distribution of the ratings by round
#'
#' @description
#' Shows, for each item, the distribution of the expert ratings in every
#' round: a box plot (median, quartiles and whiskers) with the individual
#' ratings overlaid. This is the most direct view of how the panel converges
#' or remains divided across rounds.
#'
#' @param x A `delphi_data` object.
#' @param indicator Indicator to plot. If `NULL`, the first indicator is used.
#' @param round,items Optional subsets of rounds and items.
#' @param ncol Number of columns of the panel grid.
#' @param points Whether to overlay the individual ratings. Ratings are
#'   spread horizontally only, so their values are not altered.
#'
#' @return A ggplot object, which can be further modified with ggplot2.
#' @seealso [delphi_plot_trend()], [delphi_plot_consensus()],
#'   [delphi_plot_map()], [plot.delphi_data()].
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_plot_distribution(x, indicator = "impact")
#' @export
delphi_plot_distribution <- function(x, indicator = NULL, round = NULL, items = NULL,
                                     ncol = NULL, points = TRUE) {
  assert_delphi_data(x)
  ind <- pick_indicator(x, indicator)
  long <- subset_long(x, round = round, indicator = ind, items = items)
  long <- long[!is.na(long$value), , drop = FALSE]
  s <- x$scales[[ind]]
  rounds <- sort(unique(long$round))
  long$round_f <- factor(round_labels(long$round), levels = round_labels(rounds))
  long$item <- item_factor(long$item, x$items)
  pal <- stats::setNames(round_palette(length(rounds)), round_labels(rounds))

  p <- ggplot2::ggplot(long, ggplot2::aes(x = .data$round_f, y = .data$value)) +
    ggplot2::geom_boxplot(
      ggplot2::aes(colour = .data$round_f),
      width = 0.55, linewidth = 0.4, outlier.shape = NA, fill = NA
    )
  if (points) {
    p <- p + ggplot2::geom_point(
      ggplot2::aes(colour = .data$round_f),
      position = ggplot2::position_jitter(width = 0.15, height = 0, seed = 1),
      size = 1.6, alpha = 0.55
    )
  }
  p +
    ggplot2::facet_wrap(ggplot2::vars(.data$item), ncol = ncol) +
    ggplot2::scale_colour_manual(values = pal, guide = "none") +
    ggplot2::scale_y_continuous(limits = s, breaks = scales::breaks_pretty()) +
    ggplot2::labs(
      title = "Distribution of expert ratings by round",
      subtitle = scale_subtitle(ind, s),
      x = NULL, y = "Rating"
    ) +
    theme_delphi()
}


#' Median and interquartile range across rounds
#'
#' @description
#' Shows, for each item, the median rating (point) and the interquartile
#' range (vertical bar, from the first to the third quartile) in every
#' round. Filled points mark the rounds in which the item reaches consensus
#' under the rule of [delphi_consensus()]; hollow points mark the rounds in
#' which it does not.
#'
#' @inheritParams delphi_plot_distribution
#' @param items Optional subset of items.
#' @param threshold,relative_to Consensus rule, see [delphi_consensus()].
#' @param type Quantile algorithm; see [delphi_describe()].
#'
#' @return A ggplot object.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_plot_trend(x, indicator = "impact")
#' @export
delphi_plot_trend <- function(x, indicator = NULL, items = NULL, ncol = NULL,
                              threshold = 0.20, relative_to = c("points", "range"),
                              type = 7) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  ind <- pick_indicator(x, indicator)
  cons <- delphi_consensus(x, threshold = threshold, relative_to = relative_to,
                           indicator = ind, items = items, type = type)
  cons <- as.data.frame(unclass(cons), stringsAsFactors = FALSE)
  cons <- cons[!is.na(cons$median), , drop = FALSE]
  cons$item <- item_factor(cons$item, x$items)
  cons$status <- factor(ifelse(cons$consensus, "Consensus", "No consensus"),
                        levels = c("Consensus", "No consensus"))
  s <- x$scales[[ind]]
  rounds <- sort(unique(cons$round))
  col <- delphi_colours$primary

  ggplot2::ggplot(cons, ggplot2::aes(x = .data$round, y = .data$median)) +
    ggplot2::geom_line(colour = col, linewidth = 0.5, alpha = 0.6) +
    ggplot2::geom_linerange(
      ggplot2::aes(ymin = .data$q1, ymax = .data$q3),
      colour = col, linewidth = 0.9, alpha = 0.35
    ) +
    ggplot2::geom_point(
      ggplot2::aes(shape = .data$status),
      colour = col, fill = col, size = 2.6, stroke = 0.9
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$item), ncol = ncol) +
    ggplot2::scale_shape_manual(values = c("Consensus" = 21, "No consensus" = 1),
                                drop = FALSE, name = NULL) +
    ggplot2::scale_x_continuous(breaks = rounds, labels = round_labels(rounds),
                                expand = ggplot2::expansion(add = 0.4)) +
    ggplot2::scale_y_continuous(limits = s, breaks = scales::breaks_pretty()) +
    ggplot2::labs(
      title = "Median and interquartile range across rounds",
      subtitle = scale_subtitle(ind, s),
      caption = paste0(
        "Points: median; bars: interquartile range. Consensus: IQR at most ",
        format(100 * threshold), "% of the rating scale."
      ),
      x = NULL, y = "Rating"
    ) +
    theme_delphi()
}


#' Consensus heat map
#'
#' @description
#' Shows the relative interquartile range of every item (rows) in every
#' round (columns). The colour scale is centred on the consensus threshold:
#' blue cells fall below it (consensus), red cells above it (no consensus),
#' and grey cells lie close to it. Each cell reports the IQR on the original
#' scale; an asterisk marks consensus. Indicators are shown side by side,
#' since the relative IQR is comparable across rating scales.
#'
#' @inheritParams delphi_plot_trend
#' @param indicator Indicators to plot. `NULL` plots all of them.
#' @param round,items Optional subsets of rounds and items.
#' @param digits Number of decimals of the IQR labels.
#'
#' @return A ggplot object.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_plot_consensus(x)
#' @export
delphi_plot_consensus <- function(x, indicator = NULL, round = NULL, items = NULL,
                                  threshold = 0.20, relative_to = c("points", "range"),
                                  type = 7, digits = 1) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  cons <- delphi_consensus(x, threshold = threshold, relative_to = relative_to,
                           round = round, indicator = indicator, items = items,
                           type = type)
  cons <- as.data.frame(unclass(cons), stringsAsFactors = FALSE)
  rounds <- sort(unique(cons$round))
  cons$round_f <- factor(round_labels(cons$round), levels = round_labels(rounds))
  cons$item <- item_factor(cons$item, x$items, reverse = TRUE)
  cons$indicator <- factor(cons$indicator, levels = names(x$scales)[names(x$scales) %in% cons$indicator])
  cons$label <- ifelse(
    is.na(cons$iqr), "",
    paste0(formatC(cons$iqr, format = "f", digits = digits),
           ifelse(cons$consensus %in% TRUE, "*", ""))
  )

  upper <- max(2 * threshold, max(cons$iqr_rel, na.rm = TRUE), 0.01)
  # Asymmetric diverging scale: full blue at 0, grey at the threshold, full
  # red at the largest value shown
  cols <- c(delphi_colours$low, delphi_colours$mid, delphi_colours$high)
  vals <- c(0, threshold / upper, 1)
  fill <- scales::gradient_n_pal(cols, vals)(pmin(cons$iqr_rel, upper) / upper)
  # Label colour from the luminance of the cell fill
  cons$text_col <- ifelse(!is.na(fill) & relative_luminance(fill) < 0.30,
                          "#ffffff", delphi_colours$ink)
  levels(cons$indicator) <- tools_title(levels(cons$indicator))

  ggplot2::ggplot(cons, ggplot2::aes(x = .data$round_f, y = .data$item)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$iqr_rel),
                       colour = "#ffffff", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$label, colour = .data$text_col),
                       size = 3.4) +
    ggplot2::facet_wrap(ggplot2::vars(.data$indicator), nrow = 1) +
    ggplot2::scale_fill_gradientn(
      colours = cols, values = vals, limits = c(0, upper), oob = scales::squish,
      breaks = sort(unique(c(0, threshold, scales::breaks_pretty(4)(c(0, upper))))),
      labels = scales::label_percent(accuracy = 1),
      name = "Relative IQR (IQR as a share of the rating scale)",
      na.value = "#ffffff",
      guide = ggplot2::guide_colourbar(title.position = "top")
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::labs(
      title = "Consensus by item and round",
      subtitle = paste0(
        "Cells report the IQR on the rating scale; * denotes consensus (IQR at most ",
        format(100 * threshold), "% of the scale)"
      ),
      x = NULL, y = NULL
    ) +
    theme_delphi() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      legend.key.width = ggplot2::unit(1.8, "cm"),
      legend.key.height = ggplot2::unit(0.3, "cm")
    )
}

relative_luminance <- function(col) {
  rgb <- grDevices::col2rgb(col) / 255
  lin <- ifelse(rgb <= 0.03928, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  as.numeric(0.2126 * lin[1, ] + 0.7152 * lin[2, ] + 0.0722 * lin[3, ])
}


#' Two-indicator map of the items
#'
#' @description
#' Places every item according to its median rating on two indicators, for
#' example impact (horizontal axis) and plausibility (vertical axis), as in
#' the impact-plausibility matrices used in foresight studies. Thin bars show
#' the interquartile range on each indicator, and dashed lines mark the
#' midpoints of the two scales, dividing the plane into four quadrants.
#' Filled points mark items that reach consensus on both indicators. Items
#' with the same medians on both indicators share a single label.
#'
#' @param x A `delphi_data` object with at least two indicators.
#' @param x_indicator,y_indicator Indicators on the horizontal and vertical
#'   axes. By default, the first and the second indicator.
#' @param round Round to plot. By default, the last round in which both
#'   indicators were rated.
#' @param items Optional subset of items.
#' @param threshold,relative_to Consensus rule, see [delphi_consensus()].
#' @param type Quantile algorithm; see [delphi_describe()].
#' @param iqr Whether to draw the interquartile-range bars.
#'
#' @details
#' Item labels are placed with \pkg{ggrepel} when it is installed, which
#' avoids overlaps; otherwise they are drawn next to the points.
#'
#' @return A ggplot object.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' delphi_plot_map(x, x_indicator = "impact", y_indicator = "plausibility")
#' @export
delphi_plot_map <- function(x, x_indicator = NULL, y_indicator = NULL, round = NULL,
                            items = NULL, threshold = 0.20,
                            relative_to = c("points", "range"), type = 7,
                            iqr = TRUE) {
  assert_delphi_data(x)
  relative_to <- match.arg(relative_to)
  inds <- names(x$scales)
  if (length(inds) < 2L) {
    stop_dr("A two-indicator map needs at least two indicators; the data contain only '", inds, "'.")
  }
  if (is.null(x_indicator)) x_indicator <- inds[1L]
  if (is.null(y_indicator)) y_indicator <- setdiff(inds, x_indicator)[1L]
  for (v in c(x_indicator, y_indicator)) {
    if (!is_string(v) || !v %in% inds) {
      stop_dr("Indicators must be among ", show_values(inds), ".")
    }
  }
  if (identical(x_indicator, y_indicator)) {
    stop_dr("`x_indicator` and `y_indicator` must be different.")
  }

  common <- intersect(unique(x$data$round[x$data$indicator == x_indicator]),
                      unique(x$data$round[x$data$indicator == y_indicator]))
  if (length(common) == 0L) {
    stop_dr("The two indicators were never rated in the same round.")
  }
  if (is.null(round)) {
    round <- max(common)
  } else if (length(round) != 1L || !round %in% common) {
    stop_dr("`round` must be a single round in which both indicators were rated: ",
            show_values(sort(common)), ".")
  }

  cons <- delphi_consensus(x, threshold = threshold, relative_to = relative_to,
                           round = round, indicator = c(x_indicator, y_indicator),
                           items = items, type = type)
  cx <- cons[cons$indicator == x_indicator, , drop = FALSE]
  cy <- cons[cons$indicator == y_indicator, , drop = FALSE]
  m <- merge(cx, cy, by = "item", suffixes = c("_x", "_y"))
  m <- m[!is.na(m$median_x) & !is.na(m$median_y), , drop = FALSE]
  if (nrow(m) == 0L) {
    stop_dr("No item has ratings on both indicators in round ", round, ".")
  }
  m$status <- factor(
    ifelse(m$consensus_x %in% TRUE & m$consensus_y %in% TRUE,
           "Consensus on both indicators", "No consensus on at least one"),
    levels = c("Consensus on both indicators", "No consensus on at least one")
  )
  sx <- x$scales[[x_indicator]]
  sy <- x$scales[[y_indicator]]
  col <- delphi_colours$primary

  p <- ggplot2::ggplot(m, ggplot2::aes(x = .data$median_x, y = .data$median_y)) +
    ggplot2::geom_vline(xintercept = mean(sx), linetype = "dashed",
                        colour = delphi_colours$ink_secondary, linewidth = 0.3) +
    ggplot2::geom_hline(yintercept = mean(sy), linetype = "dashed",
                        colour = delphi_colours$ink_secondary, linewidth = 0.3)
  if (iqr) {
    p <- p +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$q1_x, xmax = .data$q3_x),
                             orientation = "y", width = 0, colour = col,
                             alpha = 0.3, linewidth = 0.6) +
      ggplot2::geom_errorbar(ggplot2::aes(ymin = .data$q1_y, ymax = .data$q3_y),
                             width = 0, colour = col, alpha = 0.3, linewidth = 0.6)
  }
  p <- p +
    ggplot2::geom_point(ggplot2::aes(shape = .data$status), colour = col, fill = col,
                        size = 2.8, stroke = 0.9) +
    ggplot2::scale_shape_manual(
      values = c("Consensus on both indicators" = 21, "No consensus on at least one" = 1),
      drop = FALSE, name = NULL
    )
  # Items with the same medians share one label ("E2, E7, E10"), which is
  # common with integer rating scales
  key <- paste(m$median_x, m$median_y)
  lab <- data.frame(
    median_x = tapply(m$median_x, key, `[`, 1L),
    median_y = tapply(m$median_y, key, `[`, 1L),
    label = tapply(m$item, key, function(v) {
      v <- v[order(match(v, x$items))]
      paste(strwrap(paste(v, collapse = ", "), width = 18), collapse = "\n")
    }),
    stringsAsFactors = FALSE
  )
  label_size <- if (nrow(m) > 20L) 2.7 else 3.4
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    p <- p + ggrepel::geom_text_repel(
      data = lab, ggplot2::aes(label = .data$label), size = label_size,
      colour = delphi_colours$ink, lineheight = 0.9, seed = 1,
      min.segment.length = 0.2, box.padding = 0.35, max.overlaps = Inf
    )
  } else {
    p <- p + ggplot2::geom_text(data = lab, ggplot2::aes(label = .data$label),
                                size = label_size, lineheight = 0.9,
                                colour = delphi_colours$ink, hjust = -0.2, vjust = -0.3)
  }
  p +
    ggplot2::scale_x_continuous(limits = sx, breaks = scales::breaks_pretty()) +
    ggplot2::scale_y_continuous(limits = sy, breaks = scales::breaks_pretty()) +
    ggplot2::labs(
      title = paste0("Items by median ", x_indicator, " and ", y_indicator),
      subtitle = paste0("Round ", round, ". Points: medians; bars: interquartile ranges; ",
                        "dashed lines: scale midpoints"),
      x = paste0(tools_title(x_indicator), " (median; scale from ", sx[1L], " to ", sx[2L], ")"),
      y = paste0(tools_title(y_indicator), " (median; scale from ", sy[1L], " to ", sy[2L], ")")
    ) +
    theme_delphi() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_line(
      colour = delphi_colours$grid, linewidth = 0.3
    ))
}

tools_title <- function(s) {
  paste0(toupper(substring(s, 1L, 1L)), substring(s, 2L))
}


#' Plot a Delphi data object
#'
#' @description
#' Draws one of the DelphiR figures. This is a shortcut for the
#' `delphi_plot_*()` functions:
#'
#' * `"distribution"`: [delphi_plot_distribution()];
#' * `"trend"`: [delphi_plot_trend()];
#' * `"consensus"`: [delphi_plot_consensus()];
#' * `"map"`: [delphi_plot_map()];
#' * `"comments"`: [delphi_plot_comments()], for objects with comments.
#'
#' @param x A `delphi_data` object.
#' @param type Type of figure.
#' @param ... Further arguments passed to the corresponding function.
#' @return A ggplot object.
#' @examples
#' x <- delphi_data(delphi_example, expert_col = "expert",
#'                  round_col = "round", indicator_col = "indicator",
#'                  scale = list(impact = c(1, 10), plausibility = c(1, 100)))
#' plot(x, type = "consensus")
#' plot(x, type = "trend", indicator = "plausibility")
#' @export
plot.delphi_data <- function(x, type = c("distribution", "trend", "consensus", "map", "comments"),
                             ...) {
  type <- match.arg(type)
  fun <- switch(type,
    distribution = delphi_plot_distribution,
    trend = delphi_plot_trend,
    consensus = delphi_plot_consensus,
    map = delphi_plot_map,
    comments = delphi_plot_comments
  )
  fun(x, ...)
}
