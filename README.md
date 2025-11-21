# Thermal and Behavioural Response Analyses

This repository contains the combined workflow for processing and visualizing:

1. **Shelter / sediment temperature time series** with inundation shading  
2. **Depth–temperature positional-variability analysis** (moving-window response)

All analyses are executed from a single script:

`data_processing_and_depth_plots.R`

---

## Data Inputs

Place the following files in the repository root:

**Shelter temperature sensors**
- `PPCa0.csv`  
- `PPCb0.csv`  
- `PPCa3.csv`  
- `PPCb3.csv`  
- `tern_rect.csv`  *(tidal inundation periods)*

**Depth–temperature dataset**
- `cc_depth_temp.csv`

---

## Output Figures

### 1. Shelter temperature series

- **File:** `pp_shelters.png`  

This figure shows the time series of air and sediment (3 cm depth) temperature across the experimental period, with tidal inundation periods highlighted as shaded intervals. It provides a high-resolution view of the thermal conditions experienced by experimental animals.

### 2. Positional variability under thermal stress

- **File:** `posSD_temp_ggplot.png`  

This figure summarizes how individual movement behaviour responds to temperature. It shows:
- daily mean temperature,
- the standard deviation of position (SD of depth or horizontal position),
- moving-window averages of variability,
- and a fitted linear model describing how positional stability changes with temperature.

Together, these plots link fine-scale behavioural responses to the underlying thermal regime.

---

## Running the Workflow

To run the full workflow and generate both figures, start R in the repository root and execute:

```r
source("data_processing_and_depth_plots.R")

The script will:
- read all required input CSV files from the root folder,
- process the time series and depth–temperature data,
- produce pp_shelters.png and posSD_temp_ggplot.png in the working directory.

Required R Packages

The script uses the following R packages:
library(plyr)
library(ggplot2)
library(gganimate)
library(gifski)
library(anytime)
library(scales)
library(png)
library(ggpubr)
library(plotrix)
library(car)

Make sure these packages are installed before running the script, for example:
install.packages(c(
  "plyr", "ggplot2", "gganimate", "gifski",
  "anytime", "scales", "png", "ggpubr", "plotrix", "car"
))

Usage & Permissions

This workflow is intended solely for academic, non-commercial research.
	•	Commercial reuse, reselling, or integration into proprietary tools requires written permission from the authors.
	•	Public reposting of figures, scripts, or derived outputs beyond academic presentations and publications also requires prior approval.

Please contact the repository owner before using this workflow in commercial or public applications beyond standard academic use.

⸻

Contact

For questions, bug reports, or collaboration inquiries, please open an issue on this repository or contact the maintainer directly.
