# ==============================================================================
# School Directory Data Fetching Functions
# ==============================================================================
#
# This file contains functions for downloading school directory data from the
# New Hampshire Department of Education (NH DOE) Profiles system.
#
# Data sources:
# - School List: https://my.doe.nh.gov/Profiles/PublicReports/PublicReports.aspx?ReportName=SchoolList
# - Superintendent List: https://my.doe.nh.gov/Profiles/PublicReports/PublicReports.aspx?ReportName=SupList
# - SAU List: https://my.doe.nh.gov/profiles/reports/saulist.aspx
#
# The directory includes all public schools and SAUs in New Hampshire with
# administrator names, addresses, phone numbers, grades served, and SAU
# affiliation.
#
# NOTE: The NH DOE Profiles system is behind Akamai WAF and blocks
# headless/automated HTTP requests. Live downloads may fail. Use
# import_local_directory() with manually downloaded files as a fallback.
#
# ==============================================================================

#' Fetch New Hampshire school directory data
#'
#' Downloads and processes school directory data from the New Hampshire
#' Department of Education Profiles system. This includes all public schools
#' and SAUs with contact information, addresses, and grades served.
#'
#' @param end_year Currently unused. The directory data represents the current
#'   school year. Included for API consistency with other fetch functions.
#' @param tidy If TRUE (default), returns data in a standardized format with
#'   consistent column names. If FALSE, returns raw column names from NH DOE.
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'   Set to FALSE to force re-download from NH DOE.
#' @return A tibble with school directory data. When \code{tidy = TRUE}, columns
#'   include:
#'   \itemize{
#'     \item \code{sau_number}: SAU identifier (e.g., "1", "48")
#'     \item \code{sau_name}: SAU name (e.g., "Contoocook Valley SAU Office")
#'     \item \code{state_district_id}: District identifier
#'     \item \code{district_name}: District name
#'     \item \code{state_school_id}: School identifier
#'     \item \code{school_name}: School name
#'     \item \code{entity_type}: "school", "district", or "sau"
#'     \item \code{address}: Street address
#'     \item \code{city}: City
#'     \item \code{state}: State (always "NH")
#'     \item \code{zip}: ZIP code
#'     \item \code{phone}: Phone number
#'     \item \code{grades_served}: Grade range (e.g., "K-5", "9-12")
#'     \item \code{principal_name}: Principal name (if available)
#'     \item \code{principal_email}: Principal email (if available)
#'     \item \code{superintendent_name}: Superintendent name (if available)
#'     \item \code{superintendent_email}: Superintendent email (if available)
#'     \item \code{school_type}: School type (e.g., "Public", "Charter")
#'     \item \code{county_name}: County name (if available)
#'   }
#' @details
#' The directory data is sourced from the NH DOE Profiles system, which
#' provides current information for all schools and School Administrative
#' Units (SAUs) in New Hampshire.
#'
#' Note: NH DOE Profiles is behind Akamai WAF and may block automated
#' downloads. If live download fails, the function falls back to bundled
#' data or you can use \code{\link{import_local_directory}} with manually
#' downloaded files.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get school directory data
#' dir_data <- fetch_directory()
#'
#' # Get raw format (original NH DOE column names)
#' dir_raw <- fetch_directory(tidy = FALSE)
#'
#' # Force fresh download (ignore cache)
#' dir_fresh <- fetch_directory(use_cache = FALSE)
#'
#' # Filter to charter schools
#' library(dplyr)
#' charters <- dir_data |>
#'   filter(school_type == "Charter")
#'
#' # Find all schools in a specific SAU
#' sau48 <- dir_data |>
#'   filter(sau_number == "48")
#' }
fetch_directory <- function(end_year = NULL, tidy = TRUE, use_cache = TRUE) {

  # Determine cache type based on tidy parameter
  cache_type <- if (tidy) "directory_tidy" else "directory_raw"

  # Check cache first
  if (use_cache && cache_exists_directory(cache_type)) {
    message("Using cached school directory data")
    return(read_cache_directory(cache_type))
  }

  # Get raw data from NH DOE
  raw <- get_raw_directory()

  # Process to standard schema
  if (tidy) {
    result <- process_directory(raw)
  } else {
    result <- raw
  }

  # Cache the result
  if (use_cache) {
    write_cache_directory(result, cache_type)
  }

  result
}


