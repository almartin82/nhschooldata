# ==============================================================================
# Bundled Data Functions
# ==============================================================================
#
# This file contains functions for loading bundled enrollment data.
# The NH DOE iPlatform requires browser-based access, so we bundle
# static data files that match published NH DOE figures.
#
# Data Sources:
# - nh_enrollment_districts.rds: District-level enrollment 2015-2025
# - nh_enrollment_schools.rds: School-level enrollment 2015-2025
#
# State totals match NH DOE press releases:
# - "Student enrollment continues to slide in the Granite State" (2025)
# - "New Hampshire adapts to changing student population" (2024)
# - Reaching Higher NH analysis of NH DOE data (2022, 2023)
#
# ==============================================================================

#' Load bundled enrollment data
#'
#' Loads the bundled enrollment data from the package.
#' This is the primary data source since the NH DOE iPlatform
#' requires browser-based downloads that cannot be automated.
#'
#' @param end_year School year end (2015-2025)
#' @return List with school and district data frames
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
