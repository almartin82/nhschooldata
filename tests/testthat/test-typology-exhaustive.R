# ==============================================================================
# Exhaustive Typology Tests — Utility functions, naming standards, cache
# ==============================================================================
#
# Tests for utility functions, naming standards compliance, cache roundtrips,
# error handling, and data processing helper functions.
#
# ==============================================================================

# --- safe_numeric edge cases -------------------------------------------------

test_that("safe_numeric converts normal numbers correctly", {
  safe_numeric <- nhschooldata:::safe_numeric

  expect_equal(safe_numeric("42"), 42)
  expect_equal(safe_numeric("0"), 0)
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("3.14"), 3.14)
  expect_equal(safe_numeric("0.5"), 0.5)
  expect_equal(safe_numeric("99999"), 99999)
})

test_that("safe_numeric handles commas in numbers", {
  safe_numeric <- nhschooldata:::safe_numeric

  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric("1,234,567"), 1234567)
  expect_equal(safe_numeric("100,000"), 100000)
  expect_equal(safe_numeric("10,000,000"), 10000000)
})

test_that("safe_numeric handles whitespace", {
  safe_numeric <- nhschooldata:::safe_numeric

  expect_equal(safe_numeric("  100  "), 100)
  expect_equal(safe_numeric("  42"), 42)
  expect_equal(safe_numeric("42  "), 42)
  expect_equal(safe_numeric("\t100\t"), 100)
})

test_that("safe_numeric converts suppression markers to NA", {
  safe_numeric <- nhschooldata:::safe_numeric

  # All known suppression markers
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric(".")))
  expect_true(is.na(safe_numeric("-")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("<20")))
  expect_true(is.na(safe_numeric("N/A")))
  expect_true(is.na(safe_numeric("n/a")))
  expect_true(is.na(safe_numeric("NA")))
  expect_true(is.na(safe_numeric("N")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("  ")))  # whitespace-only
})

test_that("safe_numeric handles generic < prefixed values", {
  safe_numeric <- nhschooldata:::safe_numeric

  # Any <N pattern should be NA
  expect_true(is.na(safe_numeric("<3")))
  expect_true(is.na(safe_numeric("<15")))
  expect_true(is.na(safe_numeric("<100")))
})

test_that("safe_numeric handles vector input", {
  safe_numeric <- nhschooldata:::safe_numeric

  input <- c("100", "200", "*", "300", "<5", "N/A")
  result <- safe_numeric(input)

  expect_equal(length(result), 6L)
  expect_equal(result[1], 100)
  expect_equal(result[2], 200)
  expect_true(is.na(result[3]))
  expect_equal(result[4], 300)
  expect_true(is.na(result[5]))
  expect_true(is.na(result[6]))
})

test_that("safe_numeric returns NA for non-numeric text", {
  safe_numeric <- nhschooldata:::safe_numeric

  expect_true(is.na(safe_numeric("abc")))
  expect_true(is.na(safe_numeric("hello")))
  expect_true(is.na(safe_numeric("not a number")))
})

# --- get_available_years() structure -----------------------------------------

test_that("get_available_years returns named list with 4 elements", {
  years <- get_available_years()

  expect_true(is.list(years))
  expect_equal(length(years), 4L)
  expect_true("min_year" %in% names(years))
  expect_true("max_year" %in% names(years))
  expect_true("source" %in% names(years))
  expect_true("note" %in% names(years))
})

test_that("get_available_years has correct types", {
  years <- get_available_years()

  expect_true(is.integer(years$min_year) || is.numeric(years$min_year))
  expect_true(is.integer(years$max_year) || is.numeric(years$max_year))
  expect_true(is.character(years$source))
  expect_true(is.character(years$note))
})

test_that("get_available_years source mentions NH DOE", {
  years <- get_available_years()
  expect_true(grepl("New Hampshire", years$source))
})

test_that("get_available_years note contains data info", {
  years <- get_available_years()
  expect_true(grepl("iPlatform", years$note))
  expect_true(grepl("October 1", years$note))
})

# --- validate_year -----------------------------------------------------------

test_that("validate_year rejects years below range", {
  expect_error(nhschooldata:::validate_year(2011), "end_year must be between")
  expect_error(nhschooldata:::validate_year(2000), "end_year must be between")
  expect_error(nhschooldata:::validate_year(1990), "end_year must be between")
})

