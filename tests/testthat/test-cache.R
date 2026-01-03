# Tests for cache functions

test_that("get_cache_dir creates directory if needed", {
  cache_dir <- get_cache_dir()

  expect_true(is.character(cache_dir))
  expect_true(dir.exists(cache_dir))
  expect_true(grepl("nhschooldata", cache_dir))
})

test_that("get_cache_path constructs correct paths", {
  path_tidy <- get_cache_path(2024, "tidy")
  path_wide <- get_cache_path(2024, "wide")

  expect_true(grepl("enr_tidy_2024\\.rds$", path_tidy))
  expect_true(grepl("enr_wide_2024\\.rds$", path_wide))
  expect_true(grepl("nhschooldata", path_tidy))
})

test_that("cache_exists returns FALSE for missing files", {
  # Year that definitely won't be cached
  expect_false(cache_exists(1900, "tidy"))
  expect_false(cache_exists(9999, "wide"))
})

test_that("cache round-trip works correctly", {
  # Create test data
  test_df <- data.frame(
    end_year = 9998,
    district_id = "TEST001",
    value = 100,
    stringsAsFactors = FALSE
  )

  # Write to cache
  cache_path <- write_cache(test_df, 9998, "test")
  expect_true(file.exists(cache_path))

  # Read back
  result <- read_cache(9998, "test")
  expect_equal(result$district_id, "TEST001")
  expect_equal(result$value, 100)

  # Clean up
  file.remove(cache_path)
})

test_that("clear_cache removes files", {
  # Create test cache file
  test_df <- data.frame(end_year = 9997, value = 1)
  write_cache(test_df, 9997, "test")

  # Verify it exists
  cache_path <- get_cache_path(9997, "test")
  expect_true(file.exists(cache_path))

  # Clear specific year and type
  clear_cache(end_year = 9997, type = "test")
  expect_false(file.exists(cache_path))
})

test_that("cache_status runs without error", {
  # cache_status prints a table or message, which is expected output
  # we just want to ensure it doesn't error
  expect_no_error(cache_status())
})
