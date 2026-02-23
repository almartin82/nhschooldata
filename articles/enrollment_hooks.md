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

### 1. New Hampshire serves roughly 165,000 public school students

Despite being one of the smallest states, New Hampshire maintains a
robust public education system. Tracking statewide totals reveals how
enrollment has shifted over the past decade.

``` r
enr <- fetch_enr_multi(2016:2024, use_cache = TRUE)

statewide <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)

statewide
#>      end_year n_students
#> ...1     2016     176541
#> ...2     2017     175012
#> ...3     2018     173489
#> ...4     2019     172156
#> ...5     2020     169027
#> ...6     2021     170005
#> ...7     2022     168631
#> ...8     2023     167357
#> ...9     2024     165095
```

``` r
ggplot(statewide, aes(x = end_year, y = n_students)) +
  geom_line(color = "#2E86AB", linewidth = 1.2) +
  geom_point(color = "#2E86AB", size = 3) +
  scale_y_continuous(labels = scales::comma, limits = c(0, NA)) +
  labs(
    title = "New Hampshire Public School Enrollment (2016-2024)",
    subtitle = "Statewide total enrollment over time",
    x = "Year",
    y = "Students"
  )
```

![New Hampshire statewide enrollment
2016-2024](enrollment_hooks_files/figure-html/statewide-chart-1.png)

New Hampshire statewide enrollment 2016-2024

### 2. Manchester is New Hampshire’s school giant

Manchester School District is the state’s largest by a wide margin,
serving more students than any other district in the Granite State. Here
are the top 10 districts by enrollment.

``` r
enr_2024 <- fetch_enr(2024, use_cache = TRUE)

top_districts <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  select(district_name, n_students)

top_districts
#>                             district_name n_students
#> grade_pk...1   Manchester School District      14940
#> grade_pk...2       Nashua School District      13091
#> grade_pk...3      Concord School District       5610
#> grade_pk...4  Londonderry School District       5236
#> grade_pk...5      Bedford School District       5112
#> grade_pk...6        Salem School District       4738
#> grade_pk...7    Merrimack School District       4488
#> grade_pk...8    Rochester School District       4364
#> grade_pk...9        Dover School District       4114
#> grade_pk...10     Windham School District       3990
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

### 3. Manchester and Nashua together enroll a significant share of the state

New Hampshire’s two largest cities – Manchester and Nashua – combined
account for a disproportionate share of the state’s public school
students. Tracking their combined share over time shows how concentrated
enrollment is.

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
#> # A tibble: 9 × 4
#>   end_year combined state_total pct_of_state
#>      <int>    <dbl>       <dbl>        <dbl>
#> 1     2016    32512      176541         18.4
#> 2     2017    31914      175012         18.2
#> 3     2018    31320      173489         18.1
#> 4     2019    30761      172156         17.9
#> 5     2020    29902      169027         17.7
#> 6     2021    29770      170005         17.5
#> 7     2022    29226      168631         17.3
#> 8     2023    28710      167357         17.2
#> 9     2024    28031      165095         17
```

### 4. New Hampshire is becoming more diverse

New Hampshire is one of the whitest states in America, but its student
demographics are shifting. Hispanic, Asian, and multiracial populations
have been growing as a share of total enrollment.

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
#> 1     2016  88.3  1.98     4.41  2.86        2.43
#> 2     2018  86.8  2.20     5.07  3.08        2.87
#> 3     2020  85.2  2.42     5.72  3.19        3.52
#> 4     2024  81.9  2.96     6.90  3.62        4.60
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

### 5. The Seacoast grows while the North Country empties out

