# Get available years for enrollment data

Returns the range of years for which enrollment data is available from
the New Hampshire Department of Education.

## Usage

``` r
get_available_years()
```

## Value

Named list with min_year, max_year, source, and note

## Details

Bundled data covers 2012-2026 (15 school years). Data was downloaded
from the NH DOE iPlatform reporting system.

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2012
#> 
#> $max_year
#> [1] 2026
#> 
#> $source
#> [1] "New Hampshire Department of Education"
#> 
#> $note
#> [1] "Data availability: 2012-2026. Status: bundled data available. NH DOE enrollment data is collected on October 1 of each school year. Access raw reports at: https://my.doe.nh.gov/iPlatform"
#> 
```
