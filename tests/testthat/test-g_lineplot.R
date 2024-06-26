adsl <- tern_ex_adsl
adlb <- tern_ex_adlb %>% dplyr::filter(ANL01FL == "Y", PARAMCD == "ALT", AVISIT != "SCREENING")
adlb$AVISIT <- droplevels(adlb$AVISIT)
adlb <- dplyr::mutate(adlb, AVISIT = forcats::fct_reorder(AVISIT, AVISITN, min))

testthat::test_that("g_lineplot works with default settings", {
  testthat::expect_silent(g_lineplot <- g_lineplot(adlb, adsl))

  expect_snapshot_ggplot(title = "g_lineplot", fig = g_lineplot, width = 10, height = 8)
})

testthat::test_that("g_lineplot works with custom settings and statistics table", {
  testthat::expect_silent(g_lineplot_w_stats <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      adsl,
      group_var = control_lineplot_vars(group_var = NULL),
      mid = "median",
      table = c("n", "mean", "mean_ci"),
      control = control_analyze_vars(conf_level = 0.80),
      title = "Plot of Mean and 80% Confidence Limits by Visit",
      x_lab = "Time",
      y_lab = "Lab Test",
      subtitle = "Laboratory Test:",
      caption = "caption"
    )
  ))

  expect_snapshot_ggplot(title = "g_lineplot_w_stats", fig = g_lineplot_w_stats, width = 10, height = 8)
})

testthat::test_that("g_lineplot works with cohort_id specified", {
  testthat::expect_silent(g_lineplot_cohorts <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      adsl,
      group_var = control_lineplot_vars(group_var = "ARM", subject_var = "USUBJID"),
      mid = "median",
      table = c("n", "mean", "mean_ci"),
      control = control_analyze_vars(conf_level = 0.80),
      title = "Plot of Mean and 80% Confidence Limits by Visit",
      y_lab = "Lab Test",
      subtitle = "Laboratory Test:",
      caption = "caption"
    )
  ))

  expect_snapshot_ggplot(title = "g_lineplot_cohorts", fig = g_lineplot_cohorts, width = 10, height = 8)
})

testthat::test_that("g_lineplot maintains factor levels in legend", {
  adlb$ARM <- factor(adlb$ARM, levels = c("C: Combination", "A: Drug X", "B: Placebo"))
  testthat::expect_silent(g_lineplot_factor_levels <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      mid = "median",
      table = c("n", "mean", "mean_ci"),
      control = control_analyze_vars(conf_level = 0.80),
      title = "Plot of Mean and 80% Confidence Limits by Visit",
      y_lab = "Lab Test",
      subtitle = "Laboratory Test:",
      caption = "caption"
    )
  ))

  expect_snapshot_ggplot(title = "g_lineplot_factor_levels", fig = g_lineplot_factor_levels, width = 10, height = 8)
})
testthat::test_that("g_lineplot does not produce a warning if group_var has >6 levels", {
  set.seed(1)
  adlb$FACTOR7 <- as.factor(sample(1:7, nrow(adlb), replace = TRUE))

  testthat::expect_silent(withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      variables = control_lineplot_vars(group_var = "FACTOR7")
    )
  ))
})

testthat::test_that("g_lineplot works with facet_var specified", {
  g_lineplot_facets <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      adsl,
      variables = control_lineplot_vars(facet_var = "COUNTRY"),
      mid = "median",
      control = control_analyze_vars(conf_level = 0.80),
      title = "Plot of Mean and 80% Confidence Limits by Visit",
      y_lab = "Lab Test",
      subtitle = "Laboratory Test:",
      caption = "caption"
    )
  )
  expect_snapshot_ggplot(title = "g_lineplot_facets", fig = g_lineplot_facets, width = 10, height = 8)
})

testthat::test_that("g_lineplot xticks, xlim, and ylim arguments work", {
  g_lineplot_xticks_by <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      adsl,
      variables = control_lineplot_vars(x = "AVISITN"),
      xticks = 1
    )
  )
  expect_snapshot_ggplot(title = "g_lineplot_xticks_by", fig = g_lineplot_xticks_by, width = 10, height = 8)

  g_lineplot_xticks <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      adsl,
      variables = control_lineplot_vars(x = "AVISITN"),
      xticks = c(0, 2.5, 5)
    )
  )
  expect_snapshot_ggplot(title = "g_lineplot_xticks", fig = g_lineplot_xticks, width = 10, height = 8)

  g_lineplot_xlim_ylim <- withr::with_options(
    opts_partial_match_old,
    g_lineplot(
      adlb,
      adsl,
      variables = control_lineplot_vars(x = "AVISITN"),
      xlim = c(1, 6),
      ylim = c(17, 21),
      xticks = 1:6
    )
  )
  expect_snapshot_ggplot(title = "g_lineplot_xlim_ylim", fig = g_lineplot_xlim_ylim, width = 10, height = 8)
})

testthat::test_that("control_lineplot_vars works", {
  testthat::expect_silent(control_lineplot_vars(group_var = NA))

  # Deprecation warnings work
  lifecycle::expect_deprecated(lifecycle::expect_deprecated(control_lineplot_vars(strata = NA, cohort_id = NA)))
})