#' Get raw school directory data from NH DOE
#'
#' Downloads the raw school directory data from the New Hampshire Department
#' of Education Profiles system. Tries live download first, then falls back
#' to bundled data.
#'
#' @return Raw data frame as downloaded from NH DOE
#' @keywords internal
get_raw_directory <- function() {

  # Try bundled data first (preferred - NH DOE Profiles requires browser access)
  bundled <- load_bundled_directory()
  if (!is.null(bundled)) {
    message("Loading bundled NH DOE directory data...")
    return(bundled)
  }

  # Try live download from NH DOE Profiles
  message("Attempting to download school directory data from NH DOE...")
  message("  Note: NH DOE Profiles system may block automated downloads (Akamai WAF).")

  df <- tryCatch(
    download_nhdoe_school_list(),
    error = function(e) {
      message("  Live download failed: ", e$message)
      NULL
    }
  )

  if (!is.null(df) && nrow(df) > 0) {
    message(paste("  Downloaded", nrow(df), "school records"))
    return(dplyr::as_tibble(df))
  }

  # If live download failed and no bundled data, provide instructions
  message("  No directory data available.")
  message("  NH DOE Profiles requires browser-based access. Visit:")
  message("  https://my.doe.nh.gov/Profiles/PublicReports/PublicReports.aspx?ReportName=SchoolList")
  message("  Then use import_local_directory() to load the downloaded file.")

  stop("Could not retrieve directory data. See messages above for instructions.")
}


#' Download school list from NH DOE Profiles
#'
#' Attempts to download the School List report from the NH DOE Profiles
#' system. This may fail due to Akamai WAF protection.
#'
#' @return Data frame with school directory data
#' @keywords internal
download_nhdoe_school_list <- function() {

  url <- build_directory_url()

  # Create temp file
  tname <- tempfile(
    pattern = "nhdoe_directory_",
    tmpdir = tempdir(),
    fileext = ".html"
  )

  # Try to download with browser-like headers
  response <- tryCatch({
    httr::GET(
      url,
      httr::user_agent(
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
      ),
      httr::add_headers(
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language" = "en-US,en;q=0.5"
      ),
      httr::write_disk(tname, overwrite = TRUE),
      httr::timeout(120)
    )
  }, error = function(e) {
    unlink(tname)
    stop("Failed to connect to NH DOE Profiles: ", e$message)
  })

  # Check response
  if (httr::http_error(response)) {
    unlink(tname)
    stop("HTTP error ", httr::status_code(response), " accessing NH DOE Profiles")
  }

  # Check content type - if HTML, try to parse as table
  content_type <- httr::headers(response)[["content-type"]]
  file_size <- file.info(tname)$size

  if (file_size < 1000) {
    unlink(tname)
    stop("Response too small - likely a redirect or error page")
  }

  # Try to determine if we got data or an HTML page
  content <- readLines(tname, n = 5, warn = FALSE)
  content_text <- paste(content, collapse = " ")

  # If we got an Excel or CSV file, try to read it
  if (!grepl("<html|<!DOCTYPE", content_text, ignore.case = TRUE)) {
    # Try as CSV
    df <- tryCatch({
      readr::read_csv(
        tname,
        col_types = readr::cols(.default = readr::col_character()),
        show_col_types = FALSE
      )
    }, error = function(e) {
      # Try as Excel
      tryCatch({
        readxl::read_excel(tname, col_types = "text")
      }, error = function(e2) {
        NULL
      })
    })

    unlink(tname)

    if (!is.null(df) && nrow(df) > 0) {
      return(df)
    }
  }

  unlink(tname)
  stop("NH DOE returned HTML page - Profiles requires browser access (Akamai WAF)")
}


#' Build NH DOE school directory download URL
#'
#' Constructs the URL for the School List report from the NH DOE Profiles
#' system.
#'
#' @return URL string
#' @keywords internal
build_directory_url <- function() {
  # NH DOE Profiles - School List report
  "https://my.doe.nh.gov/Profiles/PublicReports/PublicReports.aspx?ReportName=SchoolList"
}


