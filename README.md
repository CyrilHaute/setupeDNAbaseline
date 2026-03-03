# Setup a baseline for spygen eDNA data

This repository create a baseline to analyse spygen eDNA data.

The workflow is separated into two different steps :

## I. Clean eDNA data

This step convert raw spygen eDNA data into a format suitable for analysis.

1. Raw spygen eDNA data are converted to site X species matrix and species identified multiple times are summed and summarize into one column.

2. The site X species matrix is cleaned by removing misidentified species and correct species names according to FishBase.

3. It allows adding new eDNA data to previous one, by checking for duplicate and replace or not with new data if differences are detected. This step creates data versions.

4. Create clean user-based data subset.

## II. Extract eDNA gps tracks

This step associate to each spygen survey a gps track and convert it to a shapefile.

1. Associate to each spygen survey the closest gps waypoint at the survey date.

2. Associate to each waypoint the closest gps track at the survey date.

3. Convert gps track from point to a polygon as a shapefile.


## Code R

The workflow has been entirely coded in R language and tried to use as much as possible base R codes.

Required dependencies can be found in the **DESCRIPTION** file and can be installed and load with the flowing function :

```ruby
## Install required package ----
devtools::install_deps(upgrade = "never")
```

The repository is structured as follow:

- `data/` : contains raw spygen eDNA and gps data
- `R/` : contains all functions.
- `analyses/` : contains scripts to load data and run `R/` functions
- `outputs/` : contains all results



