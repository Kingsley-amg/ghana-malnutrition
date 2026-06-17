# =============================================================================
#  01_extract.R  -  Gather malnutrition data for the Africa -> Ghana -> regions
#  analysis, from open APIs. No keys required.
#  Sources: World Bank Open Data API, DHS Program API, geoBoundaries.
#  Outputs: tidy CSVs + Ghana region boundaries in ./data
# =============================================================================
suppressMessages({ library(jsonlite); library(dplyr); library(tidyr); library(readr) })
dir.create("data", showWarnings = FALSE)

# ---- World Bank helper ------------------------------------------------------
wb <- function(code, countries = "all", years = "2000:2024") {
  url <- sprintf("https://api.worldbank.org/v2/country/%s/indicator/%s?format=json&date=%s&per_page=20000",
                 countries, code, years)
  out <- tryCatch({
    j <- fromJSON(url, flatten = TRUE); d <- j[[2]]
    tibble(iso3 = d$countryiso3code, country = d$country.value,
           year = as.integer(d$date), value = as.numeric(d$value))
  }, error = function(e) tibble(iso3=character(), country=character(),
                                year=integer(), value=numeric()))
  out |> filter(!is.na(value), nchar(iso3) == 3)
}

# African country list (Sub-Saharan + North African states)
meta <- fromJSON("https://api.worldbank.org/v2/country?format=json&per_page=400", flatten = TRUE)[[2]]
north <- c("DZA","EGY","LBY","MAR","TUN","SDN","ESH")
afr <- meta |>
  transmute(iso3 = id, country = name, region = trimws(region.value)) |>
  filter(region == "Sub-Saharan Africa" | iso3 %in% north)
write_csv(afr, "data/africa_countries.csv")

# 1) Africa context: latest stunting per African country
stunting_all <- wb("SH.STA.STNT.ZS") |> semi_join(afr, by = "iso3")
africa_latest <- stunting_all |> group_by(iso3, country) |>
  slice_max(year, n = 1, with_ties = FALSE) |> ungroup()
write_csv(africa_latest, "data/africa_stunting_latest.csv")

# 2) Ghana national trend: several malnutrition indicators
gh_inds <- c(stunting = "SH.STA.STNT.ZS", underweight = "SH.STA.MALN.ZS",
             severe_wasting = "SH.SVR.WAST.ZS", overweight = "SH.STA.OWGH.ZS",
             anaemia_child = "SH.ANM.CHLD.ZS")
ghana_trend <- lapply(names(gh_inds), function(n)
  wb(gh_inds[[n]], "GHA") |> transmute(year, indicator = n, value)) |>
  bind_rows()
write_csv(ghana_trend, "data/ghana_trend.csv")

# ---- DHS API helper ---------------------------------------------------------
dhs <- function(indicator, breakdown) {
  url <- sprintf(paste0("https://api.dhsprogram.com/rest/dhs/data?countryIds=GH",
                        "&indicatorIds=%s&breakdown=%s&f=json&perpage=2000"),
                 indicator, breakdown)
  d <- fromJSON(url)$Data
  tibble(survey_year = d$SurveyYear, indicator = indicator,
         category = d$CharacteristicCategory, label = d$CharacteristicLabel,
         value = as.numeric(d$Value))
}

# 3) Ghana stunting by region, all survey years (for maps + regional trend)
dhs_region <- dhs("CN_NUTS_C_HA2", "subnational")
write_csv(dhs_region, "data/ghana_stunting_region.csv")

# 4) Ghana stunting & underweight by wealth / education / residence (equity)
dhs_equity <- bind_rows(
  dhs("CN_NUTS_C_HA2", "background") |> mutate(indicator = "stunting"),
  dhs("CN_NUTS_C_WA2", "background") |> mutate(indicator = "underweight"))
write_csv(dhs_equity, "data/ghana_equity.csv")

# ---- Ghana region boundaries (geoBoundaries ADM1) ---------------------------
api <- fromJSON("https://www.geoboundaries.org/api/current/gbOpen/GHA/ADM1/")
download.file(api$gjDownloadURL, "data/ghana_adm1.geojson", quiet = TRUE)

cat("\n=== EXTRACT COMPLETE ===\n")
cat("African countries w/ stunting:", nrow(africa_latest), "\n")
cat("Ghana trend rows:", nrow(ghana_trend), "| indicators:", length(gh_inds), "\n")
cat("DHS region rows:", nrow(dhs_region), "| survey years:",
    paste(sort(unique(dhs_region$survey_year)), collapse = ", "), "\n")
cat("DHS equity rows:", nrow(dhs_equity), "\n")
cat("Boundaries saved:", file.exists("data/ghana_adm1.geojson"), "\n")
