
#' load_waypoint
#' 
#' This function load waypoints from gps data.
#'
#' @param path A character indicating the path to the waypoints.
#'
#' @returns A dataframe of waypoints coordinates.
#' @export
#'
#' @examples

load_waypoint <- function(path){
  
  files_waypoints <- unique(c(list.files(path, pattern = "Waypoints", recursive = TRUE, full.names = TRUE),
                              list.files(path, pattern = "Waypoint", recursive = TRUE, full.names = TRUE),
                              list.files(path, pattern = "waypoints", recursive = TRUE, full.names = TRUE),
                              list.files(path, pattern = "waypoint", recursive = TRUE, full.names = TRUE)))
  
  waypoints <- lapply(1:length(files_waypoints), function(i) {
    
    waypoint_i <- gpx::read_gpx(files_waypoints[i])
    
    waypoint_i <- waypoint_i$waypoints
    
  })
  waypoints_bind <- do.call(rbind, waypoints)
  waypoints_bind$date <- format(as.Date(waypoints_bind$Time), "%Y-%m-%d")
  
  return(waypoints_bind)
  
}


#' spygen_waypoint
#' 
#' This function attributes to each spygen survey it's closest waypoint at the date of the survey.
#'
#' @param eDNA_metadata_path A character indicating eDNA metadata path. These metadata includes spygen survey coordinates and dates.
#' @param waypoints A dataframe of waypoints coordinates.
#' @param distance_threshold A numeric indicating the maximal distance threshold in meter between a spygen survey coordinates and the closest waypoint coordinates.
#' @param path_save A character indicating the path to save data.
#'
#' @returns A list of three dataframes : 
#' 
#' "high distance" contain spygen survey with distance to the closest waypoints > `distance_threshold`;
#' 
#' "good distance" contain spygen survey with distance to the closest waypoints < `distance_threshold`;
#' 
#' "na survey" contain spygen survey with no attributed waypoints.
#' @export
#'
#' @examples

