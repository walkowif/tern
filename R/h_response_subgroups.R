#' Helper Functions for Tabulating Binary Response by Subgroup
#'
#' Helper functions that tabulate in a data frame statistics such as response rate
#' and odds ratio for population subgroups.
#'
#' @details Main functionality is to prepare data for use in a layout creating function.
#'
#' @inheritParams argument_convention
#' @param arm (`factor`)\cr the treatment group variable.
#' @param data (`data frame`)\cr the dataset containing the variables to summarize.
#' @param method (`string`)\cr
#'   specifies the test used to calculate the p-value for the difference between
#'   two proportions. For options, see [s_test_proportion_diff()]. Default is `NULL`
#'   so no test is performed.
#' @param label_all (`string`)\cr label for the total population analysis.
#' @name h_response_subgroups
#' @order 1
#' @examples
#'
#' # Testing dataset.
#' library(random.cdisc.data)
#' library(dplyr)
#'
#' adrs <- radrs(cached = TRUE)
#' adrs_labels <- var_labels(adrs)
#'
#' adrs_f <- adrs %>%
#'   filter(PARAMCD == "BESRSPI") %>%
#'   filter(ARM %in% c("A: Drug X", "B: Placebo")) %>%
#'   droplevels() %>%
#'   mutate(
#'     # Reorder levels of factor to make the placebo group the reference arm.
#'     ARM = forcats::fct_relevel(ARM, "B: Placebo"),
#'     rsp = AVALC == "CR"
#'   )
#' var_labels(adrs_f) <- c(adrs_labels, "Response")
#'
NULL

#' @describeIn h_response_subgroups helper to prepare a data frame of binary responses by arm.
#' @inheritParams h_response_subgroups
#' @export
#' @examples
#'
#' h_proportion_df(
#'   c(TRUE, FALSE, FALSE),
#'   arm = factor(c("A", "A", "B"), levels = c("A", "B"))
#' )
#'
h_proportion_df <- function(rsp, arm) {

  assert_that(
    is_logical_vector(rsp),
    is_valid_factor(arm),
    is_equal_length(rsp, arm)
  )

  lst_rsp <- split(rsp, arm)
  lst_results <- Map(function(x, arm) {

    s_prop <- s_proportion(x)
    data.frame(
      arm = arm,
      n = length(x),
      n_rsp = unname(s_prop$n_prop[1]),
      prop = unname(s_prop$n_prop[2]),
      stringsAsFactors = FALSE
    )

  }, lst_rsp, names(lst_rsp))

  df <- do.call(rbind, args = c(lst_results, make.row.names = FALSE))
  df$arm <- factor(df$arm, levels = levels(arm))
  df
}

#' @describeIn h_response_subgroups summarizes proportion of binary responses by arm and across subgroups
#'    in a data frame. `variables` corresponds to the names of variables found in `data`, passed as a named list and
#'    requires elements `rsp`, `arm` and optionally `subgroups`.
#' @export
#' @examples
#'
#' h_proportion_subgroups_df(
#'   variables = list(rsp = "rsp", arm = "ARM", subgroups = c("SEX", "BMRKR2")),
#'   data = adrs_f
#' )
#'
h_proportion_subgroups_df <- function(variables, data, label_all = "All Patients") {

  assert_that(
    is.character(variables$rsp),
    is.character(variables$arm),
    is.character(variables$subgroups) || is.null(variables$subgroups),
    is_character_single(label_all),
    is_df_with_variables(data, as.list(unlist(variables))),
    is_valid_factor(data[[variables$arm]]),
    are_equal(nlevels(data[[variables$arm]]), 2)
  )

  # Add All Patients.
  result_all <- h_proportion_df(data[[variables$rsp]], data[[variables$arm]])
  result_all$subgroup <- label_all
  result_all$var <- "ALL"
  result_all$var_label <- label_all
  result_all$row_type <- "content"

  # Add Subgroups.
  if (is.null(variables$subgroups)) {
    result_all
  } else {

    l_data <- h_split_by_subgroups(data, variables$subgroups)

    l_result <- lapply(l_data, function(grp) {
      result <- h_proportion_df(grp$df[[variables$rsp]], grp$df[[variables$arm]])
      result_labels <- grp$df_labels[rep(1, times = nrow(result)), ]
      cbind(result, result_labels)
    })
    result_subgroups <- do.call(rbind, args = c(l_result, make.row.names = FALSE))
    result_subgroups$row_type <- "analysis"

    rbind(
      result_all,
      result_subgroups
    )
  }
}

