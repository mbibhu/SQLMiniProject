-- SQL Script
-- Prepare database
DROP DATABASE IF EXISTS SpotifyRanking;

-- Create database schema 
CREATE DATABASE IF NOT EXISTS  SpotifyRanking;

-- use schema
USE spotifyranking;

-- Stores album information
CREATE TABLE IF NOT EXISTS Album (
    album_id VARCHAR(50) PRIMARY KEY     COMMENT 'Unique identifier for album',
    album_name TEXT NOT NULL             COMMENT 'Album name'
) COMMENT = 'Albums table';

-- Stores album information
CREATE TABLE IF NOT EXISTS Album_release (
    album_id VARCHAR(50)      COMMENT 'Unique identifier for album',
    release_date DATE                    COMMENT 'Release date of the album',
    primary key(album_id,release_date),
    FOREIGN KEY (album_id) REFERENCES Album(album_id)  ON DELETE cascade  
) COMMENT = 'Albums release information';

-- Stores artist information
CREATE TABLE IF NOT EXISTS Artist (
    artist_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY  COMMENT 'Auto-incrementing artist ID',
    artist_name VARCHAR(100) UNIQUE NOT NULL              COMMENT 'Name of the artist (should be unique/candidate)',
    email  VARCHAR(256) UNIQUE                            COMMENT 'Email of the artist (should be unique/candidate)'
) COMMENT = 'Artists table';

-- Stores basic metadata for Spotify tracks
CREATE TABLE IF NOT EXISTS Track (
	track_id VARCHAR(50) 	PRIMARY KEY 		    COMMENT 'Unique Spotify track ID',
    `name` TEXT NOT NULL                            COMMENT 'Track title',
    is_explicit BOOLEAN                             COMMENT 'Whether the track has explicit content',
    duration_ms INT                                 COMMENT 'Duration in milliseconds',
    album_id VARCHAR(50)                            COMMENT 'Reference to the album the track belongs to',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP   COMMENT 'record insert time',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP   COMMENT 'record update time',
    FOREIGN KEY (album_id) REFERENCES Album(album_id)  ON DELETE no action
) COMMENT = 'Track metadata table';

-- Many-to-many mapping between tracks and artists
CREATE TABLE IF NOT EXISTS TrackArtist (
    track_id VARCHAR(50)                 COMMENT 'Reference to track',
    artist_id BIGINT UNSIGNED            COMMENT 'Reference to artist',
    PRIMARY KEY (track_id, artist_id),
    FOREIGN KEY (track_id) REFERENCES Track(track_id),
    FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
) COMMENT = 'Join table mapping Tracks to Artists';

-- Stores Spotify audio features for each track
CREATE TABLE IF NOT EXISTS  TrackFeatures (
    track_id VARCHAR(50) PRIMARY KEY     COMMENT 'Same as Spotify ID; also foreign key',
    danceability FLOAT                   COMMENT 'How suitable a track is for dancing (0.0–1.0)',
    energy FLOAT                         COMMENT 'Intensity and activity (0.0–1.0)',
    `key` SMALLINT                       COMMENT 'Estimated musical key (0=C, 1=C#/Db, ..., 11=B)',
    loudness DECIMAL(7,4)                COMMENT 'Overall loudness in decibels (dB)',
    `mode` TINYINT                       COMMENT '1 = major, 0 = minor',
    speechiness FLOAT                    COMMENT 'Presence of spoken words (0.0–1.0)',
    acousticness FLOAT                   COMMENT 'Confidence measure of whether the track is acoustic',
    instrumentalness FLOAT               COMMENT 'Prediction of whether the track contains vocals',
    liveness FLOAT                       COMMENT 'Presence of an audience (live performance)',
    valence DOUBLE                       COMMENT 'Positivity/musical "happiness" (0.0–1.0)',
    tempo DOUBLE                         COMMENT 'Estimated tempo in beats per minute (BPM)',
    time_signature INT                   COMMENT 'Time signature (number of beats per bar)',
    comments TEXT                        COMMENT 'Comments about track',
    FOREIGN KEY (track_id) REFERENCES Track(track_id)
) COMMENT = 'Audio feature details for each track';

-- Daily/weekly chart rankings for tracks
CREATE TABLE IF NOT EXISTS  TrackRankTrend (
    entry_id SERIAL PRIMARY KEY          			COMMENT 'Unique identifier for each chart entry',
    track_id VARCHAR(50)                 			COMMENT 'Reference to track',
    country VARCHAR(10)                  			COMMENT 'Country code (e.g., IN)',
    snapshot_date DATE                  			COMMENT 'Date of the chart',
    daily_rank SMALLINT check(daily_rank  <= 50 )	COMMENT 'Daily rank position',
    daily_movement INT                  			COMMENT 'Daily movement compared to previous day',
    weekly_movement INT                  			COMMENT 'Weekly movement compared to previous week',
    popularity INT                       			COMMENT 'Spotify popularity score',
    FOREIGN KEY (track_id) REFERENCES Track(track_id)
) COMMENT = 'Chart rankings by date & country';

-- load raw data to unnormalized table;
CREATE TABLE IF NOT EXISTS SpotifyDataset (
--    id bigint,
    spotify_id VARCHAR(50),            -- Unique Spotify track ID
    `name` TEXT,                                     -- Track name
    artists TEXT,                                  -- Comma-separated artist names
    daily_rank INT,                                -- Rank of the song for the day
    daily_movement INT,                            -- Movement from previous day
    weekly_movement INT,                           -- Movement from previous week
    country VARCHAR(10),                           -- Country code (e.g., IN)
    snapshot_date varchar(10),                            -- Date of the chart entry
    popularity INT,                                -- Popularity score
    is_explicit varchar(10),                           -- Explicit content flag
    duration_ms INT,                               -- Duration of track in milliseconds
    album_name TEXT,                               -- Album name
    album_release_date varchar(20),                       -- Album release date
    danceability FLOAT,                            -- Danceability score (0.0 - 1.0)
    energy FLOAT,                                  -- Energy level (0.0 - 1.0)
    `key` SMALLINT,                                -- Musical key (0 = C, 1 = C#/Db, ..., 11 = B)
    loudness FLOAT,                                -- Loudness in dB
    `mode` TINYINT,                                -- 1 = Major, 0 = Minor
    speechiness FLOAT,                             -- Presence of spoken words (0.0 - 1.0)
    acousticness FLOAT,                            -- Acoustic level (0.0 - 1.0)
    instrumentalness FLOAT,                        -- Instrumental level (0.0 - 1.0)
    liveness FLOAT,                                -- Live performance presence (0.0 - 1.0)
    valence FLOAT,                                 -- Positivity of the song (0.0 - 1.0)
    tempo FLOAT,                                   -- Tempo in BPM
    time_signature INT                             -- Time signature
);

ALTER TABLE spotifydataset AUTO_INCREMENT = 1;

