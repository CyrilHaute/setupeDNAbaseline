# Setup project ----

## Install packages ----
devtools::install_deps(upgrade = "never")

## Load packages & functions ----
devtools::load_all()

source("analyses/01_clean_spygen_data.R")

source("analyses/02_extract_eDNA_tracks.R")