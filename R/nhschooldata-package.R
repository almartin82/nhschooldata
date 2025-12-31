#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' nhschooldata: Fetch and Process New Hampshire School Enrollment Data
#'
#' An R package for downloading and processing school enrollment data for
#' New Hampshire public schools. Data is sourced directly from the
#' New Hampshire Department of Education (NH DOE) iPlatform reporting system.
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Download enrollment data for a single year}
#'   \item{\code{\link{fetch_enr_multi}}}{Download enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide enrollment data to long format}
#'   \item{\code{\link{get_available_years}}}{Get the range of available years}
#'   \item{\code{\link{import_local_enrollment}}}{Import manually downloaded enrollment file}
#' }
#'
#' @section Data Source:
#' Data is sourced from the New Hampshire Department of Education:
#' \itemize{
#'   \item NH DOE iPlatform: \url{https://my.doe.nh.gov/iPlatform}
#'   \item Enrollment Reports: District and school-level fall enrollment
#'   \item Historical data: Approximately 10 years available
#' }
#'
#' @section Available Reports:
#' \itemize{
#'   \item District Fall Enrollment: Pre-K through 12 by district
#'   \item Public School Enrollments by Grade: School-level enrollment
#'   \item Enrollments by Grade: County, town, and other breakdowns
#' }
#'
#' @section New Hampshire School System:
#' New Hampshire's school system includes:
#' \itemize{
#'   \item Approximately 162 school districts
#'   \item 456 public schools
#'   \item School Administrative Units (SAUs) that may cover multiple districts
#'   \item Public charter schools
#'   \item Approximately 160,000 students enrolled (2025)
#' }
#'
#' @section Identifier System:
#' \itemize{
#'   \item District ID: State-assigned district identifier
#'   \item School ID: State-assigned school identifier
#'   \item SAU Number: School Administrative Unit number
#' }
#'
#' @section Manual Download Fallback:
#' If automated download fails, you can manually download data from the
#' NH DOE iPlatform and import it using \code{\link{import_local_enrollment}}.
#'
#' @docType package
#' @name nhschooldata-package
NULL
