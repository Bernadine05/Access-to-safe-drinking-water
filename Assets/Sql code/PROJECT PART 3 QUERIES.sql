#JOINING AUDITOR REPORT TABLE AND WATER QUALITY TABLE THROUGH THE VISITS TABLE


SELECT
auditor_report.location_id AS location_id,
visits.record_id,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM
    auditor_report 
JOIN
          visits 
JOIN
         water_quality 
ON
auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id;

#RETRIEVING SPECIFIC DATA FROM COLUMNS IN THE AUDITOR REPORT TABLE

SELECT
    location_id, 
    true_water_source_score
FROM auditor_report
WHERE 
     location_id IN ('AkHa00008','AkHa00053');
     
# FINDING IF AUDITORS SCORE = TO SURVEYOR SCORE
     
SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
WHERE auditor_report.true_water_source_score <> water_quality.subjective_quality_score
AND visits.visit_count = 1;

#ADDING THE WATER SOURCE TABLE TO THE JOIN

SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
water_source.type_of_water_source AS source_of_water,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
water_source
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND water_source.source_id = visits.source_id
WHERE 
     visits.record_id IN ('21160', '7938', '18495', '33931');
     
     
#INCORPORATING EMPLOYEES AND THEIR ID IN THE JOIN

SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS employee_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
employee
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND employee.assigned_employee_id = visits.assigned_employee_id 
WHERE   
	 auditor_report.true_water_source_score <> water_quality.subjective_quality_score
   AND visits.visit_count = 1;
   
   
#CREATING A CTE

WITH incorrect_records AS (
SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS employee_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
employee
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND employee.assigned_employee_id = visits.assigned_employee_id 
WHERE  auditor_report.true_water_source_score <> water_quality.subjective_quality_score
   AND visits.visit_count = 1 
)
select
      *
FROM
     incorrect_records;
     
#FETCHING THE NAMES OF EMPLOYEES WHO FILLED INCORRECT SCORES

WITH incorrect_records AS (
SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS employee_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
employee
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND employee.assigned_employee_id = visits.assigned_employee_id 
WHERE  auditor_report.true_water_source_score <> water_quality.subjective_quality_score
   AND visits.visit_count = 1 
)
select 
   employee_name 
FROM
     incorrect_records;
     
#COUNTING NUMBER OF MISTAKES PER EMPLOYEE

WITH incorrect_records AS (
SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS employee_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
employee
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND employee.assigned_employee_id = visits.assigned_employee_id 
WHERE  auditor_report.true_water_source_score <> water_quality.subjective_quality_score
   AND visits.visit_count = 1 
)
select 
   employee_name,
   count(employee_score) AS NUMBER_of_mistakes
FROM
     incorrect_records
group by employee_name
ORDER BY count(employee_score) DESC;

#CALCULATING AVERAGE NUMBER OF MISTAKES

WITH incorrect_records AS (
SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS employee_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
employee
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND employee.assigned_employee_id = visits.assigned_employee_id 
WHERE  auditor_report.true_water_source_score <> water_quality.subjective_quality_score
   AND visits.visit_count = 1
)
,
error_count AS (
select 
   employee_name,
count(surveyor_score) AS NUMBER_of_mistakes
FROM
     incorrect_records
     GROUP BY employee_name
)
SELECT
AVG(number_of_mistakes) AS average_error_count_per_employee
FROM
error_count;

#COMPARING EACH EMPLOYEE ERROR WITH THE AVERAGE ERROR COUNT/NUMBER OF MISTAKES TO FIND THOSE WITH ERRORS ABOVE AVERAGE


WITH incorrect_records AS (
SELECT
auditor_report.location_id AS Location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS employee_score
FROM
auditor_report 
JOIN
visits
JOIN
water_quality
JOIN
employee
ON auditor_report.location_id = visits.location_id
AND visits.record_id= water_quality.record_id
AND employee.assigned_employee_id = visits.assigned_employee_id 
WHERE  auditor_report.true_water_source_score <> water_quality.subjective_quality_score
   AND visits.visit_count = 1
)
,
error_count AS (
select 
   employee_name,
count(employee_name) AS NUMBER_of_mistakes
FROM
     incorrect_records
     GROUP BY employee_name
)
SELECT
      employee_name,
      number_of_mistakes
FROM
error_count
WHERE
 number_of_mistakes > (SELECT
AVG(number_of_mistakes) AS average_error_count_per_employee
FROM
error_count)
 GROUP BY employee_name;
 
 
#CREATING VIEW/VIRTUAL TABLE FOR THE INCORRECT RECORDS QUERY

CREATE VIEW Incorrect_records AS (
SELECT
auditor_report.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS employee_score,
auditor_report.statements AS statements
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality AS wq
ON visits.record_id = wq.record_id
JOIN
employee
ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
visits.visit_count =1
AND auditor_report.true_water_source_score != wq.subjective_quality_score);


#TAKING A CLOSER LOOK AT THE INCORRECT RECORD OF OUR SUSPECT LIST OF 4

select
      location_id,
      record_id,
      employee_name,
      auditor_score,
      employee_score,
      statements
FROM
     incorrect_records
     auditor_report
WHERE 
   statements LIKE "%cash%";
   
   
#OR

WITH error_count AS (
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name
),

suspect_list AS (
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
SELECT
employee_name,
location_id,
statements
FROM
Incorrect_records
WHERE
employee_name in (SELECT employee_name FROM suspect_list);


#STATEMENTS THAT MIGHT HINT AT BRIBERY FOR OUR MAIN SUSPECT LIST

WITH error_count AS (
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name),
suspect_list AS (
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))
SELECT
employee_name,
location_id,
statements
FROM
Incorrect_records
WHERE
statements LIKE "%cash%" ;


#CHECCKING FOR ANY OTHER EMPLOYEES IN THE SUSPECT LIST WHO MIGHT BE ASSUMED TO BE TAKING BRIBES ( USED SUSPECT LIST AS A CTE)


WITH error_count AS (
select 
   employee_name,
count(employee_name) AS NUMBER_of_mistakes
FROM
     incorrect_records
     GROUP BY employee_name
)
,
suspect_list AS (
SELECT
employee_name,
number_of_mistakes
FROM
error_count
WHERE
number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
select
      location_id,
      record_id,
      employee_name,
      auditor_score,
      employee_score,
      statements
FROM
     incorrect_records
     auditor_report
WHERE 
   employee_name IN (SELECT employee_name from suspect_list);
