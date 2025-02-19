% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/filter_predicates.R
\name{check_filter_value}
\alias{check_filter_value}
\title{Check filter value}
\usage{
check_filter_value(value)
}
\arguments{
\item{value}{value of a basic filter predicate}
}
\value{
\code{TRUE} or an error message
}
\description{
Check that the value argument in a filter predicate has length one and it is
one of the supported types. This is required for basic filter predicates.
}
\examples{
\dontrun{
check_filter_value("b")
check_filter_value(5)
# this returns an error message
check_filter_value(list(5))
}
}
\keyword{internal}
