# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert to numeric, handling suppression markers
#'
#' NH DOE uses various markers for suppressed data (*, <, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "n/a", "N")] <- NA_character_
  x[grepl("^<", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get available years for enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#' NH DOE iPlatform has data from approximately 2006 to present.
#' NCES CCD has data from 1986 to present.
#'
#' @return Named list with min_year and max_year
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # NH DOE iPlatform data availability
  # Historical data available from approximately 2006 onward
  # Current year data typically available after October 1
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  # If we're past October, current school year data may be available
  current_month <- as.integer(format(Sys.Date(), "%m"))
  max_year <- if (current_month >= 10) current_year + 1 else current_year

  list(
    min_year = 2006L,
    max_year = max_year,
    source = "NH DOE iPlatform",
    note = "Data availability may vary by year. Earliest consistent data is from 2006."
  )
}


#' Validate year parameter
#'
#' @param end_year Year to validate
#' @return TRUE if valid, throws error if not
#' @keywords internal
validate_year <- function(end_year) {
  avail <- get_available_years()

  if (!is.numeric(end_year) || length(end_year) != 1)
    stop("end_year must be a single numeric value")

  if (end_year < avail$min_year || end_year > avail$max_year) {
    stop(paste0(
      "end_year must be between ", avail$min_year, " and ", avail$max_year,
      "\nAvailable years: ", avail$min_year, "-", avail$max_year
    ))
  }

  TRUE
}


#' Determine format era for a given year
#'
#' NH DOE data has gone through several format changes:
#' - Era 1 (2006-2013): Original iPlatform format
#' - Era 2 (2014-2019): Updated column names
#' - Era 3 (2020-present): Current format with additional fields
#'
#' @param end_year School year end
#' @return Character string indicating the format era
#' @keywords internal
get_format_era <- function(end_year) {
  if (end_year <= 2013) {
    "era1"
  } else if (end_year <= 2019) {
    "era2"
  } else {
    "era3"
  }
}


#' Clean school/district names
#'
#' Standardizes school and district names by removing extra whitespace
#' and handling common abbreviations.
#'
#' @param x Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_names <- function(x) {
  x <- trimws(x)
  x <- gsub("\\s+", " ", x)  # Multiple spaces to single
  x
}


#' Parse NH district ID
#'
#' NH uses a district numbering system. Districts are identified by
#' SAU (School Administrative Unit) number and district code.
#'
#' @param x Character vector of district IDs
#' @return Cleaned district ID
#' @keywords internal
parse_district_id <- function(x) {
  # Ensure consistent formatting
  x <- trimws(x)
  x <- gsub("^0+", "", x)  # Remove leading zeros for matching
  x
}
