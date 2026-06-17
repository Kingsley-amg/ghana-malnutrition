# =============================================================================
#  make_video.R  -  render square (1080x1080) slides + an animated regional bar
#  for a LinkedIn walkthrough video. ffmpeg stitches them (see shell after).
# =============================================================================
suppressMessages({ library(tidyverse); library(sf); library(scales) })
V <- "video"; dir.create(file.path(V, "bars"), recursive = TRUE, showWarnings = FALSE)
INK <- "#16212e"; ACC <- "#1b9e77"; HI <- "#d73027"; MUT <- "#aeb8c4"

sq <- function(file, p) ggsave(file.path(V, file), p, width = 10, height = 10, dpi = 108, bg = "white")

# ---- data ----
afr   <- read_csv("data/africa_stunting_latest.csv", show_col_types = FALSE)
trend <- read_csv("data/ghana_trend.csv", show_col_types = FALSE)
region<- read_csv("data/ghana_stunting_region.csv", show_col_types = FALSE)
equity<- read_csv("data/ghana_equity.csv", show_col_types = FALSE)
gh_sf <- st_read("data/ghana_adm1.geojson", quiet = TRUE) |>
  mutate(region = str_remove(shapeName, " Region$"))
m <- c("..Western (post 2022)"="Western","..Western North"="Western North","Central"="Central",
       "Greater Accra"="Greater Accra","..Volta (post 2022)"="Volta","..Oti"="Oti","Eastern"="Eastern",
       "Ashanti"="Ashanti","..Ahafo"="Ahafo","..Bono"="Bono","..Bono East"="Bono East",
       "....Northern(post 2022)"="Northern","....Savannah"="Savannah","....Northeast"="North East",
       "..Upper East"="Upper East","..Upper West"="Upper West")
reg22 <- region |> filter(survey_year==2022, label %in% names(m)) |>
  mutate(region = m[label]) |> select(region, stunting = value) |>
  mutate(region = fct_reorder(region, stunting))

# ---- text-card helper ----
card <- function(file, lines) {
  df <- tibble(y = seq_along(lines), txt = sapply(lines, `[[`, "t"),
               size = sapply(lines, `[[`, "s"), col = sapply(lines, `[[`, "c"),
               face = sapply(lines, `[[`, "f"))
  cum <- cumsum(df$size) - df$size              # top offset of each line (relative units)
  df$ypos <- 0.86 - cum / sum(df$size) * 0.72   # always fits within [~0.14, 0.86]
  p <- ggplot(df) +
    annotate("rect", xmin=0.06, xmax=0.20, ymin=0.875, ymax=0.895, fill=ACC) +
    geom_text(aes(0.06, ypos, label = txt, size = size, colour = col, fontface = face), hjust = 0) +
    scale_size_identity() + scale_colour_identity() +
    xlim(0,1) + ylim(0,1) +
    theme_void() + theme(plot.background = element_rect(fill = INK, colour = INK))
  ggsave(file.path(V, file), p, width = 10, height = 10, dpi = 108, bg = INK)
}
L <- function(t,s,c,f="plain") list(t=t,s=s,c=c,f=f)

# ---- 1. title ----
card("01_title.png", list(
  L("CHILD MALNUTRITION", 7, ACC, "bold"),
  L("Africa, then Ghana,", 16, "white", "bold"),
  L("then its 16 regions", 16, "white", "bold"),
  L("", 4, "white"),
  L("What national averages hide", 8, MUT),
  L("DHS + World Bank data  .  built in R", 6, MUT)))

# ---- 2. Africa context ----
gv <- afr$value[afr$iso3=="GHA"]; med <- median(afr$value)
p2 <- afr |> mutate(g = iso3=="GHA") |>
  ggplot(aes(value, fct_reorder(country, value), fill = g)) +
  geom_col() + geom_vline(xintercept = med, linetype="dashed", colour="grey50") +
  scale_fill_manual(values=c(`FALSE`="grey80",`TRUE`=HI), guide="none") +
  labs(title="Ghana vs Africa: child stunting",
       subtitle=sprintf("Ghana %.0f%% (red) is well below the African median of %.0f%%", gv, med),
       x="Stunting (% of under-5s)", y=NULL) +
  theme_minimal(base_size=15) + theme(axis.text.y=element_text(size=7))
