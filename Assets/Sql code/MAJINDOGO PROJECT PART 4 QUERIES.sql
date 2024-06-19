#JOINING THE LOCATIONS TABLE WITH WATER SOURCE TABLE WITH  VISITS TABLE AS THEIR COMMON JOIN

SELECT
province_name,
town_name,
number_of_people_served,
type_of_water_source,
time_in_queue,
location_type,
results
FROM
   visits
JOIN
water_source
ON VISITS.source_id = water_source.source_id
JOIN
LOCATION
ON 
visits.location_id = location.location_id
LEFT JOIN
well_pollution
ON
visits.source_id = well_pollution.source_id
WHERE visits.visit_count = 1;

#OR

SELECT
water_source.type_of_water_source,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served,
visits.time_in_queue,
well_pollution.results
FROM
visits
LEFT JOIN
well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN
location
ON location.location_id = visits.location_id
INNER JOIN
water_source
ON water_source.source_id = visits.source_id
WHERE
visits.visit_count = 1;

#MAKING A VIEW FROM THE ABOVE QUERIES

CREATE VIEW combined_analysis_table AS 
SELECT
province_name,
town_name,
number_of_people_served,
type_of_water_source,
time_in_queue,
location_type,
results
FROM
   visits
JOIN
water_source
ON VISITS.source_id = water_source.source_id
JOIN
LOCATION
ON 
visits.location_id = location.location_id
LEFT JOIN
well_pollution
ON
visits.source_id = well_pollution.source_id
WHERE visits.visit_count = 1;

SELECT
     *
FROM
      combined_analysis_table;

#CTE TABLE CALCULATING THE POLPULATION OF EACH PROVINCE IN % BASED ON THE POPULARITY OF WATER USED

WITH province_totals AS (
SELECT
province_name,
SUM(NUMBER_of_people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
ct.province_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN NUMBER_of_people_served ELSE 0 END)* 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN NUMBER_of_people_served ELSE 0 END)* 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source  = 'tap_in_home'
THEN NUMBER_of_people_served ELSE 0 END)* 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN  type_of_water_source = 'tap_in_home_broken'
THEN NUMBER_of_people_served ELSE 0 END)* 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN  type_of_water_source = 'well' 
THEN NUMBER_of_people_served ELSE 0 END)* 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name ASC;
SELECT
    *
FROM
    PROVINCE_TOTALS;
    
# % POPULATION OF EACH TOWN  BASED ON TYPE OF WATER  COMMONLY USED joined on a composite key

WITH town_totals AS (
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served  ELSE 0 END) *100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
town_totals tt 
ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name 
GROUP BY 
ct.province_name,
ct.town_name
ORDER BY
ct.town_name ASC,
river DESC;

#STORING TOWN TOTALS AS A TEMPORARY TABLE

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served  ELSE 0 END) *100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END)* 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
town_totals tt 
ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name 
GROUP BY 
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

# PROVINCES AND TOWNS WITH NUMBER OF BROKEN TOWNS

SELECT
province_name,
town_name,
ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *

100,0) AS Pct_broken_taps

FROM
town_aggregated_water_access;


# PROJECT PROGRESS REPORT
DROP TABLE project_progress;
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town_name VARCHAR(30),
Province_name VARCHAR(30),
type_of_water_source VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT);


# CREATING A QUERY FOR THE PROGRESS REPORT TABLE

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
visits.time_in_queue,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
 and (results <> 'clean'
    OR  type_of_water_source = 'shared_tap' AND time_in_queue >= 30
    OR type_of_water_source IN ('river', 'tap_in_home_broken'))
     OR type_of_water_source IS NULL;
    
#WELL IMPROVEMENT VALUES

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
visits.time_in_queue,
water_source.type_of_water_source,
well_pollution.results,
CASE
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
ELSE 'null'
END AS IMPROVEMENT
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
 and (results <> 'clean'
    OR  type_of_water_source = 'shared_tap' AND time_in_queue >= 30
    OR type_of_water_source IN ('river', 'tap_in_home_broken'));
    
# ADDING DRILL WELLS FOR RIVER SOURCES

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
visits.time_in_queue,
water_source.type_of_water_source,
well_pollution.results,
CASE
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN type_of_water_source = 'river' THEN 'Drill well'
ELSE 'null'
END AS IMPROVEMENT
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
 and (results <> 'clean'
    OR  type_of_water_source = 'shared_tap' AND time_in_queue >= 30
    OR type_of_water_source IN ('river', 'tap_in_home_broken'));
    
    
# SHARED TAPS BASED ON QUEUE TIME BEING >=30 minutes

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
visits.time_in_queue,
water_source.type_of_water_source,
well_pollution.results,
CASE
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN type_of_water_source = 'river' THEN 'Drill well'
WHEN type_of_water_source = 'shared_tap' AND time_in_queue >=30 THEN CONCAT("Install ", FLOOR(time_in_queue/30), " taps nearby")
ELSE 'null'
END AS IMPROVEMENT
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
 and (results <> 'clean'
    OR  type_of_water_source = 'shared_tap' AND time_in_queue >= 30
    OR type_of_water_source IN ('river', 'tap_in_home_broken'));


# improvements of broken taps by diagonising the infrastracture

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
visits.time_in_queue,
water_source.type_of_water_source,
well_pollution.results,
CASE
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN type_of_water_source = 'river' THEN 'Drill well'
WHEN type_of_water_source = 'shared_tap' AND time_in_queue >=30 THEN CONCAT("Install ", FLOOR(time_in_queue/30), " taps nearby")
WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
ELSE 'null'
END AS IMPROVEMENT
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
 and (results <> 'clean'
    OR  type_of_water_source = 'shared_tap' AND time_in_queue >= 30
    OR type_of_water_source IN ('river', 'tap_in_home_broken'));
    
# CREATING VIEW

CREATE VIEW compiled_progress AS (
SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
visits.time_in_queue,
water_source.type_of_water_source,
well_pollution.results,
CASE
WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
WHEN type_of_water_source = 'river' THEN 'Drill well'
WHEN type_of_water_source = 'shared_tap' AND time_in_queue >=30 THEN CONCAT("Install ", FLOOR(time_in_queue/30), " taps nearby")
WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
ELSE 'null'
END AS IMPROVEMENT
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE visits.visit_count = 1
 and (results <> 'clean'
    OR  type_of_water_source = 'shared_tap' AND time_in_queue >= 30
    OR type_of_water_source IN ('river', 'tap_in_home_broken'))); 
    
# INSERTING DATA INTO PROJECT_PROGRESS TABLE USING CREATED VIEW

INSERT INTO
      project_progress
 (source_id,Address,Town_name,Province_name,type_of_water_source,Improvement)
 SELECT
 source_id,
   Address,
   Town_name,
   Province_name,
   type_of_water_source,
   Improvement
FROM
     compiled_progress;
    



    