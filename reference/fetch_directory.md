# Fetch New Hampshire school directory data

Downloads and processes school directory data from the New Hampshire
Department of Education Profiles system. This includes all public
schools and SAUs with contact information, addresses, and grades served.

## Usage

``` r
fetch_directory(end_year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  Currently unused. The directory data represents the current school
  year. Included for API consistency with other fetch functions.

- tidy:

  If TRUE (default), returns data in a standardized format with
  consistent column names. If FALSE, returns raw column names from NH
  DOE.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from NH DOE.

## Value

A tibble with school directory data. When `tidy = TRUE`, columns
include:

- `sau_number`: SAU identifier (e.g., "1", "48")

- `sau_name`: SAU name (e.g., "Contoocook Valley SAU Office")

- `state_district_id`: District identifier

- `district_name`: District name

- `state_school_id`: School identifier

- `school_name`: School name

- `entity_type`: "school", "district", or "sau"

- `address`: Street address

- `city`: City

- `state`: State (always "NH")

- `zip`: ZIP code

- `phone`: Phone number

- `grades_served`: Grade range (e.g., "K-5", "9-12")

- `principal_name`: Principal name (if available)

- `principal_email`: Principal email (if available)

- `superintendent_name`: Superintendent name (if available)

- `superintendent_email`: Superintendent email (if available)

- `school_type`: School type (e.g., "Public", "Charter")

- `county_name`: County name (if available)

## Details

The directory data is sourced from the NH DOE Profiles system, which
provides current information for all schools and School Administrative
Units (SAUs) in New Hampshire.

Note: NH DOE Profiles is behind Akamai WAF and may block automated
downloads. If live download fails, the function falls back to bundled
data or you can use
[`import_local_directory`](https://almartin82.github.io/nhschooldata/reference/import_local_directory.md)
with manually downloaded files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory data
dir_data <- fetch_directory()

# Get raw format (original NH DOE column names)
dir_raw <- fetch_directory(tidy = FALSE)

# Force fresh download (ignore cache)
dir_fresh <- fetch_directory(use_cache = FALSE)

# Filter to charter schools
library(dplyr)
charters <- dir_data |>
  filter(school_type == "Charter")

# Find all schools in a specific SAU
sau48 <- dir_data |>
  filter(sau_number == "48")
} # }
```
