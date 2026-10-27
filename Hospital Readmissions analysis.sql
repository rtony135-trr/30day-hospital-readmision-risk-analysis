SELECT COUNT(*)

-- CHECKING DATA AND CREATING NEW TABLE TO DO CLEANING AND ANALYSIS
FROM diabetic_data_raw;

SELECT *
FROM diabetic_data_raw
LIMIT 10 ;

CREATE TABLE diabetic_data_staging
LIKE diabetic_data_raw 
;

CREATE TABLE ids_mapping_staging
LIKE ids_mapping_raw
;

INSERT diabetic_data_staging
SELECT *
FROM diabetic_data_raw
;

INSERT ids_mapping_staging
SELECT *
FROM ids_mapping_raw
;

ALTER TABLE diabetic_data_staging
	MODIFY diag_1 VARCHAR(10)
    ;

UPDATE diabetic_data_staging
SET race = NULLIF(race,'?'),
	weight = NULLIF(weight,'?'),
	payer_code=NULLIF(payer_code,'?'),	
	medical_specialty=NULLIF(medical_specialty,'?'),
    diag_1 = NULLIF(diag_1,'?'),
    diag_2 = NULLIF(diag_2,'?'),
    diag_3 = NULLIF(diag_3,'?')
    ;
    
SELECT *
FROM diabetic_data_staging
LIMIT 1
;

-- STEP 1 - Looking at percentage of missing data in certain columns.

SELECT
ROUND(SUM(weight IS NULL)/COUNT(*) * 100,1) as pct_missing_WEIGHT,
ROUND(SUM(payer_code IS NULL)/COUNT(*) * 100,1) as pct_missing_PAYER,
ROUND(SUM(medical_specialty IS NULL)/COUNT(*) * 100,1) as pct_missing_SPECIALTY
FROM diabetic_data_staging
;

-- STEP 2 - Duplicates
SELECT patient_nbr, count(*) as encounter_count
FROM diabetic_data_staging
GROUP BY patient_nbr
HAVING encounter_count >1
ORDER BY encounter_count DESC
LIMIT 10
;

CREATE TABLE diabetic_dup AS 
SELECT t.*
FROM diabetic_data_staging AS t
INNER JOIN (SELECT patient_nbr,min(encounter_id) AS first_Encounter
FROM diabetic_data_staging 
GROUP BY patient_nbr) first_Enc
ON t.patient_nbr = first_enc.patient_nbr
AND t.encounter_id = first_enc.first_Encounter
;

-- STEP 3 -- removing patients who were inactive, were discharged to hospice,unknown/invalid dispositions
SELECT 
discharge_disposition_id,
Count(*) as encounter_count
FROM diabetic_data_staging
GROUP BY discharge_disposition_id
ORDER BY encounter_count DESC
;

SELECT *
FROM ids_mapping_raw
WHERE description like '%hospice%' OR description like '%expired%' OR description like '%deceased%'
;

-- 11,13,14,19,20,21,26

DELETE 
FROM diabetic_dup
WHERE discharge_disposition_id IN (11,13,14,19,20,21,26)
;

-- STEP 4
SELECT *
FROM ids_mapping_staging
;

CREATE TABLE discharge_disposition_map (
discharge_disposition_id INT,
description VARCHAR(150)
);

ALTER TABLE  discharge_disposition_map RENAME COLUMN description_1 TO description;

CREATE TABLE admission_source_map (
admission_source_id INT,
description VARCHAR(150)
)
;
ALTER TABLE  admission_source_map RENAME COLUMN description_2 TO description;

DESCRIBE discharge_disposition_map ;
DESCRIBE admission_source_map
;

