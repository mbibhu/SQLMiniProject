#	Data Analysis Using SQL

# 4.1:	Descriptive Statistics:
#	Write queries to calculate basic statistics such as count, sum, average, minimum, and maximum for numerical columns.

SELECT 
    COUNT(track_id) AS total_tracks, 		-- total tracks
    COUNT(distinct album_id) AS total_tracks, 	-- count of unique album    
    SUM(duration_ms) AS total_duration_ms, 	-- Total track duration
    AVG(duration_ms) AS avg_duration_ms, 	-- Average song time
    MIN(duration_ms) AS min_duration_ms, 	-- Minimum track time
    MAX(duration_ms) AS max_duration_ms,   	-- Maximum track time 
    Min(danceability) AS min_danceability,	-- Standard deviation danceability
    STD(danceability) AS std_danceability,	-- Standard deviation danceability
    max(danceability) AS max_danceability,	-- Standard deviation danceability
    Min(energy) AS min_energy,			-- Standard deviation Energy song
    STDDEV(energy) AS Std_energy,			-- Standard deviation Energy song
    max(energy) AS max_energy,			-- Standard deviation Energy song
    MAX(tempo) AS max_tempo,					-- Maximum Temp song,
    min(snapshot_date),
    max(snapshot_date)
    FROM 
    spotifyranking.track join spotifyranking.trackfeatures using(track_id)
	join spotifyranking.trackranktrend using(track_id)
    ;

# 4.2:	Data Cleaning:    
#	Write queries to identify and handle missing or inconsistent data.  
-- album release date is missing for tracks. These tracks are execluded from loading into album table
  
Select distinct album_id , album_release_date from album join (
    SELECT DISTINCT album_name, album_release_date
    FROM SpotifyDataset
    WHERE album_release_date IS  NULL
      or album_release_date = ''
      or album_release_date not REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
      AND country in ('IN','US','UK')
	) sd using(album_name);

-- Showcase update, delete, rollback, commit 
Drop table if exists album_update_delete;
Create table album_update_delete like album;
insert into album_update_delete  select * from album;
select * from album_update_delete where album_name = '' or album_name is null;
BEGIN;

SAVEPOINT before_changes;

-- Data manipulation (this can be rolled back)
UPDATE album_update_delete
SET album_name = 'Not provided'
WHERE album_name = '' OR album_name IS NULL;

select * from album_update_delete where album_name = 'Not provided';

-- If you want to roll back to the previous state before changes:
ROLLBACK TO SAVEPOINT before_changes;

-- search the record
select * from album_update_delete where album_name = 'Not provided';
BEGIN;
select * from album_update_delete where album_name = '';
-- delete the record
delete from album_update_delete where album_name = '';
-- If you want to commit the changes
COMMIT;
-- check the commit
select * from album_update_delete where album_name = '';


# 4.3: Aggregation and Grouping:
# Use GROUP BY to aggregate data by different dimensions.

-- 1. Get country wise count of tracks and their average/total song time
WITH Distinct_tracks as( 
SELECT distinct
	track_id,
    country
FROM 
    spotifyranking.trackranktrend
) 
Select 
	Country,
    COUNT(distinct track_id) AS total_tracks,
    SUM(duration_ms) AS total_duration_ms,
    AVG(duration_ms) AS avg_duration_ms
From Distinct_tracks  join   spotifyranking.track  using(track_id)
GROUP BY 
    country
ORDER BY 
    total_duration_ms DESC;

# 4.4:	Joins and Relationships:
# Write queries to join tables to extract meaningful insights.

-- 1. List Track name without Album name
SELECT 
    t.track_id,
    t.name AS track_name,
    a.album_id,
    a.album_name
FROM 
    Track t
JOIN 
    Album a ON t.album_id = a.album_id
where a.album_name is null or a.album_name = ''
ORDER BY 
	t.name;

#2 List artist with no Trending tracks for month of Jan-2025 with Left join
WITH Tracks_Jan2025 AS (
    SELECT 
        DISTINCT ta.artist_id
    FROM trackranktrend trt
    JOIN trackartist ta ON trt.track_id = ta.track_id
    WHERE trt.snapshot_date BETWEEN '2025-01-01' AND '2025-01-31'
)
SELECT 
    a.artist_id,
    a.artist_name
