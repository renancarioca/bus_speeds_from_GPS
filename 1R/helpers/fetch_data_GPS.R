# Define function to fetch data from Rio's bus GPS API for one hour
# Renan Carioca
# May 25th 2023

# API DOCUMENTATION
# https://www.data.rio/documents/transporte-rodoviário-api-de-gps-dos-ônibus-sppo-beta

require(data.table)
require(dplyr)
require(jsonlite)
require(sf)

get_GPS <- function(date_ini, date_end){
  
  # date_ini <- '2023-01-23 06:00:00'
  # date_end <- '2023-01-23 07:00:00'
  
  date_ini <- date_ini %>% gsub(pattern = " ", replacement = "+")
  date_end <- date_end %>% gsub(pattern = " ", replacement = "+")
  
  # https://dados.mobilidade.rio/gps/sppo?dataInicial=AAAA-MM-DD+HH:MM:SS&dataFinal=AAAA-MM-DD+HH:MM:SS
  
  query_ <- paste0("https://dados.mobilidade.rio/gps/sppo?dataInicial=", date_ini, "&dataFinal=", date_end)
  
  output_API <- try(expr = httr::GET(query_) %>%
                      
                      httr::content('text') %>%
                      jsonlite::fromJSON() %>%
                      mutate(latitude = latitude %>% gsub(pattern = ",", replacement = "."),
                             longitude = longitude %>% gsub(pattern = ",", replacement = ".")) %>% 
                      
                      rename(bus_id = ordem,
                             timestamp = datahora,
                             long = longitude,
                             lat = latitude) %>%
                      
                      select(bus_id, timestamp, long, lat) %>%
                      mutate(timestamp = as.POSIXct(x = as.numeric(timestamp)/1e3, origin = '1970-01-01')))
                    #%>%
                      # st_as_sf(coords = c("long", "lat"), crs = 4326) %>% as("Spatial"), silent = T)
  
  if(class(output_API) == "data.frame"){
    
    date_ini <- date_ini %>% gsub(pattern = ":", replacement = "-") %>% gsub(pattern = "\\+", replacement = "_")
    date_end <- date_end %>% gsub(pattern = ":", replacement = "-") %>% gsub(pattern = "\\+", replacement = "_")
    
    saveRDS(object = output_API, file = paste0('2outputs/0queriesGPS/', date_ini, 'T', date_end, '.RDS'))
    
  } else{return(NULL)}
  
}

# test <- get_GPS(data_ini = '2023-04-23 06:00:00',
#                  data_fim = '2023-04-23 07:00:00')
# 
# saveRDS(object = teste, file = '2outputs/0first_query')
