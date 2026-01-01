# nhschooldata: Fetch and Process New Hampshire School Enrollment Data

Downloads and processes school enrollment data for New Hampshire public
schools. Data is sourced directly from the New Hampshire Department of
Education (NH DOE) iPlatform reporting system. Provides functions for
fetching enrollment data and transforming it into tidy format for
analysis. Includes district and school-level enrollment by grade.
Historical data typically available for approximately 10 years.

An R package for downloading and processing school enrollment data for
New Hampshire public schools. Data is sourced directly from the New
Hampshire Department of Education (NH DOE) iPlatform reporting system.

## Main Functions

- [`fetch_enr`](https://almartin82.github.io/nhschooldata/reference/fetch_enr.md):

  Download enrollment data for a single year

- [`fetch_enr_multi`](https://almartin82.github.io/nhschooldata/reference/fetch_enr_multi.md):

  Download enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/nhschooldata/reference/tidy_enr.md):

  Transform wide enrollment data to long format

- [`get_available_years`](https://almartin82.github.io/nhschooldata/reference/get_available_years.md):

  Get the range of available years

- [`import_local_enrollment`](https://almartin82.github.io/nhschooldata/reference/import_local_enrollment.md):

  Import manually downloaded enrollment file

## Data Source

Data is sourced from the New Hampshire Department of Education:

- NH DOE iPlatform: <https://my.doe.nh.gov/iPlatform>

- Enrollment Reports: District and school-level fall enrollment

- Historical data: Approximately 10 years available

## Available Reports

- District Fall Enrollment: Pre-K through 12 by district

- Public School Enrollments by Grade: School-level enrollment

- Enrollments by Grade: County, town, and other breakdowns

## New Hampshire School System

New Hampshire's school system includes:

- Approximately 162 school districts

- 456 public schools

- School Administrative Units (SAUs) that may cover multiple districts

- Public charter schools

- Approximately 160,000 students enrolled (2025)

## Identifier System

- District ID: State-assigned district identifier

- School ID: State-assigned school identifier

- SAU Number: School Administrative Unit number

## Manual Download Fallback

If automated download fails, you can manually download data from the NH
DOE iPlatform and import it using
[`import_local_enrollment`](https://almartin82.github.io/nhschooldata/reference/import_local_enrollment.md).

## See also

Useful links:

- <https://almartin82.github.io/nhschooldata/>

- <https://github.com/almartin82/nhschooldata>

- Report bugs at <https://github.com/almartin82/nhschooldata/issues>

Useful links:

- <https://almartin82.github.io/nhschooldata/>

- <https://github.com/almartin82/nhschooldata>

- Report bugs at <https://github.com/almartin82/nhschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>
