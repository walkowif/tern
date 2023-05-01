#' Cox Proportional Hazards Regression
#'
#' @description `r lifecycle::badge("stable")`
#'
#' Fits a Cox regression model and estimates hazard ratio to describe the effect
#' size in a survival analysis.
#'
#' @details
#' Cox models are the most commonly used methods to estimate the magnitude of
#' the effect in survival analysis. It assumes proportional hazards: the ratio
#' of the hazards between groups (e.g., two arms) is constant over time.
#' This ratio is referred to as the "hazard ratio" (HR) and is one of the
#' most commonly reported metrics to describe the effect size in survival
#' analysis (NEST Team, 2020).
#'
#' @inheritParams argument_convention
#'
#' @seealso [fit_coxreg] for relevant fitting functions, [h_cox_regression] for relevant
#' helper functions, and [tidy_coxreg] for custom tidy methods.
#'
#' @examples
#' library(survival)
#'
#' # Testing dataset [survival::bladder].
#' set.seed(1, kind = "Mersenne-Twister")
#' dta_bladder <- with(
#'   data = bladder[bladder$enum < 5, ],
#'   tibble::tibble(
#'     TIME = stop,
#'     STATUS = event,
#'     ARM = as.factor(rx),
#'     COVAR1 = as.factor(enum) %>% formatters::with_label("A Covariate Label"),
#'     COVAR2 = factor(
#'       sample(as.factor(enum)),
#'       levels = 1:4, labels = c("F", "F", "M", "M")
#'     ) %>% formatters::with_label("Sex (F/M)")
#'   )
#' )
#' dta_bladder$AGE <- sample(20:60, size = nrow(dta_bladder), replace = TRUE)
#' dta_bladder$STUDYID <- factor("X")
#'
#' plot(
#'   survfit(Surv(TIME, STATUS) ~ ARM + COVAR1, data = dta_bladder),
#'   lty = 2:4,
#'   xlab = "Months",
#'   col = c("blue1", "blue2", "blue3", "blue4", "red1", "red2", "red3", "red4")
#' )
#'
#' @name cox_regression
NULL