spygen_waypoint <- function(eDNA_metadata_path,
                            waypoints,
                            distance_threshold,
                            path_save){
  
  # Load metadata
  
  eDNA_metadata <- read.csv(eDNA_metadata_path, header = TRUE)
  
  eDNA_metadata$date <- as.Date(eDNA_metadata$date)

  # Look for each eDNA survey the closest waypoint by date

  closest_waypoint <- pbmcapply::pbmclapply(1:nrow(eDNA_metadata), function(i) {

    spygen_i <- eDNA_metadata[i,]

    date_i <- spygen_i$date

    waypoints_date_i <- waypoints[waypoints$date == date_i,]

    if(nrow(waypoints_date_i) == 0) {

      closest_point_bind <- NA

    }else{

      waypoints_i_vect <- terra::vect(waypoints_date_i, geom = c("Longitude", "Latitude"), crs = "WGS84", keepgeom = TRUE)

      spygen_i_start <- spygen_i[, !colnames(spygen_i) %in% c("latitude_end_DD", "longitude_end_DD")]
      spygen_i_end <- spygen_i[, !colnames(spygen_i) %in% c("latitude_start_DD", "longitude_start_DD")]

      if(any(is.na(unlist(spygen_i_end[,colnames(spygen_i_end) %in% c("latitude_end_DD", "longitude_end_DD")])))) {

        spygen_i_start_vect <- terra::vect(spygen_i_start, geom = c("longitude_start_DD", "latitude_start_DD"), crs = "WGS84", keepgeom = TRUE)

        nn_cell_start <- terra::as.data.frame(terra::nearest(spygen_i_start_vect, waypoints_i_vect))
        nn_cell_end <- data.frame(from_id = NA,
                                  from_x = NA,
                                  from_y = NA,
                                  to_id = NA,
                                  distance = NA)

      }else{

        spygen_i_start_vect <- terra::vect(spygen_i_start, geom = c("longitude_start_DD", "latitude_start_DD"), crs = "WGS84", keepgeom = TRUE)
        spygen_i_end_vect <- terra::vect(spygen_i_end, geom = c("longitude_end_DD", "latitude_end_DD"), crs = "WGS84", keepgeom = TRUE)

        nn_cell_start <- terra::as.data.frame(terra::nearest(spygen_i_start_vect, waypoints_i_vect))
        nn_cell_end <- terra::as.data.frame(terra::nearest(spygen_i_end_vect, waypoints_i_vect))

      }

      if(any(is.na(c(nn_cell_start$from_x, nn_cell_start$from_y)))) {

        spygen_i_waypoint_start <- waypoints_date_i[1,][!colnames(waypoints_date_i) %in% c("date", "Description")]

        colnames(spygen_i_waypoint_start) <- paste0(colnames(spygen_i_waypoint_start), sep = "_waypoint_start")

        spygen_i_waypoint_start[!colnames(spygen_i_waypoint_start) %in% c("date")] <- NA
        spygen_i_waypoint_start$Time_waypoint_start <- as.POSIXct(spygen_i_waypoint_start$Time_waypoint_start, origin = "1970-01-01", tz = "UTC")

        spygen_i_waypoint_start$distance_start <- NA

      }else{

        spygen_i_waypoint_start <- waypoints_date_i[nn_cell_start$to_id,][!colnames(waypoints_date_i) %in% c("date", "Description")]
        colnames(spygen_i_waypoint_start) <- paste0(colnames(spygen_i_waypoint_start), sep = "_waypoint_start")

        spygen_i_waypoint_start$distance_start <- nn_cell_start$distance

      }

      if(any(is.na(c(nn_cell_end$from_x, nn_cell_end$from_y)))) {

        spygen_i_waypoint_end <- waypoints_date_i[1,][!colnames(waypoints_date_i) %in% c("date", "Description")]

        colnames(spygen_i_waypoint_end) <- paste0(colnames(spygen_i_waypoint_end), sep = "_waypoint_end")

        spygen_i_waypoint_end[!colnames(spygen_i_waypoint_end) %in% c("date")] <- NA
        spygen_i_waypoint_end$Time_waypoint_end <- as.POSIXct(spygen_i_waypoint_end$Time_waypoint_end, origin = "1970-01-01", tz = "UTC")

        spygen_i_waypoint_end$distance_end <- NA

      }else{

        spygen_i_waypoint_end <- waypoints_date_i[nn_cell_end$to_id,][!colnames(waypoints_date_i) %in% c("date", "Description")]
        colnames(spygen_i_waypoint_end) <- paste0(colnames(spygen_i_waypoint_end), sep = "_waypoint_end")

        spygen_i_waypoint_end$distance_end <- nn_cell_end$distance

      }

      spygen_i_waypoint <- do.call(cbind, list(spygen_i, spygen_i_waypoint_start, spygen_i_waypoint_end))

    }

  }, mc.cores = 1)

  closest_waypoint_bind <- do.call(rbind, closest_waypoint[which(is.na(closest_waypoint) == FALSE)])

  # Assess which surveys are beyond the distance threshold, which are below and which with no waypoints

  high_distance1 <- closest_waypoint_bind[closest_waypoint_bind$distance_start > distance_threshold & closest_waypoint_bind$distance_end > distance_threshold,]
  high_distance1 <- high_distance1[!is.na(high_distance1$spygen_code),]

  high_distance2 <- closest_waypoint_bind[closest_waypoint_bind$distance_start > distance_threshold & closest_waypoint_bind$distance_end < distance_threshold,]
  high_distance2 <- high_distance2[!is.na(high_distance2$spygen_code),]

  high_distance3 <- closest_waypoint_bind[closest_waypoint_bind$distance_start > distance_threshold & is.na(closest_waypoint_bind$distance_end),]
  high_distance3 <- high_distance3[!is.na(high_distance3$spygen_code),]

  high_distance4 <- closest_waypoint_bind[closest_waypoint_bind$distance_start < distance_threshold & closest_waypoint_bind$distance_end > distance_threshold,]
  high_distance4 <- high_distance4[!is.na(high_distance4$spygen_code),]

  high_distance <- do.call(rbind, list(high_distance1, high_distance2, high_distance3, high_distance4))

  good_distance1 <- closest_waypoint_bind[closest_waypoint_bind$distance_start < distance_threshold & closest_waypoint_bind$distance_end < distance_threshold,]
  good_distance1 <- good_distance1[!is.na(good_distance1$spygen_code),]

  good_distance2 <- closest_waypoint_bind[closest_waypoint_bind$distance_start < distance_threshold & is.na(closest_waypoint_bind$distance_end),]
  good_distance2 <- good_distance2[!is.na(good_distance2$spygen_code),]

  good_distance <- do.call(rbind, list(good_distance1, good_distance2))

  na_survey <- eDNA_metadata[which(is.na(closest_waypoint)),]

  if(sum(c(nrow(high_distance), nrow(good_distance), nrow(na_survey))) == nrow(eDNA_metadata)){

    print("All good!")

  }else{

    print("Some spygen_id are missing!")

  }

  write.csv(high_distance, file = paste0(path_save, "high_distance.csv"), row.names = FALSE)
  write.csv(good_distance, file = paste0(path_save, "good_distance.csv"), row.names = FALSE)
  write.csv(na_survey, file = paste0(path_save, "na_survey.csv"), row.names = FALSE)

  to_return <- list(high_distance, good_distance, na_survey)
  names(to_return) <- c("high_distance", "good_distance", "na_survey")

  return(to_return)

}


