# TODO: pkgdown Build Issues

## Issue: Network Connectivity Error (2026-01-01)

The pkgdown build fails due to a network timeout when checking CRAN
availability.

### Error Details

    Error:
    ! in callr subprocess.
    Caused by error in `httr2::req_perform(req)`:
    ! Failed to perform HTTP request.
    Caused by error in `curl::curl_fetch_memory()`:
    ! Timeout was reached [cloud.r-project.org]:
    Connection timed out after 10002 milliseconds

### Root Cause

The build fails at the CRAN link check step (`pkgdown:::cran_link()`).
This is a network/infrastructure issue - cloud.r-project.org is not
reachable from the current network.

### Resolution

1.  **Wait and retry** - This is likely a transient network issue. Try
    again when network connectivity to CRAN is restored.

2.  **Build locally** - Run the build from a machine with reliable CRAN
    access.

3.  **GitHub Actions** - The pkgdown GitHub Actions workflow should work
    when triggered, as GitHub runners typically have good connectivity
    to CRAN.

### Notes

- The vignette content itself (`vignettes/enrollment_hooks.Rmd`) appears
  correct
- Year ranges used: 2016-2024 (should be valid for available data)
- This is NOT a code/data issue - purely network connectivity
