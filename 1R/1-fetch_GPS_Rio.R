# Fetching data from Rio's bus GPS API for several days
# Renan Carioca
# May 25th 2023
rm(list = ls()); gc()

source('1R/helpers/fetch_data_GPS.R')

# 1. list days and times --------------------------------------------------
times <- c("06:00:00", # WILL FETCH FOR THE FOLLOWING HOUR, THAT IS 06:00:00 - 07:00:00
           "07:00:00",
           "08:00:00",
           
           "16:00:00",
           "17:00:00",
           "18:00:00")

dates <- paste0('2023-04-0', 3:7)

grid_ <- expand.grid(dates, times)

# 2. fetch data for the listed periods ------------------------------------
lapply(X = 1:nrow(grid_), FUN = function(x){
  
  cat(x, ' / ', nrow(grid_), '\n')
  
  date_ = grid_$Var1[x] %>% as.character()
  time1 = grid_$Var2[x] %>% as.character()
  time2 = ((time1 %>% hms::as_hms()) + hms::as_hms("01:00:00")) %>% hms::as_hms()
  
  date_ini_ <- paste0(date_, ' ', time1)
  date_end_ <- paste0(date_, ' ', time2)
  
  get_GPS(date_ini = date_ini_, date_end = date_end_)
  
  gc()
  
})
