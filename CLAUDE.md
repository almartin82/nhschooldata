## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

---


# Claude Code Instructions

### GIT COMMIT POLICY
- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

---

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally BEFORE opening a PR:

### CI Checks That Must Pass

| Check | Local Command | What It Tests |
|-------|---------------|---------------|
| R-CMD-check | `devtools::check()` | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pynhschooldata.py -v` | Python wrapper works correctly |
| pkgdown | `pkgdown::build_site()` | Documentation and vignettes render |

### Quick Commands

```r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pynhschooldata && pytest tests/test_pynhschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify:
- [ ] `devtools::check()` — 0 errors, 0 warnings
- [ ] `pytest tests/test_pynhschooldata.py` — all tests pass
- [ ] `pkgdown::build_site()` — builds without errors
- [ ] Vignettes render (no `eval=FALSE` hacks)

---

# nhschooldata Package Documentation

## Package Overview

`nhschooldata` provides a simple, consistent interface for accessing New Hampshire school enrollment data from the NH Department of Education (NH DOE).

## Data Source

**Primary Source**: NH DOE iPlatform Public Reports
- URL: https://my.doe.nh.gov/iPlatform
- Note: iPlatform requires browser-based access and may require authentication

**Available Years**: 2015-2025 (approximately 10 years of historical data)

## Current Status

**IMPORTANT**: The NH DOE iPlatform requires browser-based access. The automatic download functionality may fail, requiring users to:

1. Visit the iPlatform directly:
   - District enrollment: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9
   - School enrollment: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10

2. Download the Excel files manually

3. Use `import_local_enrollment()` to load the data:
   ```r
   df <- import_local_enrollment("~/Downloads/district-fall-enrollment.xlsx", 2024, "district")
   ```

## Key Functions

### Main API

```r
# Fetch enrollment data for a single year
enr <- fetch_enr(2024)  # 2023-24 school year

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# Get wide format (one row per district/school)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Import manually downloaded file
df <- import_local_enrollment("path/to/file.xlsx", 2024, "school")
```

### Helper Functions

```r
# Available years
get_available_years()

# Check cache
cache_exists(2024, "tidy")
clear_cache()
```

## Data Structure

### Tidy Format (default)

One row per district/school/subgroup/grade_level combination:

| Column | Description |
|--------|-------------|
| `end_year` | School year end (2024 = 2023-24) |
| `type` | "State", "District", or "Campus" |
| `district_id` | District identifier |
| `district_name` | District name |
| `campus_id` | School identifier |
| `campus_name` | School name |
| `subgroup` | Demographic subgroup |
| `grade_level` | "TOTAL", "PK", "K", "01"-"12" |
| `n_students` | Enrollment count |
| `pct` | Percentage of total |
| `is_state` | Boolean flag |
| `is_district` | Boolean flag |
| `is_campus` | Boolean flag |
| `is_charter` | Boolean flag |

### Subgroups

Available subgroups depend on NH DOE reporting:
- **Total**: `total_enrollment`
- **Grade levels**: `grade_pk`, `grade_k`, `grade_01` through `grade_12`

Note: Demographics (race/ethnicity, gender) may not be available in standard enrollment reports.

## Year Convention

**CRITICAL**: Years use END YEAR of the school year:
- `2024` = 2023-24 school year
- `2023` = 2022-23 school year

## Test Coverage

Current tests verify:
- Utility functions (safe_numeric, year validation, name cleaning)
- Cache management
- Data structure validation
- Local file import functionality

## Fidelity Requirement

**tidy=TRUE output MUST maintain fidelity to raw, unprocessed data:**
- State totals should equal sum of district totals
- No impossible zeros at state level
- No Inf/NaN in percentages
- Enrollment counts must match source data

## Troubleshooting

### "iPlatform may require browser access"
This is expected. Visit the URLs provided and download files manually.

### Stale cache data
Clear the cache:
```r
clear_cache()
```

### Year not found
Check available years:
```r
get_available_years()
```

## TODO

- [ ] Investigate browser automation (RSelenium) for automated downloads
- [ ] Consider bundling static data files in `inst/extdata/` like rischooldata
- [ ] Add demographic data if/when available from NH DOE


---

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE network tests.

### Test Categories:
1. URL Availability - HTTP 200 checks
2. File Download - Verify actual file (not HTML error)
3. File Parsing - readxl/readr succeeds
4. Column Structure - Expected columns exist
5. get_raw_enr() - Raw data function works
6. Data Quality - No Inf/NaN, non-negative counts
7. Aggregation - State total > 0
8. Output Fidelity - tidy=TRUE matches raw

### Running Tests:
```r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework documentation.


---

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with auto-merge:

```bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

```bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass:
- R-CMD-check (0 errors, 0 warnings)
- Python tests (if py{st}schooldata exists)
- pkgdown build (vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks pass.

