create database if not exists diabetic_patients;

use diabetic_patients;

select * from patients limit 5;

alter table patients 
modify column risk_score int; 

-- 1. Which patient segments have the highest readmission rate? Answer - Young Adult has higher readmission rate
select age_category ,
	   sum(case when readmitted = '<30' then 1 else 0 end) as readmitted_30,
       round(sum(case when readmitted = '<30' then 1 else 0 end)*100.0 / count(*) ,2) as readmission_rate
from patientspatients
group by age_category
order by readmission_rate desc;

-- 2. Does higher treatment intensity reduce readmissions? Answer - No , High TI has higher readmission rate
SELECT 
    CASE 
        WHEN treatment_intensity < 40 THEN 'Low'
        WHEN treatment_intensity BETWEEN 40 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS treatment_group,
    COUNT(*) AS total,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS readmitted,
    ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate
FROM patients
GROUP BY treatment_group;

-- 3. Which admission sources lead to the most readmissions? Answer - 20 (admission_source_id)
SELECT 
    admission_source_id,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) AS total_readmissions,
    ROUND(SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate
FROM patients
GROUP BY admission_source_id
ORDER BY readmission_rate DESC;

-- 4. Does length of hospital stay affect readmission? Answer - yes 
SELECT 
    CASE
        WHEN days_admitted <= 3 THEN 'Short Stay'
        WHEN days_admitted BETWEEN 4 AND 7 THEN 'Medium Stay'
        ELSE 'Long Stay'
    END AS stay_type,
    COUNT(*) AS total,
    SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) AS readmitted,
    ROUND(SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS readmission_rate
FROM patients
GROUP BY stay_type
ORDER BY readmission_rate DESC;

-- 5. Which patients fall into high-risk categories? Answer - Patients with risk_score between 15 and 25
WITH risk_classification AS (
    SELECT *,
        CASE 
            WHEN risk_score > 25 AND medicine_count > 20 AND lab_tests_count > 60 THEN 'High Risk'
            WHEN risk_score BETWEEN 15 AND 25 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_category
    FROM patients
)
SELECT 
    risk_category,
    COUNT(*) AS total_patients,
    SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) AS readmitted
FROM risk_classification
GROUP BY risk_category
order by readmitted desc ;

-- 6. Who are the top 5 most treated patients in each age group? Answer - 
SELECT *
FROM (
    SELECT 
        patient_id,
        age_category,
        treatment_intensity,
        RANK() OVER (PARTITION BY age_category ORDER BY treatment_intensity DESC) AS rank_in_group
    FROM patients
) ranked
WHERE rank_in_group <= 5;

-- 7. Which discharge types have the highest readmission rates? Answer - type 15
SELECT 
    discharge_disposition_id,
    COUNT(*) AS total,
    SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) AS readmitted,
    ROUND(SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate
FROM patients
GROUP BY discharge_disposition_id
ORDER BY readmission_rate DESC;

-- 8. Is there a relationship between lab tests and risk score? Answer - yes
SELECT 
    CASE 
        WHEN lab_tests_count < 30 THEN 'Low Tests'
        WHEN lab_tests_count BETWEEN 30 AND 60 THEN 'Medium Tests'
        ELSE 'High Tests'
    END AS test_group,
    ROUND(AVG(risk_score), 2) AS avg_risk_score,
    COUNT(*) AS total_patients
FROM patients
GROUP BY test_group
ORDER BY avg_risk_score DESC;

-- 9. Which patients are frequent visitors (multiple encounters)? 
SELECT 
    patient_id,
    COUNT(encounter_id) AS total_visits,
    SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) AS readmissions
FROM patients
GROUP BY patient_id
HAVING COUNT(encounter_id) > 1
ORDER BY total_visits DESC;


-- 10. How do first visits compare with later visits? (Cohort Analysis)? 
WITH ranked_visits AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY encounter_id) AS visit_number
    FROM patients
)
SELECT 
    visit_number,
    COUNT(*) AS total_visits,
    SUM(CASE WHEN readmitted != 'NO' THEN 1 ELSE 0 END) AS readmitted,
    ROUND(AVG(treatment_intensity), 2) AS avg_treatment
FROM ranked_visits
GROUP BY visit_number
ORDER BY visit_number;