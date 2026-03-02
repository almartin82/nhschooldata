# ==============================================================================
# Exhaustive Enrollment Tests — Pinned values from real NH DOE bundled data
# ==============================================================================
#
# These tests verify enrollment data integrity against known values.
# All values were obtained from the bundled NH DOE data (2012-2026).
# DO NOT fabricate or round any values — every number here was read
# from a real fetch_enr() call.
#
# ==============================================================================

# --- get_available_years() ---------------------------------------------------

test_that("get_available_years returns correct year range", {
  skip_on_cran()
  years <- get_available_years()

  expect_equal(years$min_year, 2012L)
  expect_equal(years$max_year, 2026L)
  expect_equal(years$max_year - years$min_year, 14L)  # 15 years inclusive
  expect_true(grepl("New Hampshire", years$source))
  expect_true(grepl("2012-2026", years$note))
  expect_true(grepl("bundled data available", years$note))
})

# --- Bundled years -----------------------------------------------------------

test_that("bundled data covers 15 years from 2012-2026", {
  skip_on_cran()
  byears <- get_bundled_years()

  expect_equal(length(byears), 15L)
  expect_equal(min(byears), 2012L)

  expect_equal(max(byears), 2026L)
  expect_equal(byears, 2012:2026)
})

test_that("bundled_data_available returns correct booleans", {
  skip_on_cran()

  # Every year 2012-2026 should be available
  for (yr in 2012:2026) {
    expect_true(bundled_data_available(yr), info = paste("Year", yr))
  }

  # Outside range should be FALSE
  expect_false(bundled_data_available(2011))
  expect_false(bundled_data_available(2027))
  expect_false(bundled_data_available(2000))
})

# --- State total enrollment pinned values per year ---------------------------

test_that("state total enrollment is pinned for key years", {
  skip_on_cran()

  pinned <- list(
    "2012" = 190805,
    "2018" = 178328,
    "2020" = 176168,
    "2022" = 168620,
    "2024" = 165082,
    "2025" = 162660,
    "2026" = 160322
  )

  for (yr_str in names(pinned)) {
    yr <- as.integer(yr_str)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    state_total <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                         enr$grade_level == "TOTAL", "n_students"]

    expect_equal(nrow(as.data.frame(state_total)), 1L,
                 info = paste("Exactly 1 state total row for", yr))
    expect_equal(as.numeric(state_total), pinned[[yr_str]],
                 info = paste("State total mismatch for", yr))
  }
})

# --- District count per year -------------------------------------------------

test_that("district count is pinned for key years", {
  skip_on_cran()

  pinned_districts <- list(
    "2012" = 176L,
    "2018" = 190L,
    "2022" = 195L,
    "2025" = 199L,
    "2026" = 203L
  )

  for (yr_str in names(pinned_districts)) {
    yr <- as.integer(yr_str)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    n_dist <- sum(enr$is_district & enr$subgroup == "total_enrollment" &
                    enr$grade_level == "TOTAL")

    expect_equal(n_dist, pinned_districts[[yr_str]],
                 info = paste("District count mismatch for", yr))
  }
})

# --- Campus count per year ---------------------------------------------------

test_that("campus count is pinned for key years", {
  skip_on_cran()

  pinned_campuses <- list(
    "2012" = 476L,
    "2018" = 489L,
    "2022" = 494L,
    "2025" = 500L,
    "2026" = 504L
  )

  for (yr_str in names(pinned_campuses)) {
    yr <- as.integer(yr_str)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    n_camp <- sum(enr$is_campus & enr$subgroup == "total_enrollment" &
                    enr$grade_level == "TOTAL")

    expect_equal(n_camp, pinned_campuses[[yr_str]],
                 info = paste("Campus count mismatch for", yr))
  }
})

# --- Total row count per year ------------------------------------------------

test_that("total row count is pinned for key years", {
  skip_on_cran()

  pinned_rows <- list(
    "2012" = 8840L,
    "2018" = 9146L,
    "2022" = 9276L,
    "2025" = 9400L,
    "2026" = 9492L
  )

  for (yr_str in names(pinned_rows)) {
    yr <- as.integer(yr_str)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_equal(nrow(enr), pinned_rows[[yr_str]],
                 info = paste("Row count mismatch for", yr))
  }
})

