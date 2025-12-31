# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from
# the New Hampshire Department of Education (NH DOE).
#
# Data source:
# - NH DOE iPlatform Public Reports: https://my.doe.nh.gov/iPlatform
#
# NH DOE provides enrollment data through their iPlatform reporting system,
# which uses SQL Server Reporting Services (SSRS). Reports can be exported
# via URL parameters.
#
# Available enrollment reports:
# - District Fall Enrollment: Pre-K through 12 by district
# - Public School Enrollments by Grade: School-level enrollment
# - Enrollments by Grade: Various breakdowns (county, town, etc.)
#
# Data is typically available for the current year plus several prior years.
# Historical data availability varies by report type.
#
# ==============================================================================

#' Download raw enrollment data from NH DOE
#'
#' Downloads enrollment data from the New Hampshire Department of Education
#' iPlatform reporting system. Data includes district and school-level
#' enrollment by grade.
#'
#' @param end_year School year end (2023-24 = 2024). Valid range determined
#'   by NH DOE data availability.
#' @return List with school and district data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  validate_year(end_year)

  message(paste("Downloading NH DOE enrollment data for", end_year, "..."))

  # Download district-level enrollment data
  message("  Downloading district enrollment data...")
  district_data <- download_nhdoe_district_enrollment(end_year)

  # Download school-level enrollment data
  message("  Downloading school enrollment data...")
  school_data <- download_nhdoe_school_enrollment(end_year)

  # Add end_year column
  if (!is.null(district_data) && nrow(district_data) > 0) {
    district_data$end_year <- end_year
  }
  if (!is.null(school_data) && nrow(school_data) > 0) {
    school_data$end_year <- end_year
  }

  list(
    school = school_data,
    district = district_data
  )
}


#' Download district enrollment data from NH DOE iPlatform
#'
#' Downloads the District Fall Enrollment report from NH DOE iPlatform.
#' The report includes enrollment by grade level for all districts.
#'
#' @param end_year School year end
#' @return Data frame with district enrollment data
#' @keywords internal
download_nhdoe_district_enrollment <- function(end_year) {


  # NH DOE iPlatform uses SSRS for reports

  # The District Fall Enrollment report path:
  # /BDMQ/iPlatform+Reports/Enrollment+Data/Enrollment+Reports/District+Fall+Enrollments
  #
  # SSRS reports can be exported using URL parameters:
  # - rs:Format=EXCELOPENXML for Excel format
  # - rs:Format=CSV for CSV format
  #
  # However, the iPlatform may require session cookies or have restrictions.
  # We'll try multiple approaches.

  # Format school year for NH DOE (e.g., "2023-2024" for end_year 2024)
  school_year <- format_school_year(end_year)

  # Try the iPlatform report URL with Excel export
  # Note: This may be blocked without proper session handling
  report_base <- "https://my.doe.nh.gov/iPlatform/Report/Report"
  report_path <- "/BDMQ/iPlatform+Reports/Enrollment+Data/Enrollment+Reports/District+Fall+Enrollments"

  # Try to access the report
  df <- tryCatch({
    download_iplatform_report(report_base, report_path, end_year, "district")
  }, error = function(e) {
    message("  Note: Direct iPlatform access failed: ", e$message)
    NULL
  })

  if (!is.null(df) && nrow(df) > 0) {
    return(df)
  }

  # Fallback: Try to access static files that NH DOE may publish
  df <- download_nhdoe_static_enrollment(end_year, "district")

  if (!is.null(df) && nrow(df) > 0) {
    return(df)
  }

  # If all else fails, return empty data frame with message
  message("  Warning: Could not download district enrollment data for ", end_year)
  message("  NH DOE iPlatform may require browser access. Visit:")
  message("  https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9")
  create_empty_nhdoe_df("district")
}


