use spotifyranking;

# Get upload file path
SHOW VARIABLES LIKE 'secure_file_priv';

# Delete all rows in raw table
TRUNCATE TABLE SpotifyDataset;

# Load raw table from file
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/universal_top_spotify_songs.csv'
INTO TABLE SpotifyDataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SAVEPOINT RAW_TABLE;
-- Verify the rows and columns
select snapshot_date, STR_TO_DATE(snapshot_date, '%d-%m-%Y') as snap_date  from SpotifyDataset limit 10;
select count(1) from SpotifyDataset;
select distinct country from spotifydataset;

## load individual tables from raw table

-- truncate fails due to foreign key contraints ; uncomment to test 
-- truncate album;

-- insert into album table
begin;
INSERT INTO Album (album_id, album_name)
SELECT UUID(), album_name
FROM (
    SELECT DISTINCT album_name
    FROM SpotifyDataset
    WHERE 1=1
      AND country in ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK')
) AS distinct_album;
commit;

--
begin;
INSERT INTO Album_release (album_id, release_date)
SELECT album_id, STR_TO_DATE(album_release_date, '%d-%m-%Y') AS release_date
FROM (
    Select distinct album_id , album_release_date from album join (
    SELECT DISTINCT album_name, album_release_date
    FROM SpotifyDataset
    WHERE album_release_date IS NOT NULL
      AND album_release_date <> ''
      AND album_release_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
      AND country in ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK')) sd using(album_name)
) AS distinct_album;
commit;

-- load artist table
SET SESSION TRANSACTION READ WRITE ;
START Transaction; 
INSERT INTO artist ( artist_name, email)
SELECT  
artist, 
concat(artist,'@gmail.com')
FROM (
	SELECT DISTINCT TRIM(jt.artist) AS artist 
    FROM (
		SELECT artists
		FROM SpotifyDataset
		WHERE artists IS NOT NULL AND artists <> ''
        AND country in ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK')
	) 	AS cleaned,
	JSON_TABLE(
		CONCAT('["', REPLACE(REPLACE(artists, '"', ''), ',', '","'), '"]'),
		'$[*]' COLUMNS (artist VARCHAR(255) PATH '$')
		) AS jt
    )dist_artist;
COMMIT  ;
-- Load track 


INSERT INTO Track (track_id, name, is_explicit, duration_ms, album_id)
WITH tracks AS (
    SELECT distinct
        spotify_id,
        name,
        CASE 
            WHEN LOWER(TRIM(is_explicit)) IN ('true', '1') THEN TRUE
            WHEN LOWER(TRIM(is_explicit)) IN ('false', '0') THEN FALSE
            ELSE NULL
        END AS expl,
        duration_ms,
        album_id,
        row_number() OVER (PARTITION BY spotify_id ORDER BY a.album_name DESC) AS dup_check
    FROM SpotifyDataset s 
    JOIN album a USING (album_name)
    WHERE country IN ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK')
)
SELECT 
    spotify_id, 
    name, 
    expl, 
    duration_ms, 
    album_id
FROM tracks
WHERE dup_check = 1;

-- load TrackRankTrend table
INSERT INTO TrackRankTrend (
    track_id,
    country,
    snapshot_date,
    daily_rank,
    daily_movement,
    weekly_movement,
    popularity
)
SELECT 
    sd.spotify_id,      -- track_id
    sd.country,         -- country
    STR_TO_DATE(sd.snapshot_date, '%d-%m-%Y') snapshot_date,   -- snapshot_date
    sd.daily_rank,      -- daily_rank
    sd.daily_movement,  -- daily_movement
    sd.weekly_movement, -- weekly_movement
    sd.popularity       -- popularity
FROM spotifyranking.spotifydataset sd
JOIN spotifyranking.track t 
    ON sd.spotify_id = t.track_id
WHERE sd.country IN ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK');


-- load Trackfeatures table
INSERT INTO TrackFeatures (
    track_id,
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
    Comments
)
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
    WHERE sd.country IN ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK')
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
    ) AS comments
FROM Numbered_tracks
WHERE rn = 1;

-- load trackartist
INSERT INTO trackartist (track_id, artist_id)
SELECT  track_id , artist_id from artist a join ( 
SELECT DISTINCT TRIM(jt.artist) AS artist, track_id
FROM (
  SELECT artists,spotify_id as track_id
  FROM SpotifyDataset sd
  WHERE artists IS NOT NULL AND artists <> ''
      and sd.country IN ('AU', 'NZ', 'US', 'IN', 'GB', 'DE', 'LU', 'FR', 'CA', 'DK')
 ) AS cleaned,
JSON_TABLE(
  CONCAT(
    '["', REPLACE(REPLACE(artists, '"', ''), ',', '","'), '"]'
  ),
  '$[*]' COLUMNS (
    artist VARCHAR(255) PATH '$'
  )
) AS jt) b on a.artist_name = b.artist