#' @describeIn h_response_subgroups helper to prepare a data frame with estimates of
#'   the odds ratio between a treatment and a control arm.
#' @inheritParams response_subgroups
#' @export
#' @examples
#'
#' h_odds_ratio_df(
#'   c(TRUE, FALSE, FALSE, TRUE),
#'   arm = factor(c("A", "A", "B", "B"), levels = c("A", "B"))
#' )
#' # Include p-value.
#' h_odds_ratio_df(adrs_f$rsp, adrs_f$ARM, method = "chisq")
#'
h_odds_ratio_df <- function(rsp, arm, conf_level = 0.95, method = NULL) {

  assert_that(
    is_valid_factor(arm),
    is_equal_length(rsp, arm),
    are_equal(nlevels(arm), 2)
  )

  df_rsp <- data.frame(rsp = rsp)

  l_df <- split(df_rsp, arm)

  # Odds ratio and CI.
  result_odds_ratio <- s_odds_ratio(
    df = l_df[[2]],
    .var = "rsp",
    .ref_group = l_df[[1]],
    .in_ref_col = FALSE,
    conf_level = conf_level
  )

  df <- data.frame(
    # Dummy column needed downstream to create a nested header.
    arm = " ",
    n_tot = nrow(df_rsp),
    or = unname(result_odds_ratio$or_ci["est"]),
    lcl = unname(result_odds_ratio$or_ci["lcl"]),
    ucl = unname(result_odds_ratio$or_ci["ucl"]),
    conf_level = conf_level,
    stringsAsFactors = FALSE
  )

  if (!is.null(method)) {

    # Test for difference.
    result_test <- s_test_proportion_diff(
      df = l_df[[2]],
      .var = "rsp",
      .ref_group = l_df[[1]],
      .in_ref_col = FALSE,
      variables = list(strata = NULL),
      method = method
    )

    df$pval <- as.numeric(result_test$pval)
    df$pval_label <- obj_label(result_test$pval)
  }

  df

}

#' @describeIn h_response_subgroups summarizes estimates of the odds ratio between a treatment and a control
#'   arm across subgroups in a data frame. `variables` corresponds to the names of variables found in
#'   `data`, passed as a named list and requires elements `rsp`, `arm` and optionally `subgroups`.
#' @export
#' @examples
#'
#' h_odds_ratio_subgroups_df(
#'   variables = list(rsp = "rsp", arm = "ARM", subgroups = c("SEX", "BMRKR2")),
#'   data = adrs_f
#' )
#'
h_odds_ratio_subgroups_df <- function(variables,
                                      data,
                                      conf_level = 0.95,
                                      method = NULL,
                                      label_all = "All Patients") {

  assert_that(
    is.character(variables$rsp),
    is.character(variables$arm),
    is.character(variables$subgroups) || is.null(variables$subgroups),
    is_character_single(label_all),
    is_df_with_variables(data, as.list(unlist(variables))),
    is_valid_factor(data[[variables$arm]]),
    are_equal(nlevels(data[[variables$arm]]), 2)
  )

  # Add All Patients.
  result_all <- h_odds_ratio_df(
    rsp = data[[variables$rsp]],
    arm = data[[variables$arm]],
    conf_level = conf_level,
    method = method
  )
  result_all$subgroup <- label_all
  result_all$var <- "ALL"
  result_all$var_label <- label_all
  result_all$row_type <- "content"

  if (is.null(variables$subgroups)) {
    result_all
  } else {

    l_data <- h_split_by_subgroups(data, variables$subgroups)

    l_result <- lapply(l_data, function(grp) {

      result <- h_odds_ratio_df(
        rsp = grp$df[[variables$rsp]],
        arm = grp$df[[variables$arm]],
        conf_level = conf_level,
        method = method
      )
      result_labels <- grp$df_labels[rep(1, times = nrow(result)), ]
      cbind(result, result_labels)
    })

    result_subgroups <- do.call(rbind, args = c(l_result, make.row.names = FALSE))
    result_subgroups$row_type <- "analysis"

    rbind(
      result_all,
      result_subgroups
    )
  }

}