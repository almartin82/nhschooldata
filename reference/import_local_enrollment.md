# Import local enrollment file

Imports enrollment data from a locally downloaded file. Use this
function as a fallback when automated download from NH DOE iPlatform
fails.

## Usage

``` r
import_local_enrollment(file_path, end_year, level = "school")
```

## Arguments

- file_path:

  Path to downloaded Excel or CSV file

- end_year:

  School year end (e.g., 2024 for 2023-24)

- level:

  Either "school" or "district"

## Value

Data frame with enrollment data

## Details

Visit the NH DOE iPlatform to download enrollment data manually:

- District enrollment:
  https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9

- School enrollment:
  https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10

## Examples

``` r
if (FALSE) { # \dontrun{
# Download file manually from NH DOE iPlatform, then:
df <- import_local_enrollment("~/Downloads/district-fall-enrollment.xlsx", 2024, "district")
} # }
```
