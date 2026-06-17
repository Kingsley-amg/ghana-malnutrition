# Child Malnutrition in Africa, with a Focus on Ghana

A geospatial and equity analysis of child malnutrition built in **R**, zooming
from the **African continent**, into **Ghana's national trends**, down to its
**16 regions** and social groups. Uses open data from the **DHS Program**, the
**World Bank**, and **geoBoundaries**.

> Ghana is a relative success on chronic undernutrition (stunting ~17%, well below
> the African median), but the national average hides a sharp **north–south
> divide** (Northern 30% vs Eastern 10%) and steep **wealth and education
> gradients** (poorest children ~3× as likely to be stunted as the richest).

---

## 🔗 Read the report
**[▶ Full report (HTML)](https://kingsley-amg.github.io/ghana-malnutrition/)** — knitted from R Markdown, with the regional map, charts and interpretation.
A **PDF version** is in [`report/`](report/).

## 🔍 What the analysis covers (three-level zoom)
1. **Africa context** — where Ghana ranks among African countries on stunting.
2. **Ghana over time** — national trends and the emerging "double burden" (chronic undernutrition falling while overweight/wasting persist).
3. **Within Ghana** — a **choropleth map of stunting across the 16 regions**, a ranked regional comparison, and an **equity analysis** by wealth quintile, mother's education, residence and sex.

## 🔑 Key findings
- Ghana's stunting (~17%) is **well below the African median** (~30%).
- A **2.8× north–south gap**: ~30% stunting in the Northern region vs ~10% in Eastern.
- Steep **social gradient**: ~3× more stunting in the poorest vs richest wealth quintile; ~4× by mother's education (no education vs higher).
- National progress now depends on **reaching the poorest regions and households**, not averages.

## 🗂️ Structure
```
ghana-malnutrition/
├── 01_extract.R            # pull DHS + World Bank data and Ghana region boundaries
├── ghana_malnutrition.Rmd  # the full analysis (source)
├── data/                   # extracted CSVs + ghana_adm1.geojson
├── docs/index.html         # knitted HTML report (GitHub Pages)
└── report/                 # PDF version
```

## 🔁 Reproduce
```r
install.packages(c("tidyverse","sf","jsonlite","scales","ggrepel","rmarkdown"))
Rscript 01_extract.R                       # gather data (open APIs, no keys)
rmarkdown::render("ghana_malnutrition.Rmd")
```

## 🧰 Tools & data
R · sf · ggplot2 · R Markdown — with **DHS Program API**, **World Bank Open Data**, and **geoBoundaries** (Ghana ADM1).

## ⚠️ Note
Descriptive, ecological analysis of survey estimates (with sampling error);
Ghana's region definitions changed in 2019, complicating long-run regional
comparisons. Associations are not causal.

## 👤 Author
**Kingsley Amegah** — Health Data Scientist · GitHub: [@Kingsley-amg](https://github.com/Kingsley-amg)