#' @describeIn cox_regression transforms the tabulated results from [`fit_coxreg_univar()`]
#'  and [`fit_coxreg_multivar()`] into a list. Not much calculation is done here,
#'  it rather prepares the data to be used by the layout creating function.
#'
#' @param model_df (`data.frame`)\cr contains the resulting model fit from a [`fit_coxreg`]
#'   function with tidying applied via [`broom::tidy()`].
#' @param .stats (`character`)\cr the name of statistics to be reported among:
#'   * `n`: number of observations (univariable only)
#'   * `hr`: hazard ratio
#'   * `ci`: confidence interval
#'   * `pval`: p-value of the treatment effect
#'   * `pval_inter`: p-value of the interaction effect between the treatment and the covariate (univariable only)
#' @param .which_vars (`character`)\cr which rows should statistics be returned for from the given model.
#'   Defaults to "all". Other options include "var_main" for main effects, "inter" for interaction effects,
#'   and "multi_lvl" for multivariable model covariate level rows. When `.which_vars` is "all" specific
#'   variables can be selected by specifying `.var_nms`.
#' @param .var_nms (`character`)\cr the `term` value of rows in `df` for which `.stats` should be returned. Typically
#'   this is the name of a variable. If using variable labels, `var` should be a vector of both the desired
#'   variable name and the variable label in that order to see all `.stats` related to that variable. When `.which_vars`
#'   is "var_main" `.var_nms` should be only the variable name.
#'
#' @export
#'
#' @examples
#' # s_coxreg
#'
#' # Univariable
#' u1_variables <- list(
#'   time = "TIME", event = "STATUS", arm = "ARM", covariates = c("COVAR1", "COVAR2")
#' )
#' univar_model <- fit_coxreg_univar(variables = u1_variables, data = dta_bladder)
#' df1 <- broom::tidy(univar_model)
#' s_coxreg(model_df = df1, .stats = "hr")
#'
#' # Univariable with interactions
#' univar_model_inter <- fit_coxreg_univar(
#'   variables = u1_variables, control = control_coxreg(interaction = TRUE), data = dta_bladder
#' )
#' df1_inter <- broom::tidy(univar_model_inter)
#' s_coxreg(model_df = df1_inter, .stats = "hr", .which_vars = "inter", .var_nms = "COVAR1")
#'
#' # Univariable without treatment arm - only "COVAR2" covariate effects
#' u2_variables <- list(time = "TIME", event = "STATUS", covariates = c("COVAR1", "COVAR2"))
#' univar_covs_model <- fit_coxreg_univar(variables = u2_variables, data = dta_bladder)
#' df1_covs <- broom::tidy(univar_covs_model)
#' s_coxreg(model_df = df1_covs, .stats = "hr", .var_nms = c("COVAR2", "Sex (F/M)"))
#'
#' # Multivariable.
#' m1_variables <- list(
#'   time = "TIME", event = "STATUS", arm = "ARM", covariates = c("COVAR1", "COVAR2")
#' )
#' multivar_model <- fit_coxreg_multivar(variables = m1_variables, data = dta_bladder)
#' df2 <- broom::tidy(multivar_model)
#' s_coxreg(model_df = df2, .stats = "pval", .which_vars = "var_main", .var_nms = "COVAR1")
#' s_coxreg(
#'   model_df = df2, .stats = "pval", .which_vars = "multi_lvl",
#'   .var_nms = c("COVAR1", "A Covariate Label")
#' )
#'
#' # Multivariable without treatment arm - only "COVAR1" main effect
#' m2_variables <- list(time = "TIME", event = "STATUS", covariates = c("COVAR1", "COVAR2"))
#' multivar_covs_model <- fit_coxreg_multivar(variables = m2_variables, data = dta_bladder)
#' df2_covs <- broom::tidy(multivar_covs_model)
#' s_coxreg(model_df = df2_covs, .stats = "hr")
#'
s_coxreg <- function(model_df, .stats, .which_vars = "all", .var_nms = NULL) {
  assert_df_with_variables(model_df, list(term = "term", stat = .stats))
  checkmate::assert_multi_class(model_df$term, classes = c("factor", "character"))
  model_df$term <- as.character(model_df$term)
  .var_nms <- .var_nms[!is.na(.var_nms)]

  if (length(.var_nms) > 0) model_df <- model_df[model_df$term %in% .var_nms, ]
  if (.which_vars == "multi_lvl") model_df$term <- tail(.var_nms, 1)

  # We need a list with names corresponding to the stats to display of equal length to the list of stats.
  y <- split(model_df, f = model_df$term, drop = FALSE)
  y <- stats::setNames(y, nm = rep(.stats, length(y)))

  if (.which_vars == "var_main") {
    y <- lapply(y, function(x) x[1, ]) # only main effect
  } else if (.which_vars %in% c("inter", "multi_lvl")) {
    y <- lapply(y, function(x) if (nrow(y[[1]]) > 1) x[-1, ] else x) # exclude main effect
  }

  lapply(
    X = y,
    FUN = function(x) {
      z <- as.list(x[[.stats]])
      stats::setNames(z, nm = x$term_label)
    }
  )
}

