library(random.cdisc.data)

preprocess_adrs <- function(adrs, n_records = 20) {

  adrs_labels <- var_labels(adrs)
  adrs <- adrs %>%
    dplyr::filter(PARAMCD == "BESRSPI") %>%
    dplyr::filter(ARM %in% c("A: Drug X", "B: Placebo")) %>%
    dplyr::slice(1:n_records) %>%
    droplevels() %>%
    dplyr::mutate(
      # Reorder levels of factor to make the placebo group the reference arm.
      ARM = forcats::fct_relevel(ARM, "B: Placebo"),
      rsp = AVALC == "CR"
    )
  var_labels(adrs) <- c(adrs_labels, "Response")

  adrs
}

test_that("h_proportion_df functions as expected with valid input and default arguments", {

  rsp <- c(TRUE, FALSE, FALSE, TRUE, FALSE, FALSE)
  arm <- factor(c("A", "B", "A", "B", "A", "A"), levels = c("B", "A"))

  result <- h_proportion_df(rsp = rsp, arm = arm)

  expected <- data.frame(
    arm = factor(c("B", "A"), levels = c("B", "A")),
    n = c(2, 4),
    n_rsp = c(1, 1),
    prop = c(0.5, 0.25),
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected)
})

test_that("h_proportion_df functions as expected when 0 responses in one group", {

  rsp <- c(TRUE, FALSE, FALSE, FALSE)
  arm <- factor(c("A", "A", "B", "B"), levels = c("A", "B"))

  result <- h_proportion_df(rsp = rsp, arm = arm)

  expected <- data.frame(
    arm = factor(c("A", "B"), levels = c("A", "B")),
    n = c(2, 2),
    n_rsp = c(1, 0),
    prop = c(0.5, 0),
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected)

})

test_that("h_proportion_df fails with wrong input", {

  expect_error(h_proportion_df(
    rsp = c(TRUE, FALSE, NA),
    arm = factor(c("A", "B", "A"), levels = c("B", "A"))
  ))

})

test_that("h_proportion_subgroups_df functions as expected with valid input and default arguments", {

  adrs <- radrs(cached = TRUE) %>%
    preprocess_adrs()

  result <- h_proportion_subgroups_df(
    variables = list(rsp = "rsp", arm = "ARM", subgroups = c("SEX", "STRATA2")),
    data = adrs
  )

  expected <- data.frame(
    arm = factor(rep(c("B: Placebo", "A: Drug X"), 5), levels = c("B: Placebo", "A: Drug X")),
    n = c(7, 13, 3, 5, 4, 8, 2, 9, 5, 4),
    n_rsp = c(4, 11, 1, 5, 3, 6, 2, 8, 2, 3),
    prop = c(0.5714286, 0.8461538, 0.3333333, 1, 0.75, 0.75, 1, 0.8888889, 0.4, 0.75),
    subgroup = c("All Patients", "All Patients", "F", "F", "M", "M", "S1", "S1", "S2", "S2"),
    var = c(rep("ALL", 2), rep("SEX", 4), rep("STRATA2", 4)),
    var_label = c(rep("All Patients", 2), rep("Sex", 4), rep("Stratification Factor 2", 4)),
    row_type = c(rep("content", 2), rep("analysis", 8)),
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected, tol = 0.000001)

})

test_that("h_proportion_subgroups_df functions as expected when subgroups is NULL.", {

  adrs <- radrs(cached = TRUE) %>%
    preprocess_adrs()

  result <- h_proportion_subgroups_df(
    variables = list(rsp = "rsp", arm = "ARM"),
    data = adrs
  )

  expected <- data.frame(
    arm = factor(c("B: Placebo", "A: Drug X"), levels = c("B: Placebo", "A: Drug X")),
    n = c(7, 13),
    n_rsp = c(4, 11),
    prop = c(0.5714286, 0.8461538),
    subgroup = c("All Patients", "All Patients"),
    var = rep("ALL", 2),
    var_label = rep("All Patients", 2),
    row_type = rep("content", 2),
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected, tol = 0.000001)

})

test_that("h_odds_ratio_df functions as expected with valid input and default arguments", {

  result <- h_odds_ratio_df(
    c(TRUE, FALSE, FALSE, TRUE),
    arm = factor(c("A", "A", "B", "B"), levels = c("A", "B"))
  )

  expected <- data.frame(
    arm = " ",
    n_tot = 4,
    or = 1,
    lcl = 0.01984252,
    ucl = 50.39681,
    conf_level = 0.95,
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected, tol = 0.000001)

})

test_that("h_odds_ratio_df functions as expected with valid input and non-default arguments", {

  adrs <- radrs(cached = TRUE) %>%
    preprocess_adrs(n_records = 100)

  result <- h_odds_ratio_df(
    rsp = adrs$rsp,
    arm = adrs$ARM,
    conf_level = 0.9,
    method = "chisq"
  )

  expected <- data.frame(
    arm = " ",
    n_tot = 100,
    or = 2.538461,
    lcl = 0.9745661,
    ucl = 6.611955,
    conf_level = 0.9,
    pval = 0.1017069,
    pval_label = "p-value (Chi-Squared Test)",
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected, tol = 0.000001)

})

test_that("h_odds_ratio_subgroups_df functions as expected with valid input and default arguments", {

  adrs <- radrs(cached = TRUE) %>%
    preprocess_adrs(n_records = 100)

  result <- h_odds_ratio_subgroups_df(
    variables = list(rsp = "rsp", arm = "ARM", subgroups = c("SEX", "STRATA2")),
    data = adrs
  )

  expected <- data.frame(
    arm = rep(" ", 5),
    n_tot = c(100L, 56L, 44L, 48L, 52L),
    or = c(2.538461, 4.363636, 1.235294, 2.083333, 3.043478),
    lcl = c(0.8112651, 0.8347243, 0.2204647, 0.4110081, 0.5663254),
    ucl = c(7.942886, 22.811510, 6.921525, 10.560077, 16.355893),
    conf_level = 0.95,
    subgroup = c("All Patients", "F", "M", "S1", "S2"),
    var = c("ALL", "SEX", "SEX", "STRATA2", "STRATA2"),
    var_label = c("All Patients", rep(c("Sex", "Stratification Factor 2"), each = 2)),
    row_type = c("content", rep("analysis", 4)),
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected, tol = 0.000001)

})

test_that("h_odds_ratio_subgroups_df functions as expected  when subgroups is NULL.", {

  adrs <- radrs(cached = TRUE) %>%
    preprocess_adrs(n_records = 100)

  result <- h_odds_ratio_subgroups_df(
    variables = list(rsp = "rsp", arm = "ARM"),
    data = adrs
  )

  expected <- data.frame(
    arm = " ",
    n_tot = 100L,
    or = 2.538461,
    lcl = 0.8112651,
    ucl = 7.942886,
    conf_level = 0.95,
    subgroup = "All Patients",
    var = "ALL",
    var_label = "All Patients",
    row_type = "content",
    stringsAsFactors = FALSE
  )

  expect_equal(result, expected, tol = 0.000001)

})