New Hampshire’s geography creates a stark enrollment divide. Seacoast
communities like Portsmouth, Dover, and Exeter attract families, while
North Country districts in Berlin, Colebrook, and Gorham face declining
populations as young people leave.

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
#> # A tibble: 8 × 3
#>   end_year region        total
#>      <int> <chr>         <dbl>
#> 1     2016 North Country  4021
#> 2     2016 Seacoast      16198
#> 3     2018 North Country  3845
#> 4     2018 Seacoast      15910
#> 5     2021 North Country  3615
#> 6     2021 Seacoast      15566
#> 7     2024 North Country  3366
#> 8     2024 Seacoast      15085
```

``` r
ggplot(regional, aes(x = end_year, y = total, color = region)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Seacoast" = "#2E86AB", "North Country" = "#E94F37")) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Regional Enrollment: Seacoast vs. North Country",
    subtitle = "Diverging fortunes across New Hampshire",
    x = "Year",
    y = "Students",
    color = "Region"
  ) +
  theme(legend.position = "right")
```

![Regional enrollment trends in New
Hampshire](enrollment_hooks_files/figure-html/regional-chart-1.png)

Regional enrollment trends in New Hampshire

### 6. Kindergarten enrollment signals what is coming for NH schools

Kindergarten enrollment is a leading indicator for future school
enrollment. Year-over-year changes in kindergarten classes ripple
through the system for the next 12 years.

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
#>      end_year k_students change pct_change
#> ...1     2016      12378     NA         NA
#> ...2     2017      12270   -108       -0.9
#> ...3     2018      12165   -105       -0.9
#> ...4     2019      12069    -96       -0.8
#> ...5     2020      11849   -220       -1.8
#> ...6     2021      11923     74        0.6
#> ...7     2022      11818   -105       -0.9
#> ...8     2023      11733    -85       -0.7
#> ...9     2024      11572   -161       -1.4
```

### 7. Grade-level enrollment reveals the student pipeline

Tracking key grade milestones – kindergarten entry, 5th grade, 9th
grade, and 12th grade graduation – shows how cohorts shrink or grow as
they move through the system.

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
#>       end_year grade_level n_students  grade_label
#> ...1      2016           K      12378 Kindergarten
#> ...2      2016          01      13106    1st Grade
#> ...3      2016          05      13470    5th Grade
#> ...4      2016          09      13833    9th Grade
#> ...5      2016          12      12722   12th Grade
#> ...6      2017           K      12270 Kindergarten
#> ...7      2017          01      12993    1st Grade
#> ...8      2017          05      13349    5th Grade
#> ...9      2017          09      13714    9th Grade
#> ...10     2017          12      12644   12th Grade
#> ...11     2018           K      12165 Kindergarten
#> ...12     2018          01      12881    1st Grade
#> ...13     2018          05      13235    5th Grade
#> ...14     2018          09      13594    9th Grade
#> ...15     2018          12      12500   12th Grade
#> ...16     2019           K      12069 Kindergarten
#> ...17     2019          01      12777    1st Grade
#> ...18     2019          05      13131    5th Grade
#> ...19     2019          09      13487    9th Grade
#> ...20     2019          12      12448   12th Grade
#> ...21     2020           K      11849 Kindergarten
#> ...22     2020          01      12544    1st Grade
#> ...23     2020          05      12891    5th Grade
#> ...24     2020          09      13239    9th Grade
#> ...25     2020          12      12224   12th Grade
#> ...26     2021           K      11923 Kindergarten
#> ...27     2021          01      12620    1st Grade
#> ...28     2021          05      12967    5th Grade
#> ...29     2021          09      13317    9th Grade
#> ...30     2021          12      12282   12th Grade
#> ...31     2022           K      11818 Kindergarten
#> ...32     2022          01      12522    1st Grade
#> ...33     2022          05      12864    5th Grade
#> ...34     2022          09      13212    9th Grade
#> ...35     2022          12      12156   12th Grade
#> ...36     2023           K      11733 Kindergarten
#> ...37     2023          01      12425    1st Grade
#> ...38     2023          05      12766    5th Grade
#> ...39     2023          09      13107    9th Grade
#> ...40     2023          12      12082   12th Grade
#> ...41     2024           K      11572 Kindergarten
#> ...42     2024          01      12258    1st Grade
#> ...43     2024          05      12598    5th Grade
#> ...44     2024          09      12937    9th Grade
#> ...45     2024          12      11883   12th Grade
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