FROM artist a
LEFT JOIN Tracks_Jan2025 tj ON a.artist_id = tj.artist_id
WHERE tj.artist_id IS NULL
ORDER BY a.artist_name;

#3. Join TrackArtist, Artist, and Track — Find Artists for each Track
SELECT 
	distinct
    t.name AS track_name,
    ar.artist_name
FROM 
    Track t
JOIN 
    TrackArtist ta ON t.track_id = ta.track_id
JOIN 
    Artist ar ON ta.artist_id = ar.artist_id
ORDER BY 
    track_name, artist_name;


#4. Get Tracks artist, energy and Tempo. Combine Many Joins (Track ➔ Album ➔ Artist ➔ Features)
SELECT 
    t.name AS track_name,
    a.album_name,
    ar.artist_name,
    tf.energy,
    tf.tempo
FROM 
    Track t
JOIN 
    Album a ON t.album_id = a.album_id
JOIN 
    TrackArtist ta ON t.track_id = ta.track_id
JOIN 
    Artist ar ON ta.artist_id = ar.artist_id
JOIN 
    TrackFeatures tf ON t.track_id = tf.track_id
ORDER BY 
    ar.artist_name, tf.energy DESC;


#4.5: Subqueries and CTEs:
# Use subqueries and Common Table Expressions (CTEs) to write complex queries.

# 1. Subquery — Find tracks with  energy above song 'Hampstead' and 'Ye Tune Kya Kiya'
SELECT 
    t.name AS track_name,
    tf.energy
FROM 
    Track t
JOIN 
    TrackFeatures tf ON t.track_id = tf.track_id
WHERE 
    tf.energy > any (SELECT energy FROM TrackFeatures where track_id in (select distinct track_id from track where name in
    ('Hampstead','Ye Tune Kya Kiya'))) -- subquery in where clause
ORDER BY 
    tf.energy DESC;

# 2. Subquery in SELECT — Show each track's energy compared to average
SELECT 
    t.name AS track_name,
    tf.energy,
    (SELECT AVG(energy) FROM TrackFeatures) AS avg_energy -- subquery in select clause
FROM 
    Track t
JOIN 
    TrackFeatures tf ON t.track_id = tf.track_id
ORDER BY 
    tf.energy DESC;

# 3. CTE — Top 5 Most Popular Tracks by Country (IN, US) on Jan 1st 2025
WITH TopTracks AS (
    SELECT 
        trt.track_id,
        trt.country,
        t.name AS track_name,
        trt.popularity,
        ROW_NUMBER() OVER (PARTITION BY trt.country ORDER BY trt.popularity DESC) AS rn
    FROM 
        TrackRankTrend trt
    JOIN 
        Track t ON trt.track_id = t.track_id
    WHERE 
        trt.country IN ('IN', 'US', 'UK')
        and trt.snapshot_date = '2025-01-01'
)
SELECT Distinct
    country,
    track_name,
    popularity,
    rn as rank_number
FROM 
    TopTracks
WHERE 
    rn <= 5
ORDER BY 
    country, popularity DESC;

#4. CTE with Aggregation — Average Tempo per Artist

WITH ArtistTempo AS (
    SELECT 
        ar.artist_name,
        AVG(tf.tempo) AS avg_tempo
    FROM 
        Artist ar
    JOIN 
        TrackArtist ta ON ar.artist_id = ta.artist_id
    JOIN 
        Track t ON ta.track_id = t.track_id
    JOIN 
        TrackFeatures tf ON t.track_id = tf.track_id
    GROUP BY 
        ar.artist_name
)
SELECT 
    artist_name,
    avg_tempo
FROM 
    ArtistTempo
ORDER BY 
    avg_tempo DESC;

# 4. Multiple CTEs — Tracks that are energetic AND popular in month of febuary 2025
WITH EnergeticTracks AS (
    SELECT 
        track_id,
        energy
    FROM 
        TrackFeatures
    WHERE 
        energy > 0.8
),
PopularTracks AS (
    SELECT distinct 
        track_id,
        popularity
    FROM 
        TrackRankTrend
    WHERE 
        popularity > 80
        and snapshot_date between '2025-02-01' and '2025-02-28'
)
SELECT 
    t.name,
    et.energy,
    pt.popularity
