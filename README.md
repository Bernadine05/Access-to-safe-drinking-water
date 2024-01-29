# Access-To-Water-Services

## Table of Contents

- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools Used](#tools-used)
- [Data Wrangling](#data-wrangling)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Analysis](#data-analysis)
- [Findings](#findings)
- [Recommendations](#recommendations)
- [Limitations](#limitations)

## Project Overview

A project Identifying the availability of clean drinking water from various water sources such as wells, taps and rivers for residents in an African country. The project also looks into their ease of access and problems people encounter while accessing water sources. Possible solutions and recommendations are also communicated.

### Data Sources

Md-water-services-data: The primary dataset used in this data analysis project is the "md-water-services-data.csv" file which is comprised of different tables giving detailed information about water services in the country.
Auditor-report-data: The secondary dataset used in this analysis is the "auditor-report.csv" file which contains an audit report on the database by an independent auditor and gives insights into inconsistencies in the database and records that need reviewing.

### Tools Used

- Excel and Google Sheets - Data Cleaning and creating Mock Dashboards
- SQL Server (MySQL) - Data Analysis
- Power BI - Creating Reports and Visualizations

### Data Wrangling

  In the initial data preparation step, I performed the following steps:

  1. Data loading and inspection
  2. Identifying null and missing values and utilizing data replacement methods to handle the values
  3. Data cleaning and formatting

### Exploratory Data Analysis

EDA involved exploring the water services data to answer key questions, such as:

- What are the factors contributing to the water crisis?
- What types of water sources are mainly used and how many people does each type of water source serve?
- What is the average queue time for water and peek queueing times?
- Which water sources have broken infrastructure?
- What is the cost of repairing each type of water source?

### Data Analysis

Code and features I worked with:

```Sql
#USING WINDOW FUNCTION TO RANK TYPE OF WATER SOURCE BASED ON HOW MANY PEOPLE USE IT
SELECT 
    type_of_water_source,
    SUM(number_of_people_served) as total_people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) as Rank_by_population
FROM 
    water_source
GROUP BY 
       type_of_water_source;

#EXCLUDING TAP IN HOME FROM RANKING SINCE IT IS THE BEST SOURCE OF WATER AND NOTHING MUCH CAN BE DONE TO IMPROVE IT

WITH total_people_served AS (
    SELECT 
        type_of_water_source,
        SUM(number_of_people_served) as total_people_served
    FROM 
        water_source
    WHERE
        type_of_water_source <> 'tap_in_home'
    GROUP BY 
        type_of_water_source
)

SELECT 
    t.type_of_water_source,
    t.total_people_served,
    RANK() OVER (ORDER BY t.total_people_served DESC) as Rank_by_population
FROM 
    total_people_served t;

#ASSIGNING PRIORITY TO WATER SOURCES TO ENABLE SMOOTH REPAIRS

SELECT 
    source_id,
    type_of_water_source,
    number_of_people_served,
    priority_rank
FROM 
    (
        SELECT 
            source_id,
            type_of_water_source,
            SUM(number_of_people_served) as number_of_people_served,
            dense_rank() OVER (PARTITION BY type_of_water_source ORDER BY SUM(number_of_people_served) DESC) as priority_rank
        FROM 
            water_source
        WHERE
            type_of_water_source <> 'tap_in_home'
        GROUP BY 
            source_id, type_of_water_source
  ) as ranked_sources
WHERE
    number_of_people_served > 100 
ORDER BY
    type_of_water_source, priority_rank ASC;

#INVESTIGATING QUEUE HIGHEST QUEUE TIMES FOR WATER DURING THE WEEK 

SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END
),0) AS Sunday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END
),0) AS Monday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END
),0) AS Tuesday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END
),0) AS Wednesday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END
),0) AS Thursday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END
),0) AS Friday,
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END
),0) AS Saturday
FROM
visits
WHERE
time_in_queue != 0
GROUP BY
hour_of_day
ORDER BY
hour_of_day;
    
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
```

### Findings

The analysis results are summarized as follows;
- People face long wait times for water, averaging over 120 minutes
  - Queues are longer on Saturdays
  - Queues are longer in the mornings and evenings
- The most used type of water source is the "shared tap", with 43% of the population using it and about 2,000 people sharing a single tap
- 31% of people have water infrastructure in their homes but within that group, 45% have non-functional infrastructure due to issues such as broken pipes and pumps

### Recommendations

Based on the analysis, the recommended actions are

1. Focus on improving "shared taps" first as they will benefit many people
2. Fixing existing infrastructure with enable many people to have running water in their homes, reducing queue times
3. With most repairs needed being in rural areas, the repair teams need to prepare for challenges such as bad roads and insufficient supplies and identify ways of overcoming them

### Limitations
Inconsistencies in data due to the large number of stakeholders involved in collecting and compiling the data. I had to integrate more reports later on in the project, which ensured improved accuracy and integrity of the data used but involved a more complex analysis of the data. This led to an extended deadline.
  