#' Download school enrollment data from NH DOE iPlatform
#'
#' Downloads the Public School Enrollments by Grade report from NH DOE iPlatform.
#'
#' @param end_year School year end
#' @return Data frame with school enrollment data
#' @keywords internal
download_nhdoe_school_enrollment <- function(end_year) {

  # Format school year
  school_year <- format_school_year(end_year)

  # Try iPlatform report
  report_base <- "https://my.doe.nh.gov/iPlatform/Report/Report"
  report_path <- "/BDMQ/iPlatform+Reports/Enrollment+Data/Enrollments+by+Grade/Public+School+Enrollments+by+Grade"

  df <- tryCatch({
    download_iplatform_report(report_base, report_path, end_year, "school")
  }, error = function(e) {
    message("  Note: Direct iPlatform access failed: ", e$message)
    NULL
  })

  if (!is.null(df) && nrow(df) > 0) {
    return(df)
  }

  # Fallback: Try static files
  df <- download_nhdoe_static_enrollment(end_year, "school")

  if (!is.null(df) && nrow(df) > 0) {
    return(df)
  }

  message("  Warning: Could not download school enrollment data for ", end_year)
  message("  NH DOE iPlatform may require browser access. Visit:")
  message("  https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10")
  create_empty_nhdoe_df("school")
}


#' Download report from NH DOE iPlatform
#'
#' Attempts to download a report from the NH DOE iPlatform SSRS system.
#'
#' @param report_base Base URL for reports
#' @param report_path Path to specific report
#' @param end_year School year end
#' @param level "district" or "school"
#' @return Data frame with enrollment data
#' @keywords internal
download_iplatform_report <- function(report_base, report_path, end_year, level) {

  # Build the report URL
  # iPlatform uses query parameters for report selection
  report_url <- paste0(
    report_base,
    "?path=", utils::URLencode(report_path, reserved = TRUE),
    "&name=", if (level == "district") "District+Fall+Enrollment" else "Public+School+Enrollments+by+Grade",
    "&categoryName=", if (level == "district") "Enrollment+Reports" else "Enrollments+by+Grade",
    "&categoryId=", if (level == "district") "9" else "10"
  )

  # Create temp file
  tname <- tempfile(
    pattern = paste0("nh_", level, "_enrollment_"),
    tmpdir = tempdir(),
    fileext = ".xlsx"
  )

  # Try to download with various user agents and headers
  response <- tryCatch({
    httr::GET(
      report_url,
      httr::user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"),
      httr::add_headers(
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language" = "en-US,en;q=0.5"
      ),
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(120)
    )
  }, error = function(e) {
    stop("Failed to connect to NH DOE iPlatform: ", e$message)
  })

  # Check response
  if (httr::http_error(response)) {
    unlink(tname)
    stop("HTTP error ", httr::status_code(response), " accessing iPlatform")
  }

  # Check if we got an actual data file vs HTML page
  file_size <- file.info(tname)$size
  if (file_size < 5000) {
    content <- readLines(tname, n = 20, warn = FALSE)
    content_text <- paste(content, collapse = " ")

    if (grepl("<html|<!DOCTYPE", content_text, ignore.case = TRUE)) {
      unlink(tname)
      stop("Received HTML page instead of data file - iPlatform may require authentication")
    }
  }

  # Try to read as Excel
  df <- tryCatch({
    readxl::read_excel(tname, col_types = "text")
  }, error = function(e) {
    # Try as CSV
    tryCatch({
      readr::read_csv(tname, col_types = readr::cols(.default = readr::col_character()),
                      show_col_types = FALSE)
    }, error = function(e2) {
      unlink(tname)
      stop("Could not parse downloaded file as Excel or CSV")
    })
  })

  unlink(tname)

  # Standardize column names
  names(df) <- toupper(names(df))

  df
}


