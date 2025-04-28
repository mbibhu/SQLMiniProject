# Support SQL to build DML and Questions

-- This query selects distinct album names and their release dates
SELECT DISTINCT 
    album_name,  -- The name of the album
    STR_TO_DATE(album_release_date, '%d-%m-%Y') AS release_date  -- The formatted release date
FROM SpotifyDataset;

-- This query selects distinct artist names by cleaning the `artists` column
SELECT DISTINCT 
    TRIM(jt.artist) AS artist  -- Trim any leading/trailing spaces from artist names
FROM (
    -- Inner query to clean the 'artists' column: removes NULL and empty values
    SELECT artists
    FROM SpotifyDataset
    WHERE artists IS NOT NULL AND artists <> ''
) AS cleaned,
JSON_TABLE(
    -- Convert the `artists` column into a JSON array format
    CONCAT(
        '["', REPLACE(REPLACE(artists, '"', ''), ',', '","'), '"]'
    ),
    '$[*]' COLUMNS (
        artist VARCHAR(255) PATH '$'  -- Extract each artist name from the JSON array
    )
) AS jt;


use spotifyranking;
# count of artist
select count(1) from artist;

-- This query uses a Common Table Expression (CTE) to get details for tracks.
WITH a AS (
    -- Select track details and apply transformations
    SELECT   
        spotify_id,  -- Track's unique Spotify ID
        name,  -- Track name
        CASE 
            WHEN LOWER(TRIM(is_explicit)) IN ('true', '1') THEN TRUE  -- Explicit track flag set to TRUE
            WHEN LOWER(TRIM(is_explicit)) IN ('false', '0') THEN FALSE  -- Explicit track flag set to FALSE
            ELSE NULL  -- NULL if the value is invalid or unknown
        END AS expl,
        duration_ms,  -- Track duration in milliseconds
        album_id,  -- Album ID the track belongs to
        s.album_name,  -- Album name
        row_number() OVER (PARTITION BY spotify_id ORDER BY a.album_name DESC) AS dup_check,  -- Ranking for duplicate track check
        album_release_date  -- Release date of the album
    FROM SpotifyDataset s
    JOIN album a USING (album_name)  -- Join with the album table on album_name
    WHERE country IN ('IN', 'US', 'UK')  -- Filter for specific countries
)
-- Select data from the CTE for a specific track (spotify_id)
SELECT * 
FROM a 
WHERE spotify_id = '0FIDCNYYjNvPVimz5icugS';  -- Filter for a specific track ID

 
 -- Get album details
 select * from album where album_id in ('7c6d44ec-223d-11f0-bcad-a841f4b581da',
'7c6d3915-223d-11f0-bcad-a841f4b581da');

-- Get rank for album
select  album_id, album_name , rank() over(partition by album_name ) 
from album where album_id in ('7AuYlke4foydiCbZbqS5JP') ;

-- Understand duplicates in raw data
select spotify_id, count(distinct album_name) from spotifydataset group by spotify_id having count(distinct album_name)>1;

-- Understand adding random comments from list of sentence. 
WITH Numbered_tracks AS (
    SELECT 
        sd.spotify_id,
        sd.danceability,
        sd.energy,
        sd.`key`,
        sd.loudness,
        sd.`mode`,
        sd.speechiness,
        sd.acousticness,
        sd.instrumentalness,
        sd.liveness,
        sd.valence,
        sd.tempo,
        sd.time_signature,
        ROW_NUMBER() OVER (PARTITION BY sd.spotify_id ORDER BY STR_TO_DATE(sd.snapshot_date, '%d-%m-%Y') DESC) AS rn
    FROM spotifyranking.spotifydataset sd
    JOIN spotifyranking.track t ON sd.spotify_id = t.track_id
    WHERE sd.country IN ('IN', 'US', 'UK')
)
SELECT 
    spotify_id,
    danceability,
    energy,
    `key`,
    loudness,
    `mode`,
    speechiness,
    acousticness,
    instrumentalness,
    liveness,
    valence,
    tempo,
    time_signature,
       CONCAT(
        ELT(FLOOR(RAND() * 10) + 1, 'the', 'quick', 'brown', 'fox', 'jumps', 'over', 'lazy', 'dog', 'crazy', 'bright'), ' ',
		CONVERT(CHAR(FLOOR(RAND() * 26) + 65) USING utf8mb4),  -- random uppercase letter
        CONVERT(CHAR(FLOOR(RAND() * 26) + 97) USING utf8mb4)   -- random lowercase letter
    ) AS random_comments
FROM Numbered_tracks
WHERE rn = 1;
 
-- build trackarctist DQL
SELECT artist_id, track_id from artist a join ( 
SELECT DISTINCT TRIM(jt.artist) AS artist, track_id
FROM (
  SELECT artists,spotify_id as track_id
  FROM SpotifyDataset sd
  WHERE artists IS NOT NULL AND artists <> ''
      and sd.country IN ('IN', 'US', 'UK')
 ) AS cleaned,
JSON_TABLE(
  CONCAT(
    '["', REPLACE(REPLACE(artists, '"', ''), ',', '","'), '"]'
  ),
  '$[*]' COLUMNS (
    artist VARCHAR(255) PATH '$'
  )
) AS jt) b on a.artist_name = b.artist;

select country, count(distinct spotify_id) from spotifyranking.spotifydataset group by 1 order by 2 desc;

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

-- check the data
select * from album limit 10;
select * from album_release limit 10;
select * from artist limit 10;
select * from track limit 10;
select * from trackartist limit 10;
select * from trackfeatures limit 10;
select * from trackranktrend limit 10;

 