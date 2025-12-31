# nhschooldata

Fetch and process New Hampshire school enrollment data from the New Hampshire Department of Education (NH DOE).

## Installation

```r
# Install from GitHub
devtools::install_github("almartin82/nhschooldata")
```
## Quick Start

```r
library(nhschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get wide format (one row per school/district)
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Get multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# Filter to largest districts
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)
```

## Data Availability

### Source

Data is sourced from:

1. **NH DOE iPlatform** (primary): https://my.doe.nh.gov/iPlatform
2. **NCES Common Core of Data** (backup): https://nces.ed.gov/ccd/

### Years Available

| Years | Source | Notes |
|-------|--------|-------|
| 2020-present | NH DOE iPlatform / NCES CCD | Current format with full demographics |
| 2014-2019 | NH DOE iPlatform / NCES CCD | Updated column structure |
| 2006-2013 | NCES CCD | Original iPlatform era |

**Earliest available year**: 2006
**Most recent available year**: Current school year (typically available after October 1)

### Aggregation Levels

- **State**: Statewide totals
- **District**: ~162 school districts
- **Campus/School**: ~456 public schools

### Demographics Available

| Category | Availability |
|----------|-------------|
| Race/Ethnicity (White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial) | 2006+ |
| Gender (Male, Female) | Varies by year |
| Grade Level (PK-12) | 2006+ |
| Economically Disadvantaged | Limited availability |
| Limited English Proficiency | Limited availability |
| Special Education | Limited availability |

### What's NOT Available

- Pre-2006 data is not available through this package (contact NH DOE directly)
- Some demographic breakdowns may be suppressed for small cell sizes
- Private school enrollment is not included (public schools only)
- Homeschool enrollment is not included

### Known Caveats

1. **October 1 Snapshot**: Enrollment data represents the October 1 snapshot for each school year
2. **Charter Schools**: Public charter schools are included and can be identified via the `is_charter` flag
3. **SAU Structure**: New Hampshire uses School Administrative Units (SAUs) that may oversee multiple districts
4. **Enrollment Trends**: NH has experienced steady enrollment decline since 2002 (from ~207,000 to ~165,000 students)

## Output Schema

### Wide Format (`tidy = FALSE`)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", or "Campus" |
| district_id | character | NCES district (LEA) ID |
| campus_id | character | NCES school ID |
| district_name | character | District name |
| campus_name | character | School name |
| county | character | County name |
| charter_flag | character | "Y" for charter, "N" otherwise |
| row_total | integer | Total enrollment |
| white, black, hispanic, asian, native_american, pacific_islander, multiracial | integer | Race/ethnicity counts |
| male, female | integer | Gender counts |
| grade_pk through grade_12 | integer | Grade-level counts |

### Tidy Format (`tidy = TRUE`, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | District ID |
| campus_id | character | School ID |
| district_name | character | District name |
| campus_name | character | School name |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12" |
| subgroup | character | "total_enrollment", "white", "black", etc. |
| n_students | integer | Student count |
| pct | numeric | Percentage (0-1 scale) |
| is_state | logical | TRUE for state-level rows |
| is_district | logical | TRUE for district-level rows |
| is_campus | logical | TRUE for school-level rows |
| is_charter | logical | TRUE for charter schools |

## New Hampshire School System Overview

- **Total Enrollment**: ~165,000 students (2024)
- **School Districts**: ~162
- **Public Schools**: ~456
- **School Administrative Units (SAUs)**: Oversee one or more districts
- **Largest Districts**: Manchester (~12,000), Nashua (~9,900), Bedford (~4,100), Londonderry (~4,000), Concord (~4,000)

## Caching

Data is cached locally to avoid repeated downloads:

```r
# Check cache status
cache_status()

# Clear all cached data
clear_cache()

# Clear specific year
clear_cache(2024)

# Force fresh download
fetch_enr(2024, use_cache = FALSE)
```

Cache location: `rappdirs::user_cache_dir("nhschooldata")`

## Related Packages

- [txschooldata](https://github.com/almartin82/txschooldata) - Texas school data
- [ilschooldata](https://github.com/almartin82/ilschooldata) - Illinois school data
- [nyschooldata](https://github.com/almartin82/nyschooldata) - New York school data
- [ohschooldata](https://github.com/almartin82/ohschooldata) - Ohio school data
- [paschooldata](https://github.com/almartin82/paschooldata) - Pennsylvania school data
- [caschooldata](https://github.com/almartin82/caschooldata) - California school data

## License
MIT
