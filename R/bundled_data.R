# ==============================================================================
# Bundled Data Functions
# ==============================================================================
#
# This file contains functions for loading bundled enrollment data.
# The NH DOE iPlatform requires browser-based access (Akamai WAF blocks
# headless HTTP). Real data was downloaded via headed Playwright and bundled
# in inst/extdata/.
#
# Bundled data covers 2012-2026 (15 years):
#   nh_enrollment_districts.rds — ~200 districts/year, aggregated grades
#   nh_enrollment_schools.rds — ~500 schools/year, individual grades PK-12
#
# ==============================================================================

#' Load bundled enrollment data
#'
#' Loads the bundled enrollment data from the package.
#' This is the primary data source since the NH DOE iPlatform
#' requires browser-based downloads that cannot be automated.
#'
#' @param end_year School year end (2015-2025)
#' @return List with school and district data frames, or NULL if not available
#' @keywords internal
load_bundled_enr <- function(end_year) {

  district_file <- system.file("extdata", "nh_enrollment_districts.rds",
                               package = "nhschooldata")
  school_file <- system.file("extdata", "nh_enrollment_schools.rds",
                             package = "nhschooldata")

  if (district_file == "" || school_file == "") {
    return(NULL)
  }

  district_data <- tryCatch(
    readRDS(district_file),
    error = function(e) NULL
  )

  school_data <- tryCatch(
    readRDS(school_file),
    error = function(e) NULL
  )

  if (is.null(district_data) || is.null(school_data)) {
    return(NULL)
  }

  # Filter to requested year
  district_yr <- district_data[district_data$end_year == end_year, ]
  school_yr <- school_data[school_data$end_year == end_year, ]

  if (nrow(district_yr) == 0 && nrow(school_yr) == 0) {
    return(NULL)
  }

  list(
    district = district_yr,
    school = school_yr
  )
}


#' Check if bundled data is available for a year
#'
#' @param end_year School year end
#' @return TRUE if bundled data exists for the year
#' @keywords internal
bundled_data_available <- function(end_year) {

  district_file <- system.file("extdata", "nh_enrollment_districts.rds",
                               package = "nhschooldata")

  if (district_file == "") return(FALSE)

  tryCatch({
    district_data <- readRDS(district_file)
    end_year %in% unique(district_data$end_year)
  }, error = function(e) FALSE)
}


#' Get years available in bundled data
#'
#' @return Integer vector of available years, or NULL if no bundled data
#' @keywords internal
get_bundled_years <- function() {

  district_file <- system.file("extdata", "nh_enrollment_districts.rds",
                               package = "nhschooldata")

  if (district_file == "") return(NULL)

  tryCatch({
    district_data <- readRDS(district_file)
    sort(unique(district_data$end_year))
  }, error = function(e) NULL)
}
