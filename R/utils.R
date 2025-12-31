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
#' Returns the range of years for which enrollment data is available
#' from the New Hampshire Department of Education.
#'
#' NH DOE iPlatform provides enrollment data for approximately the
#' current year plus 10 prior years. Data availability may vary.
#'
#' @return Named list with min_year, max_year, source, and note
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  # NH DOE iPlatform data availability
  # The iPlatform provides enrollment reports dating back approximately 10 years
  # Data is collected on October 1 of each school year
  #
  # Note: Exact historical availability varies by report type

  current_year <- as.integer(format(Sys.Date(), "%Y"))
  current_month <- as.integer(format(Sys.Date(), "%m"))

  # NH DOE releases fall enrollment data after October 1
  # Data for current school year is typically available by late fall
  if (current_month >= 11) {
    # After November: current school year data likely available
    max_year <- current_year + 1
  } else if (current_month >= 9) {
    # September-October: current year data being collected
    max_year <- current_year
  } else {
    # January-August: previous school year is most recent
    max_year <- current_year
  }

  # iPlatform typically provides about 10 years of historical data
  min_year <- max_year - 10

  list(
    min_year = min_year,
    max_year = max_year,
    source = "New Hampshire Department of Education iPlatform",
    note = paste0(
      "Data availability: ", min_year, "-", max_year, ". ",
      "NH DOE iPlatform provides approximately 10 years of historical data. ",
      "Enrollment is measured on October 1 of each school year. ",
      "Access data at: https://my.doe.nh.gov/iPlatform"
    )
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


#' Format school year for display
#'
#' Converts an end year integer to a display format (e.g., 2024 -> "2023-24").
#'
#' @param end_year Integer end year
#' @return Character string in "YYYY-YY" format
#' @keywords internal
format_school_year <- function(end_year) {
  start_year <- end_year - 1
  end_short <- end_year %% 100
  paste0(start_year, "-", sprintf("%02d", end_short))
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
