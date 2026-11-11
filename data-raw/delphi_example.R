# Generates the synthetic `delphi_example` dataset and the example CSV in
# inst/extdata. Run from the package root with:
#   Rscript data-raw/delphi_example.R

set.seed(2026)

n_experts <- 15
items <- paste0("E", 1:8)
experts <- sprintf("EXP%02d", seq_len(n_experts))
dropouts <- c("EXP04", "EXP11")

# Latent group position of each item, on a 0-1 scale
centre <- c(E1 = 0.80, E2 = 0.35, E3 = 0.60, E4 = 0.70,
            E5 = 0.50, E6 = 0.25, E7 = 0.85, E8 = 0.45)

to_scale <- function(p, lo, hi) {
  round(pmin(pmax(lo + p * (hi - lo), lo), hi))
}

simulate_indicator <- function(lo, hi, shift = 0) {
  r1 <- sapply(items, function(i) {
    if (i == "E5") {
      # Polarised item: two camps
      camp <- rep(c(0.2, 0.85), length.out = n_experts)
      camp + stats::rnorm(n_experts, 0, 0.08)
    } else {
      centre[[i]] + shift + stats::rnorm(n_experts, 0, 0.20)
    }
  })
  r1 <- pmin(pmax(r1, 0), 1)
  med <- apply(r1, 2, stats::median)

  # Round 2: experts move half-way towards the round-1 median,
  # except on the polarised item
  r2 <- r1
  for (j in seq_along(items)) {
    if (items[j] == "E5") {
      r2[, j] <- r1[, j] + stats::rnorm(n_experts, 0, 0.03)
    } else {
      r2[, j] <- r1[, j] + 0.5 * (med[j] - r1[, j]) + stats::rnorm(n_experts, 0, 0.05)
    }
  }
  r2 <- pmin(pmax(r2, 0), 1)

  list(
    r1 = apply(r1, 2, to_scale, lo = lo, hi = hi),
    r2 = apply(r2, 2, to_scale, lo = lo, hi = hi)
  )
}

impact <- simulate_indicator(1, 10)
plaus <- simulate_indicator(1, 100, shift = -0.05)

block <- function(m, round, indicator, keep = rep(TRUE, n_experts)) {
  df <- data.frame(expert = experts, round = round, indicator = indicator,
                   m, stringsAsFactors = FALSE, check.names = FALSE)
  df[keep, , drop = FALSE]
}

in_r2 <- !experts %in% dropouts
delphi_example <- rbind(
  block(impact$r1, 1L, "impact"),
  block(plaus$r1, 1L, "plausibility"),
  block(impact$r2, 2L, "impact", in_r2),
  block(plaus$r2, 2L, "plausibility", in_r2)
)

# A few missing ratings (item non-response)
delphi_example[3, "E6"] <- NA
delphi_example[20, "E2"] <- NA
delphi_example[35, "E8"] <- NA
rownames(delphi_example) <- NULL
for (i in items) delphi_example[[i]] <- as.integer(delphi_example[[i]])

save(delphi_example, file = "data/delphi_example.rda", compress = "xz")

# Round 1, impact only, as a semicolon-separated CSV (European export style)
r1_csv <- delphi_example[delphi_example$round == 1 &
                           delphi_example$indicator == "impact",
                         c("expert", items)]
utils::write.table(r1_csv, "inst/extdata/delphi_round1.csv", sep = ";",
                   dec = ",", row.names = FALSE, na = "", quote = FALSE)