test_that("validate_year rejects years above range", {
  expect_error(nhschooldata:::validate_year(2027), "end_year must be between")
  expect_error(nhschooldata:::validate_year(2050), "end_year must be between")
})

test_that("validate_year rejects non-numeric input", {
  expect_error(nhschooldata:::validate_year("2020"), "must be a single numeric value")
  expect_error(nhschooldata:::validate_year(TRUE), "must be a single numeric value")
})

test_that("validate_year rejects vector input", {
  expect_error(nhschooldata:::validate_year(c(2020, 2021)),
               "must be a single numeric value")
})

test_that("validate_year accepts valid years", {
  expect_true(nhschooldata:::validate_year(2012))
  expect_true(nhschooldata:::validate_year(2026))
  expect_true(nhschooldata:::validate_year(2019))
})

# --- format_school_year ------------------------------------------------------

test_that("format_school_year formats correctly", {
  fmt <- nhschooldata:::format_school_year

  expect_equal(fmt(2024), "2023-24")
  expect_equal(fmt(2020), "2019-20")
  expect_equal(fmt(2012), "2011-12")
  expect_equal(fmt(2026), "2025-26")
})

test_that("format_school_year handles century boundary", {
  fmt <- nhschooldata:::format_school_year

  expect_equal(fmt(2000), "1999-00")
  expect_equal(fmt(2100), "2099-00")
})

test_that("format_school_year returns character type", {
  result <- nhschooldata:::format_school_year(2024)
  expect_true(is.character(result))
  expect_equal(nchar(result), 7L)  # "YYYY-YY" format
})

# --- clean_names -------------------------------------------------------------

test_that("clean_names removes leading and trailing whitespace", {
  clean <- nhschooldata:::clean_names

  expect_equal(clean("  Manchester  "), "Manchester")
  expect_equal(clean("leading"), "leading")
  expect_equal(clean("trailing  "), "trailing")
})

test_that("clean_names collapses multiple spaces to single", {
  clean <- nhschooldata:::clean_names

  expect_equal(clean("School  District"), "School District")
  expect_equal(clean("multi   space   name"), "multi space name")
  expect_equal(clean("no change"), "no change")
})

test_that("clean_names handles empty string", {
  clean <- nhschooldata:::clean_names

  expect_equal(clean(""), "")
})

test_that("clean_names handles vector input", {
  clean <- nhschooldata:::clean_names

  input <- c("  foo  ", "bar  baz", "normal")
  result <- clean(input)
  expect_equal(result, c("foo", "bar baz", "normal"))
})

# --- parse_district_id -------------------------------------------------------

test_that("parse_district_id removes leading zeros", {
  parse <- nhschooldata:::parse_district_id

  expect_equal(parse("009"), "9")
  expect_equal(parse("0335"), "335")
  expect_equal(parse("100"), "100")
})

test_that("parse_district_id trims whitespace", {
  parse <- nhschooldata:::parse_district_id

  expect_equal(parse("  335  "), "335")
})

# --- Naming standards --------------------------------------------------------

test_that("subgroup names follow naming standards", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  # Currently only total_enrollment exists in NH
  allowed_subgroups <- c(
    "total_enrollment", "white", "black", "hispanic", "asian",
    "native_american", "pacific_islander", "multiracial",
    "male", "female", "special_ed", "lep", "econ_disadv"
  )

  actual_subgroups <- unique(enr$subgroup)
  for (sg in actual_subgroups) {
    expect_true(sg %in% allowed_subgroups,
                info = paste("Non-standard subgroup name:", sg))
  }
})

test_that("grade levels follow naming standards (uppercase)", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  allowed_grades <- c(
    "EE", "PK", "K", "01", "02", "03", "04", "05", "06", "07", "08",
    "09", "10", "11", "12", "TOTAL",
    "K8", "HS", "K12",
    "ELEM", "MIDDLE", "HIGH", "PG"
  )

  actual_grades <- unique(enr$grade_level)
  for (gl in actual_grades) {
    expect_true(gl %in% allowed_grades,
                info = paste("Non-standard grade level:", gl))
    expect_equal(gl, toupper(gl),
                 info = paste("Grade level not uppercase:", gl))
  }
})

