# Incluir a tabela toda de UDH no popup
# Incluir tabela de UDH
# Criar camada só com as UDH prioritárias


# Carregando bibliotecas
library(conflicted)
library(sf)
library(raster)
library(dplyr)
library(ggplot2)
library(tmap)
library(leaflet)
library(gt)


# UDH ---------------------------------------------------------------------
# Carregando o shapefile
udh <- sf::st_read("shapes/UDH/RM_Recife_UDH.shp")

dim(udh)

# Função para testar mapas
teste_mapa <- function(base) {
  leaflet({{base}}) %>%
  setView(lng = -34.895, lat = -8.120, zoom = 8) %>%
  addTiles() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  # addPolygons(color = "blue",weight = 1,fill = FALSE)
  addCircleMarkers()
  
  }


# Carregando os dados da planilha
dados <- readxl::read_excel("shapes/UDH/udh.xlsx",sheet = "udh")
str(dados)
colnames(dados)
dados <- dados |> dplyr::filter(ano ==  2010)
dados <- dados |> transmute(
  UDH_ATLAS = as.character(udh),
  pop_total = as.integer(populacao),
  pop_creche = as.integer(pop_creche),
  ivs = ivs,
  classificação = as.factor(if_else(ivs < 0.2,"1.Muito Baixo",
                          if_else(ivs < 0.3, "2.Baixo",
                                  if_else(ivs < 0.4, "3.Médio",
                                          if_else(ivs < 0.5, "4.Alta","5.Muito Alta"
                                          ))))),
  renda = as.numeric(renda_per_capita)
)


# Juntando shapefile e planilha
udh <- dplyr::left_join(udh,dados)
## Teste para verificar se a junção está correta
# d <- udh |> dplyr::filter(UDH_ATLAS == "1261070700029")  
# teste_mapa(d)

udh <- sf::st_make_valid(udh)


#Inclusão de Goiana
# Carregando arquivo com o shape
goiana <-sf::st_read("shapes/PE_MUNICIPIOS_SIRGAS2000_MALHAMUNICIPAL_IBGE_2022.shp")
goiana <- goiana |> dplyr:: filter(MUN_SEM_AC == "GOIANA")
# Carregando arquivo com os dados
goianad <-tibble(read.csv2("arquivos/goiana.csv"))
# incluindo o poligono
goianad$geometry <- goiana$geometry
# transformando o df para ficar no formato adequado (concatenar)
goianad <-  goianad |> mutate(
                              ivs = as.numeric(ivs),
                              renda = as.numeric(renda))
# Convertendo em objeto sf e definindo crs
g <- st_as_sf(goianad)
g<- sf::st_transform(g,
                 crs = sf::st_crs(udh))
# concatenando goiana na base de udh
udh <- rbind(udh,g)
rm(goiana,goianad,dados)

# Creches -----------------------------------------------------------------

# lista de municípios da RMR
rmr <- c(
  "Araçoiaba",
  "Igarassu",
  "Itapissuma",
  "Ilha de Itamaracá",
  "Abreu e Lima",
  "Paulista",
  "Olinda",
  "Camaragibe",
  "Recife",
  "Jaboatão dos Guararapes",
  "São Lourenço da Mata",
  "Moreno",
  "Cabo de Santo Agostinho",
  "Ipojuca",
  "Goiana"
)

# carrega base do censo
creches <- xlsx::read.xlsx2("arquivos/creches_base.xlsx", sheetName = 'pronto')
creches <- creches |> transmute(
  NO_MUNICIPIO = NO_MUNICIPIO,
  CO_MUNICIPIO = CO_MUNICIPIO,
  CO_ENTIDADE = CO_ENTIDADE,
  NO_ENTIDADE = NO_ENTIDADE,
  TP_DEPENDENCIA = TP_DEPENDENCIA,
  NO_BAIRRO = NO_BAIRRO,
  DS_ENDERECO = DS_ENDERECO,
  Matrículas = as.integer(QT_MAT_INF_CRE),
  LAT = as.numeric(LAT),
  LONG = as.numeric(LONG)
 )
glimpse(creches)
creches_mapa <- creches
# criando o objeto sf com lat/long
creches <- sf::st_as_sf(creches,coords = c("LONG","LAT"),
                        crs = sf::st_crs(udh))

# apenas checando
teste_mapa(creches)

# Junção com os dados de creches
creches_udh <- sf::st_join(creches,udh)
names(creches_udh)
glimpse(creches_udh)
# Trocando NA por 0
creches_udh <- creches_udh |> mutate(
  Matrículas = ifelse(is.na(Matrículas),0,Matrículas)
)

