WITH diag AS
(
SELECT
hadm_id
, CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
, CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
FROM mimic_hosp.diagnoses_icd diag )
, com AS 
(SELECT
ad.hadm_id
-- Acute kidney failure
, MAX(CASE WHEN
SUBSTR(icd9_code, 1, 3) IN ('584','412')
OR
SUBSTR(icd10_code, 1, 3) IN ('N17')
THEN 1 ELSE 0 END) AS aki_diag
FROM mimic_core.admissions ad
LEFT JOIN diag
ON ad.hadm_id = diag.hadm_id
GROUP BY ad.hadm_id )

-- select all aki patients for a hospital
, aki AS
(SELECT *
from com
where aki_diag=1 )

-- select first icu
, icu_stay AS
(select icu.subject_id, icu.hadm_id, icu.stay_id, icu.gender, icu.admission_age, icu.icu_intime, icu.icu_outtime, icu.first_icu_stay, aki.aki_diag
from mimic_derived.icustay_detail icu
JOIN aki
ON aki.hadm_id=icu.hadm_id
where hospstay_seq=1 and icustay_seq=1)

-- extract weight
, weight AS
(select icu_stay.subject_id, icu_stay.hadm_id, icu_stay.stay_id, icu_stay.gender, icu_stay.admission_age, icu_stay.icu_intime, 
icu_stay.icu_outtime, icu_stay.first_icu_stay, icu_stay.aki_diag, weight.weight
from icu_stay
JOIN mimic_derived.first_day_weight weight
on icu_stay.subject_id = weight.subject_id )

-- extract the urine output data
, urine_out AS
(select DISTINCT weight.subject_id, weight.hadm_id, weight.stay_id, weight.gender, weight.admission_age, weight.icu_intime, 
weight.icu_outtime, weight.first_icu_stay, weight.aki_diag, weight.weight, urine.urineoutput
from weight
left join mimic_derived.first_day_urine_output urine
on weight.subject_id = urine.subject_id  )

-- extract the vitalsign data
, vital_out AS
(select DISTINCT urine_out.hadm_id, urine_out.gender, urine_out.admission_age, urine_out.icu_intime, 
urine_out.icu_outtime, urine_out.first_icu_stay, urine_out.aki_diag, urine_out.weight, urine_out.urineoutput, vital.*
from urine_out
left join mimic_derived.first_day_vitalsign vital
on urine_out.subject_id = vital.subject_id )

-- extract the sofa data
, sofa_out AS
(select DISTINCT vital_out.*, sofa.sofa, sofa.renal
from vital_out
left join mimic_derived.first_day_sofa sofa
on vital_out.subject_id = sofa.subject_id )

-- extract the comorbidity_charlson data
select DISTINCT *
from sofa_out
left join mimic_derived.charlson comorb
on sofa_out.subject_id = comorb.subject_id  

