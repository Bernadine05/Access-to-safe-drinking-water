# GETTING TO KNOW THE DATA BY IDENTIFYING ALL THE TABLES IN THE SCHEMA

SHOW TABLES;

#RETRIEVING THE FIRST  FILES FROM THE LOCATION, VISITS, AND WATER_SOURCE TABLES
SELECT * 
FROM 
md_water_services.location
limit 5;

SELECT * 
FROM 
md_water_services.visits
limit 5;

SELECT * 
FROM 
md_water_services.water_source
limit 5;

#IDENTIFYING UNIQUE WATER SOURCES IN THE AREA

SELECT distinct
type_of_water_source
FROM
water_source;

#UNPACKING THE TIME TAKEN BY RESIDENTS WHEN THEY VISIT WATER SOURCES

SELECT
*
FROM
visits
WHERE
time_in_queue > 500;

#IDENTIFYING SOME OF THE TYPE OF WATER SOURCES THAT TAKE LONG (OVER 500 MIN) TO QUEUE FOR

SELECT
*
FROM
water_source
WHERE
source_id IN ("AkKi00881224","SoRu37635224","SoRu36096224", "AkLu01628224");

#IDENTIFYING WATER SOURCES THAT HAD THE HIGHEST SCORE FOR CLEAN WATER (10) BUT WERE STILL VISITED TWICE BY THE SURVEYOR

SELECT 
count(*)
FROM
water_quality
WHERE
subjective_quality_score =10 AND visit_count =2;

# IDENTIFYING THE LEVEL OF WELL POLLUTION AND THE ACCURACY OF RESULTS/RECORDS BASED ON LEVEL OF POLLUTION
    #Identified inconsistencies in the results recorded

SELECT 
*
FROM
well_pollution
WHERE
results = "clean" AND biological > 0.01;

#IDENTIFYING THE NUMBER OF ROWS IN THE DESCRIPTIONS COLUMN THAT HAVE INCORRECT DATA IN THE WELL POLLUTION TABLE

SELECT
*
FROM
well_pollution
WHERE
results = "clean" AND biological > 0.01 AND description like "clean_%";

#CORRECTING AND UPDATING DESCRIPTIONS THAT WERE RECORDED WRONGLY

SET SQL_SAFE_UPDATES =0;
 
 UPDATE
well_pollution
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';


UPDATE
well_pollution
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';


SELECT
*
FROM
well_pollution
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);

#USING A COPY TABLE TO FIRST EXECUTE THE UPDATES

 CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT
*
FROM
md_water_services.well_pollution
);