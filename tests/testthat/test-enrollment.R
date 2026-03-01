# Tests for enrollment functions
# Note: Most integration tests are marked as skip_on_cran since they require
# network access or bundled data (which is not yet available)

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("N/A")))
  expect_true(is.na(safe_numeric("n/a")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_available_years returns valid range", {
  years <- get_available_years()

  expect_true(is.list(years))
  expect_true("min_year" %in% names(years))
  expect_true("max_year" %in% names(years))
  expect_true("source" %in% names(years))
  expect_true(years$min_year <= years$max_year)
  # NH DOE iPlatform provides approximately 10 years of data
  expect_true(years$max_year - years$min_year >= 5)
  expect_true(years$max_year - years$min_year <= 15)
  expect_true(grepl("New Hampshire", years$source))
})

test_that("validate_year rejects invalid years", {
  # Years too far in the past (NH DOE only has ~10 years of data)
  expect_error(validate_year(1990), "end_year must be between")
  # Years in the future
  expect_error(validate_year(2050), "end_year must be between")
  # Non-numeric inputs
  expect_error(validate_year("2020"), "must be a single numeric value")
  expect_error(validate_year(c(2020, 2021)), "must be a single numeric value")
})

test_that("validate_year accepts valid years", {
  years <- get_available_years()
  # Test a year in the middle of the available range
  mid_year <- as.integer(mean(c(years$min_year, years$max_year)))
  expect_true(validate_year(mid_year))
  expect_true(validate_year(years$min_year))
  expect_true(validate_year(years$max_year))
})

test_that("format_school_year formats correctly", {
  expect_equal(format_school_year(2024), "2023-24")
  expect_equal(format_school_year(2020), "2019-20")
  expect_equal(format_school_year(2000), "1999-00")
})

test_that("clean_names removes extra whitespace", {
  expect_equal(clean_names("  Manchester  "), "Manchester")
  expect_equal(clean_names("School  District"), "School District")
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("nhschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("create_empty_enrollment_df returns correct structure", {
  empty_df <- create_empty_enrollment_df(2024, "Campus")

  expect_true(is.data.frame(empty_df))
  expect_equal(nrow(empty_df), 0)
  expect_true("end_year" %in% names(empty_df))
  expect_true("type" %in% names(empty_df))
  expect_true("district_id" %in% names(empty_df))
  expect_true("campus_id" %in% names(empty_df))
  expect_true("row_total" %in% names(empty_df))
})

test_that("create_empty_nhdoe_df returns correct structure", {
  school_df <- create_empty_nhdoe_df("school")
  district_df <- create_empty_nhdoe_df("district")

  expect_true(is.data.frame(school_df))
  expect_true(is.data.frame(district_df))
  expect_equal(nrow(school_df), 0)
  expect_equal(nrow(district_df), 0)
  expect_true("TOTAL" %in% names(school_df))
  expect_true("TOTAL" %in% names(district_df))
})

test_that("import_local_enrollment rejects missing files", {
  expect_error(
    import_local_enrollment("/nonexistent/file.xlsx", 2024, "school"),
    "File not found"
  )
})

test_that("import_local_enrollment rejects unsupported file types", {
  # Create a temp file with unsupported extension
  temp_file <- tempfile(fileext = ".pdf")
  file.create(temp_file)

  expect_error(
    import_local_enrollment(temp_file, 2024, "school"),
    "Unsupported file type"
  )

  unlink(temp_file)
})

test_that("bundled_data_available returns TRUE for bundled years", {
  expect_true(bundled_data_available(2024))
  expect_true(bundled_data_available(2020))
  expect_true(bundled_data_available(2012))
  expect_true(bundled_data_available(2026))
  expect_false(bundled_data_available(2011))
  expect_false(bundled_data_available(2027))
})

test_that("get_bundled_years returns expected range", {
  result <- get_bundled_years()
  expect_true(!is.null(result))
  expect_true(length(result) >= 15)
  expect_true(2012 %in% result)
  expect_true(2026 %in% result)
})

test_that("load_bundled_enr returns data for valid year", {
  bundled <- load_bundled_enr(2025)
  expect_true(!is.null(bundled))
  expect_true(is.list(bundled))
  expect_true("district" %in% names(bundled))
  expect_true("school" %in% names(bundled))
  expect_gt(nrow(bundled$district), 100)
  expect_gt(nrow(bundled$school), 400)
})

test_that("fetch_enr returns tidy data with expected columns", {
  enr <- fetch_enr(2025, use_cache = FALSE)
  expect_gt(nrow(enr), 0)
  expect_true("is_state" %in% names(enr))
  expect_true("is_district" %in% names(enr))
  expect_true("is_campus" %in% names(enr))
  expect_true("subgroup" %in% names(enr))
  expect_true("grade_level" %in% names(enr))
  expect_true("n_students" %in% names(enr))

  # State total should be reasonable (150K-200K)
  state <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                 enr$grade_level == "TOTAL", ]
  expect_equal(nrow(state), 1)
  expect_gt(state$n_students, 150000)
  expect_lt(state$n_students, 200000)
})

test_that("no negative enrollment values", {
  enr <- fetch_enr(2025, use_cache = FALSE)
  numeric_cols <- names(enr)[sapply(enr, is.numeric)]
  for (col in numeric_cols) {
    vals <- enr[[col]]
    vals <- vals[!is.na(vals)]
    if (col == "n_students") {
      expect_true(all(vals >= 0), info = paste("Non-negative", col))
    }
  }
})

test_that("no Inf or NaN in enrollment data", {
  enr <- fetch_enr(2025, use_cache = FALSE)
  numeric_cols <- names(enr)[sapply(enr, is.numeric)]
  for (col in numeric_cols) {
    vals <- enr[[col]]
    expect_false(any(is.infinite(vals), na.rm = TRUE),
                 info = paste("No Inf in", col))
    expect_false(any(is.nan(vals), na.rm = TRUE),
                 info = paste("No NaN in", col))
  }
})

test_that("fetch_enr_multi validates year parameters", {
  avail <- get_available_years()

  expect_error(
    fetch_enr_multi(c(2020, 1990)),
    "Invalid years"
  )

  expect_error(
    fetch_enr_multi(c(2020, 2050)),
    "Invalid years"
  )
})