#' check_time
#' 
#' This function calculate the difference in time (minutes) between the waypoint end and start.
#'
#' @param data A dataframe obtained from the function "spygen_waypoint". It must contain the following columns : "spygen_code", "date", "latitude_start_DD", "longitude_start_DD", "latitude_end_DD", "longitude_end_DD", "project", "time_start", "Time_waypoint_start", "Time_waypoint_end".
#'
#' @returns A dataframe with a column named "diff_time_waypoints", indicating the difference in time (minutes) between the waypoint end and start.
#' @export
#'
#' @examples

check_time <- function(data) {
  
  waypoint_time_start_end <- data[colnames(data) %in% c("spygen_code", "date", "latitude_start_DD", "longitude_start_DD", "latitude_end_DD", "longitude_end_DD", "project", "time_start", "Time_waypoint_start", "Time_waypoint_end")]
  
  waypoint_hour <- waypoint_time_start_end
  
  # waypoint_hour$time_start_time <- as.POSIXct(paste0(waypoint_hour$date, " ", waypoint_hour$time_start), tz = "UTC", format = "%Y-%m-%d %H:%M")
  
  waypoint_hour$diff_time_waypoints <- round(as.numeric((waypoint_hour$Time_waypoint_end - waypoint_hour$Time_waypoint_start) / 60))

  # waypoint_hour$diff_time_start_waypoints <- round(as.numeric((waypoint_hour$time_start_time - waypoint_hour$Time_waypoint_start) / 60), 2)

  return(waypoint_hour)

}


#' load_tracks
#' 
#' This function load tracks from gps data.
#'
#' @param path A character indicating the path to the waypoints.
#'
#' @returns A dataframe of tracks coordinates.
#' @export
#'
#' @examples

load_tracks <- function(path){
  
  files_gps <- list.files(path, full.names = TRUE)
  
  files_tracks <- unlist(lapply(1:length(files_gps), function(i) {
    
    list.files(paste0(files_gps[i], "/gps_tracks"), full.names = TRUE)
    
  }))
  
  tracks <- lapply(1:length(files_tracks), function(i) {
    
    tracks_i <- gpx::read_gpx(files_tracks[i])
    
    tracks_i <- tracks_i$tracks[[1]]
    
  })
  tracks_bind <- do.call(rbind, tracks)
  
  return(tracks_bind)
  
}


