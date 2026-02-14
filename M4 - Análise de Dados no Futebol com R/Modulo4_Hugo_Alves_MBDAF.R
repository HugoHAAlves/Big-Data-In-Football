# ------------------------------------------------------------------------------
# IMPORTAÇÃO DE DATASET E BIBLIOTECAS NECESSÁRIAS
# ------------------------------------------------------------------------------
library(tidyverse)
library(ggrepel)
library(readxl)
library(soccermatics)
library(png)
library(grid)
library(glue)

match <- read_excel("MBDAF_M4_Atividade_Individual.xlsx")
# Analisar a tabela para ganhar uma visão geral dos dados disponíveis
str(match) # É um tibble, que para o pretendido equivale a um dataframe
summary(match)

# Podemos já alterar as colunas de início, fim, e coordenadas para formato numérico
match$start <- as.numeric(match$start)
match$end <- as.numeric(match$end)
match$pos_x <- as.numeric(match$pos_x)
match$pos_y <- as.numeric(match$pos_y)

# Podemos igualmente parametrizar algumas variáveis do jogo. Pesquisando pelo histórico
# de confrontos entre estas duas equipas no Transfermarkt, descobrimos que este
# jogo ocorreu em Manchester e terminou com 2-1 para a equipa da casa.
# Fonte: https://www.transfermarkt.com/spielbericht/index/spielbericht/3651117
competition_name_var <- "Champions League"
season_name_var      <- "2021/22"
home_team_var        <- "Manchester City"
away_team_var        <- "PSG"
home_team_score_var  <- 2
away_team_score_var  <- 1

# Sabendo o jogo, faremos o mesmo para alguns dos jogadores que atuaram na partida e
# que vamos analisar mais à frente
dm_home <- c("16. Rodri")
dm_away <- c("8. Paredes")
lw_home <- c("7. Sterling")
rw_away <- c("30. Messi")
home_team_keeper_and_subs <- c("31. Ederson", "9. G. Jesus")
away_team_keeper_and_subs <- c("1. K. Navas", "24. Kehrer", "15. Danilo", "11. Di Maria")

# Por fim, vamos definir algumas variáveis com influência nos visuais.
home_team_col        <- "cadetblue2"
home_team_sec_col    <- "black"
away_team_col        <- "darkblue"
away_team_sec_col    <- "white"
first_logo_x_min     <- 82
first_logo_x_max     <- 92
bar_x                <- 93
sec_logo_x_min       <- 94
sec_logo_x_max       <- 104
logo_y_min           <- 69
logo_y_max           <- 77

# Vamos também criar uma função para gravar os gráficos criados
# como imagens. Este código estará comentado mais à frente para não
# estar a criar ficheiros para correr o código.
guardar_visual_png <- function(visual,
                               filename = NULL,
                               width = 10,
                               height = 7,
                               dpi = 300) {
  # Se o nome do ficheiro a ser guardado não for fornecido, usar nome da variável
  nome_visual <- if (is.null(filename)) {deparse(substitute(visual))} else {filename}
  # Caminho para o ficheiro
  output_dir <- file.path(getwd(), "Visuais Relatório")
  if (!dir.exists(output_dir)) {dir.create(output_dir)}
  file_path <- file.path(output_dir, paste0(nome_visual, ".png"))
  # Guardar ficheiro como png
  ggsave(filename = file_path, plot = visual,
         width = width, height = height, dpi = dpi)
  message("Ficheiro guardado em:", file_path)
}

# Por fim, vamos importar imagens para acrescentar aos gráficos, como os logótipos
# das equipas e as imagens dos jogadores.
home_team_logo <- readPNG("Imagens/Man City.png")
away_team_logo <- readPNG("Imagens/PSG.png")
dm_away_img <- readPNG("Imagens/Paredes.png") # Defensive Midfielder (away team)
dm_home_img <- readPNG("Imagens/Rodri.png") # Defensive Midfielder (home team)
rw_away_img <- readPNG("Imagens/Messi.png") # Right Winger (away team)
lw_home_img <- readPNG("Imagens/Sterling.png") # Left Winfer (home team)