INSERT INTO discharge_disposition_map (discharge_disposition_id, description) VALUES
(1, 'Discharged to home'),
(2, 'Discharged/transferred to another short term hospital'),
(3, 'Discharged/transferred to SNF'),
(4, 'Discharged/transferred to ICF'),
(5, 'Discharged/transferred to another type of inpatient care institution'),
(6, 'Discharged/transferred to home with home health service'),
(7, 'Left AMA'),
(8, 'Discharged/transferred to home under care of Home IV provider'),
(9, 'Admitted as an inpatient to this hospital'),
(10, 'Neonate discharged to another hospital for neonatal aftercare'),
(11, 'Expired'),
(12, 'Still patient or expected to return for outpatient services'),
(13, 'Hospice / home'),
(14, 'Hospice / medical facility'),
(15, 'Discharged/transferred within this institution to Medicare approved swing bed'),
(16, 'Discharged/transferred/referred another institution for outpatient services'),
(17, 'Discharged/transferred/referred to this institution for outpatient services'),
(18, 'NULL'),
(19, 'Expired at home. Medicaid only, hospice.'),
(20, 'Expired in a medical facility. Medicaid only, hospice.'),
(21, 'Expired, place unknown. Medicaid only, hospice.'),
(22, 'Discharged/transferred to another rehab fac including rehab units of a hospital.'),
(23, 'Discharged/transferred to a long term care hospital.'),
(24, 'Discharged/transferred to a nursing facility certified under Medicaid but not certified under Medicare.'),
(25, 'Not Mapped'),
(26, 'Unknown/Invalid'),
(27, 'Discharged/transferred to a federal health care facility.'),
(28, 'Discharged/transferred/referred to a psychiatric hospital of psychiatric distinct part unit of a hospital'),
(29, 'Discharged/transferred to a Critical Access Hospital (CAH).'),
(30, 'Discharged/transferred to another Type of Health Care Institution not Defined Elsewhere');

INSERT INTO admission_source_map (admission_source_id, description) VALUES
(1, 'Physician Referral'),
(2, 'Clinic Referral'),
(3, 'HMO Referral'),
(4, 'Transfer from a hospital'),
(5, 'Transfer from a Skilled Nursing Facility (SNF)'),
(6, 'Transfer from another health care facility'),
(7, 'Emergency Room'),
(8, 'Court/Law Enforcement'),
(9, 'Not Available'),
(10, 'Transfer from critial access hospital'),
(11, 'Normal Delivery'),
(12, 'Premature Delivery'),
(13, 'Sick Baby'),
(14, 'Extramural Birth'),
(15, 'Not Available'),
(17, 'NULL'),
(18, 'Transfer From Another Home Health Agency'),
(19, 'Readmission to Same Home Health Agency'),
(20, 'Not Mapped'),
(21, 'Unknown/Invalid'),
(22, 'Transfer from hospital inpt/same fac reslt in a sep claim'),
(23, 'Born inside this hospital'),
(24, 'Born outside this hospital'),
(25, 'Transfer from Ambulatory Surgery Center'),
(26, 'Transfer from Hospice'); 

SELECT * FROM discharge_disposition_map;
SELECT * FROM admission_source_map;

-- AGE CLEANING
SELECT * 
FROM diabetic_dup
LIMIT 50
;


ALTER TABLE diabetic_dup ADD COLUMN age_midpoint INT;

UPDATE diabetic_dup
SET age_midpoint = CASE
	WHEN age = '[0-10)' THEN 5
    WHEN age = '[10-20)' THEN 15 
    WHEN age = '[20-30)' THEN 25
    WHEN age = '[30-40)' THEN 35
    WHEN age = '[40-50)' THEN 45
	WHEN age = '[50-60)' THEN 55
	WHEN age = '[60-70)' THEN 65
    WHEN age = '[70-80)' THEN 75
	WHEN age = '[80-90)' THEN 85
    WHEN age = '[90-100)'THEN 95
END
;
    
SELECT * 
FROM diabetic_dup
LIMIT 50
;

-- EXPLORATORY ANALYSIS
 -- Looking at number of readmissions within 30 days, after 30 days and those who have not been readmitted
 
SELECT readmitted,
COUNT(*) as encounter_count,
ROUND (COUNT(*) / (SELECT COUNT(*) FROM diabetic_dup) * 100,1) as pct_total
FROM diabetic_dup
GROUP BY readmitted
ORDER BY encounter_count DESC
;

