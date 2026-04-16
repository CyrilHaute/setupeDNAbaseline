
# Setup a baseline for Spygen eDNA data

This repository provides a **user friendly** interface to create a
baseline to analyse [Spygen](https://www.spygen.com/fr/) **eDNA data**.
It guides users with one function per action to complete in a specific
order, all automatically.

## Installation

To clone the repository from [GitHub](https://github.com/), open R and
go to your Terminal or open directly a Terminal and do:

``` ruby
git clone https://github.com/CyrilHaute/setupeDNAbaseline
```

Required dependencies can be found in the `DESCRIPTION` file and can be
installed and load with the following function :

``` ruby
## Install devtools package ----
install.packages("devtools")

## Install required package ----
devtools::install_deps(upgrade = "never")
```

Otherwise, you can install it as a **R package**:

``` ruby
## Install devtools package ----
install.packages("devtools")

devtools::install_github("CyrilHaute/setupeDNAbaseline")
```

## <img src="Rlogo.png" width="28" style="vertical-align:-6px;"/> code

**You can just follow the `analyses/` scripts to use the workflow.**

The repository is structured as follow:

- `data/` : contains raw Spygen eDNA and gps data:
  - The `eDNA_raw_data/` file contain all eDNA raw data;
  - The `trace_gps/` file contain gps data.
- `R/` : contains all functions:
  - The *01_clean_eDNA_functions.R* script contain all functions for the
    **step I**;
  - The *02_extract_eDNA_tracks_functions.R* script contain all
    functions for the **step II**.
- `analyses/` : contains scripts to load data and run `R/` functions:
  - The *01_clean_spygen_data.R* script run and load script and data
    necessary for **step I**;
  - The *02_extract_eDNA_tracks.R* script run and load script and data
    necessary for **step II**.
- `outputs/` : contains all results:
  - The `01_clean_eDNA/` file contain all results from **step I**;
  - The `02_eDNA_tracks/` file contain all results from **step II**.

The scripts and functions have been written as much as possible in base
R. For instance, we did not used the `tidyverse` library. However, we
used the R native pipe operator `|>` instead of `%>%` that requires to
load `tidyverse`.

To use the R native pipe, follow the instructions:

- Click on R **Tools**;
- Then click on **Global Options**;
- Then click on **Code**;
- Check the box **Use native pipe operator, \|\> (requires R 4.1+)**.

Data can be accessible through
[marbec-data](https://marbec-data.ird.fr/#/signin).

The details of all functions used in the repository can be found here :
<https://cyrilhaute.github.io/setupeDNAbaseline/reference/index.html>

The workflow is separated into two different steps:

## I. Clean eDNA data

This step convert raw Spygen eDNA data into a format suitable for
analysis.

1.  The `convert_to_matrix` function convert raw Spygen eDNA data to
    **site X species** matrix. Species identified multiple times are
    summed and summarize into one column.

This function requires only one argument, the path to raw Spygen data
(in format **.xlsx**) and return an **uncleaned** site X species matrix
: It returns a list containing two objects :

- An **uncleaned** site X species matrix;

- A character of the **reference database** used.

``` ruby
spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "my/path/to/raw_eDNA_data.xlsx")
```

| spygen_code | nb | Dicentrarchus labrax | Chromis chromis | A_regius_U_cirrosa | Sciaena umbra |
|:---|:---|---:|---:|---:|---:|
| SPY180624 | nb_rep | 5 | 9 | 0 | 1 |
| SPY180624 | nb_seq | 7238 | 27013 | 0 | 220 |
| SPY181146 | nb_rep | 3 | 11 | 0 | 0 |
| SPY181146 | nb_seq | 3804 | 20232 | 0 | 0 |

As you can see, the function return a dataframe containing species not
spelled in the binomial format (e.g., **A_regius_U_cirrosa**).

2.  The `species_clean` function clean the site X species matrix by
    removing **misnamed species** (missing names, identified at the
    family level or as spp., sp., all species not spelled in the
    binomial format) and correct species names according to
    [FishBase](https://www.fishbase.se/search.php) or
    [WORMS](https://marinespecies.org/index.php) in case FishBase return
    NA.

This function requires the **uncleaned site X species matrix** obtained
with the `convert_to_matrix` function. You can also specify with the
**keep** argument, which type of species you want to keep even if not
spelled in the binominal format (but see the
[help](https://cyrilhaute.github.io/setupeDNAbaseline/reference/index.html)
of the function to know all type you can keep). By default, the function
remove all species not spelled in the binominal format.

It returns a list containing three objects :

- A dataframe in the format site X species with **new species names**
  checked from FishBase;

- A dataframe in the format site X species with **old species names**
  before checking from FishBase;

- A character vector listing all **removed species**.

This allows users to follow the cleaning steps and check which species
have been removed and which names have been corrected.

``` ruby
spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)

Or, in case you'd like to keep species identified at the family level, do:

spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix,
                                              keep = "Family")
```

Here is the cleaned site X matrix dataframe with new species names
(`spygen_matrix_clean$spygen_matrix_clean`):

| spygen_code | nb | Dicentrarchus labrax | Chromis chromis | Sciaena umbra | Sphyraena viridensis |
|:---|:---|---:|---:|---:|---:|
| SPY180624 | nb_rep | 5 | 9 | 1 | 1 |
| SPY180624 | nb_seq | 7238 | 27013 | 220 | 155 |
| SPY181146 | nb_rep | 3 | 11 | 0 | 2 |
| SPY181146 | nb_seq | 3804 | 20232 | 0 | 152 |

For the next step, save as **.csv** the dataframe with new species names
called **spygen_matrix_clean**:

``` ruby
write.csv(spygen_matrix_clean$spygen_matrix_clean, file = "my/path/to/outputs/spygen_matrix_clean.csv", row.names = FALSE)
```

3.  The `spygen_new_data` function allows adding **new eDNA data** to
    previous one, by checking for duplicate and replace or not with new
    data if differences are detected.

> \[!IMPORTANT\] To work properly, the function need to add the new
> Spygen data in the order they’ve been sent by Spygen!

This function requires the path of **old eDNA data** (in format
**.csv**), the path of **new eDNA data** (in **.xlsx** format) and the
**path** to save data. You can also specify the species you want to keep
in the new data with the **keep** argument, as in the
`species_clean_function`.

The function save new data at the indicated path.

    spygen_new_data_function(old_spygen_data_path = "my/path/to/outputs/spygen_matrix_clean.csv",
                             new_spygen_data_path = "my/path/to/new/raw_eDNA_data.xlsx",
                             path_save = "my/path/to/outputs/new_spygen_data.csv")
                             
    Or, in case you'd like to keep species identified at the family and spp. level, do:

    spygen_new_data_function(old_spygen_data_path = "my/path/to/outputs/spygen_matrix_clean.csv",
                             new_spygen_data_path = "my/path/to/new/raw_eDNA_data.xlsx",
                             keep = c("Family, "spp."),
                             path_save = "my/path/to/outputs/new_spygen_data.csv")

By doing so, this function creates successively new eDNA files, allowing
to follow data and the reference database version.

To load data created either with the `species_clean` or
`spygen_new_data` functions, do:

    read.csv("my/path/to/outputs/new_spygen_data.csv", header = TRUE, check.names = FALSE)

4.  The `spygen_subset` function is a user friendly function that create
    **subset** of eDNA data.

This function requires a path of **cleaned eDNA data** (in format
**.csv**) and a character vector of spygen code or a dataframe
containing a column **spygen_code**.

    subset_eDNA <- spygen_subset_function(eDNA_species_data_path = "my/path/to/outputs/spygen_matrix_clean.csv",
                                          spygen_code_subset = c("SPY180624", "SPY181146", "SPY181147"))

The function return a subset dataframe of eDNA data including only
species present in the subset.

> \[!CAUTION\] This step only convert data to a suitable format for
> analysis, with only basic cleaning step. This does not exempt users
> from checking the list of species returned by the functions (e.g.,
> **species detected outside their distribution range**).

## II. Extract eDNA gps tracks

This step associate to each Spygen survey a gps track and convert it to
a shapefile.

1.  The `load_waypoint` and `spygen_waypoint` functions associate to
    each Spygen survey the closest **gps waypoint** at the survey date.

The `load_waypoint` function requires only gps data path.

The `spygen_waypoint` function requires the path of Spygen metadata
(containing start and end coordinates), the waypoints data obtained with
the `load_waypoint` function, and a threshold indicating the maximum
distance in meters between the coordinates of a Spygen survey and the
coordinates of the nearest waypoint.

It returns a list containing three objects :

- A dataframe named **high distance** containing spygen survey with
  distance to the closest waypoints **greater** than the distance
  threshold;

- A dataframe named **good distance** containing spygen survey with
  distance to the closest waypoints **smaller** than the distance
  threshold;

- A dataframe named **na survey** containing spygen survey with **no
  attributed waypoints**.

``` ruby
waypoints <- load_waypoint(path = "data/trace_gps")

spygen_waypoint_output <- spygen_waypoint(eDNA_metadata_path = "data/metadata.csv",
                                          waypoints = waypoints,
                                          distance_threshold = 10,
                                          path_save = "path/to/save/data")
```

2.  The `load_tracks` and `spygen_tracks` functions associate to each
    waypoint the closest **gps track** at the survey date.

The `load_tracks` function requires only gps data path.

The `spygen_tracks` function requires the waypoints data obtained with
the `spygen_waypoint` function
(**spygen_waypoint_output\$good_distance**), and a threshold indicating
the maximum distance in meters between the coordinates of a Spygen
survey and the coordinates of the nearest track.

It returns the same thing as for the `spygen_waypoint` function, except
it’s for tracks.

``` ruby
gps_tracks <- load_tracks(path = "data/trace_gps")

spygen_tracks_output <- spygen_tracks(waypoints = spygen_waypoint_output$good_distance,
                                      gps_tracks = gps_tracks,
                                      distance_threshold = 10,
                                      path_save = "path/to/save/data")
```

3.  Finally, the `shapefile_tracks` function convert gps track from
    point to a polygon as a **shapefile**.

The function requires the tracks coordinates obtained with the
`spygen_tracks_output` function
(**spygen_tracks_output\$tracks_good_distance**).

``` ruby
shapefile_tracks(eDNA_tracks = spygen_tracks_output$tracks_good_distance,
                 path_save = "path/to/save/data")
```

It return a shapefile of Spygen tracks as follow (with green and red dot
representing waypoints start and end, respectively):

<img src="Rplot.png">

<img src="Rplot01.png">
