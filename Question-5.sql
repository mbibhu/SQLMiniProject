# Patterns observed
# Summary: Total Trending Artists vs Non-Trending Artists (January 2025)
WITH Trending_Artists AS (
    SELECT DISTINCT ta.artist_id
    FROM trackranktrend trt
    JOIN trackartist ta ON trt.track_id = ta.track_id
    WHERE trt.snapshot_date BETWEEN '2025-01-01' AND '2025-01-31'
)
SELECT 
    COUNT(DISTINCT a.artist_id) AS total_artists,
    COUNT(DISTINCT CASE WHEN ta.artist_id IS NOT NULL THEN a.artist_id END) AS trending_artists,
    COUNT(DISTINCT CASE WHEN ta.artist_id IS NULL THEN a.artist_id END) AS non_trending_artists
FROM artist a
LEFT JOIN Trending_Artists ta ON a.artist_id = ta.artist_id;

# Artists with the Highest Number of Tracks
SELECT 
    a.artist_name,
    COUNT(ta.track_id) AS total_tracks
FROM artist a
JOIN trackartist ta ON a.artist_id = ta.artist_id
GROUP BY a.artist_name
ORDER BY total_tracks DESC
LIMIT 10;

# Average Popularity by Country (January 2025)
SELECT 
    trt.country,
    AVG(trt.popularity) AS avg_popularity
FROM trackranktrend trt
WHERE trt.snapshot_date BETWEEN '2025-01-01' AND '2025-01-31'
GROUP BY trt.country
ORDER BY avg_popularity DESC;

# Enery and Danceability are co-related as we see energy bucket increases with avg danceability
SELECT 
    ROUND(t.energy, 1) AS energy_bucket,
    AVG(t.danceability) AS avg_danceability
FROM trackfeatures t
GROUP BY ROUND(t.energy, 1)
ORDER BY energy_bucket;