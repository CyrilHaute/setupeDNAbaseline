############################################################
#
# 02_extract_eDNA_tracks.R: extract eDNA tracks
#
############################################################

# Load required functions
source("R/02_extract_eDNA_tracks_functions.R")

# Set directory to save extracted eDNA tracks
dir.create("outputs/02_eDNA_tracks")
dir_save <- "outputs/02_eDNA_tracks/"


# Load waypoints data

waypoints <- load_waypoint(path = "data/raw-data/trace_gps")

# Assign a waypoint to each spygen_code 

spygen_waypoint_output <- spygen_waypoint(eDNA_metadata_path = "data/raw-data/Med_metadonnees_ADNe - v1.2_2018-2025.csv",
                                          waypoints = waypoints,
                                          distance_threshold = 10,
                                          path_save = dir_save)

# Check for errors in waypoints time

check_time_output <- check_time(data = spygen_waypoint_output$good_distance)


## Assign a gps track to each spygen_code based on waypoints

# Load gps tracks

gps_tracks <- load_tracks(path = "data/raw-data/trace_gps")

spygen_tracks_output <- spygen_tracks(waypoints = spygen_waypoint_output$good_distance,
                                      gps_tracks = gps_tracks,
                                      distance_threshold = 10,
                                      path_save = dir_save)

## Create tracks shapefile

shapefile_tracks(eDNA_tracks = spygen_tracks_output,
                 path_save = dir_save)

load_tracks <- terra::vect("outputs/02_eDNA_tracks/tracks.shp")
load_tracks$spygen_cod
exemple <- load_tracks[load_tracks$spygen_cod == "SPY200474",]
terra::plot(exemple)
