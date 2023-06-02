# Calculate speeds using the segments and GPS data in the inputs folder
# Renan Carioca
# May 29th 2023
rm(list = ls()); gc()

source('1R/helpers/get_speeds_link.R')

# 1. monitoring network ---------------------------------------------------
monitoring_network <- st_read('0inputs/rede_monitoramento/Testes.kml') %>% st_zm

# 2. gps data list --------------------------------------------------------
file_list <- list.files(path = '2outputs/0queriesGPS/', pattern = '*.RDS', full.names = T)

df_speeds <- lapply(X = file_list, FUN = function(gps_file_){

  return(get_speeds_network(monitoring_network = monitoring_network, gps_file_ = gps_file_))

}) %>% plyr::ldply(data.frame)

saveRDS(object = df_speeds, file = '2outputs/df_speeds_per_pass.RDS')

# z. archive - previous tests ---------------------------------------------
# TEST 1 - PER FILE PER LINK
# df_speeds <- lapply(X = file_list, FUN = function(gps_file_){
#   
#   gps_data_ <- readRDS(file = gps_file_)
#   
#   df_speeds_links <- lapply(X = 1:nrow(monitoring_network), FUN = function(id_link){
#     
#     cat("READING ", gps_file_, ", GETTING SPEEDS FOR ", monitoring_network$Name[id_link], '\n')
#     
#     link_get <- monitoring_network[id_link, ]
#     
#     return(get_speeds(link_ = link_get, gps_data = gps_data_))
#     
#   }) %>% plyr::ldply(data.frame)
#   
# }) %>% plyr::ldply(data.frame)
# 
# # TEST 2 - FULL DATA PER LINK
# gps_data_full <- lapply(X = file_list, FUN = readRDS) %>% plyr::ldply(data.frame)
# 
# tictoc::tic()
# df_speeds_links_full <- lapply(X = 1:nrow(monitoring_network), FUN = function(id_link){
#   
#   cat("GETTING SPEEDS FOR ", monitoring_network$Name[id_link], '\n')
#   
#   link_get <- monitoring_network[id_link, ]
#   
#   return(get_speeds(link_ = link_get, gps_data = gps_data_full))
#   
# }) %>% plyr::ldply(data.frame)
# tictoc::toc()


