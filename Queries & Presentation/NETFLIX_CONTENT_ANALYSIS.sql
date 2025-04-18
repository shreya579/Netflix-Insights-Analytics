﻿CREATE DATABASE NETFLIX_CONTENT_ANALYSIS ;

USE  NETFLIX_CONTENT_ANALYSIS ;

SELECT * FROM CREDITS;
SELECT * FROM TITLES;

---1️. Content Strategy & Growth

--- What is the year-over-year growth in Netflix content production across different genres?


WITH GENRE_SPLIT AS (
SELECT 
       RELEASE_YEAR ,
	   TRIM(VALUE) AS GENRES
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(GENRES, '[' , '' ),']', ''),''), ',')
),
GENRE_WISE_TITLE_COUNT AS 
(
SELECT 
        RELEASE_YEAR ,
		GENRES,
		COUNT(*) AS TOTAL_TITLES
FROM GENRE_SPLIT
GROUP BY RELEASE_YEAR , GENRES),
PREVIOUS_YEAR_STATUS AS (
SELECT 
      RELEASE_YEAR ,
		GENRES,
     TOTAL_TITLES AS CURRENT_YEAR_TITLES,
	 LAG(TOTAL_TITLES) OVER(PARTITION BY GENRES ORDER BY RELEASE_YEAR ) AS PREVIOUS_YEAR_TITLES 
FROM GENRE_WISE_TITLE_COUNT
)
SELECT 
      RELEASE_YEAR ,
		GENRES,
     CURRENT_YEAR_TITLES,
	 PREVIOUS_YEAR_TITLES,
	 CURRENT_YEAR_TITLES - PREVIOUS_YEAR_TITLES AS YOY_GROWTH,
	 CONCAT(CAST(ROUND((CURRENT_YEAR_TITLES - PREVIOUS_YEAR_TITLES) * 100 / CURRENT_YEAR_TITLES ,2) AS VARCHAR (255)), '%') AS GROWTH_PERCENTAGE
FROM PREVIOUS_YEAR_STATUS;


--- How does the runtime of movies & TV shows vary across different genres? 


WITH GENRE_WISE_RUNTIME AS 
(SELECT 
       TYPE AS SHOW_TYPE,
	   RUNTIME,
	   TRIM(VALUE) AS GENRES
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(GENRES, '[' , '' ),']', ''),''), ',')
)
SELECT 
      GENRES,
	  SHOW_TYPE,
	  COUNT(*) AS TOTAL_SHOWS,
	  MAX(RUNTIME),
	  MIN(RUNTIME),
	  ROUND(AVG(CAST(RUNTIME AS FLOAT )),2) AS AVG_RUNTIME,
	  ROUND(STDEV(CAST(RUNTIME AS FLOAT )),2) AS STD_DEV
FROM GENRE_WISE_RUNTIME
GROUP BY GENRES,SHOW_TYPE;

--- Which countries are producing the most content on Netflix over time?  

WITH SPLIT_COUNTRY AS 
(SELECT 
       TRIM(VALUE) AS PRODUCTION_COUNTRIES,
	   RELEASE_YEAR
	   
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(PRODUCTION_COUNTRIES, '[' , '' ),']', ''),''), ',')
),
COUNTRYWISE_CONTENT_PROD AS (
SELECT 
      RELEASE_YEAR,
	  PRODUCTION_COUNTRIES,
	  COUNT(*) AS TITLE_COUNT
FROM SPLIT_COUNTRY
GROUP BY RELEASE_YEAR,PRODUCTION_COUNTRIES
),
RANKING_COUNTRYWISE_CONTENT AS 
(SELECT 
      RELEASE_YEAR,
	  TITLE_COUNT,
	  PRODUCTION_COUNTRIES,
	  RANK() OVER(PARTITION BY RELEASE_YEAR ORDER BY TITLE_COUNT DESC ) AS RANKING_CONTENT
FROM COUNTRYWISE_CONTENT_PROD 
)
SELECT 
       RELEASE_YEAR,
	  TITLE_COUNT AS TOTAL_CONTENT,
	  PRODUCTION_COUNTRIES
	  
