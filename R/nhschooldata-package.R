#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' nhschooldata: Fetch and Process New Hampshire School Enrollment Data
#'
#' An R package for downloading and processing school enrollment data from the
#' New Hampshire Department of Education (NH DOE). Provides functions for
#' fetching enrollment data from the iPlatform reporting system and NCES Common
#' Core of Data, transforming it into tidy format for analysis.
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Download enrollment data for a single year}
#'   \item{\code{\link{fetch_enr_multi}}}{Download enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide enrollment data to long format}
#'   \item{\code{\link{get_available_years}}}{Get the range of available years}
#' }
#'
#' @section Data Sources:
#' Data is sourced from:
#' \itemize{
#'   \item NH DOE iPlatform (my.doe.nh.gov/iPlatform): 2006-present
#'   \item NCES Common Core of Data (CCD): Federal dataset backup
#' }
#'
#' @section New Hampshire School System:
#' New Hampshire's school system includes:
#' \itemize{
#'   \item Approximately 162 school districts
#'   \item 456 public schools
#'   \item School Administrative Units (SAUs) that may cover multiple districts
#'   \item Public charter schools
#'   \item Approximately 165,000 students enrolled (2024)
#' }
#'
#' @section Identifier System:
#' \itemize{
#'   \item NCES LEA ID: 7-digit federal district identifier (e.g., 3300390)
#'   \item NCES School ID: 12-digit federal school identifier
#'   \item SAU Number: State-assigned School Administrative Unit number
#' }
#'
#' @docType package
#' @name nhschooldata-package
NULL
