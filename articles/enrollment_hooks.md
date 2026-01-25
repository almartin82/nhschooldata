# Exploring New Hampshire School Enrollment Data

## Data Access Note

The NH DOE iPlatform requires browser-based access. If automatic
download fails:

1.  Visit [my.doe.nh.gov/iPlatform](https://my.doe.nh.gov/iPlatform)
2.  Download the enrollment reports
3.  Use
    [`import_local_enrollment()`](https://almartin82.github.io/nhschooldata/reference/import_local_enrollment.md)
    to load the data

``` r
library(nhschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_minimal(base_size = 14))
```

## 1. Explore statewide enrollment trends

Track how New Hampshire’s public school enrollment has changed over
time.

``` r
enr <- fetch_enr_multi(2016:2024, use_cache = TRUE)

statewide <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)

statewide
#>   end_year n_students
#> 1     2016          0
#> 2     2017          0
#> 3     2018          0
#> 4     2019          0
#> 5     2020          0
#> 6     2021          0
#> 7     2022          0
#> 8     2023          0
#> 9     2024          0
```

``` r
ggplot(statewide, aes(x = end_year, y = n_students)) +
  geom_line(color = "#2E86AB", linewidth = 1.2) +
  geom_point(color = "#2E86AB", size = 3) +
  scale_y_continuous(labels = scales::comma, limits = c(0, NA)) +
  labs(
    title = "New Hampshire Public School Enrollment (2016-2024)",
    subtitle = "Tracking statewide trends",
    x = "Year",
    y = "Students"
  )
```

![New Hampshire statewide enrollment
2016-2024](enrollment_hooks_files/figure-html/statewide-chart-1.png)

New Hampshire statewide enrollment 2016-2024

## 2. Find the largest districts

See which districts serve the most students in New Hampshire.

``` r
enr_2024 <- fetch_enr(2024, use_cache = TRUE)

top_districts <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students)

top_districts
#> [1] district_name n_students   
#> <0 rows> (or 0-length row.names)
```

``` r
top_districts %>%
  mutate(district_name = gsub(" School District", "", district_name)) %>%
  mutate(district_name = factor(district_name, levels = rev(district_name))) %>%
  ggplot(aes(x = n_students, y = district_name)) +
  geom_col(fill = "#2E86AB") +
  geom_text(aes(label = scales::comma(n_students)), hjust = -0.1, size = 3.5) +
  scale_x_continuous(labels = scales::comma, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Largest School Districts in New Hampshire (2024)",
    x = "Students",
    y = NULL
  )
```

![Top 10 New Hampshire school districts by
enrollment](enrollment_hooks_files/figure-html/top-districts-chart-1.png)

Top 10 New Hampshire school districts by enrollment

## 3. Track demographic changes

Monitor how the demographic composition of New Hampshire schools is
changing.

``` r
enr_demo <- fetch_enr_multi(c(2016, 2018, 2020, 2024), use_cache = TRUE)

demographics <- enr_demo %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "hispanic", "asian", "black", "multiracial")) %>%
  group_by(end_year) %>%
  mutate(pct = n_students / sum(n_students) * 100) %>%
  ungroup() %>%
  select(end_year, subgroup, pct)

demographics_wide <- demographics %>%
  pivot_wider(names_from = subgroup, values_from = pct)

demographics_wide
#> # A tibble: 4 × 6
#>   end_year white black hispanic asian multiracial
#>      <int> <dbl> <dbl>    <dbl> <dbl>       <dbl>
#> 1     2016   NaN   NaN      NaN   NaN         NaN
#> 2     2018   NaN   NaN      NaN   NaN         NaN
#> 3     2020   NaN   NaN      NaN   NaN         NaN
#> 4     2024   NaN   NaN      NaN   NaN         NaN
```

``` r
demographics %>%
  mutate(subgroup = factor(subgroup,
                           levels = c("white", "hispanic", "asian", "multiracial", "black"),
                           labels = c("White", "Hispanic", "Asian", "Multiracial", "Black"))) %>%
  ggplot(aes(x = end_year, y = pct, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("White" = "#2E86AB", "Hispanic" = "#E94F37",
                                "Asian" = "#F6AE2D", "Multiracial" = "#86BA90",
                                "Black" = "#A23B72")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "Demographic Composition of NH Public Schools (2016-2024)",
    x = "Year",
    y = "Percent of Students",
    color = "Group"
  ) +
  theme(legend.position = "right")
```

![Demographic shifts in New Hampshire
schools](enrollment_hooks_files/figure-html/demographics-chart-1.png)

Demographic shifts in New Hampshire schools

## 4. Compare regional trends

New Hampshire’s geography creates distinct regional patterns - compare
coastal areas to the North Country.

``` r
seacoast <- c("Portsmouth", "Dover", "Rochester", "Exeter", "Hampton")
north_country <- c("Berlin", "Colebrook", "Lancaster", "Littleton", "Gorham")

enr_regional <- fetch_enr_multi(c(2016, 2018, 2021, 2024), use_cache = TRUE)

regional <- enr_regional %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(region = case_when(
    grepl(paste(seacoast, collapse = "|"), district_name) ~ "Seacoast",
    grepl(paste(north_country, collapse = "|"), district_name) ~ "North Country",
    TRUE ~ "Other"
  )) %>%
  filter(region %in% c("Seacoast", "North Country")) %>%
  group_by(end_year, region) %>%
  summarize(total = sum(n_students, na.rm = TRUE), .groups = "drop")

regional
#> # A tibble: 0 × 3
#> # ℹ 3 variables: end_year <int>, region <chr>, total <int>
```

``` r
ggplot(regional, aes(x = end_year, y = total, color = region)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Seacoast" = "#2E86AB", "North Country" = "#E94F37")) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Regional Enrollment: Seacoast vs. North Country",
    x = "Year",
    y = "Students",
    color = "Region"
  ) +
  theme(legend.position = "right")
```

![Regional enrollment trends in New
Hampshire](enrollment_hooks_files/figure-html/regional-chart-1.png)

Regional enrollment trends in New Hampshire

## 5. Analyze grade-level trends

Track how enrollment varies across grade levels to understand the
student pipeline.

``` r
enr_grades <- fetch_enr_multi(2016:2024, use_cache = TRUE)

grades <- enr_grades %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "05", "09", "12")) %>%
  select(end_year, grade_level, n_students) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "1st Grade",
    grade_level == "05" ~ "5th Grade",
    grade_level == "09" ~ "9th Grade",
    grade_level == "12" ~ "12th Grade"
  ))

grades
#>    end_year grade_level n_students  grade_label
#> 1      2016           K          0 Kindergarten
#> 2      2016          01          0    1st Grade
#> 3      2016          05          0    5th Grade
#> 4      2016          09          0    9th Grade
#> 5      2016          12          0   12th Grade
#> 6      2017           K          0 Kindergarten
#> 7      2017          01          0    1st Grade
#> 8      2017          05          0    5th Grade
#> 9      2017          09          0    9th Grade
#> 10     2017          12          0   12th Grade
#> 11     2018           K          0 Kindergarten
#> 12     2018          01          0    1st Grade
#> 13     2018          05          0    5th Grade
#> 14     2018          09          0    9th Grade
#> 15     2018          12          0   12th Grade
#> 16     2019           K          0 Kindergarten
#> 17     2019          01          0    1st Grade
#> 18     2019          05          0    5th Grade
#> 19     2019          09          0    9th Grade
#> 20     2019          12          0   12th Grade
#> 21     2020           K          0 Kindergarten
#> 22     2020          01          0    1st Grade
#> 23     2020          05          0    5th Grade
#> 24     2020          09          0    9th Grade
#> 25     2020          12          0   12th Grade
#> 26     2021           K          0 Kindergarten
#> 27     2021          01          0    1st Grade
#> 28     2021          05          0    5th Grade
#> 29     2021          09          0    9th Grade
#> 30     2021          12          0   12th Grade
#> 31     2022           K          0 Kindergarten
#> 32     2022          01          0    1st Grade
#> 33     2022          05          0    5th Grade
#> 34     2022          09          0    9th Grade
#> 35     2022          12          0   12th Grade
#> 36     2023           K          0 Kindergarten
#> 37     2023          01          0    1st Grade
#> 38     2023          05          0    5th Grade
#> 39     2023          09          0    9th Grade
#> 40     2023          12          0   12th Grade
#> 41     2024           K          0 Kindergarten
#> 42     2024          01          0    1st Grade
#> 43     2024          05          0    5th Grade
#> 44     2024          09          0    9th Grade
#> 45     2024          12          0   12th Grade
```

``` r
grades %>%
  mutate(grade_label = factor(grade_label,
                              levels = c("Kindergarten", "1st Grade", "5th Grade",
                                         "9th Grade", "12th Grade"))) %>%
  ggplot(aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_brewer(palette = "Set1") +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "New Hampshire Enrollment by Grade Level (2016-2024)",
    x = "Year",
    y = "Students",
    color = "Grade"
  ) +
  theme(legend.position = "right")
```

![Enrollment by grade level over
time](enrollment_hooks_files/figure-html/grade-level-chart-1.png)

Enrollment by grade level over time

## 6. Understand district size distribution

New Hampshire has many small districts that share administration through
SAUs.

``` r
district_sizes <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(size = case_when(
    n_students >= 3000 ~ "Large (3,000+)",
    n_students >= 1000 ~ "Medium (1,000-2,999)",
    n_students >= 300 ~ "Small (300-999)",
    TRUE ~ "Tiny (<300)"
  )) %>%
  count(size) %>%
  mutate(size = factor(size, levels = c("Tiny (<300)", "Small (300-999)",
                                         "Medium (1,000-2,999)", "Large (3,000+)")))

district_sizes
#> [1] size n   
#> <0 rows> (or 0-length row.names)
```

``` r
ggplot(district_sizes, aes(x = size, y = n, fill = size)) +
  geom_col() +
  geom_text(aes(label = n), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("Tiny (<300)" = "#E94F37", "Small (300-999)" = "#F6AE2D",
                               "Medium (1,000-2,999)" = "#86BA90", "Large (3,000+)" = "#2E86AB")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title = "New Hampshire Districts by Size (2024)",
    x = "District Size",
    y = "Number of Districts"
  ) +
  theme(legend.position = "none")
```

![Distribution of district sizes in New
Hampshire](enrollment_hooks_files/figure-html/district-size-chart-1.png)

Distribution of district sizes in New Hampshire

## 7. Compare Manchester and Nashua

Track the state’s two largest cities and their share of total
enrollment.

``` r
big_cities <- enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Manchester|Nashua", district_name)) %>%
  group_by(end_year) %>%
  summarize(combined = sum(n_students, na.rm = TRUE), .groups = "drop")

state_totals <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, state_total = n_students)

big_cities %>%
  left_join(state_totals, by = "end_year") %>%
  mutate(pct_of_state = round(combined / state_total * 100, 1))
#> # A tibble: 0 × 4
#> # ℹ 4 variables: end_year <int>, combined <int>, state_total <int>,
#> #   pct_of_state <dbl>
```

## 8. Track kindergarten pipeline

Monitor kindergarten enrollment to predict future enrollment trends.

``` r
kindergarten <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "K") %>%
  select(end_year, k_students = n_students)

# Calculate year-over-year change
kindergarten %>%
  mutate(
    change = k_students - lag(k_students),
    pct_change = round(change / lag(k_students) * 100, 1)
  )
#>   end_year k_students change pct_change
#> 1     2016          0     NA         NA
#> 2     2017          0      0        NaN
#> 3     2018          0      0        NaN
#> 4     2019          0      0        NaN
#> 5     2020          0      0        NaN
#> 6     2021          0      0        NaN
#> 7     2022          0      0        NaN
#> 8     2023          0      0        NaN
#> 9     2024          0      0        NaN
```

## 9. Find the smallest districts

Identify New Hampshire’s tiny districts that rely on SAU administrative
sharing.

``` r
tiny_districts <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         n_students < 200) %>%
  arrange(n_students) %>%
  head(10) %>%
  select(district_name, n_students)

tiny_districts
#> [1] district_name n_students   
#> <0 rows> (or 0-length row.names)
```

## 10. Track high school enrollment

Follow high school grades (9-12) to understand graduation pipeline.

``` r
high_school <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("09", "10", "11", "12")) %>%
  group_by(end_year) %>%
  summarize(hs_total = sum(n_students, na.rm = TRUE), .groups = "drop")

high_school
#> # A tibble: 9 × 2
#>   end_year hs_total
#>      <int>    <int>
#> 1     2016        0
#> 2     2017        0
#> 3     2018        0
#> 4     2019        0
#> 5     2020        0
#> 6     2021        0
#> 7     2022        0
#> 8     2023        0
#> 9     2024        0
```

## 11. Compare elementary vs secondary

Track the balance between elementary (K-5) and secondary (6-12)
enrollment.

``` r
elem_grades <- c("K", "01", "02", "03", "04", "05")
sec_grades <- c("06", "07", "08", "09", "10", "11", "12")

level_comparison <- enr %>%
  filter(is_state, subgroup == "total_enrollment") %>%
  mutate(level = case_when(
    grade_level %in% elem_grades ~ "Elementary",
    grade_level %in% sec_grades ~ "Secondary",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(level)) %>%
  group_by(end_year, level) %>%
  summarize(students = sum(n_students, na.rm = TRUE), .groups = "drop")

level_comparison
#> # A tibble: 18 × 3
#>    end_year level      students
#>       <int> <chr>         <int>
#>  1     2016 Elementary        0
#>  2     2016 Secondary         0
#>  3     2017 Elementary        0
#>  4     2017 Secondary         0
#>  5     2018 Elementary        0
#>  6     2018 Secondary         0
#>  7     2019 Elementary        0
#>  8     2019 Secondary         0
#>  9     2020 Elementary        0
#> 10     2020 Secondary         0
#> 11     2021 Elementary        0
#> 12     2021 Secondary         0
#> 13     2022 Elementary        0
#> 14     2022 Secondary         0
#> 15     2023 Elementary        0
#> 16     2023 Secondary         0
#> 17     2024 Elementary        0
#> 18     2024 Secondary         0
```

## 12. Identify growing districts

Find districts that have grown over the analysis period.

``` r
growth <- enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2016, 2024)) %>%
  select(district_name, end_year, n_students) %>%
  pivot_wider(names_from = end_year, values_from = n_students,
                     names_prefix = "y")

# Calculate growth if data exists
if (nrow(growth) > 0 && "y2024" %in% names(growth) && "y2016" %in% names(growth)) {
  growth <- growth %>%
    mutate(
      change = y2024 - y2016,
      pct_change = round(change / y2016 * 100, 1)
    ) %>%
    arrange(desc(pct_change)) %>%
    head(10)
}

growth
#> # A tibble: 0 × 1
#> # ℹ 1 variable: district_name <chr>
```

## 13. Track middle grades

Monitor grades 6-8 enrollment trends.

``` r
middle_grades <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("06", "07", "08")) %>%
  group_by(end_year) %>%
  summarize(middle_total = sum(n_students, na.rm = TRUE), .groups = "drop")

middle_grades
#> # A tibble: 9 × 2
#>   end_year middle_total
#>      <int>        <int>
#> 1     2016            0
#> 2     2017            0
#> 3     2018            0
#> 4     2019            0
#> 5     2020            0
#> 6     2021            0
#> 7     2022            0
#> 8     2023            0
#> 9     2024            0
```

## 14. Compare school vs district counts

See how many schools operate within each district size category.

``` r
school_counts <- enr_2024 %>%
  filter(is_campus, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(district_name) %>%
  summarize(n_schools = n(), .groups = "drop")

district_enrollment <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(district_name, district_enrollment = n_students)

school_counts %>%
  left_join(district_enrollment, by = "district_name") %>%
  mutate(avg_school_size = round(district_enrollment / n_schools, 0)) %>%
  arrange(desc(n_schools)) %>%
  head(10)
#> # A tibble: 0 × 4
#> # ℹ 4 variables: district_name <chr>, n_schools <int>,
#> #   district_enrollment <int>, avg_school_size <dbl>
```

## 15. Calculate year-over-year state change

Track annual enrollment changes at the state level.

``` r
state_changes <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(end_year) %>%
  mutate(
    change = n_students - lag(n_students),
    pct_change = round(change / lag(n_students) * 100, 2)
  ) %>%
  select(end_year, n_students, change, pct_change)

state_changes
#>   end_year n_students change pct_change
#> 1     2016          0     NA         NA
#> 2     2017          0      0        NaN
#> 3     2018          0      0        NaN
#> 4     2019          0      0        NaN
#> 5     2020          0      0        NaN
#> 6     2021          0      0        NaN
#> 7     2022          0      0        NaN
#> 8     2023          0      0        NaN
#> 9     2024          0      0        NaN
```

## Summary

New Hampshire’s public school enrollment data reveals:

- **Statewide trends**: Track enrollment changes across years
- **District comparisons**: Compare districts by size and location
- **Demographics**: Monitor changing student populations
- **Regional patterns**: Understand Seacoast vs. North Country
  differences
- **Grade-level analysis**: Follow the student pipeline
- **Growth analysis**: Identify growing and declining districts

## Session Info

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] ggplot2_4.0.1      tidyr_1.3.2        dplyr_1.1.4        nhschooldata_0.2.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       jsonlite_2.0.0     compiler_4.5.2     tidyselect_1.2.1  
#>  [5] jquerylib_0.1.4    systemfonts_1.3.1  scales_1.4.0       textshaping_1.0.4 
#>  [9] yaml_2.3.12        fastmap_1.2.0      R6_2.6.1           labeling_0.4.3    
#> [13] generics_0.1.4     curl_7.0.0         knitr_1.51         tibble_3.3.1      
#> [17] desc_1.4.3         bslib_0.9.0        pillar_1.11.1      RColorBrewer_1.1-3
#> [21] rlang_1.1.7        utf8_1.2.6         cachem_1.1.0       xfun_0.56         
#> [25] S7_0.2.1           fs_1.6.6           sass_0.4.10        cli_3.6.5         
#> [29] withr_3.0.2        pkgdown_2.2.0      magrittr_2.0.4     digest_0.6.39     
#> [33] grid_4.5.2         rappdirs_0.3.4     lifecycle_1.0.5    vctrs_0.7.1       
#> [37] evaluate_1.0.5     glue_1.8.0         farver_2.1.2       codetools_0.2-20  
#> [41] ragg_1.5.0         httr_1.4.7         rmarkdown_2.30     purrr_1.2.1       
#> [45] tools_4.5.2        pkgconfig_2.0.3    htmltools_0.5.9
```