-- Looking at readmission rate for under 30 days in relation to age
SELECT age,
age_midpoint,
count(*) as encounter_count,
SUM(readmitted ='<30') as readmitted_under_30,
ROUND(SUM(readmitted ='<30')/ count(*) * 100,1) as readmission_rate_pct
FROM diabetic_dup
GROUP BY age,age_midpoint
ORDER BY age_midpoint 
;

-- Looking at readmission rate based on admission type
SELECT
    i.description AS admission_source,
    COUNT(*) AS encounter_count,
    SUM(d.readmitted = '<30') AS readmitted_under_30,
    ROUND(AVG(d.readmitted = '<30') * 100,1) AS readmission_rate_pct
FROM diabetic_dup d
LEFT JOIN admission_source_map i
    ON d.admission_source_id = i.admission_source_id
GROUP BY
    d.admission_source_id,
    i.description
ORDER BY readmission_rate_pct DESC;

   --  Which age group consumes the highest overall quantity of medications combined. 
 SELECT age_midpoint,SUM(num_medications) as total_medications, COUNT(encounter_id) as total_patients
 FROM diabetic_dup
 GROUP BY age_midpoint
 ORDER BY total_medications desc
 LIMIT 10
 ;
 -- Which age group handles the highest medication load on average.
 SELECT age_midpoint,ROUND(AVG(num_medications),1) AS avg_total_medications, COUNT(encounter_id) AS total_patients
 FROM diabetic_dup
 GROUP BY age_midpoint
 ORDER BY avg_total_medications desc
 LIMIT 10
 ; 
 
 --
 WITH patient_risk_base AS 
 ( SELECT encounter_id,
 patient_nbr,
 age_midpoint,
 time_in_hospital,
 num_lab_procedures,
 num_medications,
 number_diagnoses,
 number_emergency,
 number_inpatient,
 diag_1,
 readmitted,
 CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
 FROM diabetic_dup
 )
 SELECT * 
 FROM patient_risk_base
 LIMIT 20
 ;
 

 -- is medication burden associated with 30-day readmission
 SELECT
    num_medications,
    COUNT(*) AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted_within_30_days,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100/ COUNT(*),1) AS readmission_rate
FROM diabetic_dup
GROUP BY num_medications
ORDER BY num_medications
;

-- -- diag_1 notes
-- 390–459: Diseases of the circulatory system
-- 460–519: Diseases of the respiratory system
-- 520–579: Diseases of the digestive system
-- 580–629: Diseases of the genitourinary system
-- 800–999: Injury and poisoning

-- Top diagnoses categories driving readmission
WITH diag_category AS(
SELECT readmitted,
CASE 
	WHEN diag_1 LIKE '250%' THEN 'DIABETES'
	WHEN CAST(LEFT(diag_1,3) AS UNSIGNED) BETWEEN 390 AND 459 THEN 'CIRCULATORY'
	WHEN CAST(LEFT(diag_1,3) AS UNSIGNED) BETWEEN 460 AND 519 THEN 'RESPIRATORY'
	WHEN CAST(LEFT(diag_1,3) AS UNSIGNED) BETWEEN 520 AND 579 THEN 'DIGESTIVE'
	WHEN CAST(LEFT(diag_1,3) AS UNSIGNED) BETWEEN 580 AND 629 THEN 'GENITOURINARY'
	WHEN CAST(LEFT(diag_1,3) AS UNSIGNED) BETWEEN 800 AND 999 THEN 'INJURY AND POISIONING'
	ELSE 'OTHER'
END AS diagnoses_category,
CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS readmitted_within_30_days
FROM diabetic_dup
WHERE diag_1 IS NOT NULL)
SELECT 
diagnoses_category,
COUNT(*) as total_encounters,
ROUND(AVG(readmitted_within_30_days) * 100,1) as readmission_rate_pct
FROM diag_category
GROUP BY diagnoses_category
HAVING AVG(readmitted_within_30_days) > (SELECT AVG(readmitted_within_30_days) FROM diag_category)
ORDER BY readmission_rate_pct DESC;

-- assosciation between medication change and readmission