home_team_grob <- rasterGrob(home_team_logo, interpolate = TRUE)
away_team_grob <- rasterGrob(away_team_logo, interpolate = TRUE)
dm_away_grob <- rasterGrob(dm_away_img, interpolate = TRUE)
dm_home_grob <- rasterGrob(dm_home_img, interpolate = TRUE)
rw_away_grob <- rasterGrob(rw_away_img, interpolate = TRUE)
lw_home_grob <- rasterGrob(lw_home_img, interpolate = TRUE)

# ==============================================================================
# VISUALIZAÇÕES - DESEMPENHO INDIVIDUAL
# ==============================================================================
# ------------------------------------------------------------------------------
# 1. Leandro Paredes - Ações Defensivas
# ------------------------------------------------------------------------------
# Vamos começar por filtrar as ações defensivas do Leandro Paredes. Para isso,
# precisamos de identificar as ações relevantes.
match %>%
  distinct(Action) %>%
  arrange(Action) %>% 
  print(n = Inf)

Acoes_defensivas <- c("Air challenges (lost)", "Air challenges (won)",
                      "Challenges (won)", "Challenges (lost)", "Fouls",
                      "Interceptions", "Picking-ups",
                      "Shots blocked", "Tackles (Successful actions)",
                      "Tackles (Unsuccessful actions)")

# Como a nossa visualização será alimentada por dois conjuntos de dados diferentes
# (a desenvolver mais à frente), vamos criar dois datasets complementares de modo
# a simplificar o nosso trabalho.
dm_away_dados_defensivos <- subset(match, code == dm_away & Action %in% Acoes_defensivas)
# Confirmar que parece tudo em condições
head(dm_away_dados_defensivos)

# Antes de partir para a elaboração do gráfico, vamos associar cada ação a uma cor
# A escolha das cores foi arbitrária, com base no site https://r-charts.com/colors/
cores_acoes_defensivas <- c(
  "Air challenges (lost)" = "blue",
  "Air challenges (won)" = "cornsilk2",
  "Challenges (won)" = "gold",
  "Challenges (lost)" = "lightsteelblue1",
  "Fouls" = "firebrick2",
  "Interceptions" = "aquamarine3",
  "Picking-ups" = "lightsalmon3",
  "Shots blocked" = "darkolivegreen2",
  "Tackles (Successful actions)" = "steelblue4",
  "Tackles (Unsuccessful actions)" = "lightpink"
)

# Vamos também criar um Convex Hull, para representar a área de abrangência das
# ações defensivas do jogador Leandro Paredes. Para isso, temos de criar um
# segundo dataset, definindo os pontos que devem fazer parte do Convex Hull.
dfHull_dm_away <- dm_away_dados_defensivos %>% 
  slice(chull(pos_x, pos_y))

