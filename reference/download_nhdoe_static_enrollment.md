# Download NH DOE static enrollment files

Attempts to download enrollment data from static files that NH DOE may
publish on their website.

## Usage

``` r
download_nhdoe_static_enrollment(end_year, level)
```

## Arguments

- end_year:

  School year end

- level:

  "district" or "school"

## Value

Data frame with enrollment data, or NULL if not available