#' Process raw school directory data to standard schema
#'
#' Takes raw school directory data from NH DOE and standardizes column names,
#' types, and adds derived columns.
#'
#' @param raw_data Raw data frame from get_raw_directory()
#' @return Processed data frame with standard schema
#' @keywords internal
process_directory <- function(raw_data) {

  # Standardize column names to uppercase for consistent matching
  col_names <- toupper(names(raw_data))
  names(raw_data) <- col_names

  # Map raw columns to standard schema
  # NH DOE uses various column names depending on the export format
  result <- dplyr::tibble(
    sau_number = extract_column(raw_data, c("SAU", "SAU_NUMBER", "SAU_ID",
                                             "SAUID", "SAU #", "SAU#")),
    sau_name = extract_column(raw_data, c("SAU_NAME", "SAUNAME", "SAU NAME")),
    state_district_id = extract_column(raw_data, c("DISTRICT_ID", "DISTRICTID",
                                                     "DST_ID", "DSTID",
                                                     "DIST_ID", "DISTRICT ID")),
    district_name = extract_column(raw_data, c("DISTRICT_NAME", "DISTRICTNAME",
                                                 "DST_NAME", "DSTNAME",
                                                 "DISTRICT NAME", "DST NAME")),
    state_school_id = extract_column(raw_data, c("SCHOOL_ID", "SCHOOLID",
                                                   "SCH_ID", "SCHID",
                                                   "SCHOOL ID", "SCH ID")),
    school_name = extract_column(raw_data, c("SCHOOL_NAME", "SCHOOLNAME",
                                               "SCH_NAME", "SCHNAME",
                                               "SCHOOL NAME", "SCH NAME")),
    entity_type = "school",
    address = extract_column(raw_data, c("ADDRESS", "SCHOOL_ADDRESS",
                                           "STREET_ADDRESS", "STREET ADDRESS",
                                           "SCHOOL ADDRESS")),
    city = extract_column(raw_data, c("CITY", "SCHOOL_CITY", "TOWN",
                                        "SCHOOL CITY")),
    state = "NH",
    zip = extract_column(raw_data, c("ZIP", "ZIPCODE", "ZIP_CODE",
                                       "SCHOOL_ZIP", "ZIP CODE",
                                       "SCHOOL ZIP")),
    phone = extract_column(raw_data, c("PHONE", "TELEPHONE", "PHONE_NUMBER",
                                         "SCHOOL_PHONE", "PHONE NUMBER",
                                         "SCHOOL PHONE")),
    grades_served = extract_column(raw_data, c("GRADES", "GRADES_SERVED",
                                                 "GRADE_RANGE", "GRADE RANGE",
                                                 "GRADES SERVED")),
    principal_name = extract_column(raw_data, c("PRINCIPAL", "PRINCIPAL_NAME",
                                                  "PRINCIPAL NAME")),
    principal_email = extract_column(raw_data, c("PRINCIPAL_EMAIL",
                                                   "PRINCIPAL EMAIL")),
    superintendent_name = extract_column(raw_data, c("SUPERINTENDENT",
                                                       "SUPERINTENDENT_NAME",
                                                       "SUPERINTENDENT NAME",
                                                       "SUPT", "SUPT_NAME")),
    superintendent_email = extract_column(raw_data, c("SUPERINTENDENT_EMAIL",
                                                        "SUPERINTENDENT EMAIL",
                                                        "SUPT_EMAIL")),
    school_type = extract_column(raw_data, c("SCHOOL_TYPE", "SCHOOLTYPE",
                                               "TYPE", "FACILITY_TYPE",
                                               "SCHOOL TYPE")),
    county_name = extract_column(raw_data, c("COUNTY", "COUNTY_NAME",
                                               "COUNTY NAME"))
  )

  # Clean up whitespace
  result <- dplyr::mutate(result, dplyr::across(
    dplyr::where(is.character),
    ~ trimws(.)
  ))

  # Derive school_type from school_name if not available
  if (all(is.na(result$school_type))) {
    result$school_type <- dplyr::case_when(
      grepl("Charter|Chartered", result$school_name, ignore.case = TRUE) ~ "Charter",
      grepl("Virtual|Online", result$school_name, ignore.case = TRUE) ~ "Virtual",
      TRUE ~ "Public"
    )
  }

  result
}


#' Extract a column using multiple possible names
#'
#' Searches for a column in the data frame using several possible name variants.
#' Returns NA if none of the names match.
#'
#' @param df Data frame to search
#' @param possible_names Character vector of possible column names
#' @return Character vector from the matched column, or NA vector
#' @keywords internal
extract_column <- function(df, possible_names) {
  for (name in possible_names) {
    if (name %in% names(df)) {
      return(as.character(df[[name]]))
    }
  }
  rep(NA_character_, nrow(df))
}


