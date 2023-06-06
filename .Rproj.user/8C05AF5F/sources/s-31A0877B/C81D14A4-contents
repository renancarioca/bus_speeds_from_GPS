# Define function to calculate average speeds in a link using GPS data
# Renan Carioca
# May 25th 2023

require(dplyr)
require(sf)
require(rgeos)

get_speeds_one_corridor <- function(link_, gps_data){

#### GPS DATA MUST BE A SPATIAL POINTS DATA FRAME OBJECT AND FOLLOW THE STRUCTURE BELOW:
## BUS_ID
## TIMESTAMP AS A YYYY-MM-DD HH:MM:SS
## LONG
## LAT

# format and adapt input --------------------------------------------------
    
  if(class(gps_data) != "SpatialPointsDataFrame"){
    
    message("REVIEW GPS FORMAT, GPS DATA MUST BE A DATA FRAME OBJECT AND FOLLOW THE STRUCTURE BELOW:\n
            # BUS_ID - a unique character variable to identify each bus\n
            # TIMESTAMP as a YYYY-MM-DD HH:MM:SS character\n
            # LONG - a numeric variable representing the lontigude\n
            # LAT - a numeric variable representing the latitude")
    
    return(NULL)
    
  }
  
# define checkpoints ------------------------------------------------------
  coords <- link_ %>% st_coordinates()
  p_init <- coords %>% head(1) %>% as.data.frame() %>%
    
    mutate(segment = link_$Name,
           point = 1) %>%
    
    st_as_sf(coords = c("X", "Y"), crs = 4326) 
  
  p_end <- coords %>% tail(1) %>% as.data.frame() %>%
    
    mutate(segment = link_$Name,
           point = 2) %>%
    
    st_as_sf(coords = c("X", "Y"), crs = 4326) 
  
  checkpoints <- rbind(p_init, p_end)
  
  buffer_checkpoints <- checkpoints %>% st_buffer(dist = 50)
  
  len_segment <- link_ %>% st_length() %>% as.numeric
  
  p1 <- buffer_checkpoints %>% filter(point == 1) %>% as("Spatial")
  p2 <- buffer_checkpoints %>% filter(point == 2) %>% as("Spatial")
  
  # criar buffer para o trecho e filtrar pontos -----------------------------
  buffer_segment <- st_buffer(link_, dist = 30, nQuadSegs = 90) %>% as("Spatial")
  
  GPS_segment <- gps_data[buffer_segment, ]
  
  proj <- gProject(spgeom = link_ %>% as("Spatial"),
                   sppoint = GPS_segment, normalized = T)*len_segment
  
  GPS_segment$projection <- proj
  
  # filtrar viagens com sentidos alinhados ----------------------------------
  GPS_segment_ <- GPS_segment %>% st_as_sf() %>%
    
    arrange(bus_id, timestamp) %>%
    
    group_by(bus_id) %>%
    
    mutate(delta_proj_before = projection - lag(projection),
           delta_time_before = (as.numeric(timestamp) - lag(as.numeric(timestamp)))/60,
           
           delta_proj_after = lead(projection) - (projection),
           delta_time_after = (lead(as.numeric(timestamp)) - (as.numeric(timestamp)))/60) %>%
    
    mutate(direction = case_when(delta_proj_before > 50 & delta_time_before <= 5 ~ 'OK',
                                 delta_proj_before < -50 & delta_time_before <= 5 ~ 'OPOSITE',
                                 delta_proj_after > 50 & delta_time_after <= 5 ~ 'OK',
                                 delta_proj_after < -50 & delta_time_after <= 5 ~ 'OPOSITE',
                                 1 == 1 ~ 'Indef')) %>%
    
    filter(direction == 'OK') %>%
    
    arrange(bus_id, timestamp) %>% 
    group_by(bus_id) %>% 
    mutate(delta_time_before = (as.numeric(timestamp) - lag(as.numeric(timestamp)))/60,
           trip_counter = case_when(is.na(delta_time_before) ~ 0,
                                    delta_time_before > 5 ~ 1,
                                    delta_time_before <= 5 ~ 0) %>% cumsum,
           
           trip_id = paste0(bus_id, '-', trip_counter)) %>% ungroup %>% as("Spatial")
  

  # processar instantes de passagem -----------------------------------------
  GPSL10_p1 <- GPS_segment_[p1, ]@data
  GPSL10_p2 <- GPS_segment_[p2, ]@data
  
  GPSL10_p1 <- GPSL10_p1 %>%
    
    arrange(bus_id, timestamp) %>% 
    
    group_by(bus_id, trip_id) %>%
    
    summarise(t_avg = median(timestamp)) %>%
    
    ungroup() %>% mutate(segment = link_$Name, point = 1)
  
  GPSL10_p2 <- GPSL10_p2 %>%
    
    arrange(bus_id, timestamp) %>% 
    
    group_by(bus_id, trip_id) %>%
    
    summarise(t_avg = median(timestamp)) %>%
    
    ungroup() %>% mutate(segment = link_$Name, point = 2)
  
  timestamp_passes <- rbind(GPSL10_p1, GPSL10_p2) %>%
    
    arrange(bus_id, trip_id, t_avg) %>%
    group_by(trip_id) %>%
    
    mutate(n_points = n()) %>% filter(n_points == 2) %>%
    
    select(bus_id, segment, trip_id, point, t_avg) %>%
    
    arrange(bus_id, segment, trip_id, t_avg)
  
  # calcular velocidades ----------------------------------------------------
  if(nrow(timestamp_passes) > 0){
    
    calc_vel <- timestamp_passes %>%
      
      tidyr::pivot_wider(names_from = point, values_from = t_avg) %>%
      
      rename(t_1 = 4, t_2 = 5) %>%
      
      mutate(delta_t = as.numeric(t_2) - as.numeric(t_1),
             len_segment = len_segment,
             
             vel_km.h = len_segment/delta_t*3.6)
    
    return(calc_vel)
    
  } else{return(NULL)}
  
}

get_speeds_network <- function(monitoring_network, gps_file_){
  
  #### GPS DATA MUST BE A SPATIAL POINTS DATA FRAME OBJECT AND FOLLOW THE STRUCTURE BELOW:
  ## BUS_ID
  ## TIMESTAMP AS A YYYY-MM-DD HH:MM:SS
  ## LONG
  ## LAT
  
  cat("READING ", gps_file_, '\n')
  
  gps_data_ <- readRDS(file = gps_file_)
  
  gps_data <- try(expr = gps_data_ %>% 
                     
                     mutate(bus_id = as.character(bus_id),
                            timestamp = lubridate::ymd_hms(timestamp)) %>% 
                     sf::st_as_sf(coords = c("long", "lat"), crs = 4326) %>% na.omit() %>% 
                     as("Spatial"), silent = T)
  
  if(class(gps_data) != "SpatialPointsDataFrame"){
    
    message("REVIEW GPS FORMAT, GPS DATA MUST BE A DATA FRAME OBJECT AND FOLLOW THE STRUCTURE BELOW:\n
            # BUS_ID - a unique character variable to identify each bus\n
            # TIMESTAMP as a YYYY-MM-DD HH:MM:SS character\n
            # LONG - a numeric variable representing the lontigude\n
            # LAT - a numeric variable representing the latitude")
    
    return(NULL)
    
  }
  
  df_speeds_links <- lapply(X = 1:nrow(monitoring_network), FUN = function(id_link){
    
    cat("READING ", gps_file_, " || GETTING SPEEDS FOR ", monitoring_network$Name[id_link], '\n')
    
    link_get <- monitoring_network[id_link, ]
    
    return(get_speeds_one_corridor(link_ = link_get, gps_data = gps_data))
    
  }) %>% plyr::ldply(data.frame)
  
  return(df_speeds_links)
  
}

# test 1 -----------------------------------------------------------------
# link_ <- st_read('0inputs/rede_monitoramento/Testes.kml') %>% st_zm()
# gps_data <- readRDS(file = '2outputs/0queriesGPS/0first_query.RDS') %>%
# 
#   rename(bus_id = ordem,
#          timestamp = datahora,
#          long = longitude,
#          lat = latitude) %>%
# 
#   select(bus_id, timestamp, long, lat) %>%
#   mutate(timestamp = as.POSIXct(x = as.numeric(timestamp)/1e3, origin = '1970-01-01') %>% as.character)
# 
# df_speeds_test <- get_speeds(link_ = link_, gps_data = gps_data)
# 
# saveRDS(object = df_speeds_test, file = '2outputs/1calculated_speeds/test01.RDS')