FROM RANKING_COUNTRYWISE_CONTENT
WHERE RANKING_CONTENT = 1; 


--- What are the top-performing genres based on IMDB & TMDB scores? 

WITH SPLIT_GENRE AS 
(SELECT 
       
	   IMDB_SCORE,
	   TMDB_SCORE,
	   TRIM(VALUE) AS GENRES
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(GENRES, '[' , '' ),']', ''),''), ',')
)
SELECT 
       GENRES,
       ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB,
	   ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )),2) AS AVG_TMDB,
       COUNT(GENRES) AS GENRE_COUNT
FROM SPLIT_GENRE
GROUP BY  GENRES
ORDER BY AVG_IMDB DESC , AVG_TMDB DESC;


--- What is the average season count for successful TV shows (IMDB Score > 7)?  

SELECT 
      ROUND(AVG(CAST(SEASONS AS FLOAT )),2) AS AVG_SEASONS
FROM TITLES 
WHERE IMDB_SCORE > 7 
      AND TYPE = 'SHOW'
	  AND SEASONS IS NOT NULL
	  AND SEASONS > 0;

---2 . Audience Targeting & Engagement 
--- Which age certification category has the highest IMDB/TMDB scores?

SELECT * FROM CREDITS;
SELECT * FROM TITLES;

SELECT TOP 1
      AGE_CERTIFICATION,
      ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB,
	  ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )),2) AS AVG_TMDB
FROM TITLES
WHERE AGE_CERTIFICATION IS NOT NULL
GROUP BY AGE_CERTIFICATION
ORDER BY AVG_IMDB DESC, AVG_TMDB DESC;


--- How do IMDB & TMDB scores correlate with runtime across different genres? 

WITH SPLIT_GENRE AS (
SELECT 
       RUNTIME,
	   IMDB_SCORE,
	   TMDB_SCORE,
	   TRIM(VALUE) AS GENRES
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(GENRES, '[' , '' ),']', ''),''), ',')
)
SELECT 
      GENRES,
	  ROUND(AVG(CAST(RUNTIME AS FLOAT )),2) AS AVG_RUNTIME,
	  ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB,
	  ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )),2) AS AVG_TMDB
	  
FROM SPLIT_GENRE
WHERE RUNTIME IS NOT NULL
      AND IMDB_SCORE IS NOT NULL
      AND TMDB_SCORE IS NOT NULL
GROUP BY GENRES
ORDER BY AVG_IMDB DESC , AVG_TMDB DESC ;
	  

---What are the most popular movie durations based on audience scores & votes? 

SELECT TOP 10
      RUNTIME,
	  SUM(IMDB_VOTES) AS VOTE_COUNT,
      ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB,
	  ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )),2) AS AVG_TMDB,
	  ROUND(AVG(CAST(TMDB_POPULARITY AS FLOAT )),2) AS AVG_TMDB_POPULARITY
FROM TITLES
WHERE TYPE = 'MOVIE'
      AND IMDB_SCORE IS NOT NULL
      AND TMDB_SCORE IS NOT NULL
	  AND RUNTIME IS NOT NULL 
	  AND TMDB_POPULARITY IS NOT NULL
GROUP BY RUNTIME 
ORDER BY AVG_TMDB_POPULARITY DESC , AVG_IMDB DESC  , AVG_TMDB DESC , VOTE_COUNT DESC;
 


--- How does the popularity of titles vary across different production countries? 

WITH SPLIT_COUNTRY AS 
(SELECT
       IMDB_SCORE,
	   TMDB_SCORE,
	   TMDB_POPULARITY,
       TRIM(VALUE) AS PRODUCTION_COUNTRIES
	   
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(PRODUCTION_COUNTRIES, '[' , '' ),']', ''),''), ',')
)
SELECT
       PRODUCTION_COUNTRIES,
	   COUNT(*) AS TOTAL_TITLE,
	   ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB,
	  ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )),2) AS AVG_TMDB,
	  ROUND(AVG(CAST(TMDB_POPULARITY AS FLOAT )),2) AS AVG_TMDB_POPULARITY
