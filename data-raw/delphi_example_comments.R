# Synthetic comments for the example study (round 2), in the long layout of
# delphi_add_comments(). Themes were assigned after reading the comments.

delphi_example_comments <- data.frame(
  expert = c("EXP01", "EXP10", "EXP13", "EXP08", "EXP13", "EXP03", "EXP09",
             "EXP06", "EXP12", "EXP14", "EXP05"),
  round = 2L,
  item = c("E7", "E7", "E7", "E2", "E2", "E5", "E5", "E5", "E1", "E3", NA),
  comment = c(
    "Adoption will be slower than expected, because most firms lack the necessary skills.",
    "The technology is already available, and its costs are falling quickly.",
    "New regulation in the European Union will accelerate this change.",
    "Unlikely in the public sector, where recruitment procedures are set by law.",
    "Large firms already use these tools for the first screening of candidates.",
    "The outcome depends on policy decisions that have not been taken yet.",
    "The statement combines two different developments; I rated the first one.",
    "Differences between sectors make a single rating difficult.",
    "Hybrid arrangements are more likely than fully remote work.",
    "The costs of implementation are underestimated.",
    "Some statements would benefit from a clearer time horizon."
  ),
  theme = c("skills; time horizon", "costs", "regulation", "regulation",
            "current practice", "uncertainty", "wording", "sector differences",
            "wording", "costs", "time horizon"),
  stringsAsFactors = FALSE
)

save(delphi_example_comments, file = "data/delphi_example_comments.rda", compress = "xz")
