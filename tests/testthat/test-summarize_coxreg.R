# Bladder data from survival
dta_bladder <- local({
  # Setting general random for data generation
  set.seed(1, kind = "Mersenne-Twister")
  dta_bladder <- with(
    data = survival::bladder[survival::bladder$enum < 5, ],
    tibble::tibble(
      TIME = stop,
      STATUS = event,
      ARM = paste("ARM:", as.factor(rx)),
      ARMCD = formatters::with_label(as.factor(rx), "ARM"),
      COVAR1 = formatters::with_label(as.factor(enum), "A Covariate Label"),
      COVAR2 = formatters::with_label(
        factor(sample(as.factor(enum)), levels = 1:4, labels = c("F", "F", "M", "M")), "Sex (F/M)"
      ),
      AGE = formatters::with_label(sample(20:60, size = 340, replace = TRUE), "Age"),
      STUDYID = factor("X")
    )
  )
  dta_bladder
})

variables <- list(time = "TIME", event = "STATUS", arm = "ARMCD", covariates = c("COVAR1", "COVAR2"))
variables_no_arm <- list(time = "TIME", event = "STATUS", covariates = c("COVAR1", "COVAR2"))

# s_coxreg ----

testthat::test_that("s_coxreg converts tabulated results in a list", {
  univar_model <- fit_coxreg_univar(
    variables = variables,
    data = dta_bladder
  ) %>% broom::tidy()
  result <- s_coxreg(model_df = univar_model, .stat = "hr")

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("s_coxreg works with which_vars and var_nms arguments", {
  univar_model <- fit_coxreg_univar(
    variables = variables,
    control = control_coxreg(interaction = TRUE),
    data = dta_bladder
  ) %>% broom::tidy()
  result <- s_coxreg(model_df = univar_model, .stat = "hr", .which_vars = "inter", .var_nms = "COVAR2")

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

# a_coxreg ----

testthat::test_that("a_coxreg works as expected", {
  result <- a_coxreg(
    df = dta_bladder,
    labelstr = "Label 1",
    variables = variables,
    .spl_context = list(value = "COVAR1"),
    .stats = "n",
    .formats = "xx"
  )

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

# summarize_coxreg ----

testthat::test_that("summarize_coxreg adds the univariable Cox regression layer to rtables", {
  lyt <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      control = control_coxreg(ties = "breslow", conf_level = 0.90)
    )
  result <- lyt %>% build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)

  # custom covariate labels
  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      varlabels = c("First Covariate", "Second Covariate")
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)

  # no labels
  formatters::var_labels(dta_bladder) <- rep(NA_character_, ncol(dta_bladder))
  result <- lyt %>% build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg .section_div argument works", {
  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      .section_div = c("_", " *")
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg works with interactions in univariable case", {
  variables <- list(time = "TIME", event = "STATUS", arm = "ARMCD", covariates = c("AGE", "COVAR1", "COVAR2"))

  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      control = control_coxreg(interaction = TRUE)
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg 'at' argument works in univariable case", {
  variables <- list(time = "TIME", event = "STATUS", arm = "ARMCD", covariates = c("AGE", "COVAR2"))

  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      control = control_coxreg(interaction = TRUE),
      at = list(AGE = c(15, 30, 60))
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg na_level argument works", {
  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      control = control_coxreg(interaction = TRUE),
      na_level = "---"
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg works without treatment arm in univariable case", {
  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables_no_arm,
      control = control_coxreg(conf_level = 0.90)
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg works with numeric covariate without treatment arm in univariable case", {
  variables_no_arm <- list(time = "TIME", event = "STATUS", covariates = c("COVAR1", "AGE"))

  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables_no_arm,
      control = control_coxreg(conf_level = 0.90)
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("summarize_coxreg adds the multivariable Cox regression layer to rtables", {
  variables <- list(time = "TIME", event = "STATUS", arm = "ARMCD", covariates = c("AGE", "COVAR1", "COVAR2"))

  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      multivar = TRUE
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)

  # custom covariate labels
  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      multivar = TRUE,
      varlabels = c("Age Covariate", "First Covariate", "Second Covariate")
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)

  # no labels
  formatters::var_labels(dta_bladder) <- rep(NA_character_, ncol(dta_bladder))
  result <- basic_table() %>%
    summarize_coxreg(
      variables = variables,
      multivar = TRUE
    ) %>%
    build_table(df = dta_bladder)

  res <- testthat::expect_silent(result)
  testthat::expect_snapshot(res)
})

testthat::test_that("warning/error messages work", {
  testthat::expect_warning(
    result <- basic_table() %>%
      summarize_coxreg(
        variables = variables,
        control = control_coxreg(interaction = TRUE),
        multivar = TRUE
      ) %>%
      build_table(df = dta_bladder),
    "Interactions are not available"
  )

  testthat::expect_error(
    result <- basic_table() %>%
      summarize_coxreg(
        variables = variables_no_arm,
        control = control_coxreg(interaction = TRUE)
      ) %>%
      build_table(df = dta_bladder),
    "To include interactions"
  )
})