test_that("entity flags use standard names", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  expect_true("is_state" %in% names(enr))
  expect_true("is_district" %in% names(enr))
  expect_true("is_campus" %in% names(enr))
  expect_true("is_charter" %in% names(enr))

  # All boolean
  expect_true(is.logical(enr$is_state))
  expect_true(is.logical(enr$is_district))
  expect_true(is.logical(enr$is_campus))
  expect_true(is.logical(enr$is_charter))
})

test_that("no non-standard subgroup names like el, ell, frl, iep", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  sgs <- unique(enr$subgroup)

  banned <- c("el", "ell", "frl", "iep", "total", "low_income",
              "english_learner", "american_indian", "two_or_more",
              "economically_disadvantaged", "students_with_disabilities")

  for (b in banned) {
    expect_false(b %in% sgs, info = paste("Banned subgroup name found:", b))
  }
})

# --- Cache roundtrip ---------------------------------------------------------

test_that("cache write and read preserves data exactly", {
  skip_on_cran()

  test_df <- data.frame(
    end_year = c(9990L, 9990L),
    district_id = c("TEST001", "TEST002"),
    n_students = c(100.5, 200.3),
    name = c("Alpha", "Beta"),
    flag = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  # Write
  cache_path <- write_cache(test_df, 9990, "roundtrip_test")
  expect_true(file.exists(cache_path))

  # Read back
  result <- read_cache(9990, "roundtrip_test")

  expect_equal(nrow(result), 2L)
  expect_equal(result$end_year, c(9990L, 9990L))
  expect_equal(result$district_id, c("TEST001", "TEST002"))
  expect_equal(result$n_students, c(100.5, 200.3))
  expect_equal(result$name, c("Alpha", "Beta"))
  expect_equal(result$flag, c(TRUE, FALSE))

  # Clean up
  file.remove(cache_path)
})

test_that("cache roundtrip preserves real enrollment data exactly", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  # Write to temp cache
  cache_path <- write_cache(enr, 9991, "roundtrip_real")
  result <- read_cache(9991, "roundtrip_real")

  expect_equal(nrow(result), nrow(enr))
  expect_equal(names(result), names(enr))
  expect_equal(sum(result$n_students), sum(enr$n_students))
  expect_equal(result$n_students[1], enr$n_students[1])
  expect_equal(result$n_students[nrow(result)], enr$n_students[nrow(enr)])

  # Clean up
  file.remove(cache_path)
})

test_that("cache_exists returns FALSE for non-existent cache", {
  expect_false(cache_exists(9999, "tidy"))
  expect_false(cache_exists(9999, "wide"))
  expect_false(cache_exists(1, "nonexistent_type"))
})

test_that("get_cache_path constructs correct paths for different types", {
  tidy_path <- get_cache_path(2024, "tidy")
  wide_path <- get_cache_path(2024, "wide")

  expect_true(grepl("enr_tidy_2024\\.rds$", tidy_path))
  expect_true(grepl("enr_wide_2024\\.rds$", wide_path))
  expect_true(grepl("nhschooldata", tidy_path))
  expect_true(grepl("nhschooldata", wide_path))
})

test_that("clear_cache removes specific year/type correctly", {
  # Write test cache
  test_df <- data.frame(end_year = 9992L, value = 1L)
  write_cache(test_df, 9992, "clear_test")

  cache_path <- get_cache_path(9992, "clear_test")
  expect_true(file.exists(cache_path))

  clear_cache(end_year = 9992, type = "clear_test")
  expect_false(file.exists(cache_path))
})

test_that("cache_status runs without error", {
  expect_no_error(cache_status())
})

test_that("cache_status returns data frame (or empty)", {
  result <- cache_status()
  expect_true(is.data.frame(result))
})

# --- import_local_enrollment error handling ----------------------------------

test_that("import_local_enrollment errors on missing file", {
  expect_error(
    import_local_enrollment("/nonexistent/file.xlsx", 2024, "school"),
    "File not found"
  )
})

test_that("import_local_enrollment errors on unsupported file type", {
  temp_file <- tempfile(fileext = ".pdf")
  file.create(temp_file)
  on.exit(unlink(temp_file))

  expect_error(
    import_local_enrollment(temp_file, 2024, "school"),
    "Unsupported file type"
  )
})

test_that("import_local_enrollment rejects .txt files", {
  temp_file <- tempfile(fileext = ".txt")
  file.create(temp_file)
  on.exit(unlink(temp_file))

  expect_error(
    import_local_enrollment(temp_file, 2024, "school"),
    "Unsupported file type"
  )
})

