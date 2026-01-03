# Download raw enrollment data from NH DOE

Downloads enrollment data from the New Hampshire Department of Education
iPlatform reporting system. Data includes district and school-level
enrollment by grade.

## Usage

``` r
get_raw_enr(end_year)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024). Valid range determined by NH DOE
  data availability.

## Value

List with school and district data frames

## Details

Note: NH DOE iPlatform may require browser-based access. If automatic
download fails, use import_local_enrollment() with manually downloaded
files.
