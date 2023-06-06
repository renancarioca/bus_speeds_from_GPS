# 
# 
# 
rm(list = ls()); gc()

RDS_list <- list.files(path = '2outputs/0queriesGPS/', pattern = "*.RDS", full.names = T)

convert_RDS <- function(RDS_file){
  
  name <- RDS_file %>% strsplit(split = '//') %>% unlist %>% last %>% gsub(pattern = '.RDS', replacement = '')
  
  bd_ <- readRDS(file = RDS_file)
  
  write.table(x = bd_, file = paste0('0inputs/GPS_data/', name, '.csv'), row.names = F, sep = ';', dec = '.')
  
}

lapply(X = RDS_list, FUN = convert_RDS)

# TEST READING
# test_1 <- data.table::fread(input = '0inputs/GPS_data/2023-04-03_06-00-00T2023-04-03_07-00-00.csv', nrows = 10, sep = col_separator, dec = dec_separator)