test_that("import_local_enrollment rejects .json files", {
  temp_file <- tempfile(fileext = ".json")
  file.create(temp_file)
  on.exit(unlink(temp_file))

  expect_error(
    import_local_enrollment(temp_file, 2024, "school"),
    "Unsupported file type"
  )
})

# --- fetch_enr_multi validation ----------------------------------------------

test_that("fetch_enr_multi rejects years below range", {
  expect_error(fetch_enr_multi(c(2020, 2011)), "Invalid years")
  expect_error(fetch_enr_multi(c(2000, 2020)), "Invalid years")
})

test_that("fetch_enr_multi rejects years above range", {
  expect_error(fetch_enr_multi(c(2020, 2027)), "Invalid years")
  expect_error(fetch_enr_multi(c(2020, 2050)), "Invalid years")
})

test_that("fetch_enr_multi rejects mix of valid and invalid years", {
  expect_error(fetch_enr_multi(c(2012, 2020, 2030)), "Invalid years")
})

# --- tidy_enr() column output ------------------------------------------------

test_that("tidy_enr produces expected columns", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- tidy_enr(wide)

  expected_cols <- c(
    "end_year", "type", "district_id", "campus_id",
    "district_name", "campus_name", "sau", "sau_name",
    "county", "charter_flag",
    "grade_level", "subgroup", "n_students", "pct"
  )

  for (col in expected_cols) {
    expect_true(col %in% names(tidy),
                info = paste("tidy_enr missing column:", col))
  }
})

test_that("tidy_enr produces total_enrollment subgroup", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- tidy_enr(wide)

  expect_true("total_enrollment" %in% unique(tidy$subgroup))
})

test_that("tidy_enr produces TOTAL grade level", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- tidy_enr(wide)

  expect_true("TOTAL" %in% unique(tidy$grade_level))
})

test_that("tidy_enr filters out NA n_students", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- tidy_enr(wide)

  expect_false(any(is.na(tidy$n_students)))
})

# --- id_enr_aggs() flag correctness ------------------------------------------

test_that("id_enr_aggs adds correct entity flags", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- tidy_enr(wide)
  flagged <- id_enr_aggs(tidy)

  expect_true("is_state" %in% names(flagged))
  expect_true("is_district" %in% names(flagged))
  expect_true("is_campus" %in% names(flagged))
  expect_true("is_charter" %in% names(flagged))
  expect_true("aggregation_flag" %in% names(flagged))

  # Check flag types
  expect_true(is.logical(flagged$is_state))
  expect_true(is.logical(flagged$is_district))
  expect_true(is.logical(flagged$is_campus))
  expect_true(is.logical(flagged$is_charter))
  expect_true(is.character(flagged$aggregation_flag))
})

test_that("id_enr_aggs sets flags based on type column", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- tidy_enr(wide)
  flagged <- id_enr_aggs(tidy)

  # State rows
  state_rows <- flagged[flagged$type == "State", ]
  expect_true(all(state_rows$is_state))
  expect_true(all(!state_rows$is_district))
  expect_true(all(!state_rows$is_campus))

  # District rows
  dist_rows <- flagged[flagged$type == "District", ]
  expect_true(all(!dist_rows$is_state))
  expect_true(all(dist_rows$is_district))
  expect_true(all(!dist_rows$is_campus))

  # Campus rows
  campus_rows <- flagged[flagged$type == "Campus", ]
  expect_true(all(!campus_rows$is_state))
  expect_true(all(!campus_rows$is_district))
  expect_true(all(campus_rows$is_campus))
})

# --- enr_grade_aggs() calculations -------------------------------------------

test_that("enr_grade_aggs produces exactly 3 grade levels", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  expect_equal(sort(unique(aggs$grade_level)), c("HS", "K12", "K8"))
})

test_that("enr_grade_aggs only uses total_enrollment subgroup", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  expect_equal(unique(aggs$subgroup), "total_enrollment")
})

test_that("enr_grade_aggs K12 = K8 + HS for each entity", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  # Check for campus entities that have all three
  campus_aggs <- aggs[aggs$is_campus, ]

  # Aggregate across all campuses
  k8_total <- sum(campus_aggs$n_students[campus_aggs$grade_level == "K8"],
                  na.rm = TRUE)
  hs_total <- sum(campus_aggs$n_students[campus_aggs$grade_level == "HS"],
                  na.rm = TRUE)
  k12_total <- sum(campus_aggs$n_students[campus_aggs$grade_level == "K12"],
                   na.rm = TRUE)

  expect_equal(k12_total, k8_total + hs_total)
})

