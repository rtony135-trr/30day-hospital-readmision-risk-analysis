# <p align="center">Hospital Readmission Risk Analysis</p>

## Problem

Hospital readmission within 30 days of discharge are an important healthcare quality and resource-utilization concern. Understanding which patient characteristics and care patterns are associated with readmission can help healthcare teams identify opportunities to improve discharge planning and follow-up.

This project explores the **Diabetes 130-US Hospitals dataset**, using SQL to investigate associations between 30-day readmission and factors including previous hospital utilisation, length of stay, medication burden, age, diagnoses, admission source, and discharge disposition.

The objective was to transform raw healthcare data into structured analyses and actionable insights using MySQL.

## Data & Tools
- **Dataset:** - Diabetes 130-US Hospitals for Years 1999-2008 (UCI Machine Learning Repository, CC BY 4.0). ~100,000 patient encounters across 130 hospitals, 1999-2008
- **Scale:** Approximately 100,000 hospital encounters across 130 U.S. hospitals
- **Database:** MySQL
- **Environment:** MySQL Workbench
- **Techniques:** CTEs, aggregate functions, conditional aggregation, CASE statements, subqueries, data cleaning, and multi-table joins.

## Approach & Methodology
- **Data Cleaning:** Standardised missing-value placeholders, checked missing data, and examined duplicate patient records.
- **Data Preparation:** Created staging tables, prepared a patient-level dataset, and excluded selected discharge dispositions.
- **Data Transformation:** Built mapping tables for coded fields and converted age ranges into numerical midpoints.
- **Exploratory Analysis:** Used SQL aggregations and `CASE` statements to compare readmission rates across patient and hospital characteristics.
- **SQL Techniques:** Applied joins, CTEs, subqueries, filtering, grouping, and aggregate functions to investigate patterns in readmission data.

## Key Findings
### 1. Previous Inpatient Utilization Was Strongly Associated with Readmission
The 30-day readmission rate increased progressively with previous inpatient utilization, rising from 8.12% among patients with no previous inpatient visits to 28.30% among those with four or more.

### 2. Previous Emergency Utilization Also Showed an Increasing Trend
Readmission rates increased across the previous emergency-utilization groups. This suggests that emergency service use, alongside inpatient history, may help characterize patterns of subsequent hospital utilization.

### 3. Longer Hospital Stays Were Associated with Higher Readmission Rate
The observed readmission rate increased from 7.1% among short stays to 11.1% among stays of 11 days or longer.

### 4. Primary Diagnosis Categories Showed Differences in Readmission Rates
The preliminary diagnosis-category analysis showed differences in readmission rates across the categories returned by the SQL query, with injury and poisoning at 11.0%, circulatory diagnoses at 9.7%, and diabetes diagnoses at 9.2%.

This analysis demonstrates how diagnosis codes can be grouped into broader categories to support comparisons across clinical presentations.

## Recommendations
Based on the observed patterns:
- Investigate whether patients with repeated previous inpatient admissions could benefit from enhanced discharge planning.
- Include previous emergency visits in exploratory analyses of patient utilization and follow-up needs.
- Explore differences between diagnostic groups to better understand variation in readmission patterns.
- Investigate how utilization history, length of stay, medication burden, and diagnosis interact rather than relying on a single characteristic.

## Limitations
- The analysis retains one selected encounter per patient, based on the minimum `encounter_id`. The assumption that this represents the earliest encounter was not independently verified.
-  Selected discharge disposition codes were excluded, so the findings apply to the resulting analytical cohort.
-  Admission type and admission source are separate variables. Admission-type mapping requires a dedicated, verified mapping table. Primary diagnosis categories use selected ICD-9 code ranges and are not a comprehensive clinical classification.
-  The project investigates associations and does not establish causation or account for every potential confounding factor.
- The project demonstrates exploratory SQL analytics; it does not train or validate a clinical readmission prediction model.
- The dataset covers diabetes-related hospital encounters from U.S. hospitals during 1999–2008, so findings may not generalise directly to other populations, healthcare systems, or current clinical practice.

## SQL Skills Demonstrated
- Data staging and cleaning using `CREATE TABLE`, `UPDATE`, and `NULLIF()`
- Missing-value investigation and repeated-patient analysis
- CTEs for reusable analytical datasets
- Conditional aggregation using `CASE`, `SUM()`, and `AVG()`
- Grouped analysis using `GROUP BY`, `HAVING`, and `ORDER BY`
- Subqueries for comparisons against overall readmission rates
- Multi-table joins and code-to-description mapping
- Cohort selection and healthcare utilization analysis
- Translating query results into business-oriented findings

## Conclusion
This project demonstrates the application of MySQL to a real-world healthcare analytics problem, from data preparation and mapping validation to exploratory analysis and interpretation.

The strongest observed pattern was the association between previous inpatient utilization and 30-day readmission, followed by differences across emergency utilization and length-of-stay groups. These findings illustrate how SQL can be used to identify meaningful patterns in healthcare data and generate questions for further investigation.

## Repository Contents

- `SQL` — SQL queries for data preparation, cleaning, mapping, and exploratory analysis.
- `Data Source` — Dataset source and project information.
- `README.md` — Project overview, methodology, key findings, and limitations.
