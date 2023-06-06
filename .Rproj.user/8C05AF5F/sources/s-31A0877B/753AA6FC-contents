# Organize outputs and plot graphs
# Renan Carioca
# May 29th 2023
rm(list = ls()); gc()

require(dplyr)
require(ggplot2)
require(ggmap)
require(tidyr)

source('1R/helpers/setupgraficos.R')

monitoring_network <- st_read('0inputs/rede_monitoramento/Testes.kml') %>% st_zm

# 0. aux function - ggplot ready made graphs ------------------------------
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

plot_graphs <- function(df_speeds_median){
  
  coords <- monitoring_network %>% st_coordinates()
  long_ <- median(coords[,1])
  lat_  <- median(coords[,2])
  
  tol <- range(coords[,2]) %>% diff
  
  ph_basemap <- get_stamenmap(bbox = c(left = min(coords[,1]) - tol,
                                       bottom = min(coords[,2]) - tol,
                                       right = max(coords[,1]) + tol,
                                       top = max(coords[,2]) + tol),
                              zoom = 16,
                              maptype = "terrain",
                              # maptype = "toner-lines",
                              crop = TRUE, force = TRUE)
  
  map <- ggmap_bbox(ph_basemap)
  
  list_graphs <- expand.grid(weekday = df_speeds_median$weekday %>% unique,
                             month = df_speeds_median$month %>% unique,
                             period = df_speeds_median$period %>% unique)
  
  lapply(X = 1:nrow(list_graphs), FUN = function(x){
    
    specs <- list_graphs[x, ]
    
    df_speeds_median_specs <- df_speeds_median %>% 
      
      filter(weekday == specs$weekday,
             month == specs$month,
             period == specs$period)
    
    df_speeds_median_specs_link <- monitoring_network %>% 
      
      left_join(y = df_speeds_median_specs, by = c("Name" = "segment")) %>% 
      
      mutate(categ.speed = cut(x = q50,
                               breaks = c(0, 5, 10, 12.5, 15, 17.5, 20, 30, Inf),
                               labels = c(
                                 "> 30",
                                 "20 - 30", 
                                 "17.5 - 20", 
                                 "15 - 17.5",
                                 "12.5 - 15",
                                 "10 - 12.5",
                                 "5 - 10",
                                 "< 5") %>% rev))
    
    p <- ggmap(map) +
      
      # CONJUNTO DE DADOS
      ## SE O GRAFICO USAR UM SO CONJUNTO DE DADOS (OU MAJORITARIAMENT),
      ## PODE SER MELHOR DEFINI-LO AQUI NA ENTRADA E NAO EM CADA LINHA
      # ggplot() +
      
      ## ELEMENTOS GRAFICOS
      geom_sf(data = df_speeds_median_specs_link %>% 
                
                sf::st_transform(crs = st_crs(3857)),
              
              mapping = aes(fill = categ.speed,
                            colour = categ.speed), lwd = 1.10, inherit.aes = F) +
      
      ## FACET, SE NECESSARIO. SUGESTAO DE DEIXAR SEMPRE FREE E AJUSTAR A ESCALA NAS FUNCOES SCALE_
      ## QUANDO UM EIXO E' DEFINIDO COMO "FREE", ELE GANHA VALORES DE ESCALA E AJUDA NA LEGIBILIDADE.
      # facet_wrap(period ~ ., ncol = 2) +
      
      ## EIXOS
      ## AJUSTAR LIMITES DA ESCALA AQUI, CASO NECESSARIO FIXAR UMA ESCALA UNICA PARA OS EIXOS
      
      ## TITULO, SUBTITULO
      labs(title = paste0("Bus speeds on a ", specs$weekday[1], " from ", specs$period[1], ", ", specs$month[1]),
           subtitle = "") +
      # subtitle = "Datos (en km/h) para diferentes corredores un periodo durante la pandemia",
      # caption = 'Fuente: elaboración propia utilizando datos fornecidos por la gestión del sistema.') +
      
      ## NOME DOS EIXOS. EVITAR O EIXO Y NA VERTICAL
      ylab("") + xlab("") +
      
    #   "> 30",
    # "20 - 30", 
    # "17.5 - 20", 
    # "15 - 17.5",
    # "12.5 - 15",
    # "10 - 12.5",
    # "5 - 10",
    # "< 5"
      
      ## CONFIGURACOES DE LEGENDA
      scale_fill_manual(values = c("> 30" = grad_color_8,
                                   "20 - 30" = grad_color_7,
                                   "17.5 - 20" = grad_color_6,
                                   "15 - 17.5" = grad_color_5,
                                   "12.5 - 15" = grad_color_4,
                                   "10 - 12.5" = grad_color_3,
                                   "5 - 10" = grad_color_2,
                                   "< 5" = grad_color_1)) +
      
      scale_colour_manual(values = c("> 30" = grad_color_8,
                                     "20 - 30" = grad_color_7,
                                     "17.5 - 20" = grad_color_6,
                                     "15 - 17.5" = grad_color_5,
                                     "12.5 - 15" = grad_color_4,
                                     "10 - 12.5" = grad_color_3,
                                     "5 - 10" = grad_color_2,
                                     "< 5" = grad_color_1)) +
      
      guides(colour = guide_legend('Average speed (km/h)'),
             fill = guide_legend('Average speed (km/h)')) +
      
      ## CONFIGURACOES GERAIS
      theme(text = element_text(size = 10, family = 'Hero New', colour = color_fuente),
            title = element_text(size = 15, family = 'Hero New', colour = color_fuente),
            # plot.title = element_textbox_simple(),
            
            plot.subtitle = element_text(size = 10, family = 'Hero New', colour = color_fuente),
            legend.key = element_rect(fill = NA),
            
            axis.ticks = element_blank(),
            legend.text = element_text(size = 10, family = 'Hero New Light'),
            axis.text.y = element_blank(),
            axis.text.x = element_blank(),
            panel.background = element_rect(fill = 'white', colour = NA),
            panel.grid.minor.y = element_blank(),
            panel.grid.major.x = element_line(colour = color_lineas_eje, size = 0.25),
            panel.grid.major.y = element_line(colour = color_lineas_eje, size = 0.25),
            panel.grid.minor.x = element_blank(),
            # legend.
            # legend.title = element_text(size = 0),
            legend.position = 'top',
            strip.text = element_text(size = 10, family = 'Hero New Light', colour = color_fuente),
            strip.background = element_rect(fill = 'white', colour = NA))
    
    ggsave(p, filename = paste0('2outputs/2plotted speed maps/', specs$month[1], "_", specs$weekday, "_", specs$period, '.pdf'),
           device = cairo_pdf, dpi = 300,
           height = 8, width = 12,
           units = 'in')
    
    ggsave(p, filename = paste0('2outputs/2plotted speed maps/', specs$month[1], "_", specs$weekday, "_", specs$period, '.png'),
           device = png, dpi = 300,
           height = 8, width = 12,
           units = 'in')
    
  })
  
}