#' @describeIn cox_regression Analysis function. It is used as `afun` in [rtables::analyze()]
#'   and `cfun` in [rtables::summarize_row_groups()] within `summarize_coxreg()`.
#'
#' @param eff (`flag`)\cr whether treatment effect should be calculated. Defaults to `FALSE`.
#' @param var_main (`flag`)\cr whether main effects should be calculated. Defaults to `FALSE`.
#' @param na_level (`string`)\cr custom string to replace all `NA` values with. Defaults to `""`.
#' @param cache_env (`environment`)\cr an environment object used to cache the regression model in order to
#'   avoid repeatedly fitting the same model for every row in the table. Defaults to `NULL` (no caching).
#'
#' @examples
#' tern:::a_coxreg(
#'   df = dta_bladder,
#'   labelstr = "Label 1",
#'   variables = u1_variables,
#'   .spl_context = list(value = "COVAR1"),
#'   .stats = "n",
#'   .formats = "xx"
#' )
#'
#' tern:::a_coxreg(
#'   df = dta_bladder,
#'   labelstr = "",
#'   variables = u1_variables,
#'   .spl_context = list(value = "COVAR2"),
#'   .stats = "pval",
#'   .formats = "xx.xxxx"
#' )
#'
#' @keywords internal
a_coxreg <- function(df,
                     labelstr,
                     eff = FALSE,
                     var_main = FALSE,
                     multivar = FALSE,
                     variables,
                     at = list(),
                     control = control_coxreg(),
                     .spl_context,
                     .stats,
                     .formats,
                     na_level = "",
                     cache_env = NULL) {
  cov_no_arm <- !multivar && !"arm" %in% names(variables) && control$interaction # special case: univar no arm
  cov <- tail(.spl_context$value, 1) # current variable/covariate
  var_lbl <- formatters::var_labels(df)[cov] # check for df labels
  if (!is.na(var_lbl) && labelstr == cov && cov %in% variables$covariates) labelstr <- var_lbl # use df labels if none
  if (eff || multivar || cov_no_arm) {
    control$interaction <- FALSE
  } else {
    variables$covariates <- cov
    if (var_main) control$interaction <- TRUE
  }

  if (is.null(cache_env[[cov]])) {
    if (!multivar) {
      model <- fit_coxreg_univar(variables = variables, data = df, at = at, control = control) %>% broom::tidy()
    } else {
      model <- fit_coxreg_multivar(variables = variables, data = df, control = control) %>% broom::tidy()
    }
    cache_env[[cov]] <- model
  } else {
    model <- cache_env[[cov]]
  }
  if (!multivar && !var_main) model[, "pval_inter"] <- NA_real_

  if (cov_no_arm || (!cov_no_arm && !"arm" %in% names(variables) && is.numeric(df[[cov]]))) {
    multivar <- TRUE
    if (!cov_no_arm) var_main <- TRUE
  }

  vars_coxreg <- list(which_vars = "all", var_nms = NULL)
  if (eff) {
    if (multivar && !var_main) { # multivar treatment level
      var_lbl_arm <- formatters::var_labels(df)[[variables$arm]]
      vars_coxreg[c("var_nms", "which_vars")] <- list(c(variables$arm, var_lbl_arm), "multi_lvl")
    } else { # treatment effect
      vars_coxreg["var_nms"] <- variables$arm
      if (var_main) vars_coxreg["which_vars"] <- "var_main"
    }
  } else {
    if (!multivar || (multivar && var_main && !is.numeric(df[[cov]]))) { # covariate effect/level
      vars_coxreg[c("var_nms", "which_vars")] <- list(cov, "var_main")
    } else if (multivar) { # multivar covariate level
      vars_coxreg[c("var_nms", "which_vars")] <- list(c(cov, var_lbl), "multi_lvl")
      if (var_main) model[cov, .stats] <- NA_real_
    }
    if (!multivar && !var_main && control$interaction) vars_coxreg["which_vars"] <- "inter" # interaction effect
  }
  var_vals <- s_coxreg(model, .stats, .which_vars = vars_coxreg$which_vars, .var_nms = vars_coxreg$var_nms)[[1]]
  var_names <- if (all(grepl("\\(reference = ", names(var_vals))) && labelstr != tail(.spl_context$value, 1)) {
    paste(c(labelstr, tail(strsplit(names(var_vals), " ")[[1]], 3)), collapse = " ") # "reference" main effect labels
  } else if ((!multivar && !eff && !(!var_main && control$interaction) && nchar(labelstr) > 0) ||
    (multivar && var_main && is.numeric(df[[cov]]))) {
    labelstr # other main effect labels
  } else if (multivar && !eff && !var_main && is.numeric(df[[cov]])) {
    "All" # multivar numeric covariate
  } else {
    names(var_vals)
  }
  in_rows(
    .list = var_vals, .names = var_names, .labels = var_names,
    .formats = stats::setNames(rep(.formats, length(var_names)), var_names),
    .format_na_strs = stats::setNames(rep(na_level, length(var_names)), var_names)
  )
}