# --- Subgroup coverage -------------------------------------------------------

test_that("only total_enrollment subgroup exists (no demographics)", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_equal(sort(unique(enr$subgroup)), "total_enrollment")
})

test_that("wide format has no demographic columns", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  demo_cols <- c("white", "black", "hispanic", "asian", "native_american",
                 "pacific_islander", "multiracial", "male", "female",
                 "special_ed", "lep", "econ_disadv")

  for (col in demo_cols) {
    expect_false(col %in% names(wide),
                 info = paste(col, "should not be in wide format"))
  }
})

# --- Grade level completeness -----------------------------------------------

test_that("state-level grade levels are correct for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  state_grades <- sort(unique(enr$grade_level[enr$is_state]))

  expected <- sort(c("ELEM", "HIGH", "K", "MIDDLE", "PG", "PK", "TOTAL"))
  expect_equal(state_grades, expected)
})

test_that("district-level grade levels match state-level for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  dist_grades <- sort(unique(enr$grade_level[enr$is_district]))

  expected <- sort(c("ELEM", "HIGH", "K", "MIDDLE", "PG", "PK", "TOTAL"))
  expect_equal(dist_grades, expected)
})

test_that("campus-level grade levels include individual grades 01-12 for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  campus_grades <- sort(unique(enr$grade_level[enr$is_campus]))

  expected <- sort(c("01", "02", "03", "04", "05", "06", "07", "08",
                     "09", "10", "11", "12", "K", "PG", "PK", "TOTAL"))
  expect_equal(campus_grades, expected)
})

test_that("all grade levels are uppercase", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  all_grades <- unique(enr$grade_level)

  for (gl in all_grades) {
    expect_equal(gl, toupper(gl), info = paste("Grade level not uppercase:", gl))
  }
})

test_that("EE grade level does not exist in NH data", {
  skip_on_cran()

  # EE is listed as possible in schema but NH data does not have it
  for (yr in c(2012, 2018, 2026)) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_equal(sum(enr$grade_level == "EE"), 0L,
                 info = paste("EE should not exist in year", yr))
  }
})

# --- State grade distribution pinned values for 2026 -------------------------

test_that("state grade distribution is pinned for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  state_grades <- enr[enr$is_state & enr$subgroup == "total_enrollment", ]

  pinned <- list(
    "PK"     = 4395,
    "K"      = 10727,
    "ELEM"   = 64705,
    "MIDDLE" = 30277,
    "HIGH"   = 50144,
    "PG"     = 74,
    "TOTAL"  = 160322
  )

  for (gl in names(pinned)) {
    val <- state_grades$n_students[state_grades$grade_level == gl]
    expect_equal(length(val), 1L, info = paste("Exactly 1 row for grade", gl))
    expect_equal(val, pinned[[gl]], info = paste("State grade mismatch for", gl))
  }
})

test_that("state non-TOTAL grades sum to state TOTAL for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  state_grades <- enr[enr$is_state & enr$subgroup == "total_enrollment", ]

  non_total <- state_grades[state_grades$grade_level != "TOTAL", ]
  total <- state_grades[state_grades$grade_level == "TOTAL", ]

  expect_equal(sum(non_total$n_students), total$n_students)
})

# --- Known district values ---------------------------------------------------

test_that("Manchester district enrollment is pinned across years", {
  skip_on_cran()

  pinned <- list(
    "2012" = 15536,
    "2018" = 13621,
    "2022" = 12428,
    "2026" = 11712
  )

  for (yr_str in names(pinned)) {
    yr <- as.integer(yr_str)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    m <- enr[enr$is_district & enr$subgroup == "total_enrollment" &
               enr$grade_level == "TOTAL" &
               grepl("Manchester", enr$district_name, ignore.case = TRUE), ]

    expect_equal(nrow(m), 1L, info = paste("Exactly 1 Manchester row for", yr))
    expect_equal(m$n_students, pinned[[yr_str]],
                 info = paste("Manchester mismatch for", yr))
    expect_equal(m$district_name, "Manchester",
                 info = paste("Manchester name mismatch for", yr))
    expect_equal(m$district_id, "335",
                 info = paste("Manchester ID mismatch for", yr))
  }
})

