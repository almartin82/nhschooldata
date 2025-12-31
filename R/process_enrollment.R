# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw NH DOE enrollment data into a
# clean, standardized format.
#
# NH DOE iPlatform enrollment data typically includes:
# - District/School identifiers and names
# - SAU (School Administrative Unit) numbers
# - Enrollment by grade level (Pre-K, K, 1-12)
# - Total enrollment
#
# Note: Demographics (race/ethnicity, gender) are typically not included
# in the standard enrollment reports from NH DOE iPlatform. These would
# require separate data collection.
#
# ==============================================================================

#' Process raw NH DOE enrollment data
#'
#' Transforms raw data into a standardized schema combining school
#' and district data.
#'
#' @param raw_data List containing school and district data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process school data
  school_processed <- process_school_enr(raw_data$school, end_year)

  # Process district data
  district_processed <- process_district_enr(raw_data$district, end_year)

  # Create state aggregate
  state_processed <- create_state_aggregate(district_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, school_processed)

  result
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "Campus"))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe with same number of rows as input
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # School ID - NH DOE uses various formats
  school_id_col <- find_col(c("SCHOOL_ID", "SCHOOLID", "SCH_ID", "SCHID", "SCHOOL_NUMBER",
                               "NCESSCH", "ncessch", "school_id"))
  if (!is.null(school_id_col)) {
    result$campus_id <- trimws(as.character(df[[school_id_col]]))
  } else {
    result$campus_id <- rep(NA_character_, n_rows)
  }

  # District ID
  district_id_col <- find_col(c("DISTRICT_ID", "DISTRICTID", "DIST_ID", "DISTRICT_NUMBER",
                                 "LEAID", "leaid", "LEA_ID", "district_id"))
  if (!is.null(district_id_col)) {
    result$district_id <- trimws(as.character(df[[district_id_col]]))
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # School name
  school_name_col <- find_col(c("SCHOOL_NAME", "SCHOOLNAME", "SCH_NAME", "SCHOOL",
                                 "school_name", "SCHNAM", "NAME"))
  if (!is.null(school_name_col)) {
    result$campus_name <- clean_names(as.character(df[[school_name_col]]))
  } else {
    result$campus_name <- rep(NA_character_, n_rows)
  }

  # District name
  district_name_col <- find_col(c("DISTRICT_NAME", "DISTRICTNAME", "DIST_NAME", "DISTRICT",
                                   "LEA_NAME", "lea_name", "LEANM", "district_name"))
  if (!is.null(district_name_col)) {
    result$district_name <- clean_names(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  # SAU (School Administrative Unit) - NH specific
  sau_col <- find_col(c("SAU", "SAU_NUMBER", "SAU_ID", "SAUNUMBER"))
  if (!is.null(sau_col)) {
    result$sau <- trimws(as.character(df[[sau_col]]))
  } else {
    result$sau <- rep(NA_character_, n_rows)
  }

  # County (not always available in NH DOE data)
  county_col <- find_col(c("COUNTY", "county", "CNTY", "CONAME"))
  if (!is.null(county_col)) {
    result$county <- clean_names(as.character(df[[county_col]]))
  } else {
    result$county <- rep(NA_character_, n_rows)
  }

  # Charter status
  charter_col <- find_col(c("CHARTER", "charter", "CHARTEFLAG", "charter_school"))
  if (!is.null(charter_col)) {
    charter_vals <- df[[charter_col]]
    result$charter_flag <- ifelse(
      charter_vals %in% c("1", "Y", "Yes", "TRUE", "true", 1),
      "Y",
      "N"
    )
  } else {
    result$charter_flag <- rep(NA_character_, n_rows)
  }

  # Total enrollment
  total_col <- find_col(c("TOTAL", "total", "MEMBER", "enrollment", "ENROLLMENT", "STUDENTS"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- rep(NA_integer_, n_rows)
  }

  # Demographics - if available in NH DOE data
  demo_map <- list(
    white = c("WH", "white", "WHITE", "RACE_WHITE"),
    black = c("BL", "black", "BLACK", "RACE_BLACK", "RACE_AFRICAN_AMERICAN"),
    hispanic = c("HI", "hispanic", "HISPANIC", "RACE_HISPANIC"),
    asian = c("AS", "asian", "ASIAN", "RACE_ASIAN"),
    pacific_islander = c("HP", "pacific_islander", "PACIFIC_ISLANDER", "RACE_PACIFIC"),
    native_american = c("AM", "native_american", "AMERICAN_INDIAN", "RACE_NATIVE"),
    multiracial = c("TR", "multiracial", "TWO_OR_MORE", "RACE_TWO_OR_MORE")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Gender - may not be available in all datasets
  gender_map <- list(
    male = c("MALE", "male", "M"),
    female = c("FEMALE", "female", "F")
  )

  for (name in names(gender_map)) {
    col <- find_col(gender_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Grade levels - NH DOE uses various formats (PREK, K, G01-G12 or 1-12)
  grade_map <- list(
    grade_pk = c("PREK", "PRE-K", "PK", "pk", "PREKINDERGARTEN", "PRE_K", "PRESCHOOL"),
    grade_k = c("K", "KG", "kg", "KINDERGARTEN", "KINDER"),
    grade_01 = c("G01", "G1", "01", "1", "g01", "GRADE_1", "GR01", "GRADE1"),
    grade_02 = c("G02", "G2", "02", "2", "g02", "GRADE_2", "GR02", "GRADE2"),
    grade_03 = c("G03", "G3", "03", "3", "g03", "GRADE_3", "GR03", "GRADE3"),
    grade_04 = c("G04", "G4", "04", "4", "g04", "GRADE_4", "GR04", "GRADE4"),
    grade_05 = c("G05", "G5", "05", "5", "g05", "GRADE_5", "GR05", "GRADE5"),
    grade_06 = c("G06", "G6", "06", "6", "g06", "GRADE_6", "GR06", "GRADE6"),
    grade_07 = c("G07", "G7", "07", "7", "g07", "GRADE_7", "GR07", "GRADE7"),
    grade_08 = c("G08", "G8", "08", "8", "g08", "GRADE_8", "GR08", "GRADE8"),
    grade_09 = c("G09", "G9", "09", "9", "g09", "GRADE_9", "GR09", "GRADE9"),
    grade_10 = c("G10", "10", "g10", "GRADE_10", "GR10", "GRADE10"),
    grade_11 = c("G11", "11", "g11", "GRADE_11", "GR11", "GRADE11"),
    grade_12 = c("G12", "12", "g12", "GRADE_12", "GR12", "GRADE12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Special populations - may not be in basic NH DOE data
  special_map <- list(
    econ_disadv = c("FREELUNCH", "FREE_LUNCH", "ECON_DISADV", "FRL"),
    lep = c("LEP", "ELL", "LIMITED_ENGLISH"),
    special_ed = c("SPECED", "SPED", "SPECIAL_ED", "IEP")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(create_empty_enrollment_df(end_year, "District"))
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(paste0("^", pattern, "$"), cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID
  district_id_col <- find_col(c("LEAID", "leaid", "LEA_ID", "DISTRICT_ID", "district_id"))
  if (!is.null(district_id_col)) {
    result$district_id <- trimws(as.character(df[[district_id_col]]))
  } else {
    result$district_id <- rep(NA_character_, n_rows)
  }

  # Campus ID is NA for district rows
  result$campus_id <- rep(NA_character_, n_rows)

  # District name
  district_name_col <- find_col(c("LEA_NAME", "lea_name", "LEANM", "DISTRICT_NAME", "district_name", "NAME"))
  if (!is.null(district_name_col)) {
    result$district_name <- clean_names(as.character(df[[district_name_col]]))
  } else {
    result$district_name <- rep(NA_character_, n_rows)
  }

  result$campus_name <- rep(NA_character_, n_rows)

  # County
  county_col <- find_col(c("COUNTY", "county", "CNTY", "CONAME"))
  if (!is.null(county_col)) {
    result$county <- clean_names(as.character(df[[county_col]]))
  } else {
    result$county <- rep(NA_character_, n_rows)
  }

  # Charter flag
  charter_col <- find_col(c("CHARTER", "charter", "CHARTEFLAG"))
  if (!is.null(charter_col)) {
    charter_vals <- df[[charter_col]]
    result$charter_flag <- ifelse(
      charter_vals %in% c("1", "Y", "Yes", "TRUE", "true", 1),
      "Y",
      "N"
    )
  } else {
    result$charter_flag <- rep(NA_character_, n_rows)
  }

  # Total enrollment
  total_col <- find_col(c("TOTAL", "total", "MEMBER", "enrollment", "ENROLLMENT"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- rep(NA_integer_, n_rows)
  }

  # Demographics
  demo_map <- list(
    white = c("WH", "white", "WHITE"),
    black = c("BL", "black", "BLACK"),
    hispanic = c("HI", "hispanic", "HISPANIC"),
    asian = c("AS", "asian", "ASIAN"),
    pacific_islander = c("HP", "pacific_islander", "PACIFIC_ISLANDER"),
    native_american = c("AM", "native_american", "AMERICAN_INDIAN"),
    multiracial = c("TR", "multiracial", "TWO_OR_MORE")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Gender
  gender_map <- list(
    male = c("MALE", "male"),
    female = c("FEMALE", "female")
  )

  for (name in names(gender_map)) {
    col <- find_col(gender_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Grade levels
  grade_map <- list(
    grade_pk = c("PK", "pk", "PREKINDERGARTEN"),
    grade_k = c("KG", "kg", "K", "KINDERGARTEN"),
    grade_01 = c("G01", "g01", "GRADE_1"),
    grade_02 = c("G02", "g02", "GRADE_2"),
    grade_03 = c("G03", "g03", "GRADE_3"),
    grade_04 = c("G04", "g04", "GRADE_4"),
    grade_05 = c("G05", "g05", "GRADE_5"),
    grade_06 = c("G06", "g06", "GRADE_6"),
    grade_07 = c("G07", "g07", "GRADE_7"),
    grade_08 = c("G08", "g08", "GRADE_8"),
    grade_09 = c("G09", "g09", "GRADE_9"),
    grade_10 = c("G10", "g10", "GRADE_10"),
    grade_11 = c("G11", "g11", "GRADE_11"),
    grade_12 = c("G12", "g12", "GRADE_12")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  # Special populations
  special_map <- list(
    econ_disadv = c("FREELUNCH", "FREE_LUNCH", "ECON_DISADV"),
    lep = c("LEP", "ELL", "LIMITED_ENGLISH"),
    special_ed = c("SPECED", "SPED", "SPECIAL_ED")
  )

  for (name in names(special_map)) {
    col <- find_col(special_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- rep(NA_integer_, n_rows)
    }
  }

  result
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "econ_disadv", "lep", "special_ed",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = NA_character_,
    campus_name = NA_character_,
    county = NA_character_,
    charter_flag = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    if (col %in% names(district_df)) {
      state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
    }
  }

  state_row
}


#' Create empty enrollment data frame
#'
#' @param end_year School year end
#' @param type "Campus", "District", or "State"
#' @return Empty data frame with expected columns
#' @keywords internal
create_empty_enrollment_df <- function(end_year, type) {
  data.frame(
    end_year = integer(),
    type = character(),
    district_id = character(),
    campus_id = character(),
    district_name = character(),
    campus_name = character(),
    county = character(),
    charter_flag = character(),
    row_total = integer(),
    white = integer(),
    black = integer(),
    hispanic = integer(),
    asian = integer(),
    pacific_islander = integer(),
    native_american = integer(),
    multiracial = integer(),
    male = integer(),
    female = integer(),
    econ_disadv = integer(),
    lep = integer(),
    special_ed = integer(),
    grade_pk = integer(),
    grade_k = integer(),
    grade_01 = integer(),
    grade_02 = integer(),
    grade_03 = integer(),
    grade_04 = integer(),
    grade_05 = integer(),
    grade_06 = integer(),
    grade_07 = integer(),
    grade_08 = integer(),
    grade_09 = integer(),
    grade_10 = integer(),
    grade_11 = integer(),
    grade_12 = integer(),
    stringsAsFactors = FALSE
  )
}