FROM 
    EnergeticTracks et
JOIN 
    PopularTracks pt ON et.track_id = pt.track_id
JOIN 
    Track t ON t.track_id = et.track_id;

# 4.6:	Advanced SQL Functions:
#	Use window functions to perform calculations across a set of table rows related to the current row.

#1: ROW_NUMBER() — Find Latest Rank per Track
WITH RankedTrack AS (
  SELECT 
    track_id,
    country,
    snapshot_date,
    daily_rank,
    ROW_NUMBER() OVER (PARTITION BY track_id, country ORDER BY snapshot_date DESC) AS rn
  FROM TrackRankTrend
)
SELECT *
FROM RankedTrack
WHERE rn = 1;

#2: RANK() — Top Tracks by Popularity on Month of 2024 july
SELECT distinct
  track_id,
  name,
  popularity,
  country,
  snapshot_date,
  RANK() OVER (PARTITION BY track_id, country ORDER BY popularity DESC) AS popularity_rank,
  Dense_rank() OVER (PARTITION BY track_id, country ORDER BY popularity DESC) AS popularity_dense_rank
FROM TrackRankTrend join track using(track_id)
WHERE snapshot_date between '2024-07-01' and '2024-07-31';

# 3 top 10 popular Artist by country this year
-- Popularity defined as max popularity value and number of occurences of any of this tracks in top 50

WITH Tracks_2025 AS (
    SELECT 
        trt.track_id,
        trt.country,
        trt.popularity,
        trt.snapshot_date
    FROM trackranktrend trt
    WHERE YEAR(trt.snapshot_date) = 2025
),
Artist_Track_Stats AS (
    SELECT 
        a.artist_id,
        a.artist_name,
        t25.country,
        COUNT(*) AS num_occurrences,          -- how many times the artist appeared
        MAX(t25.popularity) AS max_popularity  -- best popularity score achieved
    FROM artist a
    JOIN trackartist ta ON a.artist_id = ta.artist_id
    JOIN Tracks_2025 t25 ON ta.track_id = t25.track_id
    GROUP BY a.artist_id, a.artist_name, t25.country
),
Ranked_Artists AS (
    SELECT 
        artist_name,
        country,
        num_occurrences,
        max_popularity,
        RANK() OVER (
            PARTITION BY country 
            ORDER BY num_occurrences DESC, max_popularity DESC
        ) AS artist_rank
    FROM Artist_Track_Stats
)
SELECT 
    country,
    artist_name,
    num_occurrences,
    max_popularity,
    artist_rank
FROM Ranked_Artists
WHERE artist_rank <= 10
ORDER BY country, artist_rank;

# 4 AVG() OVER() — Compare Track Duration to Overall Average
SELECT 
  track_id,
  `name`,
  duration_ms,
  AVG(duration_ms) OVER () AS avg_duration_ms,
  CASE 
    WHEN duration_ms > AVG(duration_ms) OVER () THEN 'Above Average'
    ELSE 'Below Average'
  END AS duration_comparison
FROM Track;

# Advance window function with lag, lead, first_value, last_value, ntile
SELECT 
  track_id,
  country,
  snapshot_date,
  daily_rank,
  LAG(daily_rank) OVER (PARTITION BY track_id, country ORDER BY snapshot_date) AS previous_day_rank,
  (daily_rank - LAG(daily_rank) OVER (PARTITION BY track_id, country ORDER BY snapshot_date)) AS rank_change,
  LEAD(daily_rank) OVER (PARTITION BY track_id, country ORDER BY snapshot_date) AS next_day_rank,
  AVG(daily_rank) OVER (PARTITION BY track_id, country ORDER BY snapshot_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_rank_last_7_days,  
  FIRST_VALUE (daily_rank) OVER (PARTITION BY track_id, country ORDER BY snapshot_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS first_rank_last_7_days,  
  last_VALUE (daily_rank) OVER (PARTITION BY track_id, country ORDER BY snapshot_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS last_rank_last_7_days  ,
  ntile(2) OVER (PARTITION BY track_id, country ORDER BY snapshot_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS nt_rank_last_7_days  
FROM TrackRankTrend
WHERE country = 'IN';