test_that("Nashua district enrollment is pinned across years", {
  skip_on_cran()

  pinned <- list(
    "2012" = 11894,
    "2018" = 11075,
    "2022" = 10138,
    "2026" = 9501
  )

  for (yr_str in names(pinned)) {
    yr <- as.integer(yr_str)
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    n <- enr[enr$is_district & enr$subgroup == "total_enrollment" &
               enr$grade_level == "TOTAL" &
               grepl("Nashua", enr$district_name, ignore.case = TRUE), ]

    expect_equal(nrow(n), 1L, info = paste("Exactly 1 Nashua row for", yr))
    expect_equal(n$n_students, pinned[[yr_str]],
                 info = paste("Nashua mismatch for", yr))
    expect_equal(n$district_name, "Nashua",
                 info = paste("Nashua name mismatch for", yr))
  }
})

test_that("Concord district enrollment is pinned for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  c <- enr[enr$is_district & enr$subgroup == "total_enrollment" &
             enr$grade_level == "TOTAL" &
             grepl("Concord", enr$district_name, ignore.case = TRUE), ]

  expect_equal(nrow(c), 1L)
  expect_equal(c$n_students, 3755)
  expect_equal(c$district_name, "Concord")
})

# --- Wide vs tidy fidelity ---------------------------------------------------

test_that("wide format row count matches expected for 2026", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)

  expect_equal(nrow(wide), 708L)
  expect_equal(sum(wide$type == "State"), 1L)
  expect_equal(sum(wide$type == "District"), 203L)
  expect_equal(sum(wide$type == "Campus"), 504L)
})

test_that("wide state row_total matches tidy state total for 2026", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  wide_state <- wide[wide$type == "State", "row_total"]
  tidy_state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL", "n_students"]

  expect_equal(as.numeric(wide_state), as.numeric(tidy_state))
})

test_that("wide format has expected columns for 2026", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)

  required_cols <- c(
    "end_year", "type", "district_id", "campus_id",
    "district_name", "campus_name", "sau", "sau_name",
    "county", "charter_flag", "row_total",
    "grade_pk", "grade_k", "grade_elem", "grade_middle",
    "grade_high", "grade_pg",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  for (col in required_cols) {
    expect_true(col %in% names(wide), info = paste("Missing column:", col))
  }
})

test_that("wide campus row_total equals sum of individual grades", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  campuses <- wide[wide$type == "Campus", ]

  # First campus as a spot check
  campus1 <- campuses[1, ]
  ind_grades <- c("grade_pk", "grade_k", "grade_01", "grade_02", "grade_03",
                  "grade_04", "grade_05", "grade_06", "grade_07", "grade_08",
                  "grade_09", "grade_10", "grade_11", "grade_12", "grade_pg")
  ind_sum <- sum(sapply(ind_grades, function(g) {
    val <- campus1[[g]]
    if (is.na(val)) 0 else as.numeric(val)
  }))

  expect_equal(ind_sum, as.numeric(campus1$row_total),
               info = paste("Campus", campus1$campus_name, "grade sum != row_total"))
})

test_that("sum of district totals equals state total (wide) for 2026", {
  skip_on_cran()

  wide <- fetch_enr(2026, tidy = FALSE, use_cache = TRUE)
  dist_sum <- sum(wide$row_total[wide$type == "District"], na.rm = TRUE)
  state_total <- wide$row_total[wide$type == "State"]

  expect_equal(dist_sum, state_total)
})

# --- Entity flag mutual exclusivity ------------------------------------------

test_that("entity flags are mutually exclusive", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  # Each row should have exactly one TRUE among is_state, is_district, is_campus
  flag_sum <- as.integer(enr$is_state) + as.integer(enr$is_district) +
    as.integer(enr$is_campus)
  expect_true(all(flag_sum == 1L),
              info = "Every row must have exactly one entity flag TRUE")
})

test_that("entity type column matches entity flags", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  expect_true(all(enr$is_state == (enr$type == "State")))
  expect_true(all(enr$is_district == (enr$type == "District")))
  expect_true(all(enr$is_campus == (enr$type == "Campus")))
})

