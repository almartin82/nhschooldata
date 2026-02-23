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

NH DOE iPlatform provides enrollment data for approximately the current
year plus 10 prior years. Data availability may vary.

Note: No bundled data is currently available. The iPlatform requires
browser-based access. Use
[`import_local_enrollment`](https://almartin82.github.io/nhschooldata/reference/import_local_enrollment.md)
to load manually downloaded files.

## Examples

``` r
get_available_years()
#> $min_year
#> [1] 2016
#> 
#> $max_year
#> [1] 2026
#> 
#> $source
#> [1] "New Hampshire Department of Education"
#> 
#> $note
#> [1] "Data availability: 2016-2026. Status: no bundled data; live download or manual import required. NH DOE enrollment data is collected on October 1 of each school year. Access raw reports at: https://my.doe.nh.gov/iPlatform"
#> 
```
