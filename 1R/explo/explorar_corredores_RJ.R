# 
# 
# 
rm(list = ls()); gc()

require(dplyr)
require(sf)
require(tidyr)

# # 1. input ----------------------------------------------------------------
shapes_ <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/shapes.txt')
stop_times <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/stop_times.txt')
frequencies_ <- read.csv('0inputs/gtfs_rio-de-janeiro/frequencies.txt')

routes <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/routes.txt')

agencies <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/agency.txt')
fare_rules <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/fare_rules.txt')

routes <- routes %>% left_join(y = fare_rules, by = 'route_id')

trips <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/trips.txt')

services <- read.csv(file = '0inputs/gtfs_rio-de-janeiro/calendar.txt')

trip_2_agency <- trips %>% select(route_id, trip_id) %>% left_join(y = routes %>% select(route_id, agency_id))

tripsconsider <- trips %>% filter(service_id %in% c("U")) %>% select(trip_id) %>% unlist() %>% as.character

# # 2. create unified shape -------------------------------------------------
unif_shape <- cbind(shapes_ %>% head(-1),
                    shapes_ %>% tail(-1)) %>%
  
  rename(shape_id1 = 1,
         shape_pt_lat1 = 3,
         shape_pt_lon1 = 4,
         shape_pt_sequence1 = 2,
         shape_dist_traveled1 = 5,
         
         shape_id2 = 6,
         shape_pt_lat2 = 8,
         shape_pt_lon2 = 9,
         shape_pt_sequence2 = 7,
         shape_dist_traveled2 = 10) %>%
  
  filter(shape_id1 == shape_id2,
         shape_pt_sequence2 == shape_pt_sequence1 + 1) %>%
  
  select(shape_id = shape_id1,
         shape_pt_lon1,
         shape_pt_lat1,
         
         shape_pt_lon2,
         shape_pt_lat2) %>%
  
  mutate(idx = paste0(shape_pt_lon1, "_", shape_pt_lat1, "_",
                      shape_pt_lon2, "_", shape_pt_lat2))


# 3. get peak frequency ---------------------------------------------------
frequencies <- frequencies_ %>%
  
  mutate(start_time = case_when(start_time >= "24:00:00" ~ "00:00:00",
                                1 == 1 ~ start_time),
         end_time = case_when(end_time >= "24:00:00" ~ "23:59:59",
                              1 == 1 ~ end_time))

depart_times <- lapply(X = 1:nrow(frequencies), FUN = function(x){
  
  cat(x, '\n')
  
  departs <- seq(frequencies$start_time[x] %>% hms::as_hms() %>% as.numeric(),
                 frequencies$end_time[x] %>% hms::as_hms() %>% as.numeric(),
                 frequencies$headway_secs[x]) %>% hms::as_hms()
  
  df_ <- data.frame(trip_id = frequencies$trip_id[x]) %>% cbind(departs)
  
  return(df_)
  
}) %>% plyr::ldply(data.frame)

# 
trips.hour_route <- depart_times %>%
  
  filter(trip_id %in% tripsconsider) %>%
  
  left_join(y = trip_2_agency, by = 'trip_id') %>%
  
  mutate(hour = substr(departs, 1, 2),
         direction_id = trip_id %>% substr(12, 12)) %>%
  
  # filter(hour == "06") %>%
  
  group_by(trip_id, agency_id, route_id, direction_id, hour) %>%
  summarise(trips = n()) %>% ungroup() %>%
  
  left_join(y = trips %>% select(trip_id, shape_id),
            by = c("trip_id"))

# WHAT IS THE PEAK HOUR?
peak.hour <- trips.hour_route %>%
  
  group_by(hour) %>%
  summarise(qtd = sum(trips)) %>% ungroup()

# 07

trip_freq_peakhour <- trips.hour_route %>%
  
  filter(hour == "07") %>%
  
  mutate(route_id_ = paste0(route_id, "-", direction_id)) %>%
  
  group_by(route_id, shape_id) %>%
  summarise(trips = sum(trips)) %>% ungroup()

trips.link <- unif_shape %>%
  
  # mutate(shape_id = shape_id %>% substr(3, 13))# %>%
  # left_join(y = trips.hour_route,
  left_join(y = trip_freq_peakhour,
            by = c("shape_id")) %>% na.omit() %>%
  
  select(idx, trips) %>%
  
  # mutate(link_idx = 1:n()) %>%
  
  group_by(idx) %>%
  
  summarise(trips_ = sum(trips, na.rm = 1)) %>% ungroup() %>%
  
  separate(col = "idx", into = c("long1", "lat1", "long2", "lat2"), sep = "_", remove = T) %>%
  
  mutate(link_idx = 1:n()) %>%
  select(link_idx, long1, lat1, long2, lat2, trips_)