#' Download NH DOE static enrollment files
#'
#' Attempts to download enrollment data from static files that NH DOE
#' may publish on their website.
#'
#' @param end_year School year end
#' @param level "district" or "school"
#' @return Data frame with enrollment data, or NULL if not available
#' @keywords internal
download_nhdoe_static_enrollment <- function(end_year, level) {

  # NH DOE sometimes publishes static Excel files
  # Common patterns seen on education.nh.gov/sites/g/files/

  school_year_short <- paste0(
    substr(as.character(end_year - 1), 3, 4),
    substr(as.character(end_year), 3, 4)
  )

  # Build list of potential URLs to try
  base_urls <- c(
    "https://www.education.nh.gov/sites/g/files/ehbemt326/files/inline-documents/sonh/",
    "https://www.education.nh.gov/sites/g/files/ehbemt326/files/inline-documents/"
  )

  potential_files <- c(
    paste0("fall_enrollment_", school_year_short, ".xlsx"),
    paste0("fall-enrollment-", school_year_short, ".xlsx"),
    paste0("enrollment_", end_year, ".xlsx"),
    paste0("enrollment-", end_year, ".xlsx"),
    paste0(level, "_enrollment_", school_year_short, ".xlsx"),
    paste0(level, "-enrollment-", school_year_short, ".xlsx")
  )

  # Try each combination
  for (base_url in base_urls) {
    for (filename in potential_files) {
      url <- paste0(base_url, filename)

      tname <- tempfile(fileext = ".xlsx")

      result <- tryCatch({
        response <- httr::GET(
          url,
          httr::write_disk(tname, overwrite = TRUE),
          httr::timeout(30),
          httr::user_agent("nhschooldata R package")
        )

        if (!httr::http_error(response) && file.info(tname)$size > 1000) {
          df <- readxl::read_excel(tname, col_types = "text")
          names(df) <- toupper(names(df))
          unlink(tname)
          return(df)
        }
        unlink(tname)
        NULL
      }, error = function(e) {
        unlink(tname)
        NULL
      })

      if (!is.null(result)) {
        return(result)
      }
    }
  }

  NULL
}


#' Create empty NH DOE data frame
#'
#' Creates an empty data frame with expected NH DOE column structure.
#'
#' @param level "school" or "district"
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_nhdoe_df <- function(level = "school") {
  if (level == "school") {
    data.frame(
      SCHOOL_ID = character(),
      SCHOOL_NAME = character(),
      DISTRICT_ID = character(),
      DISTRICT_NAME = character(),
      SAU = character(),
      PREK = integer(),
      K = integer(),
      G01 = integer(),
      G02 = integer(),
      G03 = integer(),
      G04 = integer(),
      G05 = integer(),
      G06 = integer(),
      G07 = integer(),
      G08 = integer(),
      G09 = integer(),
      G10 = integer(),
      G11 = integer(),
      G12 = integer(),
      TOTAL = integer(),
      end_year = integer(),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(
      DISTRICT_ID = character(),
      DISTRICT_NAME = character(),
      SAU = character(),
      PREK = integer(),
      K = integer(),
      ELEMENTARY = integer(),
      MIDDLE = integer(),
      HIGH_SCHOOL = integer(),
      TOTAL = integer(),
      end_year = integer(),
      stringsAsFactors = FALSE
    )
  }
}


#' Import local enrollment file
#'
#' Imports enrollment data from a locally downloaded file. Use this function
#' as a fallback when automated download from NH DOE iPlatform fails.
#'
#' Visit the NH DOE iPlatform to download enrollment data manually:
#' - District enrollment: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9
#' - School enrollment: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10
#'
#' @param file_path Path to downloaded Excel or CSV file
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @param level Either "school" or "district"
#' @return Data frame with enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Download file manually from NH DOE iPlatform, then:
#' df <- import_local_enrollment("~/Downloads/district-fall-enrollment.xlsx", 2024, "district")
#' }
import_local_enrollment <- function(file_path, end_year, level = "school") {

  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Determine file type and read
  ext <- tolower(tools::file_ext(file_path))

  if (ext %in% c("xlsx", "xls")) {
    df <- readxl::read_excel(file_path, col_types = "text")
  } else if (ext == "csv") {
    df <- readr::read_csv(file_path,
                          col_types = readr::cols(.default = readr::col_character()),
                          show_col_types = FALSE)
  } else {
    stop("Unsupported file type: ", ext, ". Use .xlsx, .xls, or .csv")
  }

  # Standardize column names
  names(df) <- toupper(names(df))

  # Add end_year
  df$end_year <- end_year

  message("Imported ", nrow(df), " rows from ", basename(file_path))

  df
}
