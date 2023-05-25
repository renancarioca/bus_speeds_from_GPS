# Codigo auxiliar - ler dados de GPS do SPPO do Rio a partir da API 
# Renan Carioca
# 25 de maio de 2023

# DOCUMENTACAO
# https://www.data.rio/documents/transporte-rodoviário-api-de-gps-dos-ônibus-sppo-beta

require(data.table)
require(dplyr)
require(jsonlite)
require(sf)

get_GPS <- function(data_ini, data_fim){
  
  # data_ini <- '2023-01-23 06:00:00'
  # data_fim <- '2023-01-23 07:00:00'
  
  data_ini <- data_ini %>% gsub(pattern = " ", replacement = "+", x = data_ini)
  data_fim <- data_fim %>% gsub(pattern = " ", replacement = "+", x = data_fim)
  
  # https://dados.mobilidade.rio/gps/sppo?dataInicial=AAAA-MM-DD+HH:MM:SS&dataFinal=AAAA-MM-DD+HH:MM:SS
  # https://dados.mobilidade.rio/gps/sppo?dataInicial=2023-01-01+06:00:00&dataFinal=2023-01-01+07:00:00
  
  query_ <- paste0("https://dados.mobilidade.rio/gps/sppo?dataInicial=", data_ini,"&dataFinal=", data_fim)
  
  output_API <- try(expr = httr::GET(query_) %>%
                      
                      httr::content('text') %>%
                      jsonlite::fromJSON() %>%
                      mutate(latitude = latitude %>% gsub(pattern = ",", replacement = "."),
                             longitude = longitude %>% gsub(pattern = ",", replacement = ".")), silent = T)
  
  # nao adicionar esse processo agora, esperar o bloco de arquivos total
  # st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

  if(class(output_API) == "data.frame"){
    
    return(output_API)
    
  } else{return(NULL)}
  
}

# teste <- get_GPS(data_ini = '2023-04-23 06:00:00',
#                  data_fim = '2023-04-23 07:00:00')
# 
# saveRDS(object = teste, file = '2outputs/0primeiroteste_query.RDS')