test_that("type column has exactly 3 levels", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_equal(sort(unique(enr$type)), c("Campus", "District", "State"))
})

test_that("aggregation_flag column has correct values", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_equal(sort(unique(enr$aggregation_flag)),
               c("campus", "district", "state"))
})

# --- Charter flag behavior ---------------------------------------------------

test_that("charter_flag is all NA in NH data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(all(is.na(enr$charter_flag)))
})

test_that("is_charter is all FALSE when charter_flag is NA", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(all(!enr$is_charter))
  expect_equal(sum(enr$is_charter), 0L)
})

# --- SAU and county columns --------------------------------------------------

test_that("SAU columns are populated for non-state rows", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  non_state <- enr[!enr$is_state, ]

  # SAU should be mostly populated
  sau_non_na <- sum(!is.na(non_state$sau))
  sau_pct <- sau_non_na / nrow(non_state)
  expect_true(sau_pct > 0.99,
              info = "SAU should be populated for >99% of non-state rows")

  # SAU name should match
  sau_name_non_na <- sum(!is.na(non_state$sau_name))
  expect_equal(sau_non_na, sau_name_non_na)
})

test_that("county column is NA in NH data (not provided by iPlatform)", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(all(is.na(enr$county)))
})

test_that("SAU examples are correct for known districts", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  # Manchester should have SAU
  m <- enr[enr$is_district & enr$subgroup == "total_enrollment" &
             enr$grade_level == "TOTAL" &
             enr$district_name == "Manchester", ]
  expect_false(is.na(m$sau))
  expect_false(is.na(m$sau_name))
})

# --- Cross-year consistency --------------------------------------------------

test_that("district count changes by less than 10% year-over-year", {
  skip_on_cran()

  years_to_check <- c(2012, 2016, 2020, 2024, 2026)
  dist_counts <- integer(length(years_to_check))

  for (i in seq_along(years_to_check)) {
    enr <- fetch_enr(years_to_check[i], tidy = TRUE, use_cache = TRUE)
    dist_counts[i] <- sum(enr$is_district & enr$subgroup == "total_enrollment" &
                            enr$grade_level == "TOTAL")
  }

  for (i in 2:length(dist_counts)) {
    pct_change <- abs(dist_counts[i] - dist_counts[i - 1]) / dist_counts[i - 1]
    expect_true(pct_change < 0.10,
                info = paste("District count changed >10% between",
                             years_to_check[i - 1], "and", years_to_check[i]))
  }
})

test_that("state enrollment changes by less than 10% year-over-year", {
  skip_on_cran()

  years_to_check <- c(2012, 2016, 2020, 2024, 2026)
  state_totals <- numeric(length(years_to_check))

  for (i in seq_along(years_to_check)) {
    enr <- fetch_enr(years_to_check[i], tidy = TRUE, use_cache = TRUE)
    state_totals[i] <- enr$n_students[enr$is_state &
                                        enr$subgroup == "total_enrollment" &
                                        enr$grade_level == "TOTAL"]
  }

  for (i in 2:length(state_totals)) {
    pct_change <- abs(state_totals[i] - state_totals[i - 1]) / state_totals[i - 1]
    expect_true(pct_change < 0.10,
                info = paste("State total changed >10% between",
                             years_to_check[i - 1], "and", years_to_check[i]))
  }
})

test_that("Manchester district ID is consistent across all years", {
  skip_on_cran()

  for (yr in c(2012, 2018, 2022, 2026)) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    m <- enr[enr$is_district & enr$subgroup == "total_enrollment" &
               enr$grade_level == "TOTAL" &
               enr$district_name == "Manchester", ]

    expect_equal(m$district_id, "335",
                 info = paste("Manchester ID should be 335 in year", yr))
  }
})

# --- Grade aggregations (enr_grade_aggs) -------------------------------------

test_that("enr_grade_aggs produces K8, HS, K12 grade levels", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  expect_equal(sort(unique(aggs$grade_level)), c("HS", "K12", "K8"))
})

