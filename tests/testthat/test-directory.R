# ==============================================================================
# Tests for fetch_directory() and related functions
# ==============================================================================
#
# These tests verify the school directory data pipeline.
# Live network tests are skipped when offline or on CRAN.
#
# ==============================================================================

library(testthat)

# ==============================================================================
# Helper: skip conditions
# ==============================================================================

skip_if_no_directory_data <- function() {
  dir_file <- system.file("extdata", "nh_directory.rds",
                           package = "nhschooldata")
  if (dir_file == "") {
    skip("No bundled directory data available")
  }
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("NH DOE Profiles URL is well-formed", {
  skip_on_cran()

  url <- nhschooldata:::build_directory_url()
  expect_true(is.character(url))
  expect_true(grepl("^https://", url))
  expect_true(grepl("my.doe.nh.gov", url))
  expect_true(grepl("SchoolList", url))
})

# ==============================================================================
# STEP 2: Bundled Data Tests
# ==============================================================================

test_that("load_bundled_directory returns data or NULL gracefully", {
  skip_on_cran()

  result <- nhschooldata:::load_bundled_directory()

  # Should either be NULL (no bundled data yet) or a data frame

  if (!is.null(result)) {
    expect_true(is.data.frame(result))
    expect_gt(nrow(result), 0)
  }
})

# ==============================================================================
# STEP 3: Processing Tests (unit tests with mock data)
# ==============================================================================

test_that("process_directory handles standard column names", {
  skip_on_cran()

  # Create minimal mock data with expected column names
  mock_data <- data.frame(
    SAU = c("1", "1", "48"),
    SAU_NAME = c("Contoocook Valley", "Contoocook Valley", "Plymouth"),
    DISTRICT_ID = c("100", "100", "200"),
    DISTRICT_NAME = c("Peterborough", "Peterborough", "Plymouth"),
    SCHOOL_ID = c("10001", "10002", "20001"),
    SCHOOL_NAME = c("Peterborough Elementary", "South Meadow School",
                     "Plymouth Elementary"),
    ADDRESS = c("123 Main St", "456 Oak Ave", "789 Elm St"),
    CITY = c("Peterborough", "Peterborough", "Plymouth"),
    ZIP = c("03458", "03458", "03264"),
    PHONE = c("603-555-0100", "603-555-0200", "603-555-0300"),
    GRADES = c("K-4", "5-8", "K-5"),
    PRINCIPAL = c("John Smith", "Jane Doe", "Bob Wilson"),
    stringsAsFactors = FALSE
  )

  result <- nhschooldata:::process_directory(mock_data)

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 3)

  # Check required columns exist
  required_cols <- c("sau_number", "state_district_id", "state_school_id",
                      "district_name", "school_name", "entity_type",
                      "address", "city", "state", "zip", "phone",
                      "grades_served", "principal_name")
  for (col in required_cols) {
    expect_true(col %in% names(result),
                info = paste("Missing column:", col))
  }

  # Check values
  expect_equal(result$state[1], "NH")
  expect_equal(result$entity_type[1], "school")
  expect_equal(result$sau_number[1], "1")
  expect_equal(result$school_name[1], "Peterborough Elementary")
  expect_equal(result$principal_name[1], "John Smith")
})

test_that("process_directory handles alternative column names", {
  skip_on_cran()

  # Test with alternative NH DOE column naming (e.g., SAUID, DSTID, SCHID)
  mock_data <- data.frame(
    SAUID = c("10"),
    SAUNAME = c("Derry"),
    DSTID = c("300"),
    DSTNAME = c("Derry"),
    SCHID = c("30001"),
    SCHNAME = c("Derry Village School"),
    ADDRESS = c("28 South Main St"),
    CITY = c("Derry"),
    ZIP = c("03038"),
    PHONE = c("603-432-1234"),
    GRADES = c("1-4"),
    PRINCIPAL = c("Alice Johnson"),
    stringsAsFactors = FALSE
  )

  result <- nhschooldata:::process_directory(mock_data)

  expect_equal(nrow(result), 1)
  expect_equal(result$sau_number[1], "10")
  expect_equal(result$district_name[1], "Derry")
  expect_equal(result$school_name[1], "Derry Village School")
})

test_that("process_directory derives charter school type", {
  skip_on_cran()

  mock_data <- data.frame(
    SAU = c("400", "401"),
    SAU_NAME = c("VLACS", "Gate City"),
    DISTRICT_ID = c("400", "401"),
    DISTRICT_NAME = c("VLACS", "Gate City"),
    SCHOOL_ID = c("40001", "40101"),
    SCHOOL_NAME = c("Virtual Learning Academy Charter School",
                     "Gate City Charter School For the Arts"),
    ADDRESS = c("1 Main St", "2 Main St"),
    CITY = c("Exeter", "Nashua"),
    ZIP = c("03833", "03060"),
    PHONE = c("603-778-1234", "603-886-1234"),
    GRADES = c("6-12", "5-8"),
    PRINCIPAL = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )

  result <- nhschooldata:::process_directory(mock_data)

  expect_equal(result$school_type[1], "Charter")
  expect_equal(result$school_type[2], "Charter")
})

# ==============================================================================
# STEP 4: extract_column Tests
# ==============================================================================

test_that("extract_column finds column by name", {
  skip_on_cran()

  df <- data.frame(SAU = c("1", "2"), OTHER = c("a", "b"),
                    stringsAsFactors = FALSE)

  result <- nhschooldata:::extract_column(df, c("SAU", "SAUID"))
  expect_equal(result, c("1", "2"))
})

test_that("extract_column falls through to second name", {
  skip_on_cran()

  df <- data.frame(SAUID = c("1", "2"), OTHER = c("a", "b"),
                    stringsAsFactors = FALSE)

  result <- nhschooldata:::extract_column(df, c("SAU", "SAUID"))
  expect_equal(result, c("1", "2"))
})

