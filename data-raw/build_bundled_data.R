#!/usr/bin/env Rscript
# ==============================================================================
# Build Bundled Data from NH DOE iPlatform Downloads
# ==============================================================================
#
# Reads Excel files downloaded from NH DOE iPlatform and creates bundled RDS
# files for the package. Source files are in data-raw/downloads/.
#
# District report columns (aggregated grades):
#   SAU #, SAU Name, District #, District Name,
#   PreSchool, Kindergarten, Elementary, Middle, High, PG, Total
#
# School report columns (individual grades):
#   SAU #, SAU Name, District #, District Name, School #, School Name,
#   PreSchool, Kindergarten, 1-12, *PG, Total
#
# Output:
#   inst/extdata/nh_enrollment_districts.rds — all years, processed format
#   inst/extdata/nh_enrollment_schools.rds — all years, processed format
#   data/nh_enrollment.rda — combined tidy format
#
# Usage:
#   Rscript data-raw/build_bundled_data.R
# ==============================================================================

library(readxl)
library(dplyr)
library(purrr)

# Configuration
DOWNLOAD_DIR <- file.path("data-raw", "downloads")
YEARS <- 2012:2026

# ==============================================================================
# Parse district Excel files
# ==============================================================================

parse_district_excel <- function(path, end_year) {
  # Read raw with no column names to handle header rows
  raw <- readxl::read_excel(path, col_types = "text", col_names = FALSE)

  # Find header row (contains "SAU #" and "District Name")
  header_row <- NULL
  for (i in 1:min(20, nrow(raw))) {
    vals <- as.character(raw[i, ])
    if (any(grepl("^SAU #$", vals, ignore.case = TRUE)) &&
        any(grepl("District Name", vals, ignore.case = TRUE))) {
      header_row <- i
      break
    }
  }

  if (is.null(header_row)) {
    warning("Could not find header row in ", path)
    return(NULL)
  }

  # Extract headers and data
  headers <- as.character(raw[header_row, ])
  data_rows <- raw[(header_row + 1):nrow(raw), ]
  names(data_rows) <- headers

  # Clean column names
  names(data_rows) <- trimws(names(data_rows))

  # Remove footnote/metadata rows at bottom
  # These have NA in numeric columns or contain text like "Foot Notes"
  data_rows <- data_rows[!is.na(data_rows[["Total"]]), ]
  data_rows <- data_rows[!grepl("^(Foot|Academic|Rivendell|Data Source|Data collected)",
                                data_rows[[1]], ignore.case = TRUE), ]
  # Remove rows where Total is not a number
  data_rows <- data_rows[!is.na(suppressWarnings(as.numeric(data_rows[["Total"]]))), ]

  safe_int <- function(x) as.integer(suppressWarnings(as.numeric(x)))

  # Determine PG column name
  pg_col <- if ("*PG" %in% names(data_rows)) "*PG" else if ("PG" %in% names(data_rows)) "PG" else NULL

  # Rename to standardized format
  df <- data_rows %>%
    transmute(
      end_year = end_year,
      type = "District",
      sau = trimws(`SAU #`),
      sau_name = trimws(`SAU Name`),
      district_id = trimws(`District #`),
      district_name = trimws(`District Name`),
      campus_id = NA_character_,
      campus_name = NA_character_,
      county = NA_character_,
      charter_flag = NA_character_,
      grade_pk = safe_int(PreSchool),
      grade_k = safe_int(Kindergarten),
      grade_elem = safe_int(Elementary),
      grade_middle = safe_int(Middle),
      grade_high = safe_int(High),
      grade_pg = if (!is.null(pg_col)) safe_int(.data[[pg_col]]) else NA_integer_,
      row_total = safe_int(Total)
    )

  # Remove state totals and sub-category totals rows
  df <- df[!grepl("State Total|Total:", df$district_name, ignore.case = TRUE), ]

  df
}


# ==============================================================================
# Parse school Excel files
# ==============================================================================

parse_school_excel <- function(path, end_year) {
  raw <- readxl::read_excel(path, col_types = "text", col_names = FALSE)

  # Find header row
  header_row <- NULL
  for (i in 1:min(20, nrow(raw))) {
    vals <- as.character(raw[i, ])
    if (any(grepl("^SAU #$", vals, ignore.case = TRUE)) &&
        any(grepl("School Name", vals, ignore.case = TRUE))) {
      header_row <- i
      break
    }
  }

  if (is.null(header_row)) {
    warning("Could not find header row in ", path)
    return(NULL)
  }

  headers <- as.character(raw[header_row, ])
  data_rows <- raw[(header_row + 1):nrow(raw), ]
  names(data_rows) <- trimws(headers)

  # Remove footnote/metadata rows
  data_rows <- data_rows[!is.na(data_rows[["Total"]]), ]
  data_rows <- data_rows[!grepl("^(Foot|Academic|Rivendell|Data Source|Data collected|\\*PG)",
                                data_rows[[1]], ignore.case = TRUE), ]
  data_rows <- data_rows[!is.na(suppressWarnings(as.numeric(data_rows[["Total"]]))), ]

  # Remove state total and subtotal rows
  data_rows <- data_rows[!grepl("State Total|SubTotal", data_rows[["School Name"]], ignore.case = TRUE), ]

  safe_int <- function(x) as.integer(suppressWarnings(as.numeric(x)))

  # Handle PG column name (sometimes "*PG", sometimes "PG")
  pg_col <- if ("*PG" %in% names(data_rows)) "*PG" else if ("PG" %in% names(data_rows)) "PG" else NULL

  df <- data_rows %>%
    transmute(
      end_year = end_year,
      type = "Campus",
      sau = trimws(`SAU #`),
      sau_name = trimws(`SAU Name`),
      district_id = trimws(`District #`),
      district_name = trimws(`District Name`),
      campus_id = trimws(`School #`),
      campus_name = trimws(`School Name`),
      county = NA_character_,
      charter_flag = NA_character_,
      grade_pk = safe_int(PreSchool),
      grade_k = safe_int(Kindergarten),
      grade_01 = safe_int(`1`),
      grade_02 = safe_int(`2`),
      grade_03 = safe_int(`3`),
      grade_04 = safe_int(`4`),
      grade_05 = safe_int(`5`),
      grade_06 = safe_int(`6`),
      grade_07 = safe_int(`7`),
      grade_08 = safe_int(`8`),
      grade_09 = safe_int(`9`),
      grade_10 = safe_int(`10`),
      grade_11 = safe_int(`11`),
      grade_12 = safe_int(`12`),
      grade_pg = if (!is.null(pg_col)) safe_int(.data[[pg_col]]) else NA_integer_,
      row_total = safe_int(Total)
    )

  df
}