FROM SPLIT_COUNTRY
WHERE 
      IMDB_SCORE IS NOT NULL
      AND TMDB_SCORE IS NOT NULL
	  AND TMDB_POPULARITY IS NOT NULL
GROUP BY PRODUCTION_COUNTRIES
ORDER BY AVG_TMDB_POPULARITY DESC , AVG_IMDB DESC  , AVG_TMDB DESC


--- Are TV shows or movies more popular globally, based on TMDB popularity scores?  

SELECT 
       TYPE AS CONTENT_TYPE ,
	   ROUND(AVG(CAST(TMDB_POPULARITY AS FLOAT )),2) AS AVG_TMDB_POPULARITY
FROM TITLES 
WHERE TMDB_POPULARITY  IS NOT NULL
GROUP BY TYPE
ORDER BY AVG_TMDB_POPULARITY DESC ;


---3️⃣ Competitive Analysis & Market Expansion  
--- What are the  top 10 production countries` producing the highest-rated content? 
SELECT * FROM TITLES;
SELECT * FROM CREDITS;

WITH SPLIT_COUNTRY AS 
(SELECT
       IMDB_SCORE,
	   TMDB_SCORE,
	   TRIM(VALUE) AS PRODUCTION_COUNTRIES
	   
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(PRODUCTION_COUNTRIES, '[' , '' ),']', ''),''), ',')
)
SELECT
       PRODUCTION_COUNTRIES,
	   COUNT(*) AS TOTAL_TITLE,
	   ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB,
	  ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )),2) AS AVG_TMDB
FROM SPLIT_COUNTRY
WHERE 
      IMDB_SCORE IS NOT NULL
      AND TMDB_SCORE IS NOT NULL
GROUP BY PRODUCTION_COUNTRIES
ORDER BY   AVG_IMDB DESC  , AVG_TMDB DESC ;


--- Which genres have the widest international reach, appearing in multiple countries?  

WITH SPLIT_GENRE AS (
SELECT
      TRIM(VALUE) AS GENRES,
	  PRODUCTION_COUNTRIES
	   
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(GENRES, '[' , '' ),']', ''),''), ',')
),
SPLIT_COUNTRY AS (
SELECT
      TRIM(VALUE) AS PRODUCTION_COUNTRIES,
	  GENRES
	   
FROM SPLIT_GENRE
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(PRODUCTION_COUNTRIES, '[' , '' ),']', ''),''), ',')
)
SELECT 
      GENRES,
	  COUNT(DISTINCT PRODUCTION_COUNTRIES) AS INTERNATIONAL_REACH
FROM SPLIT_COUNTRY
GROUP BY GENRES
ORDER BY INTERNATIONAL_REACH DESC;


--- What is the distribution of IMDB scores across production countries? 
SELECT * FROM TITLES;

WITH SPLIT_COUNTRY AS (
SELECT
      TRIM(VALUE) AS PRODUCTION_COUNTRIES,
	  IMDB_SCORE
FROM TITLES
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(PRODUCTION_COUNTRIES, '[' , '' ),']', ''),''), ',')
)
SELECT 
       PRODUCTION_COUNTRIES,
       COUNT(*) AS TOTAL_TITLE,
	   ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB_SCORE,
	   ROUND(MAX(CAST(IMDB_SCORE AS FLOAT )),2) AS MAX_IMDB_SCORE,
	   ROUND(MIN(CAST(IMDB_SCORE AS FLOAT )),2) AS MIN_IMDB_sCORE
FROM SPLIT_COUNTRY
WHERE IMDB_SCORE IS NOT NULL
GROUP BY PRODUCTION_COUNTRIES
ORDER BY AVG_IMDB_SCORE DESC;


--- How many unique actors & directors contribute to Netflix content each year? 

SELECT * FROM CREDITS;
SELECT * FROM TITLES;


WITH YEARLY_ACTOR_CONTR AS (
SELECT 
      T.RELEASE_YEAR,
	  C.NAME AS PERSON_NAME,
	  ROLE
FROM CREDITS C
JOIN TITLES T
ON C.ID = T.ID 
)
SELECT 
     RELEASE_YEAR,
	 COUNT(DISTINCT CASE WHEN ROLE IN ('ACTOR' ) THEN PERSON_NAME END) AS ACTOR_COUNT,
	 COUNT(DISTINCT CASE WHEN ROLE IN ('DIRECTOR' ) THEN PERSON_NAME END) AS DIRECTOR_COUNT
FROM YEARLY_ACTOR_CONTR
GROUP BY RELEASE_YEAR
ORDER BY RELEASE_YEAR;


--- What is the trend in Netflix's reliance on international content over time? 
SELECT * FROM TITLES;

WITH INTERNATIONAL_CONTENT AS (
SELECT    RELEASE_YEAR,
          COUNT(*) AS TOTAL_TITLES,
		  COUNT(CASE WHEN PRODUCTION_COUNTRIES NOT LIKE '%US%' THEN 1 END ) AS INTERNATIONAL_CONTENT
FROM TITLES 
GROUP BY RELEASE_YEAR 
)
SELECT 
       RELEASE_YEAR,
	   TOTAL_TITLES,
	   INTERNATIONAL_CONTENT,
	   CONCAT(CAST(ROUND((INTERNATIONAL_CONTENT*100)/TOTAL_TITLES,2) AS VARCHAR(255)), '%') AS INTERNATIONAL_CONTENT_PERCENTAGE
FROM INTERNATIONAL_CONTENT
ORDER BY RELEASE_YEAR


---- Who are the top 10 actors with the most appearances in Netflix content?  
---- What is the average IMDB score for movies starring these top actors? 

SELECT  TOP 10
       C.NAME AS ACTOR_NAME,
       COUNT(T.TITLE) AS CONTENT_COUNT,
	   ROUND(AVG(CAST(T.IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB_SCORE

FROM CREDITS C
JOIN TITLES T
ON C.ID = T.ID 
WHERE C.ROLE = 'ACTOR'
GROUP BY C.NAME 
ORDER BY CONTENT_COUNT DESC;


--- Which actors/directors are consistently involved in high-rated productions? 


SELECT TOP 10
       C.ROLE,
	   C.NAME AS ARTISTS,
	   COUNT(T.TITLE) AS HIGH_RATED_PRODUCTION
	   
FROM TITLES T
JOIN CREDITS C
ON T.ID = C.ID 
WHERE IMDB_SCORE > 8
GROUP BY  C.ROLE , C.NAME
ORDER BY HIGH_RATED_PRODUCTION DESC;

--- Who are the highest-rated directors based on IMDB & TMDB scores?  

SELECT TOP 10 
      C.NAME AS DIRECTORS_NAME,
	  COUNT(T.TITLE) AS HIGH_RATED_PRODUCTION
FROM TITLES T
JOIN CREDITS C
ON T.ID = C.ID 
WHERE IMDB_SCORE > 8 
      AND TMDB_SCORE > 8
	  AND ROLE = 'DIRECTOR'
GROUP BY  C.NAME
ORDER BY HIGH_RATED_PRODUCTION DESC;

--- Which actors have worked in multiple genres, and how do their ratings compare?  

WITH SPLIT_GENRE AS (
SELECT
      C.NAME AS ACTOR_NAME,
      IMDB_SCORE,
	  TRIM(VALUE) AS GENRES
	 
FROM TITLES T
JOIN CREDITS C
ON T.ID = C.ID
CROSS APPLY STRING_SPLIT (NULLIF(REPLACE(REPLACE(GENRES, '[' , '' ),']', ''),''), ',')
WHERE ROLE = 'ACTOR'
)
SELECT ACTOR_NAME ,
       ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB_SCORE,
	   COUNT(DISTINCT GENRES) AS CONTENT_COUNT
	   
FROM SPLIT_GENRE
GROUP BY ACTOR_NAME
ORDER BY  CONTENT_COUNT DESC 

--- 5️⃣ User Engagement & Performance Metrics 
--- What is the correlation between IMDB votes and TMDB popularity?


WITH CORR_FACTOR AS(
SELECT 
      IMDB_VOTES,
	  TMDB_POPULARITY,
	  IMDB_VOTES - AVG(IMDB_VOTES) OVER() AS X,
	  TMDB_POPULARITY - AVG(TMDB_POPULARITY) OVER () AS Y
FROM TITLES 
WHERE IMDB_VOTES IS NOT NULL
      AND TMDB_POPULARITY IS NOT NULL
)
SELECT
      ROUND(SUM(X*Y)/
	  (SQRT(SUM(X*X)) * SQRT(SUM(Y*Y))),3) AS CORR_COEFFIECIENT
FROM CORR_FACTOR;

--- Do older movies (pre-2000) perform better or worse than newer content?

SELECT 
      CASE 
	       WHEN RELEASE_YEAR < 2000 THEN 'OLDER(PRE-2000)'
		   ELSE 'NEWER (2000 & LATER)'
	 END AS MOVIE_CATEGORY,
	 ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )) , 2) AS AVG_IMDB_SCORE,
	 ROUND(AVG(CAST(TMDB_SCORE AS FLOAT )) , 2) AS AVG_TMDB_SCORE,
	 ROUND(AVG(CAST(TMDB_POPULARITY AS FLOAT )) , 2) AS AVG_IMDB_SCORE
FROM TITLES
WHERE TYPE ='MOVIE'
GROUP BY 
       CASE 
	       WHEN RELEASE_YEAR < 2000 THEN 'OLDER(PRE-2000)'
		   ELSE 'NEWER (2000 & LATER)'
	 END ;

--- What is the average IMDB score & votes for Netflix Originals vs. third-party content?

WITH COUNTRY_WISE_CONTENT AS (
SELECT    IMDB_SCORE,
          IMDB_VOTES,
		  (CASE WHEN PRODUCTION_COUNTRIES  LIKE '%US%' THEN 'NETFLIX_ORIGINAL'
		  ELSE 'THIRD_PARTY_CONTENT'
		  END) AS CONTENT_DISTRIBUTION
FROM TITLES
)
SELECT 	  
       CONTENT_DISTRIBUTION, 
	   ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB_SCORE,
	   ROUND(AVG(CAST(IMDB_VOTES AS FLOAT )),2) AS AVG_IMDB_VOTE
FROM COUNTRY_WISE_CONTENT
GROUP BY CONTENT_DISTRIBUTION


--- Which types of content (Movies vs. TV Shows) have the highest audience engagement?

SELECT 
     TYPE AS CONTENT_TYPE,
	 COUNT(*) AS TOTAL_TILES,
	 ROUND(AVG(CAST(IMDB_SCORE AS FLOAT )),2) AS AVG_IMDB_SCORE,
	 ROUND(AVG(CAST(IMDB_VOTES AS FLOAT )),2) AS AVG_IMDB_VOTE,
	 ROUND(AVG(CAST(TMDB_POPULARITY AS FLOAT )),2) AS AVG_TMDB_POPULARITY
FROM TITLES
WHERE IMDB_SCORE IS NOT NULL 
AND TMDB_SCORE IS NOT NULL
AND TMDB_POPULARITY IS NOT NULL
GROUP BY TYPE ;


--- What is the average TMDB popularity trend for content produced in the last 5 years?

SELECT 
       RELEASE_YEAR,
	   COUNT(*) AS TOTAL_TITLES,
	   ROUND(AVG(CAST(TMDB_POPULARITY AS FLOAT )),2) AS AVG_TMDB_POPULARITY
FROM TITLES
WHERE RELEASE_YEAR  >= (SELECT MAX(RELEASE_YEAR) FROM TITLES) - 5
GROUP BY RELEASE_YEAR
ORDER BY RELEASE_YEAR
     




