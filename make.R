# Project title
#
# Project description
# ...
#
# Author: Cyril Hautecoeur (mail : hautecoeurcyril@gmail.com)
# Date: 02/03/2026

# Setup project ----

## Install packages ----
devtools::install_deps(upgrade = "never")

## Load packages & functions ----
devtools::load_all()

source("analyses/01_clean_spygen_data.R")

source("analyses/02_extract_eDNA_tracks.R")