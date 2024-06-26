% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/h_survival_biomarkers_subgroups.R
\name{h_survival_biomarkers_subgroups}
\alias{h_survival_biomarkers_subgroups}
\alias{h_surv_to_coxreg_variables}
\alias{h_coxreg_mult_cont_df}
\alias{h_tab_surv_one_biomarker}
\title{Helper functions for tabulating biomarker effects on survival by subgroup}
\usage{
h_surv_to_coxreg_variables(variables, biomarker)

h_coxreg_mult_cont_df(variables, data, control = control_coxreg())

h_tab_surv_one_biomarker(
  df,
  vars,
  time_unit,
  na_str = default_na_str(),
  .indent_mods = 0L,
  ...
)
}
\arguments{
\item{variables}{(named \code{list} of \code{string})\cr list of additional analysis variables.}

\item{biomarker}{(\code{string})\cr the name of the biomarker variable.}

\item{data}{(\code{data.frame})\cr the dataset containing the variables to summarize.}

\item{control}{(\code{list})\cr a list of parameters as returned by the helper function \code{\link[=control_coxreg]{control_coxreg()}}.}

\item{df}{(\code{data.frame})\cr results for a single biomarker, as part of what is
returned by \code{\link[=extract_survival_biomarkers]{extract_survival_biomarkers()}} (it needs a couple of columns which are
added by that high-level function relative to what is returned by \code{\link[=h_coxreg_mult_cont_df]{h_coxreg_mult_cont_df()}},
see the example).}

\item{vars}{(\code{character})\cr the names of statistics to be reported among:
\itemize{
\item \code{n_tot_events}: Total number of events per group.
\item \code{n_tot}: Total number of observations per group.
\item \code{median}: Median survival time.
\item \code{hr}: Hazard ratio.
\item \code{ci}: Confidence interval of hazard ratio.
\item \code{pval}: p-value of the effect.
Note, one of the statistics \code{n_tot} and \code{n_tot_events}, as well as both \code{hr} and \code{ci} are required.
}}

\item{time_unit}{(\code{string})\cr label with unit of median survival time. Default \code{NULL} skips displaying unit.}

\item{na_str}{(\code{string})\cr string used to replace all \code{NA} or empty values in the output.}

\item{.indent_mods}{(named \code{integer})\cr indent modifiers for the labels. Defaults to 0, which corresponds to the
unmodified default behavior. Can be negative.}

\item{...}{additional arguments for the lower level functions.}
}
\value{
\itemize{
\item \code{h_surv_to_coxreg_variables()} returns a named \code{list} of elements \code{time}, \code{event}, \code{arm},
\code{covariates}, and \code{strata}.
}

\itemize{
\item \code{h_coxreg_mult_cont_df()} returns a \code{data.frame} containing estimates and statistics for the selected biomarkers.
}

\itemize{
\item \code{h_tab_surv_one_biomarker()} returns an \code{rtables} table object with the given statistics arranged in columns.
}
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#stable}{\figure{lifecycle-stable.svg}{options: alt='[Stable]'}}}{\strong{[Stable]}}

Helper functions which are documented here separately to not confuse the user
when reading about the user-facing functions.
}
\section{Functions}{
\itemize{
\item \code{h_surv_to_coxreg_variables()}: Helps with converting the "survival" function variable list
to the "Cox regression" variable list. The reason is that currently there is an inconsistency between the variable
names accepted by \code{extract_survival_subgroups()} and \code{fit_coxreg_multivar()}.

\item \code{h_coxreg_mult_cont_df()}: Prepares estimates for number of events, patients and median survival
times, as well as hazard ratio estimates, confidence intervals and p-values, for multiple biomarkers
in a given single data set.
\code{variables} corresponds to names of variables found in \code{data}, passed as a named list and requires elements
\code{tte}, \code{is_event}, \code{biomarkers} (vector of continuous biomarker variables) and optionally \code{subgroups} and \code{strata}.

\item \code{h_tab_surv_one_biomarker()}: Prepares a single sub-table given a \code{df_sub} containing
the results for a single biomarker.

}}
\examples{
library(dplyr)
library(forcats)

adtte <- tern_ex_adtte

# Save variable labels before data processing steps.
adtte_labels <- formatters::var_labels(adtte, fill = FALSE)

adtte_f <- adtte \%>\%
  filter(PARAMCD == "OS") \%>\%
  mutate(
    AVALU = as.character(AVALU),
    is_event = CNSR == 0
  )
labels <- c("AVALU" = adtte_labels[["AVALU"]], "is_event" = "Event Flag")
formatters::var_labels(adtte_f)[names(labels)] <- labels

# This is how the variable list is converted internally.
h_surv_to_coxreg_variables(
  variables = list(
    tte = "AVAL",
    is_event = "EVNT",
    covariates = c("A", "B"),
    strata = "D"
  ),
  biomarker = "AGE"
)

# For a single population, estimate separately the effects
# of two biomarkers.
df <- h_coxreg_mult_cont_df(
  variables = list(
    tte = "AVAL",
    is_event = "is_event",
    biomarkers = c("BMRKR1", "AGE"),
    covariates = "SEX",
    strata = c("STRATA1", "STRATA2")
  ),
  data = adtte_f
)
df

# If the data set is empty, still the corresponding rows with missings are returned.
h_coxreg_mult_cont_df(
  variables = list(
    tte = "AVAL",
    is_event = "is_event",
    biomarkers = c("BMRKR1", "AGE"),
    covariates = "REGION1",
    strata = c("STRATA1", "STRATA2")
  ),
  data = adtte_f[NULL, ]
)

# Starting from above `df`, zoom in on one biomarker and add required columns.
df1 <- df[1, ]
df1$subgroup <- "All patients"
df1$row_type <- "content"
df1$var <- "ALL"
df1$var_label <- "All patients"
h_tab_surv_one_biomarker(
  df1,
  vars = c("n_tot", "n_tot_events", "median", "hr", "ci", "pval"),
  time_unit = "days"
)

}
