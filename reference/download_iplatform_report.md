# Download report from NH DOE iPlatform

Attempts to download a report from the NH DOE iPlatform SSRS system.

## Usage

``` r
download_iplatform_report(report_base, report_path, end_year, level)
```

## Arguments

- report_base:

  Base URL for reports

- report_path:

  Path to specific report

- end_year:

  School year end

- level:

  "district" or "school"

## Value

Data frame with enrollment data