# 1. read and adjust speeds data frame ------------------------------------
df_speeds <- readRDS(file = '2outputs/df_speeds_per_pass.RDS') %>%
  
  mutate(hour  = substr(t_1, 12, 13) %>% as.numeric,
         date  = substr(t_1, 1, 10),
         month = substr(t_1, 1, 7))

df_speeds_summary <- df_speeds %>% 
  
  mutate(weekday = weekdays(as.Date(date)),
         weekday = case_when(weekday %in% c("Saturday", "Sunday") ~ weekday,
                             1 == 1 ~ "Weekday"),
         period = case_when(hour %in% 6:8 ~ '6AM-9AM',
                            hour %in% 9:15 ~ '9AM-4PM',
                            hour %in% 16:18 ~ '4PM-7PM',
                            1 == 1 ~ '7PM-6AM') %>% factor(levels = c("6AM-9AM",
                                                                      "9AM-4PM",
                                                                      "4PM-7PM",
                                                                      "7PM-6AM"))) %>% 
  
  group_by(weekday, date, segment, period, hour) %>% 
  
  summarise(n_passes_identified = n(),
            q50 = quantile(vel_km.h, 0.5, na.rm = 1),
            
            q25 = quantile(vel_km.h, 0.25, na.rm = 1),
            q75 = quantile(vel_km.h, 0.75, na.rm = 1),
            
            q10 = quantile(vel_km.h, 0.10, na.rm = 1),
            q90 = quantile(vel_km.h, 0.90, na.rm = 1)) %>% ungroup

write.csv2(x = df_speeds_summary, file = '2outputs/speeds_summary.csv', row.names = F)

df_speeds_median <- df_speeds %>% 
  
  mutate(weekday = weekdays(as.Date(date)),
         weekday = case_when(weekday %in% c("Saturday", "Sunday") ~ weekday,
                             1 == 1 ~ "Weekday"),
         period = case_when(hour %in% 6:8 ~ '6AM-9AM',
                            hour %in% 9:15 ~ '9AM-4PM',
                            hour %in% 16:18 ~ '4PM-7PM',
                            1 == 1 ~ '7PM-6AM') %>% factor(levels = c("6AM-9AM",
                                                                      "9AM-4PM",
                                                                      "4PM-7PM",
                                                                      "7PM-6AM"))) %>% 
  
  group_by(weekday, month, segment, period) %>% 
  
  summarise(q50 = quantile(vel_km.h, 0.5, na.rm = 1),
            
            q25 = quantile(vel_km.h, 0.25, na.rm = 1),
            q75 = quantile(vel_km.h, 0.75, na.rm = 1),
            
            q10 = quantile(vel_km.h, 0.10, na.rm = 1),
            q90 = quantile(vel_km.h, 0.90, na.rm = 1)) %>% ungroup

# 2. plot graphs ----------------------------------------------------------
plot_graphs(df_speeds_median = df_speeds_median)