test_that("enr_grade_aggs campus-level sums are correct for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  campus_k8 <- sum(aggs$n_students[aggs$is_campus & aggs$grade_level == "K8"],
                   na.rm = TRUE)
  campus_hs <- sum(aggs$n_students[aggs$is_campus & aggs$grade_level == "HS"],
                   na.rm = TRUE)
  campus_k12 <- sum(aggs$n_students[aggs$is_campus & aggs$grade_level == "K12"],
                    na.rm = TRUE)

  expect_equal(campus_k8, 105709)
  expect_equal(campus_hs, 50096)
  expect_equal(campus_k12, 155805)

  # K12 should equal K8 + HS
  expect_equal(campus_k12, campus_k8 + campus_hs)
})

test_that("enr_grade_aggs state-level only aggregates from K (individual grades missing)", {
  skip_on_cran()

  # State level only has ELEM/MIDDLE/HIGH, not 01-12
  # So K8 = K (only grade matching K, 01-08 at state level is K)
  # HS = 0 (no 09-12 at state level)
  # K12 = K
  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(enr)

  state_aggs <- aggs[aggs$is_state, ]
  expect_equal(nrow(state_aggs), 2L)  # K8 and K12 only (HS would be 0 and filtered)

  state_k8 <- state_aggs$n_students[state_aggs$grade_level == "K8"]
  expect_equal(state_k8, 10727)  # Only K matches at state level

  state_k12 <- state_aggs$n_students[state_aggs$grade_level == "K12"]
  expect_equal(state_k12, 10727)  # Only K matches at state level
})

# --- Multi-year fetch --------------------------------------------------------

test_that("fetch_enr_multi returns combined data with correct years", {
  skip_on_cran()

  years <- c(2020, 2022, 2024, 2026)
  enr_multi <- fetch_enr_multi(years, use_cache = TRUE)

  expect_equal(sort(unique(enr_multi$end_year)), years)
  expect_equal(nrow(enr_multi), 37524L)
})

test_that("fetch_enr_multi state totals match single-year fetches", {
  skip_on_cran()

  years <- c(2020, 2026)
  enr_multi <- fetch_enr_multi(years, use_cache = TRUE)

  for (yr in years) {
    multi_total <- enr_multi$n_students[enr_multi$is_state &
                                          enr_multi$subgroup == "total_enrollment" &
                                          enr_multi$grade_level == "TOTAL" &
                                          enr_multi$end_year == yr]
    single <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    single_total <- single$n_students[single$is_state &
                                        single$subgroup == "total_enrollment" &
                                        single$grade_level == "TOTAL"]

    expect_equal(multi_total, single_total,
                 info = paste("Multi vs single mismatch for", yr))
  }
})

# --- Data quality checks -----------------------------------------------------

test_that("no negative enrollment counts in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  non_na <- enr$n_students[!is.na(enr$n_students)]
  expect_true(all(non_na >= 0))
})

test_that("no Inf or NaN in enrollment data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_false(any(is.infinite(enr$n_students)))
  expect_false(any(is.nan(enr$n_students)))
  expect_false(any(is.infinite(enr$pct), na.rm = TRUE))
  expect_false(any(is.nan(enr$pct), na.rm = TRUE))
})

test_that("pct values are between 0 and 1", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  non_na_pct <- enr$pct[!is.na(enr$pct)]

  expect_true(all(non_na_pct >= 0), info = "pct should be >= 0")
  expect_true(all(non_na_pct <= 1), info = "pct should be <= 1")
})

test_that("pct equals 1.0 for total_enrollment TOTAL rows", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  totals <- enr[enr$subgroup == "total_enrollment" & enr$grade_level == "TOTAL", ]

  # All these should have pct = 1
  expect_true(all(totals$pct == 1.0))
  expect_equal(nrow(totals), 708L)  # 1 state + 203 districts + 504 campuses
})

test_that("no duplicate rows in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  key <- paste(enr$type, enr$district_id, enr$campus_id,
               enr$subgroup, enr$grade_level, sep = "|")
  expect_equal(length(key), length(unique(key)),
               info = "No duplicate rows by type+district+campus+subgroup+grade")
})

test_that("no NA in n_students (all rows are non-NA after tidy filtering)", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  # tidy_enr filters out NA n_students
  expect_false(any(is.na(enr$n_students)))
})

