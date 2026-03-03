# Setup a baseline for spygen eDNA data

This repository create a baseline to analyse spygen eDNA data.

The workflow is separated into two different steps :

## 1. Clean eDNA data

This step convert raw spygen eDNA data into a format suitable for analysis.

First, raw spygen eDNA data are converted to site X species matrix and species identified multiple times are summed and summarize into one column.

Second, the site X species matrix is cleaned by removing misidentified species and correct species names according to FishBase.

Third, it allows adding new eDNA data to previous one, by checking for duplicate and replace or not with new data if differences are detected. This step creates data versions.

Finally, this step allow to create clean user-based data subset.

## 2. Extract eDNA gps tracks

This step associate to each spygen survey a gps track and convert it to a shapefile.

First, it associate to each spygen survey the closest gps waypoint at the survey date.

Second, it associate to each waypoint the closest gps track at the survey date.

Third, it convert gps track from point to a polygon as a shapefile.