#' @describeIn cox_regression layout creating function.
#'
#' @inheritParams fit_coxreg_univar
#' @param multivar (`flag`)\cr Defaults to `FALSE`. If `TRUE` multivariable Cox regression will run, otherwise
#'   univariable Cox regression will run.
#' @param common_var (`character`)\cr the name of a factor variable in the dataset which takes the same value
#'   for all rows. This should be created during pre-processing if no such variable currently exists.
#' @param .section_div (`character`)\cr string which should be repeated as a section divider between sections.
#'   Defaults to `NA` for no section divider. If a vector of two strings are given, the first will be used between
#'   treatment and covariate sections and the second between different covariates.
#'
#' @export
#' @seealso [fit_coxreg_univar()] and [fit_coxreg_multivar()] which also take the `variables`, `data`,
#'   `at` (univariable only), and `control` arguments but return unformatted univariable and multivariable
#'   Cox regression models, respectively.
#'
#' @examples
#' # summarize_coxreg
#'
#' result_univar <- basic_table() %>%
#'   summarize_coxreg(variables = u1_variables) %>%
#'   build_table(dta_bladder)
#' result_univar
#'
#' result_multivar <- basic_table() %>%
#'   summarize_coxreg(
#'     variables = m1_variables,
#'     multivar = TRUE,
#'   ) %>%
#'   build_table(dta_bladder)
#' result_multivar
#'
#' result_univar_covs <- basic_table() %>%
#'   summarize_coxreg(
#'     variables = u2_variables,
#'   ) %>%
#'   build_table(dta_bladder)
#' result_univar_covs
#'
#' result_multivar_covs <- basic_table() %>%
#'   summarize_coxreg(
#'     variables = m2_variables,
#'     multivar = TRUE,
#'     varlabels = c("Covariate 1", "Covariate 2") # custom labels
#'   ) %>%
#'   build_table(dta_bladder)
#' result_multivar_covs
#'
summarize_coxreg <- function(lyt,
                             variables,
                             control = control_coxreg(),
                             at = list(),
                             multivar = FALSE,
                             common_var = "STUDYID",
                             .stats = c("n", "hr", "ci", "pval", "pval_inter"),
                             .formats = c(
                               n = "xx", hr = "xx.xx", ci = "(xx.xx, xx.xx)",
                               pval = "x.xxxx | (<0.0001)", pval_inter = "x.xxxx | (<0.0001)"
                             ),
                             varlabels = NULL,
                             .indent_mods = NULL,
                             na_level = "",
                             .section_div = NA_character_) {
  if (multivar && control$interaction) {
    warning(paste(
      "Interactions are not available for multivariable cox regression using summarize_coxreg.",
      "The model will be calculated without interaction effects."
    ))
  }
  if (control$interaction && !"arm" %in% names(variables)) {
    stop("To include interactions please specify 'arm' in variables.")
  }

  .stats <- if (!"arm" %in% names(variables) || multivar) { # only valid statistics
    intersect(c("hr", "ci", "pval"), .stats)
  } else if (control$interaction) {
    intersect(c("n", "hr", "ci", "pval", "pval_inter"), .stats)
  } else {
    intersect(c("n", "hr", "ci", "pval"), .stats)
  }
  stat_labels <- c(
    n = "n", hr = "Hazard Ratio", ci = paste0(control$conf_level * 100, "% CI"),
    pval = "p-value", pval_inter = "Interaction p-value"
  )
  stat_labels <- stat_labels[names(stat_labels) %in% .stats]
  .formats <- .formats[names(.formats) %in% .stats]
  env <- new.env() # create caching environment

  lyt <- lyt %>%
    split_cols_by_multivar(
      vars = rep(common_var, length(.stats)),
      varlabels = stat_labels,
      extra_args = list(
        .stats = .stats, .formats = .formats, na_level = rep(na_level, length(.stats)),
        cache_env = replicate(length(.stats), list(env))
      )
    )

  if ("arm" %in% names(variables)) { # treatment effect
    lyt <- lyt %>%
      split_rows_by(
        common_var,
        split_label = "Treatment:",
        label_pos = "visible",
        section_div = head(.section_div, 1)
      ) %>%
      summarize_row_groups(
        cfun = a_coxreg,
        extra_args = list(
          variables = variables, control = control, multivar = multivar, eff = TRUE, var_main = multivar
        )
      )
    if (multivar) { # treatment level effects
      lyt <- lyt %>%
        analyze_colvars(
          afun = a_coxreg,
          extra_args = list(eff = TRUE, control = control, variables = variables, multivar = multivar)
        )
    }
  }

  if ("covariates" %in% names(variables)) { # covariate main effects
    lyt <- lyt %>%
      split_rows_by_multivar(
        vars = variables$covariates,
        varlabels = varlabels,
        split_label = "Covariate:",
        nested = FALSE,
        section_div = tail(.section_div, 1)
      ) %>%
      summarize_row_groups(
        cfun = a_coxreg,
        extra_args = list(
          variables = variables, at = at, control = control, multivar = multivar,
          var_main = if (multivar) multivar else control$interaction
        )
      )
    if (!"arm" %in% names(variables)) control$interaction <- TRUE # special case: univar no arm
    if (multivar || control$interaction) { # covariate level effects
      lyt <- lyt %>%
        analyze_colvars(
          afun = a_coxreg,
          extra_args = list(variables = variables, at = at, control = control, multivar = multivar, labelstr = "")
        )
    }
  }

  lyt
}