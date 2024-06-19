USE md_water_services;

#TRIMMING PHONE NUMBERS AND UPDATING THE AFFECTED TABLE

SELECT
	length(phone_number)
FROM
    employee;
SELECT
     rtrim(phone_number)
FROM
    employee;

    SET SQL_SAFE_UPDATES =0;
    
    UPDATE
          employee
	SET phone_number= rtrim(phone_number);
    
    # COUNTING HOW MANY EMPLOYEES LIVE IN EACH TOWN
    
    SELECT
         town_name,
         COUNT(employee_name) AS number_of_employees
   FROM
         employee
   GROUP BY town_name;
   
   #TOP 3 EMPLOYEES WITH THE HIGHEST VISIT COUNTS
   
   SELECT
   assigned_employee_id, 
   COUNT(visit_count) AS NUMBER_OF_VISITS
FROM md_water_services.visits
GROUP BY (assigned_employee_id)
order by SUM(visit_count) DESC
limit 3;

#NAME, EMAIL ADDRESS, AND PHONE NUMBER OF EMPLOYEES WITH THE HIGHEST VISITS

SELECT
   phone_number,email,employee_name
   from
       employee
WHERE
      assigned_employee_id IN ('1', '30', '34');
    
 #FINDING THE NUMBER OF RECORDS PER TOWN
 
 SELECT
     town_name,
count(*) AS records_per_town
  FROM md_water_services.location
  group by town_name
  ORDER BY COUNT(*) DESC;
  
  #RECORDS PER PROVINCE
  
  SELECT
     province_name,
count(*) AS records_per_province
  FROM md_water_services.location
  group by province_name
  ORDER BY COUNT(*) DESC;
  
   #STATUS OF WATER CRISIS BASED ON RECORDS PER TOWN IN PROVINCES IN MAJINDOGO
    
    
    SELECT 
    province_name,
    town_name,
    COUNT(*) as records_per_town
FROM 
    md_water_services.location
GROUP BY 
    province_name, town_name
ORDER BY 
    province_name ASC, records_per_town DESC;
    
    #NUMBER OF RECORDS FOR EACH LOCATION TYPE
    
    SELECT
     location_type,
count(*) AS number_of_records
  FROM md_water_services.location
  group by location_type
  ORDER BY COUNT(*) DESC;
  
  SELECT
       23740/(23740+15910) *100;
       
#TOTAL NUMBER OF PEOPLE SURVEYED FROM WATER_SOURCE TABLE

SELECT 
SUM(number_of_people_served) AS total_people_surveyed 
FROM md_water_services.water_source;

#TOTAL NUMBER OF TAPS, WELLS AND RIVERS IN MAJINDOGO

SELECT 
    type_of_water_source,
    COUNT(*) as count
FROM 
    water_source
WHERE 
    type_of_water_source IN ('well', 'tap_in_home', 'tap_in_home_broken', 'shared_tap', 'river')
GROUP BY 
    type_of_water_source
    ORDER BY COUNT(*) DESC;
    
    #AVERAGE NUMBER OF PEOPLE SERVED BY EACH WATER TYPE
    
    SELECT 
    type_of_water_source,
    ROUND(AVG(number_of_people_served)) AS avg_people_served
FROM 
    water_source
GROUP BY 
    type_of_water_source;
    
#GIVEN THAT A TAP IN HOME SERVES 6 PEOPLE ON AVERAGE, THE TAP IN HOME RESULT INDICATES THERE ARE ABOUT 100 TAPS SURVEYED

    
#NUMBER OF PEOPLE GETTING WATER FROM EACH TYPE OF WATER SOURCE

SELECT 
    type_of_water_source,
    SUM(number_of_people_served) AS POP_served_by_each_water_type
FROM 
    water_source
GROUP BY 
    type_of_water_source
    ORDER BY sum(number_of_people_served) DESC;
    

# % OF PEOPLE SERVED BY EACH WATER TYPE

SELECT 
    type_of_water_source,
    round(SUM(number_of_people_served) / (SELECT SUM(number_of_people_served) FROM water_source) * 100) as percentage_served
FROM 
    water_source
GROUP BY 
    type_of_water_source
    ORDER BY round(SUM(number_of_people_served) / (SELECT SUM(number_of_people_served) FROM water_source) * 100) DESC;
    
#USING WINDOW FUNCTION TO RANK TYPE OF WATER SOURCE BASED ON HOW MANY PEOPLE USE IT


SELECT 
    type_of_water_source,
    SUM(number_of_people_served) as total_people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) as Rank_by_population
FROM 
    water_source
GROUP BY 
       type_of_water_source;
    
SELECT * 
    FROM
    water_source
WHERE
      type_of_water_source <> 'tap_in_home';

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
    
    #OR
    
SELECT 
            source_id,
            type_of_water_source,
            SUM(number_of_people_served) as number_of_people_served,
            rank() OVER (PARTITION BY type_of_water_source ORDER BY SUM(number_of_people_served) DESC) as priority_rank
FROM water_source
WHERE type_of_water_source IN ('river', 'tap_in_home_broken', 'shared_tap', 'well')
group by
      source_id, type_of_water_source
order by priority_rank, type_of_water_source;
    
    
#FINDING HOW LONG THE SURVEY TOOK IN DAYS AND IN YEARS

SELECT
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) as survey_duration_in_days
FROM
    visits;
    
SELECT 
    DATEDIFF(
        MAX(time_of_record), 
        MIN(time_of_record)
    ) / 365.25 as survey_duration_years
FROM 
    visits;
    
#AVERAGE QUEUE TIME IN MAJINDOGO FOR WATER GIVEN THAT TAP IN HOME WATER OPTION HAS NO QUEUE TIME

SELECT  
avg(nullif(time_in_queue,0)) AS AVG_total_queue_time 
FROM md_water_services.visits;

#AVERAGE QUEUE TIME FOR EACH DAY OF THE WEEK

SELECT
     DATE_FORMAT(time_of_record, '%W') as day_of_week,
    round(AVG(nullif(time_in_queue,0))) as avg_queue_time
FROM
    visits
GROUP BY
    Day_of_week  
    ORDER BY
       AVG(time_in_queue) DESC;
       
#FINDING TIME OF DAY THAT MOST PEOPLE COLLECT WATER

SELECT 
    DATE_FORMAT(time_of_record, '%H:00') AS hour_of_day,
    round(AVG(time_in_queue)) AS avg_visits
FROM 
    visits
GROUP BY 
    DATE_FORMAT(time_of_record, '%H:00')
ORDER BY 
    hour_of_day;
    
#INVESTIGATING QUEUE HIGHEST QUEUE TIMES FOR WATER DURING THE WEEK IN MAJINDOGO

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
    