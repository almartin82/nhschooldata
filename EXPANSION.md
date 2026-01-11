# New Hampshire School Data Expansion Research

**Last Updated:** 2026-01-11 **Theme Researched:** Assessment (NH SAS,
K-8 and High School, excluding SAT/ACT)

## Summary of Findings

New Hampshire has **15+ years of historic assessment data** available
(2008-2024), but access is **extremely restricted** due to: 1.
Akamai/EdgeSuite bot blocking (HTTP 403 on automated requests) 2.
Browser-required authentication for iPlatform 3. Tableau dashboards with
no public API 4. Inline documents directory blocked (403 Forbidden)

**CRITICAL BARRIER:** This appears to be one of the most restrictive
state DOE sites in the country for programmatic access.

------------------------------------------------------------------------

## Data Sources Found

### Source 1: NH DOE Assessment Data Page (PRIMARY SOURCE)

- **URL:**
  <https://www.education.nh.gov/who-we-are/division-of-educator-and-analytic-resources/bureau-of-education-statistics/assessment-data>
- **HTTP Status:** 200 (page loads) BUT links likely blocked by Akamai
- **Format:** CSV and Excel files mentioned on page
- **Years Available:**
  - **2023-24:** Disaggregated Data (CSV + Excel)
  - **2022-23:** Disaggregated Data (CSV + Excel)
  - **2021-22:** Disaggregated Data (CSV + Excel)
  - **2020-21:** Disaggregated Data (CSV + Excel)
  - **2018-19:** Disaggregated Data (regular + 95% denominator) (CSV +
    Excel)
  - **2017-18:** Disaggregated Data (regular + 95% denominator) (CSV +
    Excel)
  - **2016-17 to 2008-09:** “Prior Years’ Results” (CSV + Excel)
- **Access Method:** Direct download links on page (BUT likely blocked
  by Akamai/EdgeSuite)
- **Update Frequency:** Annual

**RED FLAGS:** - curl requests return “Access Denied” from
Akamai/EdgeSuite - File directory
`/sites/g/files/ehbemt326/files/inline-documents/` returns HTTP 403 -
Automated access appears actively blocked

### Source 2: iAchieve Tableau Dashboard (2016-2017 data)

- **URL:**
  <https://www.nh.gov/t/DOE/views/iAchieve/ProficiencyandGrowth>
- **Format:** Interactive Tableau dashboard
- **Years:** 2016-2017 primarily
- **Access Method:** Browser-only, JavaScript-rendered
- **Wrapper URL:**
  <https://jwt.nh.gov/?src_route=iAchieve/AssessmentParticipation>

**RED FLAGS:** - Tableau dashboards have no API for bulk download -
Requires browser interaction - Would need Selenium/Playwright for
automation (complex, fragile)

### Source 3: NH School and District Profiles (2010-2015 data)

- **URL:**
  <https://my.doe.nh.gov/profiles/profile.aspx#accountabilitystatus>
- **Format:** Interactive profiles
- **Years:** 2010-2015
- **Access Method:** Browser-based interface

**RED FLAGS:** - Requires browser interaction - No clear bulk download
mechanism

### Source 4: NH DOE iPlatform

- **URL:** <https://my.doe.nh.gov/iPlatform>
- **Format:** Interactive dashboard
- **Access Method:** Requires login/authentication
- **Features:** Assessment Participation, Proficiency and Growth,
  Achievement Levels

**RED FLAGS:** - Authentication required - No documented public API -
Similar to current enrollment data access issues

------------------------------------------------------------------------

## Assessment Types Available

### NH SAS (New Hampshire Statewide Assessment System)

- **Grades:** 3-8 + 11 (high school)
- **Subjects:** English Language Arts/Writing, Mathematics, Science
- **Years:** 2017-present (transitioned from SBAC)

### SBAC (Smarter Balanced Assessment Consortium)

- **Years:** 2015-2017
- **Superseded by:** NH SAS

### NECAP (New England Common Assessment Program)

- **Years:** Through ~2013-2014
- **Subjects:** Math, Reading, Writing, Science
- **Superseded by:** SBAC

------------------------------------------------------------------------

## Data Availability by Year (from SDGANH documentation)

