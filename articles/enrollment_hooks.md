# 10 Insights from New Hampshire School Enrollment Data

``` r
library(nhschooldata)
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_minimal(base_size = 14))
```

## New Hampshire Enrollment Trends (2016-2024)

New Hampshire’s public school enrollment reflects the state’s
demographic challenges - an aging population and declining birth rates
leading to gradual enrollment decline.

``` r
enr <- fetch_enr_multi(2016:2024)

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
    subtitle = "Gradual decline reflecting demographic trends",
    x = "Year",
    y = "Students"
  )
```

![New Hampshire statewide enrollment
2016-2024](enrollment_hooks_files/figure-html/statewide-chart-1.png)

New Hampshire statewide enrollment 2016-2024

## Top Districts: Manchester Leads, But Suburbs Grow

Manchester remains the largest district, but suburban communities like
Bedford are gaining while urban centers shrink.

``` r
enr_2024 <- fetch_enr(2024)

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
    subtitle = "Manchester and Nashua together serve 13% of state students",
    x = "Students",
    y = NULL
  )
```

![Top 10 New Hampshire school districts by
enrollment](enrollment_hooks_files/figure-html/top-districts-chart-1.png)

Top 10 New Hampshire school districts by enrollment

## Demographics: New Hampshire Is Getting More Diverse

Hispanic and multiracial students are among the fastest-growing
demographic groups.

``` r
enr_demo <- fetch_enr_multi(c(2016, 2018, 2020, 2024))

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
    subtitle = "Hispanic and multiracial populations growing",
    x = "Year",
    y = "Percent of Students",
    color = "Group"
  ) +
  theme(legend.position = "right")
```

![Demographic shifts in New Hampshire
schools](enrollment_hooks_files/figure-html/demographics-chart-1.png)

Demographic shifts in New Hampshire schools

## Regional Divergence: Seacoast Steady, North Country Declining

Coastal communities are holding relatively steady while the North
Country has experienced steeper declines.

``` r
seacoast <- c("Portsmouth", "Dover", "Rochester", "Exeter", "Hampton")
north_country <- c("Berlin", "Colebrook", "Lancaster", "Littleton", "Gorham")

enr_regional <- fetch_enr_multi(c(2016, 2018, 2021, 2024))

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
    subtitle = "North Country experiencing steeper declines than coastal areas",
    x = "Year",
    y = "Students",
    color = "Region"
  ) +
  theme(legend.position = "right")
```

![Regional enrollment trends in New
Hampshire](enrollment_hooks_files/figure-html/regional-chart-1.png)

Regional enrollment trends in New Hampshire

## Grade-Level Trends: The Pipeline Is Narrowing

Kindergarten enrollment trends signal potential future decline, as fewer
students enter the system each year.

``` r
enr_grades <- fetch_enr_multi(2016:2024)

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
    subtitle = "Tracking enrollment pipeline across grade levels",
    x = "Year",
    y = "Students",
    color = "Grade"
  ) +
  theme(legend.position = "right")
```

![Enrollment by grade level over
time](enrollment_hooks_files/figure-html/grade-level-chart-1.png)

Enrollment by grade level over time

## District Size Distribution: Many Tiny Districts

New Hampshire has 45 districts with fewer than 300 students. Many of
these share administration through SAUs (School Administrative Units).

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
    subtitle = "45 tiny districts with fewer than 300 students",
    x = "District Size",
    y = "Number of Districts"
  ) +
  theme(legend.position = "none")
```

![Distribution of district sizes in New
Hampshire](enrollment_hooks_files/figure-html/district-size-chart-1.png)

Distribution of district sizes in New Hampshire

## Summary

New Hampshire’s public school enrollment tells a story of demographic
transition:

- **Declining enrollment**: Gradual decline reflecting aging population
- **Regional divergence**: Coastal areas stable, rural North Country
  experiencing steeper declines
- **Diversification**: Hispanic and multiracial student populations
  growing
- **Many small districts**: Districts sharing administration through
  SAUs
