# Calculate speeds using the segments and GPS data in the inputs folder
# Renan Carioca
# May 29th 2023
rm(list = ls()); gc()

source('1R/0-code_setup.R')
source('1R/helpers/get_speeds_link.R')

# 1. monitoring network ---------------------------------------------------
monitoring_network <- st_read(monitoring_network_kml_file) %>% st_zm

# 2. gps data list --------------------------------------------------------
file_list <- list.files(path = GPS_folder_path, pattern = c('*.csv'), full.names = T)

df_speeds <- lapply(X = file_list, FUN = function(gps_file_){

  return(get_speeds_network(monitoring_network = monitoring_network, gps_file_ = gps_file_))

}) %>% plyr::ldply(data.frame)

saveRDS(object = df_speeds, file = '2outputs/df_speeds_per_pass.RDS')

