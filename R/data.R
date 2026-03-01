#' New Hampshire School Enrollment Data
#'
#' Bundled enrollment data from the New Hampshire Department of Education,
#' covering 2012-2026 (15 school years). Includes district-level and
#' school-level enrollment by grade.
#'
#' Data was downloaded from the NH DOE iPlatform reporting system
#' (\url{https://my.doe.nh.gov/iPlatform}) and processed into a standardized
#' format. District data has aggregated grade bands (PreSchool, Kindergarten,
#' Elementary, Middle, High); school data has individual grades (PK, K, 1-12).
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{end_year}{School year end (e.g., 2024 for 2023-24)}
#'   \item{type}{"District" or "Campus"}
#'   \item{sau}{SAU (School Administrative Unit) number}
#'   \item{sau_name}{SAU name}
#'   \item{district_id}{District number}
#'   \item{district_name}{District name}
#'   \item{campus_id}{School number (NA for district rows)}
#'   \item{campus_name}{School name (NA for district rows)}
#'   \item{county}{County (NA — not in standard iPlatform reports)}
#'   \item{charter_flag}{Charter school flag (NA — not in standard reports)}
#'   \item{grade_pk}{PreSchool enrollment}
#'   \item{grade_k}{Kindergarten enrollment}
#'   \item{grade_elem}{Elementary enrollment (district data only)}
#'   \item{grade_middle}{Middle school enrollment (district data only)}
#'   \item{grade_high}{High school enrollment (district data only)}
#'   \item{grade_01}{Grade 1 enrollment (school data only)}
#'   \item{grade_02}{Grade 2 enrollment (school data only)}
#'   \item{grade_03}{Grade 3 enrollment (school data only)}
#'   \item{grade_04}{Grade 4 enrollment (school data only)}
#'   \item{grade_05}{Grade 5 enrollment (school data only)}
#'   \item{grade_06}{Grade 6 enrollment (school data only)}
#'   \item{grade_07}{Grade 7 enrollment (school data only)}
#'   \item{grade_08}{Grade 8 enrollment (school data only)}
#'   \item{grade_09}{Grade 9 enrollment (school data only)}
#'   \item{grade_10}{Grade 10 enrollment (school data only)}
#'   \item{grade_11}{Grade 11 enrollment (school data only)}
#'   \item{grade_12}{Grade 12 enrollment (school data only)}
#'   \item{grade_pg}{Post-graduate enrollment}
#'   \item{row_total}{Total enrollment for the row}
#' }
#'
#' @source NH DOE iPlatform: \url{https://my.doe.nh.gov/iPlatform}
#' @examples
#' data(nh_enrollment)
#' head(nh_enrollment)
#'
#' # State totals by year
#' library(dplyr)
#' nh_enrollment |>
#'   filter(type == "District") |>
#'   group_by(end_year) |>
#'   summarize(total = sum(row_total, na.rm = TRUE))
"nh_enrollment"
