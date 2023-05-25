# Codigo auxiliar - estimar velocidades operacionais para um corredor
# Renan Carioca
# 25 de maio de 2023

require(dplyr)
require(sf)
require(rgeos)

get_velocidades <- function(link_, bd_gps_){
  
  # definir pontos de controle ----------------------------------------------
  coords <- link_ %>% st_coordinates()
  p_init <- coords %>% head(1) %>% as.data.frame() %>%
    
    mutate(trecho = link_$Name,
           ponto = 1) %>%
    
    st_as_sf(coords = c("X", "Y"), crs = 4326) 
  
  p_fim  <- coords %>% tail(1) %>% as.data.frame() %>%
    
    mutate(trecho = link_$Name,
           ponto = 2) %>%
    
    st_as_sf(coords = c("X", "Y"), crs = 4326) 
  
  pontos_controle <- rbind(p_init, p_fim)
  
  buffer_pontos <- pontos_controle %>% st_buffer(dist = 50)
  
  compri_trecho <- link_ %>% st_length() %>% as.numeric
  
  p1 <- buffer_pontos %>% filter(ponto == 1) %>% as("Spatial")
  p2 <- buffer_pontos %>% filter(ponto == 2) %>% as("Spatial")
  
  # criar buffer para o trecho e filtrar pontos -----------------------------
  buffer_trecho <- st_buffer(link_, dist = 30, nQuadSegs = 90) %>% as("Spatial")
  
  GPS_trecho <- bd_gps_[buffer_trecho, ]
  
  proj <- gProject(spgeom = link_ %>% as("Spatial"),
                   sppoint = GPS_trecho, normalized = T)*compri_trecho
  
  GPS_trecho$projecao <- proj
  GPS_trecho$datahora <- (as.numeric(GPS_trecho$datahora)/1e3) %>% as.POSIXct(origin = '1970-01-01')
  
  # filtrar viagens com sentidos alinhados ----------------------------------
  GPS_trecho_ <- GPS_trecho %>% st_as_sf() %>%
    
    arrange(ordem, datahora) %>%
    
    group_by(ordem) %>%
    
    mutate(delta_proj_before = projecao - lag(projecao),
           delta_time_before = (as.numeric(datahora) - lag(as.numeric(datahora)))/60,
           
           delta_proj_after = lead(projecao) - (projecao),
           delta_time_after = (lead(as.numeric(datahora)) - (as.numeric(datahora)))/60) %>%
    
    mutate(direction = case_when(delta_proj_before > 50 & delta_time_before <= 5 ~ 'OK',
                                 delta_proj_before < -50 & delta_time_before <= 5 ~ 'OPOSTO',
                                 delta_proj_after > 50 & delta_time_after <= 5 ~ 'OK',
                                 delta_proj_after < -50 & delta_time_after <= 5 ~ 'OPOSTO',
                                 1 == 1 ~ 'Indef')) %>%
    
    filter(direction == 'OK') %>%
    
    arrange(ordem, datahora) %>% 
    group_by(ordem) %>% 
    mutate(delta_time_before = (as.numeric(datahora) - lag(as.numeric(datahora)))/60,
           trip_counter = case_when(is.na(delta_time_before) ~ 0,
                                    delta_time_before > 5 ~ 1,
                                    delta_time_before <= 5 ~ 0) %>% cumsum,
           
           trip_id = paste0(ordem, '-', trip_counter)) %>% ungroup %>% as("Spatial")
  

  # processar instantes de passagem -----------------------------------------
  GPSL10_p1 <- GPS_trecho_[p1, ]@data
  GPSL10_p2 <- GPS_trecho_[p2, ]@data
  
  GPSL10_p1 <- GPSL10_p1 %>%
    
    arrange(ordem, datahora) %>% 
    
    group_by(ordem, trip_id) %>%
    
    summarise(t_avg = median(datahora)) %>%
    
    ungroup() %>% mutate(trecho = link_$Name, ponto = 1)
  
  GPSL10_p2 <- GPSL10_p2 %>%
    
    arrange(ordem, datahora) %>% 
    
    group_by(ordem, trip_id) %>%
    
    summarise(t_avg = median(datahora)) %>%
    
    ungroup() %>% mutate(trecho = link_$Name, ponto = 2)
  
  instantes_passagem <- rbind(GPSL10_p1, GPSL10_p2) %>%
    
    arrange(ordem, trip_id, t_avg) %>%
    group_by(trip_id) %>%
    
    mutate(qtd_pontos = n()) %>% filter(qtd_pontos == 2) %>%
    
    select(ordem, trecho, trip_id, ponto, t_avg) %>%
    
    arrange(ordem, trecho, trip_id, t_avg)
  
  # calcular velocidades ----------------------------------------------------
  if(nrow(instantes_passagem) > 0){
    
    calc_vel <- instantes_passagem %>%
      
      tidyr::pivot_wider(names_from = ponto, values_from = t_avg) %>%
      
      rename(t_1 = 4, t_2 = 5) %>%
      
      mutate(delta_t = as.numeric(t_2) - as.numeric(t_1),
             compri_trecho = compri_trecho,
             
             vel_km.h = compri_trecho/delta_t*3.6)
    
    return(calc_vel)
    
  } else{return(NULL)}
  
}

# teste 1 -----------------------------------------------------------------
# rede_monitoramento <- st_read('0inputs/rede_monitoramento/Testes.kml') %>% st_zm()
# bd_gps <- readRDS(file = '2outputs/0primeiroteste_query.RDS')
# 
# bd_gps_ <- bd_gps %>% st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>% as("Spatial")
# 
# df_velocs_teste <- get_velocidades(link_ = rede_monitoramento[1, ], bd_gps_ = bd_gps_)
# 
# saveRDS(object = df_velocs_teste, file = '2outputs/1calculo_velocidades/teste01.RDS')

