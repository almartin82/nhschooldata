# Import local directory file

Imports school directory data from a locally downloaded file. Use this
function as a fallback when automated download from NH DOE Profiles
fails.

## Usage

``` r
import_local_directory(file_path)
```

## Arguments

- file_path:

  Path to downloaded Excel or CSV file

## Value

Data frame with directory data

## Details

Visit the NH DOE Profiles to download the school list manually:
<https://my.doe.nh.gov/Profiles/PublicReports/PublicReports.aspx?ReportName=SchoolList>

## Examples

``` r
if (FALSE) { # \dontrun{
# Download file manually from NH DOE Profiles, then:
df <- import_local_directory("~/Downloads/school-list.xlsx")

# Process to tidy format
tidy_df <- process_directory(df)
} # }
```