test_that("extract_column returns NA when no match", {
  skip_on_cran()

  df <- data.frame(FOO = c("a", "b"), BAR = c("c", "d"),
                    stringsAsFactors = FALSE)

  result <- nhschooldata:::extract_column(df, c("SAU", "SAUID"))
  expect_equal(result, c(NA_character_, NA_character_))
})

# ==============================================================================
# STEP 5: Cache Round-Trip Tests
# ==============================================================================

test_that("directory cache write and read round-trip works", {
  skip_on_cran()

  test_data <- data.frame(
    school_name = c("Test School A", "Test School B"),
    city = c("Concord", "Manchester"),
    stringsAsFactors = FALSE
  )

  cache_type <- "directory_test_roundtrip"

  # Write
  nhschooldata:::write_cache_directory(test_data, cache_type)

  # Verify cache exists
  expect_true(nhschooldata:::cache_exists_directory(cache_type))

  # Read back
  cached <- nhschooldata:::read_cache_directory(cache_type)
  expect_equal(nrow(cached), 2)
  expect_equal(cached$school_name, c("Test School A", "Test School B"))

  # Clean up
  cache_path <- nhschooldata:::build_cache_path_directory(cache_type)
  unlink(cache_path)
})

test_that("cache_exists_directory returns FALSE for missing cache", {
  skip_on_cran()

  expect_false(nhschooldata:::cache_exists_directory("directory_nonexistent"))
})

# ==============================================================================
# STEP 6: clear_directory_cache Tests
# ==============================================================================

test_that("clear_directory_cache handles empty cache", {
  skip_on_cran()

  # Should not error
  expect_message(clear_directory_cache(), "No cached directory|removed|does not")
})

# ==============================================================================
# STEP 7: import_local_directory Tests
# ==============================================================================

test_that("import_local_directory errors on missing file", {
  skip_on_cran()

  expect_error(
    import_local_directory("/tmp/nonexistent_file.csv"),
    "File not found"
  )
})

test_that("import_local_directory reads CSV file", {
  skip_on_cran()

  # Create test CSV
  tfile <- tempfile(fileext = ".csv")
  write.csv(
    data.frame(
      SAU = "1",
      SCHOOL_NAME = "Test School",
      CITY = "Concord",
      stringsAsFactors = FALSE
    ),
    tfile,
    row.names = FALSE
  )

  result <- import_local_directory(tfile)
  expect_equal(nrow(result), 1)
  expect_true("SCHOOL_NAME" %in% names(result) || "school_name" %in% names(result))

  unlink(tfile)
})

test_that("import_local_directory rejects unsupported formats", {
  skip_on_cran()

  tfile <- tempfile(fileext = ".json")
  writeLines("{}", tfile)

  expect_error(
    import_local_directory(tfile),
    "Unsupported file type"
  )

  unlink(tfile)
})

# ==============================================================================
# STEP 8: Integration Tests (with bundled data if available)
# ==============================================================================

test_that("fetch_directory returns tidy data with expected schema", {
  skip_on_cran()
  skip_if_no_directory_data()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  expect_true(is.data.frame(dir_data))
  expect_gt(nrow(dir_data), 0)

  # Check required tidy columns
  required_cols <- c("sau_number", "state_district_id", "school_name",
                      "entity_type", "state")
  for (col in required_cols) {
    expect_true(col %in% names(dir_data),
                info = paste("Missing column:", col))
  }

  # All records should be NH
  expect_true(all(dir_data$state == "NH", na.rm = TRUE))

  # Entity type should be "school"
  expect_true(all(dir_data$entity_type == "school", na.rm = TRUE))
})

test_that("fetch_directory raw format preserves original columns", {
  skip_on_cran()
  skip_if_no_directory_data()

  dir_raw <- fetch_directory(tidy = FALSE, use_cache = FALSE)

  expect_true(is.data.frame(dir_raw))
  expect_gt(nrow(dir_raw), 0)
})

test_that("directory data has multiple SAUs", {
  skip_on_cran()
  skip_if_no_directory_data()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # NH has ~80+ SAUs
  n_saus <- length(unique(dir_data$sau_number[!is.na(dir_data$sau_number)]))
  expect_gt(n_saus, 10,
            label = "Should have multiple SAUs")
})

test_that("directory data has many schools", {
  skip_on_cran()
  skip_if_no_directory_data()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # NH has ~500 schools
  expect_gt(nrow(dir_data), 100,
            label = "Should have 100+ school records")
})

test_that("directory data includes charter schools", {
  skip_on_cran()
  skip_if_no_directory_data()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # NH has ~30+ charter schools
  charters <- dir_data[!is.na(dir_data$school_type) &
                         dir_data$school_type == "Charter", ]
  expect_gt(nrow(charters), 0,
            label = "Should have at least some charter schools")
})

test_that("most schools have addresses", {
  skip_on_cran()
  skip_if_no_directory_data()

  dir_data <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  pct_with_address <- mean(!is.na(dir_data$address) & dir_data$address != "")
  expect_gt(pct_with_address, 0.5,
            label = "More than half of schools should have addresses")
})

# ==============================================================================
# STEP 9: Raw vs Tidy Fidelity
# ==============================================================================

test_that("tidy output has same number of rows as raw", {
  skip_on_cran()
  skip_if_no_directory_data()

  raw <- fetch_directory(tidy = FALSE, use_cache = FALSE)
  tidy <- fetch_directory(tidy = TRUE, use_cache = FALSE)

  # process_directory should not add or remove rows
  expect_equal(nrow(tidy), nrow(raw))
})
