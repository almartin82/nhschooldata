# Load bundled enrollment data

Loads the bundled enrollment data from the package. This is the primary
data source since the NH DOE iPlatform requires browser-based downloads
that cannot be automated.

## Usage

``` r
load_bundled_enr(end_year)
```

## Arguments

- end_year:

  School year end (2015-2025)

## Value

List with school and district data frames, or NULL if not available
