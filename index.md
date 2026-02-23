# nhschooldata

Fetch and analyze New Hampshire school enrollment data from the NH
Department of Education in R or Python.

Part of the [state schooldata
project](https://github.com/almartin82?tab=repositories&q=schooldata),
inspired by [njschooldata](https://github.com/almartin82/njschooldata).

## Status: Under Construction

This package’s data pipeline is **not yet functional**. The NH DOE
[iPlatform](https://my.doe.nh.gov/iPlatform) requires browser-based
authentication, which prevents automated data downloads. The package
infrastructure (fetching, processing, tidying) is built and ready, but
**no real enrollment data is currently bundled**.

Previously, this package shipped synthetic data generated with
[`set.seed()`](https://rdrr.io/r/base/Random.html) /
[`runif()`](https://rdrr.io/r/stats/Uniform.html). That data has been
removed because every number in a schooldata package must trace back to
a real state DOE source.

### What is being investigated

1.  **Manual download + bundle** – download enrollment files from
    iPlatform by hand and commit them to `inst/extdata/`
2.  **Browser automation** – use RSelenium or Playwright to script
    iPlatform downloads
3.  **Alternative state source** – if NH DOE publishes data in another
    format

### Manual data access (available now)

You can download data directly from the NH DOE:

- **District enrollment**:
  <https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9>
- **School enrollment**:
  <https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10>

Then import locally:

``` r
library(nhschooldata)

df <- import_local_enrollment(
  "~/Downloads/district-fall-enrollment.xlsx",
  end_year = 2024,
  level = "district"
)
```

## Installation

### R

``` r
remotes::install_github("almartin82/nhschooldata")
```

### Python

``` bash
pip install git+https://github.com/almartin82/nhschooldata.git#subdirectory=pynhschooldata
```

## Data Notes

| Item                 | Detail                                                                   |
|----------------------|--------------------------------------------------------------------------|
| **Source**           | [NH DOE iPlatform](https://my.doe.nh.gov/iPlatform)                      |
| **Entity types**     | ~162 districts (organized into SAUs), ~456 schools                       |
| **Census day**       | October 1 of each school year                                            |
| **Known limitation** | iPlatform requires browser-based access; automated downloads do not work |
| **Suppression**      | Counts \< 10 may be suppressed with `*`                                  |

## API Overview

The package API is ready – it just needs real data behind it.

``` r
library(nhschooldata)

# Check what years are available
get_available_years()

# Fetch enrollment (will attempt live download, then bundled data)
enr <- fetch_enr(2024)

# Multi-year fetch
enr_multi <- fetch_enr_multi(2020:2024)

# Import a manually downloaded file
df <- import_local_enrollment("path/to/file.xlsx", 2024, "district")

# Cache management
cache_status()
clear_cache()
```
