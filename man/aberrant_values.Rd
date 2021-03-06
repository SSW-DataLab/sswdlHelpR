% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aberrant_values.R
\name{aberrant_values}
\alias{aberrant_values}
\title{Create a summary table of aberrant values of a data.frame}
\usage{
aberrant_values(df)
}
\arguments{
\item{df}{A \code{data.frame} to create a summary from}
}
\value{
A \code{tbl_df} with one row per column of \code{df} and columns \code{column}, \code{class}, \code{n_distinct}, \code{n_NA}, \code{n_not_NA}, \code{pct_NA}
}
\description{
This creates a table of the column names, types, number of unique values, and number and percentage of missing values for each column in the input.
}