# trips.link_aux <- trips.link %>% select(link_idx, trips_)
trips.link_coords <- trips.link %>% select(-trips_)

# library(sf)
ls0 <- lapply(X = 1:nrow(trips.link_coords), function(x){
  
  v <- as.numeric(trips.link_coords[x, c(2,3,4,5)])
  m <- matrix(v, nrow = 2, byrow = T)
  
  # mapview::mapview(st_sfc(st_linestring(m), crs = 4326))
  return(st_sfc(st_linestring(m), crs = 4326))
  # return(st_linestring(m))
  
})

# ls = st_multilinestring(x = ls0)

ls = do.call(c, ls0)

ls <- st_as_sf(x = ls) %>% rename(geometry = 1)

ls$link_idx = trips.link$link_idx
ls$trips = trips.link$trips_
# ls$agency_id = trips.link$agency_id

saveRDS(object = ls, file = '1R/explo/SPPO_RJ_volumes.RDS')

# 4. make test gif --------------------------------------------------------
require(ggplot2)
require(ggmap)
require(devtools)
require(osmdata)

purple1 <- '#323372'
purple2 <- '#8280ae'
purple3 <- '#afb6db'

green1 <- '#65b641'
green2 <- '#a3d87f'
green3 <- '#e6f6ca'

orange1 <- '#ff2a06'
orange2 <- '#f38858'
orange3 <- '#f2dcc3'

gtfs_freqs <- readRDS(file = '1R/explo/SPPO_RJ_volumes.RDS')

bbox_gtfs <- sf::st_bbox(gtfs_freqs)
bbox_gtfs <- matrix(data = as.numeric(bbox_gtfs), ncol = 2, byrow = T)

# Transform nc to EPSG 3857 (Pseudo-Mercator, what Google uses)
gtfs_freqs_3857 <- st_transform(gtfs_freqs, 3857)

# map <- get_map(getbb("Rio de Janeiro, RJ, Brazil"), maptype = "terrain", source = "osm")
map <- get_map(getbb("Rio de Janeiro, RJ, Brazil"), maptype = "toner-lines", source = "stamen")

# Define a function to fix the bbox to be in EPSG:3857
ggmap_bbox <- function(map) {
  if (!inherits(map, "ggmap")) stop("map must be a ggmap object")
  # Extract the bounding box (in lat/lon) from the ggmap to a numeric vector, 
  # and set the names to what sf::st_bbox expects:
  map_bbox <- setNames(unlist(attr(map, "bb")), 
                       c("ymin", "xmin", "ymax", "xmax"))
  
  # Coonvert the bbox to an sf polygon, transform it to 3857, 
  # and convert back to a bbox (convoluted, but it works)
  bbox_3857 <- st_bbox(st_transform(st_as_sfc(st_bbox(map_bbox, crs = 4326)), 3857))
  
  # Overwrite the bbox of the ggmap object with the transformed coordinates 
  attr(map, "bb")$ll.lat <- bbox_3857["ymin"]
  attr(map, "bb")$ll.lon <- bbox_3857["xmin"]
  attr(map, "bb")$ur.lat <- bbox_3857["ymax"]
  attr(map, "bb")$ur.lon <- bbox_3857["xmax"]
  map
}

# Use the function:
map <- ggmap_bbox(map)

# p <- ggmap(map) + 
#   coord_sf(crs = st_crs(3857)) + # force the ggplot2 map to be in 3857
#   geom_sf(data = gtfs_freqs_3857 %>% filter(trips > 30), inherit.aes = FALSE)

# seq_freqs <- c(1, seq(10, 1000, 20)) %>% as.numeric %>% sort
seq_freqs <- c(1, seq(5, 300, 5))
# seq_freqs <- c(1, seq(5, 200, 10))

unlink(x = list.files(path = '1R/explo/gif/imgs_gif/', pattern = '*.png', full.names = T))

