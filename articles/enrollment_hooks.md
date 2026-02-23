# Exploring New Hampshire School Enrollment Data

## Status: Under Construction

The NH DOE iPlatform requires browser-based access, which prevents
automated data downloads. This package’s data pipeline is built but **no
real enrollment data is currently bundled**. Once real data from the NH
DOE is available, this vignette will be updated with data stories and
visualizations.

See the package README for manual data access instructions.

## Package API

``` r
library(nhschooldata)
```

The main functions are ready to use once data is available:

``` r
# Check available years
get_available_years()

# Fetch enrollment for a single year
enr <- fetch_enr(2024)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# Import manually downloaded file from NH DOE iPlatform
df <- import_local_enrollment("~/Downloads/enrollment.xlsx", 2024, "district")
```

## Manual Data Access

Download data directly from the NH DOE:

- **District enrollment**:
  <https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9>
- **School enrollment**:
  <https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10>

Then import using
[`import_local_enrollment()`](https://almartin82.github.io/nhschooldata/reference/import_local_enrollment.md):

``` r
df <- import_local_enrollment(
  "~/Downloads/district-fall-enrollment.xlsx",
  end_year = 2024,
  level = "district"
)

# Process and tidy the imported data
processed <- process_enr(list(district = df, school = NULL), 2024)
tidy <- tidy_enr(processed)
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
#> [1] nhschooldata_0.2.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
#>  [5] xfun_0.56         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
#>  [9] rmarkdown_2.30    lifecycle_1.0.5   cli_3.6.5         sass_0.4.10      
#> [13] pkgdown_2.2.0     textshaping_1.0.4 jquerylib_0.1.4   systemfonts_1.3.1
#> [17] compiler_4.5.2    tools_4.5.2       ragg_1.5.0        evaluate_1.0.5   
#> [21] bslib_0.10.0      yaml_2.3.12       jsonlite_2.0.0    rlang_1.1.7      
#> [25] fs_1.6.6
```
