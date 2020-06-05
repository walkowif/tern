
# tern 0.6.7

* Add `stat_mean_ci` and `stat_median_ci` for error bars in `ggplot2`
* Add new tern function `t_coxreg` as single interface for diverse cox regression types
* Add compound table for binary endpoint: `t_binary_endpoint` and elementary functions: `t_el_proportion`,
  `t_el_proportion_diff` and `t_el_test_proportion_diff`. The supporting summary functions added are: 
  `s_proportion`, `s_adj_proportion_diff`, `s_proportion_diff` and `s_test_proportion_diff`.
* Added new tern function `t_events_patyear` to create event table adjusted person-years
* Added new tern function `t_abnormality` and the elementary table function `t_el_abnormality`
* Removed `grade_levels` argument from `t_events_term_grade_id` functions. If a different ordering of the rows is needed,
  this must be done through postprocessing by reordering the leaves of the table tree. Eventually, a helper function
  will be provided.
* Added `prune_zero_rows` argument to `t_events_per_term_grade_id` and `t_max_grade_per_id` to not show rows of all zeros
  as they can clutter the visualization in the Shiny app and make it slower.
* Fixed position of (N=xx) in `t_summary_by` output when numeric columns are summarized in parallel with `compare_in_header` 
* rename t_coxph to t_coxph_pairwise to reflect the model process, add details in documentation.
* Remove `test.nest` dependency


# tern 0.6.6

* Remove `test.nest` dependency

# tern 0.6.5

* Change default option for denominator to be `N` in `t_summary`
* fix IQR bug: IQR as Q3 minus Q1
* Add new function `t_logistic` for multi-variable logistic regression table
* Add new function `df_explicit_na` to replace `NA` by explicit values
* Added possibility in `t_tte` to specify confidence level independent for `survfit`, `coxph`, and `ztest`, see the manual.
* Fixed bug in `t_rsp` of not showing p-value, odds ratio and CIs when `strata_data` is not `NULL`
* Added stratified analysis for `t_forest_rsp` and `t_forest_tte`, stratified analysis is footnoted in `g_forest`.
* Added `footnotes`, `footnotes<-` and `add_footnotes<-` functions to deal with footnotes
* Added argument `conf_int` for confidence interval level to `t_el_forest_rps`, `t_forest_rsp`, `t_el_forest_tte`, `t_forest_tte`
* Added argument `col_symbol_size` to `g_forest` to control the relative size of symbols used in the plot.
* Added `s_coxph_pairwise` function to perform pairwise testing which is used by `t_tte` and `t_coxph`
* Added methods for `t_count_true` replacing `t_summary_true`
* Updated `t_count_unique` to create analysis subsets, add `t_el_count_unique` for vectors
* Fixed bug in `t_events_term_id` so that table sort order is by decreasing frequency instead of alphabetical.
* Added function `color_palette` and a new nest color palette

# tern 0.6.4

* Refactored after renaming functions in `utils.nest`
* Added `event_type` argument to `t_events_per_term_grade_id`
* Added one/two-arm t-test functions
* improvements in `t_summary_by`
* internal code refactoring

# tern 0.6.3

* Added `node` S4 class to create trees:
    - for all related tree functions see the reference under trees 

* Removed functions:
    - Moved all the label functions to `rtables`
    - deleted `keys` and `keys<-` functions

* New helper functions:
    - exported `tabulate_pairwise`
    - `get_N`, `col_N_add_total`, `check_id`
    - `na_as_level`
    - `as_factor_keep_attributes`
    - `r_by`

* New TLGs:
    - disposition elementary table `t_el_disposition`
    - `t_el_forest_tte`, `t_el_forest_rsp`

* Changed Arguments:
    - all compound tables
        - added `table_tree` argument which returns a `node` object
    - `t_summary.numeric`
        - added `f_numeric` to choose which statistics should be calculated
    - `t_summary.factor`
        - `denominator` now also allows for `omit` if the percentages should be omitted.
    - `t_summary_by`
        - renamed `by` to `row_by`
    - `t_forest_rsp`, `t_forest_tte`
        - changed functionality of `group_data` using `row_by_list`
        - removed `na_omit_group`
    - `t_count_unique`
        - removed `indent` argument, use the `indent` function in `rtables` instead

# tern 0.6.2

* use cached data from `random.cdisc.data` to speed up testing
* added `t_summary.Date` method
* added `save_join`

# tern 0.6.1

* Fixed colors in Kaplan-Meyer-Plot https://github.roche.com/NEST/tern/issues/66
* Refactor of all functions to pass `test.nest` tests:
    * changed `width_row.names` argument of `g_forest` function into `width_row_names`
    * changed `censor.show` argument of `g_km` function into `censor_show`
    * changed `col.legend.title` argument of `g_waterfall` function into `col_legend_title`
    * changed `na.rm` argument of `t_count_unique` function into `na_rm`
    * changed `row.name` argument of `t_count_unique` function into `row_name`
    * changed `na.omit.group` argument of `t_forest_rsp` function into `na_omit_group`
    * changed `na.omit.group` argument of `t_forest_tte` function into `na_omit_group`
    * changed `row.name.TRUE` and `row.name.FALSE` arguments of `t_summary.logical` into `row_name_true` and `row_name_false` respectively
    * rename `splotTextGrob` into `split_text_grob`
    * fix examples
    * refactor of internal functions code

# tern 0.6.0

* Removed functions `addTable`, `t_summarize_by_visit`, `t_summarize_variables`.
* Added `t_summary_by` function.
* Refactor of `g_km` function, renamed `kmGrob` into `kmCurveGrob`.
* Refactor `t_events_*` family of functions.
* Updated examples.

# tern 0.5.0.3 

## New TLGs

* `t_summary` and methods for `data.frame`, `numeric`, `logical`, `character`,
`factor`, and `Date` objects
* `t_events_per_term_id`, `t_events_per_term_grade_id`: Adverse Events &
Concomitant Treatment Tables
* `t_max_grade_per_id`, `t_count_unique`, `t_events_summary` elementary tables
used for the Adverse Events & Concomitant Treatment Tables
* `g_waterfall`: Horizontal Waterfall Plot

## New Helper Functions

* `decorate_grob`, `decorate_grob_set`, `decorate_grob_factory`, `splitTextGrob`
* `stack_grobs`, `arrange_grobs`, `draw_grob`

## TLG changes

* `t_tte` now shows two rows with ranges for event and censored times,
respectively.
* `g_km` works with one arm `survfit` objects
* in forest plot functions, added formatting to display extreme values to
">999.9".
* `t_summarise_variables` uses now `n` instead of `N` as a denominator for
calculating percentages for factors by default.
* `t_rsp` now works when all response values are `TRUE` or `FALSE`

## Deprecated Functions

* `t_summarize_variables` is deprecated as `t_summary` is more powerful
* `t_summarize_by_visit` will be replaced with `t_summary_by` in an upcoming release.

# tern 0.5.0

First version where analysis functions names and arguments have been harmonized. 