#' Import local directory file
#'
#' Imports school directory data from a locally downloaded file. Use this
#' function as a fallback when automated download from NH DOE Profiles fails.
#'
#' Visit the NH DOE Profiles to download the school list manually:
#' \url{https://my.doe.nh.gov/Profiles/PublicReports/PublicReports.aspx?ReportName=SchoolList}
#'
#' @param file_path Path to downloaded Excel or CSV file
#' @return Data frame with directory data
#' @export
#' @examples
#' \dontrun{
#' # Download file manually from NH DOE Profiles, then:
#' df <- import_local_directory("~/Downloads/school-list.xlsx")
#'
#' # Process to tidy format
#' tidy_df <- process_directory(df)
#' }
import_local_directory <- function(file_path) {

  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Determine file type and read
  ext <- tolower(tools::file_ext(file_path))

  if (ext %in% c("xlsx", "xls")) {
    df <- readxl::read_excel(file_path, col_types = "text")
  } else if (ext == "csv") {
    df <- readr::read_csv(
      file_path,
      col_types = readr::cols(.default = readr::col_character()),
      show_col_types = FALSE
    )
  } else {
    stop("Unsupported file type: ", ext, ". Use .xlsx, .xls, or .csv")
  }

  message("Imported ", nrow(df), " rows from ", basename(file_path))

  dplyr::as_tibble(df)
}


#' Load bundled directory data
#'
#' Loads the bundled directory data from the package. This is the primary
#' data source since the NH DOE Profiles system requires browser-based
#' downloads that cannot be automated.
#'
#' @return Data frame with directory data, or NULL if not available
#' @keywords internal
load_bundled_directory <- function() {

  dir_file <- system.file("extdata", "nh_directory.rds",
                           package = "nhschooldata")

  if (dir_file == "") {
    return(NULL)
  }

  tryCatch(
    readRDS(dir_file),
    error = function(e) NULL
  )
}


# ==============================================================================
# Directory-specific cache functions
# ==============================================================================

#' Build cache file path for directory data
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return File path string
#' @keywords internal
build_cache_path_directory <- function(cache_type) {
  cache_dir <- get_cache_dir()
  file.path(cache_dir, paste0(cache_type, ".rds"))
}


#' Check if cached directory data exists
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @param max_age Maximum age in days (default 7). Set to Inf to ignore age.
#' @return Logical indicating if valid cache exists
#' @keywords internal
cache_exists_directory <- function(cache_type, max_age = 7) {
  cache_path <- build_cache_path_directory(cache_type)

  if (!file.exists(cache_path)) {
    return(FALSE)
  }

  # Check age
  file_info <- file.info(cache_path)
  age_days <- as.numeric(difftime(Sys.time(), file_info$mtime, units = "days"))

  age_days <= max_age
}


#' Read directory data from cache
#'
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Cached data frame
#' @keywords internal
read_cache_directory <- function(cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  readRDS(cache_path)
}


#' Write directory data to cache
#'
#' @param data Data frame to cache
#' @param cache_type Type of cache ("directory_tidy" or "directory_raw")
#' @return Invisibly returns the cache path
#' @keywords internal
write_cache_directory <- function(data, cache_type) {
  cache_path <- build_cache_path_directory(cache_type)
  cache_dir <- dirname(cache_path)

  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }

  saveRDS(data, cache_path)
  invisible(cache_path)
}


#' Clear school directory cache
#'
#' Removes cached school directory data files.
#'
#' @return Invisibly returns the number of files removed
#' @export
#' @examples
#' \dontrun{
#' # Clear cached directory data
#' clear_directory_cache()
#' }
clear_directory_cache <- function() {
  cache_dir <- get_cache_dir()

  if (!dir.exists(cache_dir)) {
    message("Cache directory does not exist")
    return(invisible(0))
  }

  files <- list.files(cache_dir, pattern = "^directory_", full.names = TRUE)

  if (length(files) > 0) {
    file.remove(files)
    message(paste("Removed", length(files), "cached directory file(s)"))
  } else {
    message("No cached directory files to remove")
  }

  invisible(length(files))
}
