% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/decorate_grob.R
\name{decorate_grob_factory}
\alias{decorate_grob_factory}
\title{Update page number}
\usage{
decorate_grob_factory(npages, ...)
}
\arguments{
\item{npages}{(\code{numeric(1)})\cr total number of pages.}

\item{...}{arguments passed on to \code{\link[=decorate_grob]{decorate_grob()}}.}
}
\value{
Closure that increments the page number.
}
\description{
Automatically updates page number.
}
\keyword{internal}