# Resumindo os dados com group-by por UDH
udh_matriculas <- st_drop_geometry(creches_udh) |> group_by(UDH_ATLAS) |> summarise(Matrículas =sum(Matrículas)) 

# "Juntando" a informação de Matrículas à base de udh
udh_matriculas <- left_join(udh,udh_matriculas)
udh_matriculas <- udh_matriculas |> mutate( Matrículas = ifelse(is.na(Matrículas),0,Matrículas))
rm(udh)
udh <- udh_matriculas
rm(udh_matriculas)

# ### Pega o número de linha das creches
linhas_creches <- sf::st_contains(udh, creches) |>
  unlist() |>
  sort()

### Seleciona as creches
creches_ivs <- creches[linhas_creches, ]

### Calcula quantas creches estão contidas em cada célula
intersecao_creches <- sf::st_contains(udh, creches_ivs) |>
  purrr::map_int(length)
rm(creches_ivs)
### Indica a qtd. de creches
udh <- udh |>
  dplyr::mutate(creches = intersecao_creches)

# Grade -------------------------------------------------------------------

# Carrega os shapes dos municípios da RMR
RMR <- sf::read_sf("shapes/RMRseparada.shp")
RMR <- sf::st_transform(RMR,
                        crs = sf::st_crs(udh))
# Incluindo Goiana
gr <- st_as_sf(tibble(
  "code_mn" = 2606200,
  "name_mn" = "Goiana", 
  "cod_stt" = 26, 
  "abbrv_s" = "PE",
  "geometry" = g$geometry
))
# Transformando par sf
gr <- st_transform(gr,crs = sf::st_crs(udh))
# concatenando os dados
RMR <- rbind(RMR,gr)
rm(gr)

# Une a RMR em um único shape (sem resolver fronteiras internas)
RMRunida <- sf::st_combine(RMR)
RMRunida <- sf::st_transform(RMRunida,
                             crs = sf::st_crs(udh))
#plot(RMRunida)
# Obtém os limites da RMR (bounding box)
RMRlimites <- sf::st_bbox(RMRunida)

# Calcula as dimensões da bounding box
pt1 <- c(RMRlimites[1], RMRlimites[2])
pt2 <- c(RMRlimites[1], RMRlimites[4])
altura <- geodist::geodist(pt1, pt2, measure = "geodesic")/1000
pt3 <- c(RMRlimites[1], RMRlimites[2])
pt4 <- c(RMRlimites[3], RMRlimites[2])
comprimento <- geodist::geodist(pt3, pt4, measure = "geodesic")/1000

# Carrega os pontos de energia da RMR
## O carregamento do arquivo original foi comentado para agilizar a carga
## a partir de um arquivo RDS.
  # pontosEnergia <- sf::st_read("shapes/PT_CONS_RMR_atualizado.shp")
  # 
  # 
  # # Converte os pontos ao mesmo CRS do shape da RMR
  # pontosEnergia <- sf::st_transform(pontosEnergia,
  #                                   crs = sf::st_crs(udh))
  # saveRDS(pontosEnergia,"arquivos/pontosEnergia.rds")
pontosEnergia <- readRDS("arquivos/pontosEnergia.rds")
# Plot pontos de energia

# Funções -----------------------------------------------------------------
## Gera o grid com base na "bounding box" da RMR
RMRcells <- function() {
  #  selectedResolucao = 2
  ### Calcula o número de linhas e colunas para gerar o grid
  nrows <- ceiling(altura[1]/selectedResolucao)
  ncols <- ceiling(comprimento[1]/selectedResolucao)
  
  ### Gera o grid
  grid <- sf::st_make_grid(
    x = RMRunida,
    n = c(ncols, nrows)
  )
  
  ### Converte a sf
  sf::st_as_sf(grid)
  
}

## Filtra apenas as creches dentro da RMR
crechesRMR <- function(){
  
  ### Pega o número de linha das creches
  linhas <- sf::st_contains(RMRcells(), creches) |> 
    unlist() |> 
    sort()
  
  ### Seleciona as creches
  creches[linhas, ]
  
}

## Seleciona as células do grid que superam o critério de corte
chosenCells <- function(){
  # selectedInfantes = 100
  ### Calcula quantos pontos estão contidos em cada célula
  intersecao <- sf::st_contains(RMRcells(), pontosEnergia) |> 
    purrr::map_int(length)
  
  ### Estima a população total e a infantil em cada célula
  grade <- RMRcells() |> 
    dplyr::mutate(popTotal = 2.4*intersecao,
                  popInfantil = popTotal*0.09)
  
  ## Mantém apenas as células com uma qtd. mínima de crianças
  grade <- grade |>
    dplyr::filter(popInfantil >= selectedInfantes)
  
  ### Calcula quantas creches estão contidas em cada célula
  intersecao <- sf::st_contains(grade, crechesRMR()) |> 
    purrr::map_int(length)
  
  ### Indica a qtd. de creches
  grade |> 
    dplyr::mutate(creches = intersecao)
  
}