| Year    | Data Source                | Format      | Access Difficulty         |
|---------|----------------------------|-------------|---------------------------|
| 2023-24 | Disaggregated Data Files   | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2022-23 | Disaggregated Data Files   | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2021-22 | Disaggregated Data Files   | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2020-21 | Disaggregated Data Files   | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2018-19 | Disaggregated Data Files   | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2017-18 | Disaggregated Data Files   | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2016-17 | iAchieve Tableau Dashboard | Interactive | **VERY HIGH** (Tableau)   |
| 2015-16 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2014-15 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2013-14 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2012-13 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2011-12 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2010-11 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2009-10 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |
| 2008-09 | Prior Years’ Results       | CSV, Excel  | **HIGH** (Akamai blocked) |

------------------------------------------------------------------------

## Schema Analysis

**LIMITATION:** Unable to download sample files due to HTTP 403 errors.
Schema analysis would require: 1. Manual download of files via browser
2. Manual inspection of column structures 3. Documentation of schema
changes over time

### Expected Data Elements (based on SDGANH documentation)

**Disaggregated Data Files (2018-present) should contain:** -
School/District identifiers - Grade levels (3-8, 11) - Subjects (ELA,
Math, Science) - Achievement levels (Level 1-4) - Proficiency
percentages - Student counts (denominators) - Demographic breakdowns
(sex, race, ethnicity, socioeconomic)

**Data Suppression Rules (from SDGANH):** - Results replaced with
“\>90%” or “\<10%” when small numbers - No achievement score reported if
10 or fewer students - Grade 0 used for district/state aggregates

------------------------------------------------------------------------

## Access Barriers

### Technical Barriers

1.  **Akamai/EdgeSuite Bot Blocking:**
    - All curl requests return “Access Denied”
    - User-Agent blocking likely in place
    - Rate limiting may be aggressive
2.  **Directory Protection:**
    - `/sites/g/files/ehbemt326/files/inline-documents/` returns 403
    - No directory listing allowed
    - Files cannot be enumerated programmatically
3.  **JavaScript-Rendered Content:**
    - iPlatform requires browser
    - Tableau dashboards are interactive
    - No REST API endpoints documented

### Procedural Barriers

1.  **Authentication Required:**
    - iPlatform requires login
    - myNHDOE SSO system
    - No public API keys
2.  **No Bulk Download Interface:**
    - Files must be downloaded individually
    - 15+ years = 30+ files (CSV + Excel for each year)
    - No documented batch download method

------------------------------------------------------------------------

## Recommended Implementation

### Priority: **LOW** (due to extreme access barriers)

### Complexity: **VERY HIGH**

### Estimated Files to Modify: 6-8 new files

### Implementation Challenges

1.  **Cannot automate downloads** - HTTP 403 blocks all programmatic
    access
2.  **Manual intervention required** - User must download files via
    browser
3.  **No stable URL patterns** - Cannot predict file URLs without
    enumeration
4.  **Schema unknown** - Would need manual inspection of downloaded
    files

### Potential Workarounds (Ordered by feasibility)

#### Option 1: import_local\_\*() Pattern (LIKE RI SCHOOLDATA)

- **Pros:**

  - Works with manual downloads
  - Users download files via browser
  - Package reads local files
  - Similar to current enrollment approach

- **Cons:**

  - Poor user experience
  - No automated updates
  - High user burden

- **Implementation:**

  ``` r
  import_local_assessment(file_path, year, type = "disaggregated")
  ```

#### Option 2: Browser Automation (Selenium/Playwright)

- **Pros:**
  - Can potentially bypass JavaScript rendering
  - Can navigate iPlatform
  - Can download files
- **Cons:**
  - Extremely fragile (breaks if site changes)
  - Heavy dependencies (browser drivers)
  - Slow (requires full browser)
  - May still be blocked by bot detection
  - Hard to maintain in CI/CD
- **Estimated Effort:** 40-60 hours initial + ongoing maintenance

#### Option 3: Contact NH DOE for API Access

- **Pros:**
  - May provide official API endpoint
  - Stable, documented access
  - Supports automation
- **Cons:**
  - No guarantee they’ll provide access
  - May require data use agreement
  - Timeline uncertain
