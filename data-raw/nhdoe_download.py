#!/usr/bin/env python3
"""
Download enrollment data from NH DOE iPlatform using Playwright.

NH DOE iPlatform (my.doe.nh.gov/iPlatform) uses SSRS behind Akamai WAF.
Headless Chromium gets blocked, but headed (visible) Chromium passes.

Usage:
    python3 nhdoe_download.py --report district --years 2015-2026 --output-dir downloads/
    python3 nhdoe_download.py --report school --year 2025 --output downloads/school_2025.xlsx

Arguments:
    --report     Report type: "district" or "school"
    --year       Single year (end_year)
    --years      Year range (e.g. 2015-2026)
    --output     Output file path (single year mode)
    --output-dir Output directory (batch mode)
    --timeout    Download timeout in seconds (default: 120)

Requirements:
    pip install playwright && playwright install chromium
"""

import argparse
import os
import sys
import time


DISTRICT_REPORT_URL = (
    "https://my.doe.nh.gov/iPlatform/Report/Report?"
    "path=%2FBDMQ%2FiPlatform+Reports%2FEnrollment+Data%2FEnrollment+Reports%2FDistrict+Fall+Enrollments"
    "&name=District+Fall+Enrollment"
    "&categoryName=Enrollment+Reports"
    "&categoryId=9"
)

SCHOOL_REPORT_URL = (
    "https://my.doe.nh.gov/iPlatform/Report/Report?"
    "path=%2FBDMQ%2FiPlatform+Reports%2FEnrollment+Data%2FEnrollments+by+Grade%2FSchool+Enrollments+by+Grade+Public"
    "&name=Public+School+Enrollments+by+Grade"
    "&categoryName=Enrollments+by+Grade"
    "&categoryId=10"
)


def download_report(report_type, year, output=None, timeout=120):
    """Download a single report from NH DOE iPlatform."""
    from playwright.sync_api import sync_playwright

    url = DISTRICT_REPORT_URL if report_type == "district" else SCHOOL_REPORT_URL

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
            args=["--disable-blink-features=AutomationControlled"],
        )
        page = browser.new_page()

        try:
            page.goto(url, timeout=30000, wait_until="domcontentloaded")
            time.sleep(3)

            # Select year
            page.select_option("#SchoolYear", str(year))
            time.sleep(1)

            # Click Run Report
            page.click("text=Run Report")

            # Wait for report to render (the table to appear)
            print(f"  Waiting for {report_type} report year {year}...", file=sys.stderr)
            time.sleep(10)

            # Verify report loaded by checking for table rows
            tables = page.query_selector_all("table")
            if len(tables) < 1:
                print(f"  WARNING: No tables found for year {year}", file=sys.stderr)

            # Click Export dropdown, then Excel
            export_btn = page.query_selector('[title="Export"]')
            if export_btn:
                export_btn.click()
                time.sleep(1)

                # Click Excel option
                with page.expect_download(timeout=timeout * 1000) as download_info:
                    page.click("text=Excel")

                download = download_info.value

                if output is None:
                    output = f"nh_{report_type}_{year}.xlsx"

                download.save_as(output)
                file_size = os.path.getsize(output)
                print(f"SUCCESS:{output} ({file_size} bytes)")
                return output
            else:
                print(f"  ERROR: Export button not found", file=sys.stderr)
                return None

        except Exception as e:
            print(f"ERROR:{e}", file=sys.stderr)
            return None

        finally:
            browser.close()


def batch_download(report_type, years, output_dir=None, timeout=120):
    """Download reports for multiple years using a single browser session."""
    from playwright.sync_api import sync_playwright

    if output_dir is None:
        output_dir = os.getcwd()
    os.makedirs(output_dir, exist_ok=True)

    url = DISTRICT_REPORT_URL if report_type == "district" else SCHOOL_REPORT_URL

    results = []

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
            args=["--disable-blink-features=AutomationControlled"],
        )
        page = browser.new_page()

        try:
            page.goto(url, timeout=30000, wait_until="domcontentloaded")
            time.sleep(3)

            for year in years:
                output_path = os.path.join(
                    output_dir, f"nh_{report_type}_{year}.xlsx"
                )

                if os.path.exists(output_path) and os.path.getsize(output_path) > 5000:
                    print(f"EXISTS:{output_path} ({os.path.getsize(output_path)} bytes)")
                    results.append(output_path)
                    continue

                print(f"Downloading {report_type} year {year}...", file=sys.stderr)

                try:
                    # Select year
                    page.select_option("#SchoolYear", str(year))
                    time.sleep(1)

                    # Click Run Report
                    page.click("text=Run Report")
                    time.sleep(8)

                    # Click Export -> Excel
                    export_btn = page.query_selector('[title="Export"]')
                    if export_btn:
                        export_btn.click()
                        time.sleep(1)

                        with page.expect_download(timeout=timeout * 1000) as download_info:
                            page.click("text=Excel")

                        download = download_info.value
                        download.save_as(output_path)
                        file_size = os.path.getsize(output_path)
                        print(f"SUCCESS:{output_path} ({file_size} bytes)")
                        results.append(output_path)
                    else:
                        print(f"FAILED:{year} - Export button not found", file=sys.stderr)

                except Exception as e:
                    print(f"FAILED:{year} - {e}", file=sys.stderr)

                # Brief pause between downloads
                time.sleep(2)

        except Exception as e:
            print(f"ERROR: {e}", file=sys.stderr)

        finally:
            browser.close()

    return results


def parse_year_range(year_str):
    """Parse year range like '2015-2026' or single year '2025'."""
    if "-" in year_str:
        parts = year_str.split("-")
        start = int(parts[0])
        end = int(parts[1])
        return list(range(start, end + 1))
    return [int(year_str)]


def main():
    parser = argparse.ArgumentParser(
        description="Download enrollment data from NH DOE iPlatform"
    )
    parser.add_argument(
        "--report",
        required=True,
        choices=["district", "school"],
        help="Report type",
    )
    parser.add_argument("--year", help="Single year (end_year)")
    parser.add_argument("--years", help="Year range (e.g. 2015-2026)")
    parser.add_argument("--output", help="Output file path (single year)")
    parser.add_argument("--output-dir", help="Output directory (batch mode)")
    parser.add_argument(
        "--timeout", type=int, default=120, help="Download timeout in seconds"
    )

    args = parser.parse_args()

    if args.years:
        years = parse_year_range(args.years)
        results = batch_download(
            report_type=args.report,
            years=years,
            output_dir=args.output_dir,
            timeout=args.timeout,
        )
        print(f"\nDownloaded {len(results)} files", file=sys.stderr)
    elif args.year:
        download_report(
            report_type=args.report,
            year=args.year,
            output=args.output,
            timeout=args.timeout,
        )
    else:
        parser.error("Either --year or --years is required")


if __name__ == "__main__":
    main()