# ==============================================================================
# Main processing
# ==============================================================================

cat("Processing NH DOE enrollment data...\n")
cat("Download directory:", DOWNLOAD_DIR, "\n")
cat("Years:", paste(YEARS, collapse = ", "), "\n\n")

# Process district files
cat("=== District Files ===\n")
district_all <- map_df(YEARS, function(yr) {
  path <- file.path(DOWNLOAD_DIR, paste0("nh_district_", yr, ".xlsx"))
  if (!file.exists(path)) {
    cat(sprintf("  SKIP %d: file not found\n", yr))
    return(NULL)
  }
  cat(sprintf("  Processing %d...", yr))
  df <- parse_district_excel(path, yr)
  if (!is.null(df)) {
    cat(sprintf(" %d districts, total=%s\n", nrow(df),
                format(sum(df$row_total, na.rm = TRUE), big.mark = ",")))
  }
  df
})

cat(sprintf("\nDistrict data: %d rows, %d years, %d unique districts\n",
            nrow(district_all),
            length(unique(district_all$end_year)),
            length(unique(district_all$district_id))))

# Process school files
cat("\n=== School Files ===\n")
school_all <- map_df(YEARS, function(yr) {
  path <- file.path(DOWNLOAD_DIR, paste0("nh_school_", yr, ".xlsx"))
  if (!file.exists(path)) {
    cat(sprintf("  SKIP %d: file not found\n", yr))
    return(NULL)
  }
  cat(sprintf("  Processing %d...", yr))
  df <- parse_school_excel(path, yr)
  if (!is.null(df)) {
    cat(sprintf(" %d schools, total=%s\n", nrow(df),
                format(sum(df$row_total, na.rm = TRUE), big.mark = ",")))
  }
  df
})

cat(sprintf("\nSchool data: %d rows, %d years, %d unique schools\n",
            nrow(school_all),
            length(unique(school_all$end_year)),
            length(unique(school_all$campus_id))))

# ==============================================================================
# Validation
# ==============================================================================

cat("\n=== Validation ===\n")

# Check state totals by year
cat("State totals by year (from district data):\n")
state_totals <- district_all %>%
  group_by(end_year) %>%
  summarize(
    n_districts = n(),
    total_enrollment = sum(row_total, na.rm = TRUE),
    .groups = "drop"
  )
print(as.data.frame(state_totals))

# Check for issues
cat("\nData quality checks:\n")
cat("  Negative values in district data:",
    sum(district_all$row_total < 0, na.rm = TRUE), "\n")
cat("  NA totals in district data:",
    sum(is.na(district_all$row_total)), "\n")
cat("  Negative values in school data:",
    sum(school_all$row_total < 0, na.rm = TRUE), "\n")
cat("  NA totals in school data:",
    sum(is.na(school_all$row_total)), "\n")

# Cross-validate: district totals should match school totals
cat("\nCross-validation (district vs school totals by year):\n")
school_totals <- school_all %>%
  group_by(end_year) %>%
  summarize(school_total = sum(row_total, na.rm = TRUE), .groups = "drop")

comparison <- state_totals %>%
  left_join(school_totals, by = "end_year") %>%
  mutate(diff = total_enrollment - school_total)
print(as.data.frame(comparison))

# ==============================================================================
# Save bundled data
# ==============================================================================

cat("\n=== Saving Bundled Data ===\n")

# Create output directories
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
dir.create("data", recursive = TRUE, showWarnings = FALSE)

# Save district RDS
district_path <- "inst/extdata/nh_enrollment_districts.rds"
saveRDS(district_all, district_path)
cat(sprintf("Saved %s (%s bytes)\n", district_path,
            format(file.size(district_path), big.mark = ",")))

# Save school RDS
school_path <- "inst/extdata/nh_enrollment_schools.rds"
saveRDS(school_all, school_path)
cat(sprintf("Saved %s (%s bytes)\n", school_path,
            format(file.size(school_path), big.mark = ",")))

# Build combined tidy dataset for data()
cat("\nBuilding tidy dataset for data(nh_enrollment)...\n")

# We need to create the tidy format that fetch_enr() would return
# This requires the package's own tidy_enr and id_enr_aggs functions
# For now, save the processed (wide) format and let the package tidy on load
nh_enrollment <- bind_rows(
  district_all,
  school_all
) %>%
  arrange(end_year, type, district_id, campus_id)

save(nh_enrollment, file = "data/nh_enrollment.rda", compress = "xz")
cat(sprintf("Saved data/nh_enrollment.rda (%s bytes)\n",
            format(file.size("data/nh_enrollment.rda"), big.mark = ",")))

cat("\nDone! Bundled data is ready.\n")