test_that("state total equals sum of district totals in tidy data for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  state_total <- enr$n_students[enr$is_state & enr$subgroup == "total_enrollment" &
                                  enr$grade_level == "TOTAL"]
  dist_sum <- sum(enr$n_students[enr$is_district & enr$subgroup == "total_enrollment" &
                                   enr$grade_level == "TOTAL"])

  expect_equal(dist_sum, state_total)
})

# --- Tidy column structure ---------------------------------------------------

test_that("tidy format has all expected columns", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  required_cols <- c(
    "end_year", "type", "district_id", "campus_id",
    "district_name", "campus_name", "sau", "sau_name",
    "county", "charter_flag", "grade_level", "subgroup",
    "n_students", "pct", "is_state", "is_district",
    "is_campus", "aggregation_flag", "is_charter"
  )

  for (col in required_cols) {
    expect_true(col %in% names(enr), info = paste("Missing tidy column:", col))
  }
})

test_that("end_year is correct in tidy data", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  expect_true(all(enr$end_year == 2026L))
})

# --- Campus-level grade totals pinned for 2026 --------------------------------

test_that("campus-level grade totals are pinned for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  campus_data <- enr[enr$is_campus & enr$subgroup == "total_enrollment", ]

  pinned <- list(
    "01" = 11169,
    "02" = 11331,
    "03" = 11677,
    "04" = 12160,
    "05" = 11983,
    "06" = 12095,
    "07" = 12311,
    "08" = 12256,
    "09" = 13156,
    "10" = 12213,
    "11" = 12339,
    "12" = 12388,
    "K"  = 10727,
    "PG" = 73,
    "PK" = 4395,
    "TOTAL" = 160273
  )

  for (gl in names(pinned)) {
    total <- sum(campus_data$n_students[campus_data$grade_level == gl], na.rm = TRUE)
    expect_equal(total, pinned[[gl]],
                 info = paste("Campus grade total mismatch for", gl))
  }
})

# --- Manchester has 20 campuses (most in the state) --------------------------

test_that("Manchester has the most campuses in the state (20) for 2026", {
  skip_on_cran()

  enr <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)
  camp_per_dist <- tapply(
    enr$campus_id[enr$is_campus & enr$subgroup == "total_enrollment" &
                    enr$grade_level == "TOTAL"],
    enr$district_name[enr$is_campus & enr$subgroup == "total_enrollment" &
                        enr$grade_level == "TOTAL"],
    function(x) length(unique(x))
  )

  expect_equal(max(camp_per_dist), 20L)
  expect_equal(names(which.max(camp_per_dist)), "Manchester")
})

# --- Wide format for 2012 ----------------------------------------------------

test_that("wide format row count is correct for 2012", {
  skip_on_cran()

  wide <- fetch_enr(2012, tidy = FALSE, use_cache = TRUE)

  expect_equal(nrow(wide), 653L)
  expect_equal(sum(wide$type == "District"), 176L)
  expect_equal(sum(wide$type == "Campus"), 476L)
  expect_equal(sum(wide$type == "State"), 1L)
})

# --- NH enrollment declining trend -------------------------------------------

test_that("NH enrollment shows declining trend 2012-2026", {
  skip_on_cran()

  enr_2012 <- fetch_enr(2012, tidy = TRUE, use_cache = TRUE)
  enr_2026 <- fetch_enr(2026, tidy = TRUE, use_cache = TRUE)

  total_2012 <- enr_2012$n_students[enr_2012$is_state &
                                      enr_2012$subgroup == "total_enrollment" &
                                      enr_2012$grade_level == "TOTAL"]
  total_2026 <- enr_2026$n_students[enr_2026$is_state &
                                      enr_2026$subgroup == "total_enrollment" &
                                      enr_2026$grade_level == "TOTAL"]

  expect_true(total_2012 > total_2026,
              info = "NH enrollment should be declining from 2012 to 2026")
  # About 16% decline
  pct_decline <- (total_2012 - total_2026) / total_2012
  expect_true(pct_decline > 0.10)
  expect_true(pct_decline < 0.25)
})