SELECT 
`change`,
ROUND(SUM(readmitted = '<30')/ COUNT(*) * 100,1) AS readmission_rate_pct
FROM diabetic_dup
GROUP BY `change`
;

-- looking at association between previous inpatient hospitalizations and readmission
SELECT
 CASE 
 WHEN number_inpatient = 0 THEN '0 previous inpatient visits'
 WHEN number_inpatient = 1 THEN '1 previous inpatient visit'
 WHEN number_inpatient BETWEEN 2 AND 3 THEN '2-3 previous inpatient visits'
 ELSE '4+ previous inpatient visits'
 END as inpatient_hospitalizations,
 COUNT(*) as total_encounters,
 ROUND(AVG(readmitted = '<30')*100,2) AS readmission_rate_pct_less_than_30days
 FROM diabetic_dup
 GROUP BY inpatient_hospitalizations
 ORDER BY 
 CASE inpatient_hospitalizations
	WHEN '0 previous inpatient visits' THEN 1
	WHEN '1 previous inpatient visit' THEN 2
	WHEN '2-3 previous inpatient visits' THEN 3
	ELSE  4
    END
    ;

SELECT
 CASE 
 WHEN number_outpatient = 0 THEN '0 previous outpatient visits'
 WHEN number_outpatient = 1 THEN '1 previous outpatient visit'
 WHEN number_outpatient BETWEEN 2 AND 3 THEN '2-3 previous outpatient visits'
 ELSE '4+ previous outpatient visits'
 END as outpatient_tier,
 COUNT(*) as total_encounters,
 ROUND(AVG(readmitted = '<30')*100,2) AS readmission_rate_pct_less_than_30days
 FROM diabetic_dup
 GROUP BY outpatient_tier
 ORDER BY 
 CASE outpatient_tier
	WHEN '0 previous outpatient visits' THEN 1
	WHEN '1 previous outpatient visit' THEN 2
	WHEN '2-3 previous outpatient visits' THEN 3
	ELSE  4
    END
    ;
    
   SELECT
 CASE 
 WHEN number_emergency = 0 THEN '0 previous emergency visits'
 WHEN number_emergency = 1 THEN '1 previous emergency visit'
 WHEN number_emergency BETWEEN 2 AND 3 THEN '2-3 previous emergency visits'
 ELSE '4+ previous emergency visits'
 END as emergency_tier,
 COUNT(*) as total_encounters,
 ROUND(AVG(readmitted = '<30')*100,2) AS readmission_rate_pct_less_than_30days
 FROM diabetic_dup
 GROUP BY emergency_tier
 ORDER BY 
 CASE emergency_tier
	WHEN '0 previous emergency visits' THEN 1
	WHEN '1 previous emergency visit' THEN 2
	WHEN '2-3 previous emergency visits' THEN 3
	ELSE  4
    END
    ;
    
   --   Discharge Disposition Impact on Readmission
    SELECT m.description,
    COUNT(*) as total_encounters,
    ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct_less_than_30days
    FROM discharge_disposition_map m
    JOIN diabetic_dup d
    ON m.discharge_disposition_id = d.discharge_disposition_id
    GROUP BY m.description
    HAVING COUNT(*) > 100
    ORDER BY readmission_rate_pct_less_than_30days DESC
    LIMIT 10
    ;
    
    -- Analysing relationship between length of stay and 30 day readmission
SELECT
    CASE
        WHEN time_in_hospital < 3 THEN 'Short Stay'
        WHEN time_in_hospital BETWEEN 3 AND 10 THEN 'Medium Stay'
        ELSE 'Long Stay'
    END AS time_in_hospital_tier,
    COUNT(*) AS total_encounters,
    SUM(readmitted = '<30') AS readmitted_within_30_days,
    ROUND(AVG(readmitted = '<30') * 100, 1)
        AS readmission_rate_pct
FROM diabetic_dup
GROUP BY time_in_hospital_tier
ORDER BY
    CASE time_in_hospital_tier
        WHEN 'Short Stay' THEN 1
        WHEN 'Medium Stay' THEN 2
        ELSE 3
    END;
    