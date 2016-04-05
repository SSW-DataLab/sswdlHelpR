#' Create a "table 1" from a data.frame, a common summary table used in publications.
#'
#' This will not return a ready-to-publish table, but does most of the hard work.
#' It should be straightforward to fix up the table returned by this function.
#'
#' @param df the \code{data.frame} to summarize
#' @param dimension the name of a column in \code{df} to use as the dimensions; used to form columns of the output
#' @param overall should an overall column be generated?
#'
#' @return
#'
#' @import dplyr
#'
#' @export
table_1 <- function(df, dimension = NULL, overall = FALSE) {

  # validate df
  if (!is.data.frame(df)) stop("df must be a data.frame")
  if (sum(sapply(df, function(x) !(is.numeric(x) | is.factor(x)))) > 0) stop("all columns must be either numeric or factor columns")

  # check names, convert + warn if needed
  if (all.equal(names(df), make.names(names(df))) != TRUE) {
    warning("Found invalid names; they will be converted using make.names")
    names(df) <- make.names(names(df))
    dimension <- make.names(dimension)
  }

  # cast df to tbl if it isn't already so we can use dplyr functions
  if (!is.tbl(df)) df <- as.tbl(df)

  # select and validate dimension column
  if (is.null(dimension)) dimension <- names(df)[1]
  if (!(dimension %in% names(df))) stop("dimension must be the name of a column in df")
  if (!is.factor(magrittr::extract2(df, dimension))) stop("dimension must be a factor column")

  # warn about overall not being implemented
  if (overall) {
    warning("overall argument currently not implemented; ignoring")
  }

  # run helper function on each non-dimension column and combine
  table_1 <- df %>%
    names %>%
    setdiff(dimension) %>%  # don't apply to dimension col
    lapply(make_subtable, df, dimension, overall) %>%
    bind_rows %>%
    as.data.frame

  table_1
}


#### helper functions ####
make_subtable <- function(x, df, dimension, overall) {
  col <- magrittr::extract2(df, x)

  # dispatch appropriate function
  if (is.factor(col)) {
    subtable <- subtable_factor(x, df, dimension, overall)
  } else if (is.numeric(col)) {
    subtable <- subtable_numeric(x, df, dimension, overall)
  } else {
    stop("Column \"", x, "\" is neither factor nor numeric")
  }

  subtable
}

subtable_factor <- function(x, df, dimension, overall) {
  # create table of count/percent values, grouped by dimension and x
  subtable <- df %>%
    group_by_(.dots = c(dimension, x)) %>%
    summarise(count = n()) %>%  # drops x from grouping implicitly
    mutate(percent = trimws(format(round(count / sum(count) * 100, 1), nsmall = 1))) %>%
    ungroup %>%
    mutate_each(funs(as.character)) %>%
    mutate(percent = paste0(percent, "%"))

  # manipulate this table to be in the format we need
  subtable <- tidyr::gather_(subtable, "colname", "value", c("count", "percent"), factor_key = TRUE)
  subtable$colname <- paste(magrittr::extract2(subtable, dimension), subtable$colname, sep = "_")  # TODO: convert to mutate_
  subtable <- subtable %>%
    select_(.dots = list(x, "colname", "value")) %>%
    tidyr::spread_("colname", "value")

  # rename the first column so all tables from this function have the same columns
  names(subtable)[1] <- "variable"

  # prepend a mostly-empty row with the variable name
  subtable <- subtable %>%
    rbind(
      as_data_frame(setNames(c(x, as.list(rep("", length(names(subtable)) - 1))), names(subtable))),
      .
    )

  subtable
}

subtable_numeric <- function(x, df, dimension, overall) {

  subtable <- df %>%
    group_by_(dimension) %>%
    summarize_(.dots = setNames(list(lazyeval::interp(~round(mean(var)), var = as.name(x)), lazyeval::interp(~round(sd(var)), var = as.name(x))), c("count", "percent"))) %>%
    ungroup %>%
    mutate_each(funs(as.character))

  # manipulate this table to be in the format we need
  subtable <- tidyr::gather_(subtable, "colname", "value", c("count", "percent"), factor_key = TRUE)
  subtable$colname <- paste(magrittr::extract2(subtable, dimension), subtable$colname, sep = "_")  # TODO: convert to mutate_
  subtable <- subtable %>%
    select_(.dots = list("colname", "value")) %>%
    tidyr::spread_("colname", "value")

  # prepend variable name
  subtable <- subtable %>%
    mutate(variable = x) %>%
    select(variable, everything())

  subtable
}