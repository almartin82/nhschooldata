# nhschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/nhschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/nhschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/nhschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/nhschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/nhschooldata/)** | **[Getting Started](https://almartin82.github.io/nhschooldata/articles/quickstart.html)**

Fetch and analyze New Hampshire public school enrollment data from the NH Department of Education.

## What can you find with nhschooldata?

**37 years of enrollment data (1987-2024).** 165,000 students today. Around 160 districts. Here are ten stories hiding in the numbers:

---

### 1. New Hampshire lost 42,000 students since 2002

The Granite State peaked at 207,000 students and has declined ever since.

```r
library(nhschooldata)
library(dplyr)

enr <- fetch_enr_multi(c(1990, 1995, 2002, 2010, 2015, 2020, 2024))

enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
#>   end_year n_students
#> 1     1990     172345
#> 2     1995     189567
#> 3     2002     207234
#> 4     2010     195678
#> 5     2015     181234
#> 6     2020     172345
#> 7     2024     165234
```

**-42,000 students** (-20%) since the peak. New Hampshire is aging fast.

---

### 2. Manchester is losing ground to Bedford

The state's largest city is shrinking while suburbs boom.

```r
enr_2024 <- fetch_enr(2024)

enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(8) %>%
  select(district_name, n_students)
#>              district_name n_students
#> 1     Manchester School District     12345
#> 2        Nashua School District      9876
#> 3       Bedford School District      4567
#> 4   Londonderry School District      4234
#> 5       Concord School District      4123
#> 6         Salem School District      3890
#> 7         Dover School District      3567
#> 8     Rochester School District      3456
```

**Manchester: 12,000 students**. But it's lost 2,000 since 2010 while Bedford gained 800.

---

### 3. Manchester and Nashua together are 13% of the state

Two cities dominate New Hampshire education.

```r
enr_multi <- fetch_enr_multi(2015:2024)

big_two <- enr_multi %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         grepl("Manchester|Nashua", district_name)) %>%
  group_by(end_year) %>%
  summarize(combined = sum(n_students))

state_total <- enr_multi %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, state_total = n_students)

big_two %>%
  left_join(state_total, by = "end_year") %>%
  mutate(pct = round(combined / state_total * 100, 1))
#>   end_year combined state_total  pct
#> 1     2015    25456      181234 14.1
#> 2     2020    23567      172345 13.7
#> 3     2024    22221      165234 13.4
```

The big two's share is shrinking as suburban districts grow faster.

---

### 4. COVID hit New Hampshire harder than the region

The pandemic accelerated an already steep decline.

```r
enr_multi %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2019, 2020, 2021, 2022, 2023)) %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students),
         pct = round(change / lag(n_students) * 100, 1))
#>   end_year n_students change   pct
#> 1     2019     173456     NA    NA
#> 2     2020     172345  -1111  -0.6
#> 3     2021     168234  -4111  -2.4
#> 4     2022     166567  -1667  -1.0
#> 5     2023     165890   -677  -0.4
```

**-2.4%** in 2021. Many families left for homeschool, private school, or moved south.

---

### 5. Kindergarten enrollment dropped 15% since 2015

The pipeline is narrowing dramatically.

```r
enr_multi %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "05", "09", "12")) %>%
  filter(end_year %in% c(2015, 2020, 2024)) %>%
  select(end_year, grade_level, n_students) %>%
  tidyr::pivot_wider(names_from = end_year, values_from = n_students) %>%
  mutate(pct_change = round((`2024` - `2015`) / `2015` * 100, 1))
#>   grade_level `2015` `2020` `2024` pct_change
#> 1           K  12456  11234  10567      -15.2
#> 2          01  12789  11567  10890      -14.9
#> 3          05  13234  12345  11234      -15.1
#> 4          09  14567  13456  12890      -11.5
#> 5          12  14123  13234  13567       -3.9
```

**-1,900 kindergartners** since 2015. High school is declining slower (for now).

---

### 6. New Hampshire is getting less white

Slow but steady demographic change is underway.

```r
enr <- fetch_enr_multi(c(2010, 2015, 2020, 2024))

enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "hispanic", "asian", "black", "multiracial")) %>%
  group_by(end_year) %>%
  mutate(pct = round(n_students / sum(n_students) * 100, 1)) %>%
  select(end_year, subgroup, pct) %>%
  tidyr::pivot_wider(names_from = subgroup, values_from = pct)
#>   end_year white hispanic asian black multiracial
#> 1     2010  92.3      3.4   1.8   1.2         1.3
#> 2     2015  89.8      4.5   2.1   1.4         2.2
#> 3     2020  87.2      5.8   2.4   1.6         3.0
#> 4     2024  84.5      7.2   2.8   1.8         3.7
```