for(i in length(seq_freqs):1){
  
  idx_real <- paste0('000', i) %>% stringr::str_sub(-3, -1)
  
  cat(i, '//', length(seq_freqs), '\n')
  
  if(seq_freqs[i] == 1){
    
    p <- ggmap(map) + 
      coord_sf(crs = st_crs(3857)) + # force the ggplot2 map to be in 3857
      geom_sf(data = gtfs_freqs_3857 %>% filter(trips > seq_freqs[i]),
              # mapping = aes(col = agency_id),
              mapping = aes(size = trips),
              col = orange1,
              # lwd = 0.5,
              inherit.aes = FALSE) +
      
      ylab("") + xlab("") +
      
      scale_size_continuous(range = c(0.05, 1)) +
      
      guides(size = 'none') +
      
      labs(caption = 'Using GTFS data published in April/2023',
           title = paste0("Bus network in Rio de Janeiro / SPPO"),
           subtitle = paste0("Streets with at least ", seq_freqs[i], " bus from 7AM to 8AM")) +
      
      theme(text = element_text(size = 11, family = 'Hero New'),
            title = element_text(size = 11, family = 'Hero New'),
            # plot.title = element_textbox_simple(),
            
            plot.subtitle = element_text(size = 9, family = 'Hero New'),
            legend.key = element_rect(fill = NA),
            
            axis.ticks = element_blank(),
            legend.text = element_text(size = 7, family = 'Hero New Light'),
            axis.text.y = element_blank(),
            axis.text.x = element_blank(),
            panel.background = element_rect(fill = 'white', colour = NA),
            panel.grid.minor.y = element_blank(),
            panel.grid.major.x = element_line(size = 0.25),
            panel.grid.major.y = element_line(size = 0.25),
            panel.grid.minor.x = element_blank(),
            # legend.
            # legend.title = element_text(size = 0),
            legend.position = 'top',
            strip.text = element_text(size = 7, family = 'Hero New Light'),
            strip.background = element_rect(fill = 'white', colour = NA))
    
  } else{
    
    p <- ggmap(map) + 
      coord_sf(crs = st_crs(3857)) + # force the ggplot2 map to be in 3857
      geom_sf(data = gtfs_freqs_3857 %>% filter(trips > seq_freqs[i]),
              # mapping = aes(col = agency_id),
              mapping = aes(size = trips),
              col = orange1,
              # lwd = 0.5,
              inherit.aes = FALSE) +
      
      scale_size_continuous(range = c(0.05, 1)) +
      
      ylab("") + xlab("") +
      
      labs(caption = 'Using GTFS data published in April/2023',
           title = paste0("Bus network in Rio de Janeiro / SPPO"),
           subtitle = paste0("Streets with at least ", seq_freqs[i], " buses from 7AM to 8AM")) +
      
      guides(size = 'none') +
      
      theme(text = element_text(size = 11, family = 'Hero New'),
            title = element_text(size = 11, family = 'Hero New'),
            # plot.title = element_textbox_simple(),
            
            plot.subtitle = element_text(size = 9, family = 'Hero New'),
            legend.key = element_rect(fill = NA),
            
            axis.ticks = element_blank(),
            legend.text = element_text(size = 7, family = 'Hero New Light'),
            axis.text.y = element_blank(),
            axis.text.x = element_blank(),
            panel.background = element_rect(fill = 'white', colour = NA),
            panel.grid.minor.y = element_blank(),
            panel.grid.major.x = element_line(size = 0.25),
            panel.grid.major.y = element_line(size = 0.25),
            panel.grid.minor.x = element_blank(),
            # legend.
            # legend.title = element_text(size = 0),
            legend.position = 'top',
            strip.text = element_text(size = 7, family = 'Hero New Light'),
            strip.background = element_rect(fill = 'white', colour = NA))
    
  }
  
  ggsave(filename = paste0('1R/explo/gif/imgs_gif/', idx_real, '.png'),
         plot = p, dpi = 120, height = 4, width = 6)
  
}

require(magick)

imgs <- list.files('1R/explo/gif/imgs_gif/', full.names = TRUE) %>% sort(decreasing = T)
img_list <- lapply(c(rep(first(imgs), 5),
                     imgs,
                     rep(last(imgs), 5)), image_read)

img_joined <- image_join(img_list)

img_animated <- image_animate(img_joined, fps = 5)

image_write(image = img_animated,
            path = "rio.gif")

# 5. save shapefile -------------------------------------------------------
gtfs_freqs <- readRDS(file = '1R/explo/SPPO_RJ_volumes.RDS')

require(sf)
st_write(obj = gtfs_freqs, dsn = '1R/explo/', layer = 'shp_Rio', driver = "ESRI Shapefile")
