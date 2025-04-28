# Spotify Dataset and Database Design

## Original Dataset: SpotifyDataset
The original `SpotifyDataset` was a comprehensive dataset from Spotify, capturing insights into top-ranking Spotify songs across various countries.
It included information such as Track Details,Artist Details, Album Details, Audio Features and Track popularity trends over time.

The data was originally organized as a **single flat table**, leading to redundancy and difficulty in managing relationships across different entities.

## Derivation of Entities and Formation of Tables
To normalize and organize the data efficiently, the following logical entities and corresponding tables were derived:

**Album**: Core information about albums 
**Album_release**: Specific release information of albums (may vary across regions or formats) |
**Artist**: Information about artists (name, genre, etc.)
**Track**: Basic information about each track
**TrackArtist**:  Mapping table between tracks and artists (to handle collaborations)
**TrackFeatures**: Audio and technical features associated with tracks
**TrackRankTrend**:  Historical ranking and popularity trends of tracks over time

This structure supports better data integrity, reduces redundancy, and makes querying more efficient.

## Database Tables Overview
Here’s a description of each table:

### 1. Album
- `album_id` (Primary Key)
- `album_name`
- Other basic album-related fields
- 4NF

### 2. Album_release
- `release_id` (Primary Key)
- `album_id` (Foreign Key → Album)
- `release_date`
- Possibly additional release details (region, version, etc.)

### 3. Artist
- `artist_id` (Primary Key)
- `artist_name`
- `artist_genre`

### 4. Track
- `track_id` (Primary Key)
- `track_name`
- `album_id` (Foreign Key → Album)
- Duration, explicit flag, etc.

### 5. TrackArtist
- `track_id` (Foreign Key → Track)
- `artist_id` (Foreign Key → Artist)

(Composite Primary Key on `track_id` + `artist_id` to handle collaborations.)

### 6. TrackFeatures
- `track_id` (Foreign Key → Track)
- Danceability, energy, tempo, acousticness, instrumentalness, etc.
(One-to-one relationship with Track.)

### 7. TrackRankTrend
- `track_id` (Foreign Key → Track)
- `date`
- `rank_position`
- `popularity_score`
(Many-to-one with Track — A track can have multiple ranking records over time.)

## Normalization Summary
To normalize the original Spotify dataset 
- Core entities such as Album, Artist, Track, and Track Features were identified and structured into separate tables. 
- Many-to-many relationships, particularly between Tracks and Artists, were resolved using a junction table (TrackArtist)
- Multivalued attributes were decomposed into distinct relations. 
- Eliminated repeating groups, partial, and multivalued dependencies.

Database design satisfies Fourth Normal Form (4NF), ensuring minimal redundancy,enhanced data integrity, and improved scalability.

## Building Relationships
The relationships are carefully designed to maintain integrity:

- **Album_release** → **Album**:	Many-to-One - Each release belongs to one album
- **Track** → **Album**:	Many-to-One - Each track belongs to one album
- **TrackArtist** → **Track** and **Artist**:	Many-to-Many - Tracks can have multiple artists (and vice versa)
- **TrackFeatures** → **Track**:	One-to-One - Each track has exactly one set of audio features
- **TrackRankTrend** → **Track**:	Many-to-One - Multiple rankings over different dates for a track

## SQL Files Overview
- **Spotify-DDL.sql**  
  → Contains **DDL scripts** for creating tables, primary keys, and foreign keys.

- **Spotify_DML.sql**  
  → Contains **DML scripts** for inserting sample data into the tables.

- **Spotify-DQL.sql**  
  → Contains **DQL queries** to retrieve meaningful insights and perform analysis.

## Design Choices
- **Normalization**: Ensured minimal data duplication by creating separate entity tables and mapping tables.
- **Many-to-Many Handling**: `TrackArtist` allows modeling collaborations between multiple artists and tracks.
- **Historical Analysis**: `TrackRankTrend` enables trend analysis over time.
- **Extensibility**: New features, trends, artists, or albums can be added easily without altering existing structures.


## Entity-Relationship (ER) Diagram

Below is the ER diagram illustrating the relationships between tables:

![ER Diagram](C:/Bibhu/Work/SQL/MiniProject/ER_DIAGRAM.png)