# Podemos então partir para a elaboração do gráfico.
# Recorrendo à função soccerPitch do soccermatics, vamos começar por criar o relvado
dm_away_def <- soccerPitch(lengthPitch = 105, widthPitch = 68,
                           theme = "grass", arrow = c("r"),
                           title = glue("{dm_away} | Ações Defensivas"),
                           subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}")) +
  # Tendo o relvado, vamos representar a área de abrangência defensiva
  geom_polygon(data = dfHull_dm_away, aes(x = pos_x, y = pos_y),
               fill = "lightblue", alpha = 0.4) +
  # A partir daqui, podemos adicionar as coordenadas das ações defensivas do jogador
  # Leandro Paredes e customizar a aparência
  geom_point(data = dm_away_dados_defensivos,
           aes(x = pos_x, y = pos_y, fill = factor(Action)),
           color = "black", size = 5, shape = 21, stroke = 0.6) +
  labs(x = NULL, y = NULL, fill = "Tipo Ação") +
  scale_fill_manual(values = cores_acoes_defensivas) +
  theme(legend.position = "right") +
  # Finalizar com os logótipos das equipas
  annotation_custom(away_team_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
  annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "white", linewidth = 0.5) +
  annotation_custom(dm_away_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
print(dm_away_def)

#guardar_visual_png(dm_away_def, width = 15)



# ------------------------------------------------------------------------------
# 2. Rodri - Percurso e Mapa de Calor
# ------------------------------------------------------------------------------
# Uma vez que agora as nossas visualizações partem de um único dataset, poderá
# ser mais simples filtrar diretamente na construção do gráfico.
# Mapa de movimentações
dm_home_pathmap <- match %>%
  # Filtrar dados para incluir apenas o jogador Rodri
  filter(code == dm_home) %>%
  # Alterar o nome das colunas de coordenadas, para serem reconhecidas diretamente
  # pela função SoccerPath().
  rename(x = pos_x, y = pos_y) %>%
  # Criar o visual
  {
    soccerPath(., col = home_team_col, lwd = 0.8, theme = "dark", arrow = "r",
               title = glue("{dm_home} | Mapa de Movimentações"),
               subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}")) +
      annotation_custom(home_team_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
      annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "white", linewidth = 0.5) +
      annotation_custom(dm_home_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
  }
print(dm_home_pathmap)

#guardar_visual_png(dm_home_pathmap)

# Mapa de Calor
# Vamos recorrer ao parâmetro kde (definido como TRUE) para suavizar
# a apresentação do mapa de calor. Assim, não será necessários definir
# bins onde ocorreram as ações do jogador Rodri.
dm_home_heatmap <- match %>%
  # Filtrar dados para incluir apenas o jogador Rodri
  filter(code == dm_home) %>%
  # Alterar o nome das colunas de coordenadas, para serem reconhecidas diretamente
  # pela função SoccerPath().
  rename(x = pos_x, y = pos_y) %>%
  {
    soccerHeatmap(., kde = TRUE, arrow = c("r"),
                  title = glue("{dm_home} | Mapa de Calor"),
                  subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}"),
    ) +
      annotation_custom(home_team_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
      annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "black", linewidth = 0.5) +
      annotation_custom(dm_home_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
  }
print(dm_home_heatmap)

#guardar_visual_png(dm_home_heatmap)



# ------------------------------------------------------------------------------
# 3. Messi e Sterling - Dribles
# ------------------------------------------------------------------------------
# Vamos começar por identificar os dois jogadores e filtrar os dados para manter
# apenas os dribles por eles realizados.Não vamos considerar a ação "Dribbling".
# Não tem indicação de sucesso ou insucesso e, analisando os dados em causa, não
# é claro que seja uma ação que deva ser incluída.
wingers <- c(lw_home, rw_away)
Dribles <- c("Dribbles (Successful actions)", "Dribbles (Unsuccessful actions)")

# Vamos também definir aspetos de customização do visual (forma e cor).
shape_dribles <- c("Dribbles (Successful actions)" = 19, "Dribbles (Unsuccessful actions)" = 13)
color_equipa <- setNames(
  c(home_team_col, away_team_col),
  c(home_team_var, away_team_var)
)

wingers_dribbles <- match %>%
  # Filtrar pelos jogadores e ações em análise
  filter(code %in% wingers, Action %in% Dribles) %>%
  # Seria interessante mostrar no mesmo visual os dados dos dois jogadores.
  # Para isso, teremos de inverter os dados de um deles para ficar claro onde
  # ocorreram os dribles - caso contrário, as coordenadas indicariam que ambos
  # estavam a atacar da esquerda para a direita, o que não é o caso. Vamos
  # inverter os dados do jogador da equipa a jogar fora de casa.
  mutate(
    pos_x = ifelse(code == rw_away, 105 - pos_x, pos_x),
    pos_y = ifelse(code == rw_away, 68 - pos_y, pos_y)
  ) %>% 
  {
    soccerPitch(theme = "grass",
                title = glue("{lw_home} vs {rw_away} | Dribles Efetuados"),
                subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}")) +
      geom_point(data = ., aes(pos_x, pos_y, colour = factor(Team), shape = factor(Action)), size = 4) +
      scale_shape_manual(values = shape_dribles) +
      scale_color_manual(values = color_equipa) +
      labs(color = "Equipa", shape = "Precisão") +
      theme(legend.position = "right", plot.caption = element_text(hjust = 0.5, size = 10, face = "italic")) +
      # Finalizar com os logótipos das equipas
      annotation_custom(lw_home_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
      annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "white", linewidth = 0.5) +
      annotation_custom(rw_away_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
  }
print(wingers_dribbles)

#guardar_visual_png(wingers_dribbles, width = 13)



# ==============================================================================
# VISUALIZAÇÕES - DESEMPENHO COLETIVO
# ==============================================================================
# ------------------------------------------------------------------------------
# 1. Convex Hull
# ------------------------------------------------------------------------------
# Para elaborar o Convex Hull, vamos remover os suplentes utilizados e os
# guarda-redes de ambas as equipas.
players_to_remove <- c(home_team_keeper_and_subs, away_team_keeper_and_subs)
match_Hull <- match %>%
  filter(!code %in% players_to_remove)

# Tendo em conta que vamos mostrar os dados dos jogadores do Manchester City e do PSG na
# mesma visualização, vamos inverter as coordenadas dos jogadores da equipa visitante.
match_Hull <- match_Hull %>%
  mutate(
    pos_x = ifelse(Team == away_team_var, 105 - pos_x, pos_x),
    pos_y = ifelse(Team == away_team_var, 68 - pos_y, pos_y))

# Podemos agora calcular as posições médias dos jogadores...
match_pos_media <- match_Hull %>% 
  group_by(code, Team) %>% 
  summarise(
    avg_x = mean(pos_x, na.rm = TRUE),
    avg_y = mean(pos_y, na.rm = TRUE),
    .groups = "drop")

#... e criar datasets específicos para cada uma das equipas. À semelhança do que
# foi feito para o gráfico das ações defensivas, também aqui a nossa visualização
# será alimentada por dois conjuntos de dados diferentes e complementada com
# informação de variáveis específicas para cada caso (amplitude e profundidade).
# Assim, ter dois datasets irá, neste caso concreto, simplificar o nosso trabalho.
home_team_pos_media <- match_pos_media %>% 
  filter(Team == home_team_var)
away_team_pos_media <- match_pos_media %>% 
  filter(Team == away_team_var)

# Vamos também calcular a profundidade e amplitude das equipas para completar o visual
home_team_Profundidade <- round((max(home_team_pos_media$avg_x) - sort(home_team_pos_media$avg_x)[2]), 2)
home_team_Amplitude <- round((max(home_team_pos_media$avg_y) - sort(home_team_pos_media$avg_y)[2]), 2)
away_team_Profundidade <- round((max(away_team_pos_media$avg_x) - sort(away_team_pos_media$avg_x)[2]), 2)
away_team_Amplitude <- round((max(away_team_pos_media$avg_y) - sort(away_team_pos_media$avg_y)[2]), 2)

# Finalmente, vamos filtrar, dentro de cada equipa, os pontos exteriores que determinam
# os respetivos Convex Hulls
dfHull_home_team <- home_team_pos_media %>%
  filter(Team == home_team_var) %>% 
  slice(chull(avg_x, avg_y))
dfHull_away_team <- away_team_pos_media %>% 
  filter(Team == away_team_var) %>%
  slice(chull(avg_x, avg_y))

# Podemos agora partir para a criação da visualização. Em vez de recorrer à função
# soccerPositionMap(), vamos utilizar a função soccerPitch() para permitir mais opções
# de customização
match_CH <- soccerPitch(lengthPitch = 105, widthPitch = 68, theme = "grass",
                        title = "Convex Hulls",
                        subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}")) +
  # Convex hulls
  geom_polygon(data = dfHull_home_team, aes(x = avg_x, y = avg_y), fill = home_team_col, alpha = 0.4) +
  geom_polygon(data = dfHull_away_team, aes(x = avg_x, y = avg_y), fill = away_team_col, alpha = 0.4) +
  # Pontos a representar as posições médias dos jogadores
  geom_point(data = home_team_pos_media, aes(x = avg_x, y = avg_y),
             fill = home_team_col, color = home_team_sec_col, size = 5, shape = 21, stroke = 0.6) +
  geom_point(data = away_team_pos_media, aes(x = avg_x, y = avg_y),
             fill = away_team_col, color = "red", size = 5, shape = 21, stroke = 0.6) +
  # Nomes dos jogadores, a apresentar por cima da respetiva posição média
  geom_text_repel(data = home_team_pos_media,
                  aes(x = avg_x, y = avg_y, label = code),
                  color = home_team_col, size = 3, nudge_y = 2.1) +
  geom_text_repel(data = away_team_pos_media,
                  aes(x = avg_x, y = avg_y, label = code),
                  color = away_team_col, size = 3, nudge_y = 2.1) +
  # Anotações com a profundidade e amplitude de ambas as equipas
  annotate("text", x = 2, y = 6.5,
           label = paste0(glue("{home_team_var}\nProfundidade: "), home_team_Profundidade, "m\nAmplitude: ", home_team_Amplitude, "m"),
           color = home_team_col, hjust = 0, size = 4) +
  annotate("text", x = 103, y = 6.5,
           label = paste0(glue("{away_team_var}\nProfundidade: "), away_team_Profundidade, "m\nAmplitude: ", away_team_Amplitude, "m"),
           color = away_team_sec_col, hjust = 1, size = 4) +
  # Finalizar com os logótipos das equipas
  annotation_custom(home_team_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
  annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "white", linewidth = 0.5) +
  annotation_custom(away_team_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
print(match_CH)

#guardar_visual_png(match_CH)



# ------------------------------------------------------------------------------
# 2. Mapa de passes
# ------------------------------------------------------------------------------
# Vamos seguir uma abordagem semelhante à visualização realizada para comparar
# os dribles realizados por Raheem Sterling contra os de Lionel Messi.

# Não vamos considerar as ações "Key passes (accurate)" e "Key passes (inaccurate)"
# nem "Crosses (accurate)" e "Crosses (inaccurate)", uma vez que a análise da
# tabela revela que estes passes também são contabilizados como "Passes (inaccurate)"
# e "Passes accurate", respetivamente.
Passes <- c("Passes (inaccurate)", "Passes accurate")
df_Passes_match <- subset(match, Action %in% Passes)
head(df_Passes_match)

# Novamente, para mostrar ambas as equipas no mesmo campo, temos primeiro de
# inverter os dados de um deles para ficar claro onde ocorreram os passes -
# - caso contrário, as coordenadas indicariam que ambos estavam a atacar da
# esquerda para a direita, o que não é naturalmente o caso.Vamos inverter os
# dados da equipa que jogou fora neste jogo.
df_Passes_match <- df_Passes_match %>%
  mutate(
    pos_x = ifelse(Team == away_team_var, 105 - pos_x, pos_x),
    pos_y = ifelse(Team == away_team_var, 68 - pos_y, pos_y))

# Vamos também calcular o número de passes por equipa em função do seu sucesso,
# para juntar informação ao visual.
passes_resumo <- df_Passes_match %>%
  group_by(Team, Action) %>%
  summarise(n_passes = n(), .groups = "drop") %>% 
  pivot_wider(names_from = Action, values_from = n_passes, values_fill = 0)
home_team_label <- passes_resumo %>%
  filter(Team == home_team_var) %>%
  mutate(label = paste0(
    glue("{home_team_var}"), "\n",
    "Passes Completados: ", `Passes accurate`, "\n",
    "Passes Falhados: ", `Passes (inaccurate)`)) %>%
  pull(label)
away_team_label <- passes_resumo %>%
  filter(Team == away_team_var) %>%
  mutate(label = paste0(
    glue("{away_team_var}"), "\n",
    "Passes Completados: ", `Passes accurate`, "\n",
    "Passes Falhados: ", `Passes (inaccurate)`)) %>%
  pull(label)

# Perfeito. Podemos agora construir a visualização. Já definimos anteriormente a
# cor das equipas, mas vamos refazê-lo para ficar definido em cada bloco de código.
shape_passes <- c("Passes accurate" = 19, "Passes (inaccurate)" = 13)
color_equipa <- setNames(
  c(home_team_col, away_team_col),
  c(home_team_var, away_team_var)
)

match_passes <- soccerPitch(theme = "grass",
                            title = "Comparação dos Passes Efetuados",
                            subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}")) +
  geom_point(data = df_Passes_match, aes(pos_x, pos_y, colour = factor(Team), shape = factor(Action)), size = 2) +
  scale_shape_manual(values = shape_passes) +
  scale_color_manual(values = color_equipa) +
  # Anotações com o número de passes de cada equipa
  annotate("text", x = 2, y = 6.5, label = home_team_label, color = home_team_col, hjust = 0, size = 4) +
  annotate("text", x = 103, y = 6.5, label = away_team_label, color = away_team_sec_col, hjust = 1, size = 4) +
  labs(color = "Equipa", shape = "Precisão") +
  theme(legend.position = "right", plot.caption = element_text(hjust = 0.5, size = 10, face = "italic")) +
  # Finalizar com os logótipos das equipas
  annotation_custom(home_team_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
  annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "white", linewidth = 0.5) +
  annotation_custom(away_team_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
print(match_passes)

#guardar_visual_png(match_passes, width = 13)



# ------------------------------------------------------------------------------
# 3. Mapa de Expected Goals (xG)
# ------------------------------------------------------------------------------
# O primeiro passo para esta visualização será filtrar o dataset para manter
# apenas as ações com xG, que serão o objeto da nossa análise.
match_com_xG <- match %>%
  filter(xG > 0)

# Vamos apenas confirmar que não há ações estranhas com valores de xG. Em teoria,
# apenas esperamos encontrar remates.
match_com_xG %>%
  distinct(Action) %>%
  arrange(Action) %>% 
  print(n = Inf)

# Como já temos feito, vamos inverter as coordenadas dos remates dos jogadores
# do PSG de modo a mostrar os dados de ambas as equipas no mesmo campo. Vamos
# igualmente agrupar os remates em função do seu enquadramento com a baliza.
match_com_xG <- match_com_xG %>%
  mutate(
    pos_x = ifelse(Team == away_team_var, 105 - pos_x, pos_x),
    pos_y = ifelse(Team == away_team_var, 68 - pos_y, pos_y),
    Tipo_Remate = case_when(
      Action %in% c("Goals", "Shot on target") ~ "Remate Enquadrado",
      TRUE ~ "Remate Não Enquadrado"
    ))

# À semelhança do que já temos vindo a fazer, vamos somar os golos esperados
# de cada equipa e completar a visualização com esta informação.
xG_resumo <- match_com_xG %>%
  group_by(Team) %>%
  summarise(
    xG_total = round(sum(xG, na.rm = TRUE), 2),
    .groups = "drop")
home_team_xG_label <- xG_resumo %>%
  filter(Team == home_team_var) %>%
  mutate(label = paste0(glue("{home_team_var}\nGolos Esperados (xG): "), xG_total)) %>%
  pull(label)
away_team_xG_label <- xG_resumo %>%
  filter(Team == away_team_var) %>%
  mutate(label = paste0(glue("{away_team_var}\nGolos Esperados (xG): "), xG_total)) %>%
  pull(label)

# Perfeito. Podemos agora partir para a criação do visual.
shape_remates <- c("Remate Enquadrado" = 19, "Remate Não Enquadrado" = 13)
color_equipa <- setNames(
  c(home_team_col, away_team_col),
  c(home_team_var, away_team_var)
)

match_xG <- soccerPitch(theme = "grass",
                        title ="Análise de Remates por xG",
                        subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}")) +
  geom_point(data = match_com_xG, mapping = aes(x = pos_x, y = pos_y, shape = factor(Tipo_Remate), colour = factor(Team), size = xG)) +
  geom_point(data = subset(match_com_xG, Action == "Goals"), aes(x = pos_x, y = pos_y, size = xG),
             shape = 21, fill = NA, colour = "gold2",  stroke = 1.2) +
  scale_shape_manual(values = shape_remates) +
  scale_color_manual(values = color_equipa) +
  scale_size_continuous(range = c(2, 8)) +
  labs(color = "Equipa", shape = "Tipo de Remate") +
  # Remover a legenda para o tamanho, e aumentar tamanho dos símbolos para a forma e cor
  guides(
    size = "none",
    shape = guide_legend(override.aes = list(size = 3)),
    colour = guide_legend(override.aes = list(size = 3))
  ) +
  # Anotações com os golos esperados de cada equipa
  annotate("text", x = 103, y = 5, label = home_team_xG_label, color = home_team_col, hjust = 1, size = 4) +
  annotate("text", x = 2, y = 5, label = away_team_xG_label, color = away_team_sec_col, hjust = 0, size = 4) +
  theme(legend.position = "right", plot.caption = element_text(hjust = 0.5, size = 10, face = "italic")) +
  # Finalizar com os logótipos das equipas
  annotation_custom(home_team_grob, xmin = first_logo_x_min, xmax = first_logo_x_max, ymin = logo_y_min, ymax = logo_y_max) +
  annotate("segment", x = bar_x, xend = bar_x, y = logo_y_min, yend = logo_y_max, colour = "white", linewidth = 0.5) +
  annotation_custom(away_team_grob, xmin = sec_logo_x_min, xmax = sec_logo_x_max, ymin = logo_y_min, ymax = logo_y_max)
print(match_xG)

#guardar_visual_png(match_xG, width = 13)



# Para terminar, e como complemento, vamos criar uma timeline com os golos
# esperados das duas equipas. Não tendo os dados no formato correto para aplicar
# a função soccerxGTimeline() da biblioteca soccermatics, vamos aproveitar a
# liberdade adicional para criar um gráfico com a biblioteca ggplot2 (incluída)
# no package tidyverse.
# Vamos começar por calcular o valor cumulativo dos golos esperados, desde o
# início da partida até ao fim dos 90 minutos.
xg_timeline_plot <- match_com_xG %>%
  arrange(Team, start) %>%
  group_by(Team) %>%
  mutate(cum_xG = cumsum(xG)) %>%
  reframe(
    start = c(0, start, 90 * 60), # Assegurar que as linhas começam no minuto 0 e terminam no minuto 90
    cum_xG = c(0, cum_xG, last(cum_xG)),
    Action = c(NA, Action, NA),
    code   = c(NA, code, NA))

# Definir as posições dos logótipos das equipas, no final da respetiva linha
logo_positions <- xg_timeline_plot %>%
  group_by(Team) %>%
  filter(start == max(start)) %>%
  summarise(x = max(start) / 60, y = last(cum_xG), .groups = "drop")

# Criar o gráfico, começando por definir quais os dados a usar
timeline_xg <- ggplot(xg_timeline_plot, aes(x = start / 60, y = cum_xG, colour = Team)) +
  geom_step(linewidth = 0.8) +
  # Acrescentar círculo com borda dourada e nome do marcador para os golos
  geom_point(data = subset(xg_timeline_plot, Action == "Goals"), size = 3.5) +
  geom_point(data = subset(xg_timeline_plot, Action == "Goals"),
             aes(x = start / 60, y = cum_xG),
             shape = 21, fill = NA, colour = "gold", size = 4) +
  geom_text(data = subset(xg_timeline_plot, Action == "Goals"),
            aes(x = start / 60, y = cum_xG, label = code),
            nudge_y = 0.1, size = 4, color = "black", show.legend = FALSE) +
  scale_color_manual(values = color_equipa) +
  # Definir escala horizontal de 15 em 15 minutos
  scale_x_continuous(limits = c(0, 90), breaks = seq(15, 90, by = 15)) +
  labs(
    title = "Timeline de Golos Esperados (xG)",
    subtitle = glue("{home_team_var} {home_team_score_var}-{away_team_score_var} {away_team_var}"),
    x = "Minuto",
    y = "Golos Esperados (xG)"
  ) +
  # Remover legenda
  guides(colour = "none") +
  # Linha para separar a primeira da segunda parte
  geom_vline(xintercept = 45, linetype = "dashed", colour = "grey60") +
  # Inserir logótipos das equipas no fim de cada linha
  annotation_custom(home_team_grob, xmin = 90.5, xmax = 94.5,
    ymin = logo_positions$y[logo_positions$Team == home_team_var] - 2,
    ymax = logo_positions$y[logo_positions$Team == home_team_var] + 2) +
  annotation_custom(away_team_grob, xmin = 90.5, xmax = 94.5,
    ymin = logo_positions$y[logo_positions$Team == away_team_var] - 2,
    ymax = logo_positions$y[logo_positions$Team == away_team_var] + 2) +
  theme_classic()

#guardar_visual_png(timeline_xg)