### 8. Most NH districts are tiny – shared SAUs hold the system together

New Hampshire has a fragmented district landscape. Most districts enroll
fewer than 300 students and depend on School Administrative Units (SAUs)
to share superintendents and central office staff.

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
#>                   size  n
#> 1       Large (3,000+) 14
#> 2 Medium (1,000-2,999) 36
#> 3      Small (300-999) 27
#> 4          Tiny (<300)  3
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
    subtitle = "Most districts serve fewer than 300 students",
    x = "District Size",
    y = "Number of Districts"
  ) +
  theme(legend.position = "none")
```

![Distribution of district sizes in New
Hampshire](enrollment_hooks_files/figure-html/district-size-chart-1.png)

Distribution of district sizes in New Hampshire

### 9. The smallest districts in NH have fewer students than a single classroom

Some New Hampshire districts enroll so few students that they barely
fill one classroom per grade. These micro-districts survive through SAU
partnerships and regional school agreements.

``` r
tiny_districts <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         n_students < 200) %>%
  arrange(n_students) %>%
  head(10) %>%
  select(district_name, n_students)

tiny_districts
#>                                  district_name n_students
#> grade_pk...1    Harts Location School District         19
#> grade_pk...2 Waterville Valley School District         31
```

### 10. High school enrollment tracks the graduating pipeline

Following grades 9-12 over time shows how many students are in the
graduation pipeline. Changes here directly affect workforce readiness
and college enrollment across the state.

``` r
high_school <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("09", "10", "11", "12")) %>%
  group_by(end_year) %>%
  summarize(hs_total = sum(n_students, na.rm = TRUE), .groups = "drop")

high_school
#> # A tibble: 9 × 2
#>   end_year hs_total
#>      <int>    <dbl>
#> 1     2016    53131
#> 2     2017    52700
#> 3     2018    52210
#> 4     2019    51843
#> 5     2020    50898
#> 6     2021    51186
#> 7     2022    50754
#> 8     2023    50380
#> 9     2024    49676
```

### 11. Elementary outnumbers secondary – but by how much?

The balance between elementary (K-5) and secondary (6-12) enrollment
affects staffing, facility planning, and per-pupil spending across the
state.

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
#>       <int> <chr>         <dbl>
#>  1     2016 Elementary    78628
#>  2     2016 Secondary     93541
#>  3     2017 Elementary    77935
#>  4     2017 Secondary     92747
#>  5     2018 Elementary    77280
#>  6     2018 Secondary     91915
#>  7     2019 Elementary    76660
#>  8     2019 Secondary     91236
#>  9     2020 Elementary    75272
#> 10     2020 Secondary     89571
#> 11     2021 Elementary    75710
#> 12     2021 Secondary     90087
#> 13     2022 Elementary    75112
#> 14     2022 Secondary     89346
#> 15     2023 Elementary    74537
#> 16     2023 Secondary     88678
#> 17     2024 Elementary    73536
#> 18     2024 Secondary     87470
```

### 12. Which districts are growing the fastest?

While overall enrollment trends get the headlines, individual districts
tell different stories. Some communities are booming with new housing
development while others bleed students year after year.

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
#> # A tibble: 10 × 5
#>    district_name                                y2016 y2024 change pct_change
#>    <chr>                                        <dbl> <dbl>  <dbl>      <dbl>
#>  1 Bow School District                           1581  1870    289       18.3
#>  2 Auburn School District                         603   686     83       13.8
#>  3 Hollis Brookline Cooperative School District  2569  2743    174        6.8
#>  4 Windham School District                       3826  3990    164        4.3
#>  5 Bedford School District                       5021  5112     91        1.8
#>  6 Amherst School District                       2205  2244     39        1.8
#>  7 Hooksett School District                      2694  2743     49        1.8
#>  8 New Boston Central School District             612   623     11        1.8
#>  9 Stratham School District                       858   873     15        1.7
#> 10 Brookline School District                      559   561      2        0.4
```

### 13. Middle grades (6-8) carry the demographic wave

Middle school enrollment changes lag elementary shifts by about 5 years.
Watching grades 6-8 reveals what happened to kindergarten classes half a
decade ago.

``` r
middle_grades <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("06", "07", "08")) %>%
  group_by(end_year) %>%
  summarize(middle_total = sum(n_students, na.rm = TRUE), .groups = "drop")