#' spygen_tracks
#' 
#' This function attributes to each spygen survey it's closest tracks at the date of the survey.
#'
#' @param waypoints A dataframe, the "good_distance" one obtained with the "spygen_waypoint" function.
#' @param gps_tracks A dataframe of tracks coordinates.
#' @param distance_threshold A numeric indicating the maximal distance threshold in meter between a spygen survey coordinates and the closest tracks coordinates.
#' @param path_save A character indicating the path to save data.
#'
#' @returns A list of three dataframe : 
#' 
#' "high distance" contain spygen survey with distance to the closest tracks > `distance_threshold`;
#' 
#' "good distance" contain spygen survey with distance to the closest tracks < `distance_threshold`;
#' 
#' "na survey" contain spygen survey with no attributed tracks.
#' @export
#'
#' @examples

spygen_tracks <- function(waypoints,
                          gps_tracks,
                          distance_threshold,
                          path_save){
  
  gps_tracks$date <- as.Date(gps_tracks$Time)
  
  # Look for each eDNA waypoint the closest tracks by date
  
  closest_tracks <- pbmcapply::pbmclapply(1:nrow(waypoints), function(i) {
    
    spygen_i <- waypoints[i,]
    
    date_i <- spygen_i$date
    
    tracks_eDNA_i <- gps_tracks[gps_tracks$date %in% date_i,]
    
    if(nrow(tracks_eDNA_i) == 0) {
      
      tracks_spygen_i <- cbind(spygen_i[,!colnames(spygen_i) %in% c("Elevation_waypoint_start",
                                                              "Time_waypoint_start",
                                                              "Name_waypoint_start",
                                                              "distance_start",
                                                              "Elevation_waypoint_end",
                                                              "Time_waypoint_end",
                                                              "Name_waypoint_end",
                                                              "distance_end")],
                               data.frame(Elevation = NA,
                                          Time = NA,
                                          Latitude = NA,
                                          Longitude = NA,
                                          extensions = NA,
                                          `Segment ID` = NA,
                                          distance_start = NA,
                                          distance_end = NA,
                                          check.names = FALSE))
      
    }else{
      
      tracks_eDNA_i_vect <- terra::vect(tracks_eDNA_i, geom = c("Longitude", "Latitude"), crs = "WGS84", keepgeom = TRUE)
      
      spygen_i_start <- spygen_i[, colnames(spygen_i) %in% c("spygen_code", "Time_waypoint_start", "Latitude_waypoint_start", "Longitude_waypoint_start")]
      spygen_i_end <- spygen_i[, colnames(spygen_i) %in% c("spygen_code","Time_waypoint_end", "Latitude_waypoint_end", "Longitude_waypoint_end")]
      
      spygen_i_start_vect <- terra::vect(spygen_i_start, geom = c("Longitude_waypoint_start", "Latitude_waypoint_start"), crs = "WGS84", keepgeom = TRUE)
      spygen_i_end_vect <- terra::vect(spygen_i_end, geom = c("Longitude_waypoint_end", "Latitude_waypoint_end"), crs = "WGS84", keepgeom = TRUE)
      
      nn_cell_start <- terra::as.data.frame(terra::nearest(spygen_i_start_vect, tracks_eDNA_i_vect))
      nn_cell_end <- terra::as.data.frame(terra::nearest(spygen_i_end_vect, tracks_eDNA_i_vect))
      
      tracks_spygen_i <- tracks_eDNA_i[nn_cell_start$to_id:nn_cell_end$to_id,]
      
      tracks_spygen_i <- tracks_spygen_i[,which(!colnames(tracks_spygen_i) == "date")]
      
      tracks_spygen_i$distance_start <- nn_cell_start$distance
      tracks_spygen_i$distance_end <- nn_cell_end$distance
      
      tracks_spygen_i <- cbind(spygen_i[,!colnames(spygen_i) %in% c("Elevation_waypoint_start",
                                                                    "Time_waypoint_start",
                                                                    "Name_waypoint_start",
                                                                    "distance_start",
                                                                    "Elevation_waypoint_end",
                                                                    "Time_waypoint_end",
                                                                    "Name_waypoint_end",
                                                                    "distance_end")], tracks_spygen_i)
      
    }
    
  }, mc.cores = 1)
  closest_tracks_bind <- do.call(rbind, closest_tracks)

  # Assess which surveys are beyond the distance threshold, which are below and which with no tracks
  
  high_distance1 <- closest_tracks_bind[closest_tracks_bind$distance_start > distance_threshold & closest_tracks_bind$distance_end > distance_threshold,]
  high_distance1 <- high_distance1[!is.na(high_distance1$spygen_code),]
  
  high_distance2 <- closest_tracks_bind[closest_tracks_bind$distance_start > distance_threshold & closest_tracks_bind$distance_end < distance_threshold,]
  high_distance2 <- high_distance2[!is.na(high_distance2$spygen_code),]
  
  high_distance3 <- closest_tracks_bind[closest_tracks_bind$distance_start > distance_threshold & is.na(closest_tracks_bind$distance_end),]
  high_distance3 <- high_distance3[!is.na(high_distance3$spygen_code),]
  
  high_distance4 <- closest_tracks_bind[closest_tracks_bind$distance_start < distance_threshold & closest_tracks_bind$distance_end > distance_threshold,]
  high_distance4 <- high_distance4[!is.na(high_distance4$spygen_code),]
  
  tracks_high_distance <- do.call(rbind, list(high_distance1, high_distance2, high_distance3, high_distance4))
  
  good_distance1 <- closest_tracks_bind[closest_tracks_bind$distance_start < distance_threshold & closest_tracks_bind$distance_end < distance_threshold,]
  good_distance1 <- good_distance1[!is.na(good_distance1$spygen_code),]
  
  good_distance2 <- closest_tracks_bind[closest_tracks_bind$distance_start < distance_threshold & is.na(closest_tracks_bind$distance_end),]
  good_distance2 <- good_distance2[!is.na(good_distance2$spygen_code),]
  
  tracks_good_distance <- do.call(rbind, list(good_distance1, good_distance2))
  
  tracks_na_survey <- closest_tracks_bind[which(is.na(closest_tracks_bind$distance_start)),]
  
  if(sum(c(length(unique(tracks_high_distance$spygen_code)),
           length(unique(tracks_good_distance$spygen_code)),
           length(unique(tracks_na_survey$spygen_code)))) == nrow(waypoints)){
    
    print("All good!")
    
  }else{
    
    print("Some spygen_id are missing!")
    
  }
  
  write.csv(tracks_high_distance, file = paste0(path_save, "tracks_high_distance.csv"), row.names = FALSE)
  write.csv(tracks_good_distance, file = paste0(path_save, "tracks_good_distance.csv"), row.names = FALSE)
  write.csv(tracks_na_survey, file = paste0(path_save, "tracks_na_survey.csv"), row.names = FALSE)
  
  to_return <- list(tracks_high_distance, tracks_good_distance, tracks_na_survey)
  names(to_return) <- c("tracks_high_distance", "tracks_good_distance", "tracks_na_survey")
  
  return(to_return)
  
}

#' shapefile_tracks
#' 
#' This function convert tracks point as a dataframe into a shapefile.
#'
#' @param eDNA_tracks A dataframe, the "tracks_good_distance" one obtained with the "spygen_tracks" function. 
#' @param path_save A character indicating the path to save data.
#'
#' @returns Save the shapefile to the path indicated by `path_save`
#' @export
#'
#' @examples

shapefile_tracks <- function(eDNA_tracks,
                             path_save){
  
  eDNA_bind <- eDNA_tracks[!is.na(eDNA_tracks$spygen_code),]
  
  eDNA_i_shp <- terra::vect(eDNA_bind, geom = c("Longitude", "Latitude"), crs = "WGS84")
  
  create_shp <- terra::convHull(eDNA_i_shp, by = "spygen_code")
  
  terra::writeVector(create_shp, file = paste0(path_save, "tracks.shp"), overwrite = TRUE)

}

