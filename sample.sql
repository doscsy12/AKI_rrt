WITH diag AS
(
SELECT
hadm_id
, CASE WHEN icd_version = 9 THEN icd_code ELSE NULL END AS icd9_code
, CASE WHEN icd_version = 10 THEN icd_code ELSE NULL END AS icd10_code
FROM mimic_hosp.diagnoses_icd diag )
, text1 AS 

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
, text2 AS (
SELECT *
from text1
where aki_diag=1 )

-- select first icu
, text3 AS (
select DISTINCT *
from mimic_derived.icustay_detail
where hospstay_seq=1 and icustay_seq=1)

-- patients diagnosis for aki in one hospital and we only extract one patients first hospital and first icu
, text4 AS (

select DISTINCT *
from text2 t2
inner join text3 t3
-- on t2.subject_id = t3.subject_id and t2.hadm_id = t3.hadm_id )
on t2.hadm_id = t3.hadm_id)

-- extract the lab data
, text5 AS (
select DISTINCT *
from text4 t4
left join mimic_derived.first_day_lab lab
on t4.subject_id = lab.subject_id and t4.stay_id = lab.stay_id )

-- extract the comorbidity_charlson data
, text6 AS (
select DISTINCT *
from text5 t5
left join mimic_derived.charlson comorb
on t5.subject_id = comorb.subject_id and t5.hadm_id = comorb.hadm_id )
-- on t5.subject_id = comorb.subject_id and t5.stay_id = comorb.stay_id )
	
-- extract the vitalsign data
, text7 AS (
select DISTINCT *
from text6 t6
left join mimic_derived.first_day_vitalsign vital
on t6.subject_id = vital.subject_id and t6.stay_id = vital.stay_id )

-- extract the weight data
, text8 AS (
select DISTINCT *
from text7 t7
left join mimic_derived.first_day_weight weight
on t7.subject_id = weight.subject_id and t7.stay_id = weight.stay_id )

-- extract the height data
, text9 AS (
select DISTINCT *
from text8 t8
left join mimic_derived.first_day_height heig
on t8.subject_id = heig.subject_id and t8.stay_id =heig.stay_id )

-- extract the urine output data
, text10 AS (
select DISTINCT *
from text9 t9
left join mimic_derived.first_day_urine_output urine
on t9.subject_id = urine.subject_id and t9.stay_id =urine.stay_id )

-- extract the sofa data
, text11 AS (
select DISTINCT *
from text10 t10
left join mimic_derived.first_day_sofa sofa
on t10.subject_id = sofa.subject_id and t10.stay_id = sofa.stay_id )

, kidg as(
select DISTINCT *
,ROW_NUMBER() OVER (PARTITION BY stay_id ORDER BY charttime DESC) AS kigoord
, CASE WHEN aki_stage >0 THEN 1 ELSE 0 END AS new_event_flag     
from mimic_derived.kdigo_stages
where  aki_stage  IS NOT NULL)

, kidg2 as(
select DISTINCT *
,ROW_NUMBER() OVER (PARTITION BY stay_id ORDER BY charttime DESC) AS kigoord2
from kidg
where  aki_stage  IS NOT NULL and new_event_flag =1 )

, kidg3 as(
select DISTINCT *
from kidg2
where kigoord2=1)

, kidg4 as(
select DISTINCT *
,ROW_NUMBER() OVER (PARTITION BY stay_id ORDER BY charttime DESC) AS rrtorder
from mimic_derived.rrt rt
where dialysis_active=1
)

, kidg5 as(
select DISTINCT *
from kidg4
where rrtorder =1 
)

, kidg6 as(
select 
ki.subject_id,
ki.hadm_id,
ki.stay_id,
ki.charttime,
ki.creat_low_past_7day,
ki.creat_low_past_48hr,
ki.creat,
ki.aki_stage_creat,
ki.uo_rt_6hr,
ki.uo_rt_12hr,
ki.uo_rt_24hr,
ki.aki_stage_uo,
ki.kigoord,
ki.new_event_flag,
ki.kigoord2,
round((datetime_diff(ki.charttime,rt.charttime, 'HOUR'::text) / 24.0)) AS timediff

from kidg3 ki
inner join kidg5 rt
on ki.stay_id = rt.stay_id)
select *
from kidg6
where timediff > 8.0 