test_that("enr_grade_aggs has pct = NA (not calculated for aggregates)", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  expect_true(all(is.na(aggs$pct)))
})

test_that("enr_grade_aggs row count is correct for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  expect_equal(nrow(aggs), 1920L)
})

# --- create_empty_enrollment_df -----------------------------------------------

test_that("create_empty_enrollment_df has 0 rows and correct columns", {
  empty <- nhschooldata:::create_empty_enrollment_df(2024, "Campus")

  expect_equal(nrow(empty), 0L)
  expect_true("end_year" %in% names(empty))
  expect_true("type" %in% names(empty))
  expect_true("district_id" %in% names(empty))
  expect_true("campus_id" %in% names(empty))
  expect_true("row_total" %in% names(empty))
  expect_true("white" %in% names(empty))
  expect_true("black" %in% names(empty))
  expect_true("hispanic" %in% names(empty))
  expect_true("special_ed" %in% names(empty))
  expect_true("lep" %in% names(empty))
  expect_true("econ_disadv" %in% names(empty))
})

# --- create_empty_nhdoe_df ---------------------------------------------------

test_that("create_empty_nhdoe_df school has SSRS columns", {
  empty <- nhschooldata:::create_empty_nhdoe_df("school")

  expect_equal(nrow(empty), 0L)
  expect_true("SCHOOL_ID" %in% names(empty))
  expect_true("SCHOOL_NAME" %in% names(empty))
  expect_true("TOTAL" %in% names(empty))
  expect_true("SAU" %in% names(empty))
})

test_that("create_empty_nhdoe_df district has SSRS columns", {
  empty <- nhschooldata:::create_empty_nhdoe_df("district")

  expect_equal(nrow(empty), 0L)
  expect_true("DISTRICT_ID" %in% names(empty))
  expect_true("DISTRICT_NAME" %in% names(empty))
  expect_true("TOTAL" %in% names(empty))
  expect_true("ELEMENTARY" %in% names(empty))
  expect_true("MIDDLE" %in% names(empty))
  expect_true("HIGH_SCHOOL" %in% names(empty))
})

# --- load_bundled_enr --------------------------------------------------------

test_that("load_bundled_enr returns list with district and school", {
  skip_on_cran()

  result <- load_bundled_enr(2025)

  expect_true(is.list(result))
  expect_true("district" %in% names(result))
  expect_true("school" %in% names(result))
  expect_gt(nrow(result$district), 100)
  expect_gt(nrow(result$school), 400)
})

test_that("load_bundled_enr returns NULL for invalid year", {
  skip_on_cran()

  result <- load_bundled_enr(2050)
  expect_null(result)
})

test_that("load_bundled_enr district data has expected columns", {
  skip_on_cran()

  result <- load_bundled_enr(2025)
  df <- result$district

  expect_true("end_year" %in% names(df))
  expect_true("type" %in% names(df))
  expect_true("district_id" %in% names(df))
  expect_true("district_name" %in% names(df))
  expect_true("row_total" %in% names(df))
  expect_true("sau" %in% names(df))
})

# --- Data type consistency ---------------------------------------------------

test_that("n_students is numeric in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(enr$n_students))
})

test_that("pct is numeric in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(enr$pct))
})

test_that("end_year is numeric in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(is.numeric(enr$end_year))
})

test_that("district_id and campus_id are character in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(enr$district_id))
  expect_true(is.character(enr$campus_id))
})

test_that("subgroup and grade_level are character in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(enr$subgroup))
  expect_true(is.character(enr$grade_level))
})

test_that("type is character in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(is.character(enr$type))
})

# --- nh_enrollment bundled dataset -------------------------------------------

test_that("nh_enrollment bundled dataset loads correctly", {
  skip_on_cran()

  data(nh_enrollment, package = "nhschooldata")
  expect_true(is.data.frame(nh_enrollment))
  expect_gt(nrow(nh_enrollment), 0)
  expect_true("end_year" %in% names(nh_enrollment))
  expect_true("type" %in% names(nh_enrollment))
  expect_true("row_total" %in% names(nh_enrollment))
})