sq("02_africa.png", p2)

# ---- 3. the map ----
map_df <- gh_sf |> left_join(as_tibble(reg22), by="region")
p3 <- ggplot(map_df) +
  geom_sf(aes(fill=stunting), colour="white", linewidth=0.3) +
  scale_fill_distiller(palette="RdYlGn", direction=-1, name="Stunting %") +
  geom_sf_text(aes(label=paste0(region,"\n",round(stunting),"%")), size=3) +
  labs(title="Stunting by region, Ghana 2022",
       subtitle="The north carries a far heavier burden than the south") +
  theme_void(base_size=15) + theme(plot.title=element_text(face="bold"))
sq("03_map.png", p3)

# ---- 4. animated regional bar (grows, then holds) ----
mx <- max(reg22$stunting)
prog <- c(seq(0.05, 1, length.out = 22), rep(1, 12))
for (i in seq_along(prog)) {
  pr <- prog[i]
  pb <- ggplot(reg22, aes(stunting*pr, region)) +
    geom_col(fill = ACC) +
    geom_text(aes(label = round(stunting*pr)), hjust = -0.2, size = 4) +
    scale_x_continuous(limits = c(0, mx*1.15), expand = c(0,0)) +
    labs(title="Stunting by region (%), Ghana 2022",
         subtitle="Northern ~30%  vs  Eastern ~10%  =  a 2.8x gap", x=NULL, y=NULL) +
    theme_minimal(base_size=15) + theme(plot.title=element_text(face="bold"))
  ggsave(sprintf("%s/bars/f_%03d.png", V, i), pb, width=10, height=10, dpi=108, bg="white")
}

# ---- 5. equity ----
eq <- equity |> filter(survey_year==2022, indicator=="stunting",
                       category %in% c("Wealth quintile","Education","Residence")) |>
  mutate(label = factor(label, levels=c("Lowest","Second","Middle","Fourth","Highest",
        "No education","Primary","Secondary","Higher","Rural","Urban")))
p5 <- ggplot(eq, aes(label, value, fill=category)) +
  geom_col(show.legend=FALSE) + geom_text(aes(label=paste0(round(value),"%")), vjust=-0.3, size=3.5) +
  facet_wrap(~category, scales="free_x") + scale_fill_brewer(palette="Set2") +
  labs(title="Who is left behind? Stunting by social group",
       subtitle="Poorest children ~3x, and children of mothers with no education ~4x, more likely stunted",
       x=NULL, y="Stunting (%)") + theme_minimal(base_size=14)
sq("05_equity.png", p5)

# ---- 6. national trend ----
p6 <- trend |> filter(indicator %in% c("stunting","underweight","overweight")) |>
  ggplot(aes(year, value, colour=indicator)) +
  geom_line(linewidth=1.2) + geom_point(size=2.5) +
  scale_colour_brewer(palette="Set1") +
  labs(title="Ghana's progress over two decades",
       subtitle="Chronic undernutrition has fallen, but overweight signals a coming double burden",
       x=NULL, y="% of children under 5", colour=NULL) +
  theme_minimal(base_size=15) + theme(legend.position="bottom")
sq("06_trend.png", p6)

# ---- 7. end card ----
card("07_end.png", list(
  L("THE TAKEAWAY", 7, ACC, "bold"),
  L("Progress is real, but", 15, "white", "bold"),
  L("the burden is concentrated", 15, "white", "bold"),
  L("", 4, "white"),
  L("Reaching the poorest regions and", 8, MUT),
  L("households matters more than averages", 8, MUT),
  L("", 4, "white"),
  L("Live report: kingsley-amg.github.io/ghana-malnutrition", 7, ACC, "bold"),
  L("Code: github.com/Kingsley-amg/ghana-malnutrition", 7, "white"),
  L("", 3, "white"),
  L("Kingsley Amegah  .  Health Data Scientist", 7, MUT)))

cat("rendered slides + ", length(prog), " bar frames\n")
