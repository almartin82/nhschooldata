# nhschooldata - Claude Instructions

## Data Source

This package uses ONLY New Hampshire Department of Education (NH DOE) data sources.
Do NOT use Urban Institute API, NCES CCD, or any federal data sources.

### Primary Data Source

**NH DOE iPlatform Public Reports**
- URL: https://my.doe.nh.gov/iPlatform
- Enrollment Reports: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9
- Enrollments by Grade: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=10

### Available Reports

1. **District Fall Enrollment**
   - Path: `/BDMQ/iPlatform+Reports/Enrollment+Data/Enrollment+Reports/District+Fall+Enrollments`
   - Contains: Pre-K through 12 enrollment by district

2. **Public School Enrollments by Grade**
   - Path: `/BDMQ/iPlatform+Reports/Enrollment+Data/Enrollments+by+Grade/Public+School+Enrollments+by+Grade`
   - Contains: School-level enrollment by grade

3. **Other Enrollment Reports**
   - County Enrollments by Grade
   - High School Enrollments
   - Kindergarten Enrollments
   - Preschool Enrollments
   - Town Enrollment By Grade

### Data Characteristics

- **Collection Date**: October 1 of each school year
- **Historical Data**: Approximately 10 years available
- **Format**: Reports available via SSRS (SQL Server Reporting Services)
- **Access**: Public reports available without authentication
- **Demographics**: Basic enrollment counts; race/ethnicity data may require separate reports

### Technical Notes

1. **iPlatform Access**: The iPlatform uses SSRS for reports. Direct programmatic access
   may be limited. If automated download fails, users can:
   - Visit the iPlatform website directly
   - Download reports manually
   - Use `import_local_enrollment()` to import downloaded files

2. **Column Naming**: NH DOE uses various column naming conventions:
   - Grade levels: PREK, K, G01-G12 or 1-12
   - IDs: DISTRICT_ID, SCHOOL_ID, SAU
   - Names: DISTRICT_NAME, SCHOOL_NAME

3. **SAU (School Administrative Unit)**: NH-specific organizational unit that may
   cover multiple school districts.

### Fallback Options

If automated download fails:
1. Visit https://my.doe.nh.gov/iPlatform
2. Navigate to Enrollment Reports
3. Select desired report and year
4. Export to Excel
5. Use `import_local_enrollment(file_path, end_year, level)` to import

### Key URLs

- NH DOE Main: https://www.education.nh.gov/
- Data Reports: https://www.education.nh.gov/who-we-are/division-of-educator-and-analytic-resources/bureau-of-education-statistics/data-reports
- iPlatform: https://my.doe.nh.gov/iPlatform
- Enrollment Reports: https://my.doe.nh.gov/iPlatform/Report/DataReportsSubCategory?reportSubCategoryId=9

## Package Structure

- `get_raw_enrollment.R`: Downloads raw data from NH DOE
- `process_enrollment.R`: Processes raw data into standardized format
- `fetch_enrollment.R`: Main user-facing functions
- `tidy_enrollment.R`: Transforms wide to long format
- `utils.R`: Utility functions including `get_available_years()`
- `cache.R`: Caching functions

## Important Guidelines

1. NEVER suggest using Urban Institute API or NCES CCD data
2. NEVER suggest manual downloads as the primary solution
3. If iPlatform access fails, provide the `import_local_enrollment()` fallback
4. Always reference NH DOE iPlatform as the data source
5. Historical data is limited to approximately 10 years (not back to 1987)