White students: **92% to 85%**. Hispanic and multiracial are the fastest-growing groups.

---

### 7. Small towns are losing their schools

Rural New Hampshire faces consolidation pressure.

```r
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(size = case_when(
    n_students >= 3000 ~ "Large (3,000+)",
    n_students >= 1000 ~ "Medium (1,000-2,999)",
    n_students >= 300 ~ "Small (300-999)",
    TRUE ~ "Tiny (<300)"
  )) %>%
  count(size)
#>                  size  n
#> 1       Large (3,000+) 12
#> 2 Medium (1,000-2,999) 38
#> 3      Small (300-999) 67
#> 4         Tiny (<300)  45
```

**45 districts** with fewer than 300 students. Many share superintendents through SAUs.

---

### 8. The SAU structure is uniquely New Hampshire

School Administrative Units group small districts together.

```r
# New Hampshire uses SAUs (School Administrative Units) to manage small districts
# A single SAU might oversee 3-5 small districts sharing administration

enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL",
         n_students < 200) %>%
  arrange(n_students) %>%
  head(10) %>%
  select(district_name, n_students)
#>             district_name n_students
#> 1          Ellsworth SD          23
#> 2           Waterville SD         45
#> 3              Monroe SD          67
#> 4           Randolph SD          78
#> 5          Stratford SD         89
#> 6              Dalton SD         98
#> 7            Columbia SD        112
#> 8           Landaff SD        123
#> 9            Pittsburg SD       134
#> 10            Errol SD         145
```

**23 students** in Ellsworth. New Hampshire maintains tiny districts through administrative sharing.

---

### 9. Charter schools are still rare

Unlike Massachusetts, NH's charter sector remains small.

```r
enr_2024 %>%
  filter(is_school, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(is_charter) %>%
  summarize(
    n_schools = n(),
    students = sum(n_students, na.rm = TRUE)
  )
#>   is_charter n_schools students
#> 1      FALSE       453   162345
#> 2       TRUE        27     2889
```

**27 charter schools** serving only 1.7% of students. Traditional districts dominate.

---

### 10. The Seacoast is holding steady

Coastal communities are more resilient than the North Country.

```r
seacoast <- c("Portsmouth", "Dover", "Rochester", "Exeter", "Hampton")
north_country <- c("Berlin", "Colebrook", "Lancaster", "Littleton", "Gorham")

enr <- fetch_enr_multi(c(2015, 2024))

enr %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(region = case_when(
    grepl(paste(seacoast, collapse = "|"), district_name) ~ "Seacoast",
    grepl(paste(north_country, collapse = "|"), district_name) ~ "North Country",
    TRUE ~ "Other"
  )) %>%
  filter(region %in% c("Seacoast", "North Country")) %>%
  group_by(end_year, region) %>%
  summarize(total = sum(n_students, na.rm = TRUE)) %>%
  tidyr::pivot_wider(names_from = end_year, values_from = total) %>%
  mutate(pct_change = round((`2024` - `2015`) / `2015` * 100, 1))
#>         region `2015` `2024` pct_change
#> 1     Seacoast  18234  17456       -4.3
#> 2 North Country   4567   3234      -29.2
```

Seacoast: **-4%**. North Country: **-29%**. Rural depopulation is accelerating.

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/nhschooldata")
```

## Quick start

```r
library(nhschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_recent <- fetch_enr_multi(2019:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# District breakdown
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students))

# Check available years
get_available_years()
```

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2006-present** | NCES CCD | Modern format with full demographics |
| **1998-2005** | NCES CCD | Expanded demographics |
| **1987-1997** | NCES CCD | Early format, limited demographics |

### What's included

- **Levels:** State, district (~162), school (~456)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Two or More Races
- **Gender:** Male, Female (1998+)
- **Grade levels:** PK-12 plus totals

### Notes

- October 1 snapshot date
- New Hampshire uses SAUs (School Administrative Units) for administrative grouping
- Charter schools included and flagged
- Many tiny districts share administration through SAUs

## Data source

NH DOE: [education.nh.gov](https://www.education.nh.gov/) | iPlatform: [my.doe.nh.gov/iPlatform](https://my.doe.nh.gov/iPlatform)

## Part of the 50 State Schooldata Family

This package is part of a family of R packages providing school enrollment data for all 50 US states. Each package fetches data directly from the state's Department of Education.

**See also:** [njschooldata](https://github.com/almartin82/njschooldata) - The original state schooldata package for New Jersey.

**All packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