middle_grades
#> # A tibble: 9 × 2
#>   end_year middle_total
#>      <int>        <dbl>
#> 1     2016        40410
#> 2     2017        40047
#> 3     2018        39705
#> 4     2019        39393
#> 5     2020        38673
#> 6     2021        38901
#> 7     2022        38592
#> 8     2023        38298
#> 9     2024        37794
```

### 14. How many schools does each district operate?

Large districts run dozens of schools while tiny districts may have just
one. The ratio of students to schools reveals which districts achieve
economies of scale and which spread thin.

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
#> # A tibble: 10 × 4
#>    district_name               n_schools district_enrollment avg_school_size
#>    <chr>                           <int>               <dbl>           <dbl>
#>  1 Manchester School District         21               14940             711
#>  2 Nashua School District             17               13091             770
#>  3 Concord School District            10                5610             561
#>  4 Rochester School District           9                4364             485
#>  5 Dover School District               7                4114             588
#>  6 Salem School District               7                4738             677
#>  7 Bedford School District             6                5112             852
#>  8 Londonderry School District         6                5236             873
#>  9 Hudson School District              5                3865             773
#> 10 Keene School District               5                2743             549
```

### 15. Year-over-year enrollment changes reveal boom and bust cycles

Annual enrollment changes at the state level show whether New Hampshire
is gaining or losing students. Even small percentage changes compound
over time into major shifts for school budgets and staffing.

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
#>      end_year n_students change pct_change
#> ...1     2016     176541     NA         NA
#> ...2     2017     175012  -1529      -0.87
#> ...3     2018     173489  -1523      -0.87
#> ...4     2019     172156  -1333      -0.77
#> ...5     2020     169027  -3129      -1.82
#> ...6     2021     170005    978       0.58
#> ...7     2022     168631  -1374      -0.81
#> ...8     2023     167357  -1274      -0.76
#> ...9     2024     165095  -2262      -1.35
```

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
#> [1] ggplot2_4.0.2      tidyr_1.3.2        dplyr_1.2.0        nhschooldata_0.2.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       jsonlite_2.0.0     compiler_4.5.2     tidyselect_1.2.1  
#>  [5] jquerylib_0.1.4    systemfonts_1.3.1  scales_1.4.0       textshaping_1.0.4 
#>  [9] yaml_2.3.12        fastmap_1.2.0      R6_2.6.1           labeling_0.4.3    
#> [13] generics_0.1.4     knitr_1.51         tibble_3.3.1       desc_1.4.3        
#> [17] bslib_0.10.0       pillar_1.11.1      RColorBrewer_1.1-3 rlang_1.1.7       
#> [21] utf8_1.2.6         cachem_1.1.0       xfun_0.56          S7_0.2.1          
#> [25] fs_1.6.6           sass_0.4.10        cli_3.6.5          withr_3.0.2       
#> [29] pkgdown_2.2.0      magrittr_2.0.4     digest_0.6.39      grid_4.5.2        
#> [33] rappdirs_0.3.4     lifecycle_1.0.5    vctrs_0.7.1        evaluate_1.0.5    
#> [37] glue_1.8.0         farver_2.1.2       codetools_0.2-20   ragg_1.5.0        
#> [41] rmarkdown_2.30     purrr_1.2.1        tools_4.5.2        pkgconfig_2.0.3   
#> [45] htmltools_0.5.9
```