- **Contacts:**
  - Data Collection & Reporting Help Desk:
    <https://nhdoepm.atlassian.net>
  - Assessment and Accountability Help Desk:
    <https://nhdoepm.atlassian.net/servicedesk/customer/portal/22/group/66>

#### Option 4: Alternative Data Sources (NOT RECOMMENDED)

- **Federal Data (NCES, EdData Express):**
  - ❌ **PROHIBITED** by project rules
  - Loses state-level detail
  - Aggregated differently than NH DOE
- **Third-Party Aggregators (SDGANH, etc.):**
  - May not have redistribution rights
  - Data may be processed/transformed
  - Licensing unclear

------------------------------------------------------------------------

## Test Requirements

**Cannot write tests** without actual file access. Would need:

### Fidelity Tests (Once files obtained)

- Year 2024: State proficiency rate (to be verified)
- Year 2020: COVID baseline year
- Year 2018: First disaggregated data year
- Year 2016: iAchieve data (if accessible)

### Data Quality Checks

- Proficiency between 0-100%
- No negative student counts
- State totals consistent across years
- Major districts present (Manchester, Nashua, etc.)

------------------------------------------------------------------------

## Time Series Heuristics

**Cannot establish** without data access. Would expect: - State
proficiency: ~45-55% (ELA/Math combined) - ~165,000 students tested -
~160 districts with data - Major districts: Manchester, Nashua, Concord

------------------------------------------------------------------------

## Comparison to Other States

### Most Restrictive Access Encountered

- Arkansas: Direct download, stable URLs ✅
- Texas: Public API, bulk downloads ✅
- New York: Open data portal ✅
- **New Hampshire: BLOCKED** ❌

### Similar Cases

- **Rhode Island:** Uses import_local\_\*() pattern due to similar
  access issues
- **New Hampshire Enrollment:** Already uses import_local_enrollment()
  fallback

------------------------------------------------------------------------

## Recommendation

### DO NOT IMPLEMENT ASSESSMENT DATA AT THIS TIME

**Rationale:**

1.  **Technical Barriers Too High:**
    - HTTP 403 blocks all automation
    - No API endpoints
    - Tableau dashboards can’t be scraped reliably
2.  **Better Targets Available:**
    - 48 other states with accessible data
    - Focus efforts on high-impact, accessible sources
3.  **Maintenance Burden:**
    - Browser automation is extremely fragile
    - Would break constantly
    - Not worth the effort
4.  **User Experience:**
    - Manual download pattern is poor UX
    - Better to not offer than to offer badly

### Alternative: Document Manual Process

If users request NH assessment data, provide: 1. Link to NH DOE
Assessment Data page 2. Instructions for manual download 3. Code
templates for reading downloaded files 4. Example analysis workflows

------------------------------------------------------------------------

## Next Steps (If Assessment Data Becomes Critical)

1.  **Contact NH DOE** for API access or bulk download options
2.  **Pilot Selenium approach** for 2-3 recent years
3.  **Evaluate maintenance burden** vs. user value
4.  **Document schema** from manually downloaded files
5.  **Reassess feasibility**

------------------------------------------------------------------------

## References

- [NH DOE Assessment Data
  Page](https://www.education.nh.gov/who-we-are/division-of-educator-and-analytic-resources/bureau-of-education-statistics/assessment-data)
- [NH DOE iPlatform](https://my.doe.nh.gov/iPlatform)
- [NH iAchieve
  Portal](https://jwt.nh.gov/?src_route=iAchieve/AssessmentParticipation)
- [SDGANH Proficiency Data
  Documentation](https://sdganh.org/nh-proficiency-results-consolidated/)
- [NH Education Facts](https://www.nhfacts.com/datasources)
- [NH DOE Data Collection Help
  Desk](https://nhdoepm.atlassian.net/servicedesk/customer/portal/2/group/67/create/200)
- [NH Assessment and Accountability Help
  Desk](https://nhdoepm.atlassian.net/servicedesk/customer/portal/22/group/66)

------------------------------------------------------------------------

**Researcher Note:** This represents the most challenging state DOE
access encountered in the project to date. The combination of bot
blocking, authentication requirements, and Tableau dashboards makes
automated data access effectively impossible without direct DOE
cooperation.