# Mapa --------------------------------------------------------------------

## Gera um mapa interativo com as células relevantes

## Adiciona a informação da qtd. de crianças estimada
selectedResolucao = 2
selectedInfantes = 20
# criando a grade com a função definida chosenCells
gradedf <- chosenCells() 
# transformando em sf
gradedf <- sf::st_transform(gradedf,
                            sf::st_crs(udh))
# "aparando" o shape para permitir a junção
gradedf <- sf::st_make_valid(gradedf)
# faz a junção das bases
Grade <- sf::st_join(gradedf,udh)
# retira as células sem população
Grade <- Grade |> subset(pop_total>0 )

### Criando as variáveis para o popup
udh <- udh |> mutate(
  `População Atendida (%)` = pop_creche/Matrículas,
  `Déficit de Vagas` = pop_creche - Matrículas
)

# Criando o texto dos popups
pop_creche <- paste(
  creches_mapa$NO_ENTIDADE,"<br/>",
  "Cidade: ", creches_mapa$NO_MUNICIPIO,"<br/>", 
  "Bairro: ", creches_mapa$NO_BAIRRO, "<br/>",
  "Matrículas: ", creches_mapa$Matrículas, "<br/>",
  "IVS Status: ", Grade$classificação, "<br/>", 
  sep="") %>%
  lapply(htmltools::HTML)

pop_udh <- paste(
  udh$UDH_ATLAS,"<br/>",
  "Cidade: ", udh$NM_MUNICIP,"<br/>", 
  "IVS: ", udh$ivs, "<br/>",
  "IVS Status: ", udh$classificação, "<br/>", 
  "População: ", udh$pop_total, "<br/>",
  "População Creches: ", udh$pop_creche, "<br/>",
  "População Atendida: ",  stringr::str_c(
    round(udh$`População Atendida (%)`,2),
    "%"),"<br/>",
  "Matrículas: ", udh$Matrículas, "<br/>",
  "Renda: ", udh$renda,"<br/>",
  sep="") %>%
  lapply(htmltools::HTML)

# Paleta de Cores
palette_ivs <- leaflet::colorNumeric( palette="viridis", domain=udh$ivs, na.color="transparent")
palette_renda <- leaflet::colorNumeric( palette="viridis", domain=udh$renda, na.color="transparent")
palette_status <- leaflet::colorFactor(palette =c("cornflowerblue","lightgreen","wheat","tomato" ,"red") , domain = (udh$classificação))


# mapa interativo
mapa_creches <-  
leaflet::leaflet() %>%
  setView(lng = -34.895, lat = -8.120, zoom = 8) %>%
  addTiles() %>%
  addLegend( data = udh, pal=palette_status, values=~classificação, opacity=0.5, title = "Índice de Vulnerabilidade Social (IVS)", position = "bottomleft" ,group = "IVS" ) %>%
  addLegend( data = udh, pal=palette_renda, values=~renda, opacity=0.5, title = "Renda)", position = "bottomleft" ,group = "Renda" ) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLayersControl(overlayGroups = c("Creches","IVS","Renda","Grade"),options = layersControlOptions(collapsed = FALSE)) %>%
  hideGroup(c("IVS","Renda","Grade"))%>%
  addPolygons(data = udh,fillColor = ~palette_status(classificação),stroke=TRUE, fillOpacity = 0.25,popup = pop_udh, color="black", weight=0.3, group = "IVS" ,labelOptions = labelOptions( style = list("font-weight" = "normal", padding = "3px 8px"), textsize = "5px", direction = "auto"  )) %>%
  addPolygons(data = udh,fillColor = ~palette_renda(renda),stroke=TRUE, fillOpacity = 0.25, popup = pop_udh,color="white", weight=0.3, group = "Renda" ,labelOptions = labelOptions( style = list("font-weight" = "normal", padding = "3px 8px"), textsize = "5px", direction = "auto"  )) %>%  
  addPolygons(data = Grade,color = "blue",weight = 1,fill = FALSE, group = "Grade") %>%
  addCircleMarkers(data = creches_mapa, lat = ~LAT, lng = ~LONG, radius = 1, color = "darkgreen", popup = pop_creche, group = "Creches")



# Output RDS --------------------------------------------------------------
saveRDS(Grade,"arquivos/Grade.rds")
saveRDS(udh,"arquivos/udh.rds")
saveRDS(creches_mapa,"arquivos/creches_mapa.rds")
