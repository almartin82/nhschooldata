# New Hampshire School Enrollment Data

Bundled enrollment data from the New Hampshire Department of Education,
covering 2012-2026 (15 school years). Includes district-level and
school-level enrollment by grade.

## Usage

``` r
nh_enrollment
```

## Format

A data frame with the following columns:

- end_year:

  School year end (e.g., 2024 for 2023-24)

- type:

  "District" or "Campus"

- sau:

  SAU (School Administrative Unit) number

- sau_name:

  SAU name

- district_id:

  District number

- district_name:

  District name

- campus_id:

  School number (NA for district rows)

- campus_name:

  School name (NA for district rows)

- county:

  County (NA — not in standard iPlatform reports)

- charter_flag:

  Charter school flag (NA — not in standard reports)

- grade_pk:

  PreSchool enrollment

- grade_k:

  Kindergarten enrollment

- grade_elem:

  Elementary enrollment (district data only)

- grade_middle:

  Middle school enrollment (district data only)

- grade_high:

  High school enrollment (district data only)

- grade_01:

  Grade 1 enrollment (school data only)

- grade_02:

  Grade 2 enrollment (school data only)

- grade_03:

  Grade 3 enrollment (school data only)

- grade_04:

  Grade 4 enrollment (school data only)

- grade_05:

  Grade 5 enrollment (school data only)

- grade_06:

  Grade 6 enrollment (school data only)

- grade_07:

  Grade 7 enrollment (school data only)

- grade_08:

  Grade 8 enrollment (school data only)

- grade_09:

  Grade 9 enrollment (school data only)

- grade_10:

  Grade 10 enrollment (school data only)

- grade_11:

  Grade 11 enrollment (school data only)

- grade_12:

  Grade 12 enrollment (school data only)

- grade_pg:

  Post-graduate enrollment

- row_total:

  Total enrollment for the row

## Source

NH DOE iPlatform: <https://my.doe.nh.gov/iPlatform>

## Details

Data was downloaded from the NH DOE iPlatform reporting system
(<https://my.doe.nh.gov/iPlatform>) and processed into a standardized
format. District data has aggregated grade bands (PreSchool,
Kindergarten, Elementary, Middle, High); school data has individual
grades (PK, K, 1-12).

## Examples

``` r
data(nh_enrollment)
head(nh_enrollment)
#> # A tibble: 6 × 29
#>   end_year type   sau   sau_name district_id district_name campus_id campus_name
#>      <int> <chr>  <chr> <chr>    <chr>       <chr>         <chr>     <chr>      
#> 1     2012 Campus 6     Claremo… 101         Claremont     20115     Claremont …
#> 2     2012 Campus 6     Claremo… 101         Claremont     20140     Stevens Hi…
#> 3     2012 Campus 6     Claremo… 101         Claremont     20145     Bluff Scho…
#> 4     2012 Campus 6     Claremo… 101         Claremont     20160     Maple Aven…
#> 5     2012 Campus 6     Claremo… 101         Claremont     20165     Disnard El…
#> 6     2012 Campus 7     Colebro… 105         Colebrook     20185     Colebrook …
#> # ℹ 21 more variables: county <chr>, charter_flag <chr>, grade_pk <int>,
#> #   grade_k <int>, grade_elem <int>, grade_middle <int>, grade_high <int>,
#> #   grade_pg <int>, row_total <int>, grade_01 <int>, grade_02 <int>,
#> #   grade_03 <int>, grade_04 <int>, grade_05 <int>, grade_06 <int>,
#> #   grade_07 <int>, grade_08 <int>, grade_09 <int>, grade_10 <int>,
#> #   grade_11 <int>, grade_12 <int>

# State totals by year
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
nh_enrollment |>
  filter(type == "District") |>
  group_by(end_year) |>
  summarize(total = sum(row_total, na.rm = TRUE))
#> # A tibble: 15 × 2
#>    end_year  total
#>       <int>  <int>
#>  1     2012 190805
#>  2     2013 187962
#>  3     2014 185320
#>  4     2015 183604
#>  5     2016 181339
#>  6     2017 179734
#>  7     2018 178328
#>  8     2019 177365
#>  9     2020 176168
#> 10     2021 167909
#> 11     2022 168620
#> 12     2023 167357
#> 13     2024 165082
#> 14     2025 162660
#> 15     2026 160322
```
