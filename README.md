
# Setup a baseline for Spygen eDNA data

This repository provides a **user friendly** interface to create a
baseline to analyse [Spygen](https://www.spygen.com/fr/) **eDNA data**.
It guides users with one function per action to complete in a specific
order, all automatically.

## Installation

<<<<<<< HEAD
To clone the repository from [GitHub](https://github.com/), open R and
go to your Terminal or open directly a Terminal and do:
=======
You can clone the repository from [GitHub](https://github.com/) with:
>>>>>>> 06a9e421830b343862dc47a8a55aa044e58d7574

``` ruby
install.packages("devtools")

devtools::install_github("CyrilHaute/setupeDNAbaseline")
```

<<<<<<< HEAD
## <img src="Rlogo.png" width="28" style="vertical-align:-6px;"/> code

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

You can just follow the `analyses/` scripts to use the workflow.

The scripts and functions have been written as much as possible in base
R. For instance, we did not used the `tidyverse` library. However, we
used the R native pipe operator `|>`.

To use the R native pipe, follow the instructions:

- Click on R **Tools**;
- Then click on **Global Options**;
- Then click on **Code**;
- Check the box **Use native pipe operator, \|\> (requires R 4.1+)**.

By doing so, we don’t need to load any package from `tidyverse`.

Data can be accessible through
[marbec-data](https://marbec-data.ird.fr/#/signin).

The details of all functions used in the repository can be found here :
<https://cyrilhaute.github.io/setupeDNAbaseline/reference/index.html>

=======
>>>>>>> 06a9e421830b343862dc47a8a55aa044e58d7574
The workflow is separated into two different steps:

## I. Clean eDNA data

This step convert raw Spygen eDNA data into a format suitable for
analysis.

1.  The `convert_to_matrix` function convert raw Spygen eDNA data to
    **site X species** matrix. Species identified multiple times are
    summed and summarize into one column.

This function requires only one argument, the path to raw Spygen data
(in **.xlsx** format!) and return an **uncleaned** site X species matrix
:

``` ruby
spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "my/path/to/raw_eDNA_data.xlsx")
```

| spygen_code | nb | Dicentrarchus labrax | Chromis chromis | A_regius_U_cirrosa | Sciaena umbra |
|:---|:---|---:|---:|---:|---:|
| SPY180624 | nb_rep | 5 | 9 | 0 | 1 |
| SPY180624 | nb_seq | 7238 | 27013 | 0 | 220 |
| SPY181146 | nb_rep | 3 | 11 | 0 | 0 |
| SPY181146 | nb_seq | 3804 | 20232 | 0 | 0 |

<<<<<<< HEAD
As you can see, the function return a dataframe containing species not
spelled in the binomial format (e.g., **A_regius_U_cirrosa**).

2.  The `species_clean` function clean the site X species matrix by
    removing **misnamed species** (missing names, identified at the
    family level or as spp., sp., all species not spelled in the
    binomial format) and correct species names according to
=======
2.  The `species_clean` function clean the site X species matrix by
    removing **misnamed species** and correct species names according to
>>>>>>> 06a9e421830b343862dc47a8a55aa044e58d7574
    [FishBase](https://www.fishbase.se/search.php).

This function requires the **uncleaned site X species matrix** obtained
with the `convert_to_matrix` function.

It returns a list containing three objects :

- A dataframe in the format site X species with **new species names**
  checked from FishBase;

- A dataframe in the format site X species with **old species names**
  before checking from FishBase;

- A character vector listing all **removed species**.

<<<<<<< HEAD
This allows users to follow the cleaning steps and check which species
have been removed and which names have been corrected.
=======
By doing so, it allows users to follow the steps of cleaning and check
the removed species and which have been their names corrected.
>>>>>>> 06a9e421830b343862dc47a8a55aa044e58d7574

``` ruby
spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)
```
<<<<<<< HEAD

Here is the cleaned site X matrix dataframe with new species names
(`spygen_matrix_clean$spygen_matrix_clean`):
=======
>>>>>>> 06a9e421830b343862dc47a8a55aa044e58d7574

| spygen_code | nb | Dicentrarchus labrax | Chromis chromis | Sciaena umbra | Sphyraena viridensis |
|:---|:---|---:|---:|---:|---:|
| SPY180624 | nb_rep | 5 | 9 | 1 | 1 |
| SPY180624 | nb_seq | 7238 | 27013 | 220 | 155 |
| SPY181146 | nb_rep | 3 | 11 | 0 | 2 |
| SPY181146 | nb_seq | 3804 | 20232 | 0 | 152 |

For the next step, save as **.csv** the dataframe with new species names
called **spygen_matrix_clean**:

    write.csv(spygen_matrix_clean$spygen_matrix_clean, file = "my/path/to/outputs/spygen_matrix_clean.csv", row.names = FALSE)

3.  The `spygen_new_data` function allows adding **new eDNA data** to
    previous one, by checking for duplicate and replace or not with new
    data if differences are detected.

> \[!IMPORTANT\] To work properly, the function need to add the new
> Spygen data in the order they’ve been sent by Spygen!

This function requires the path of **old eDNA data** (in format
**.csv**) and the path of **new eDNA data** (in **.xlsx** format).

The function return a dataframe with new eDNA data.

    new_spygen_data <- spygen_new_data_function(old_spygen_data_path = "my/path/to/outputs/spygen_matrix_clean.csv",
                                                new_spygen_data_path = "my/path/to/new/raw_eDNA_data.xlsx",
                                                path_save = "my/path/to/outputs/new_spygen_data.csv")

By doing so, this function creates successively new eDNA files, allowing
to follow data and the reference database version.

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
> analysis with only basic cleaning step. This does not exempt users
> from checking the list of species returned by the functions (e.g.,
> **species detected outside their distribution range**).

## II. Extract eDNA gps tracks

This step associate to each Spygen survey a gps track and convert it to
a shapefile.

1.  Associate to each Spygen survey the closest **gps waypoint** at the
    survey date.

2.  Associate to each waypoint the closest **gps track** at the survey
    date.

3.  Convert gps track from point to a polygon as a **shapefile**.

## <img src="Rlogo.png" width="28" style="vertical-align:-6px;"/> code

The workflow has been entirely coded in ***R*** language and tried to
use as much as possible base R codes.

Required dependencies can be found in the `DESCRIPTION` file and can be
installed and load with the flowing function :

``` ruby
## Install required package ----
devtools::install_deps(upgrade = "never")
```

The repository is structured as follow:

- `data/` : contains raw Spygen eDNA and gps data;
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

The details of all functions used in the repository can be found here :
<https://cyrilhaute.github.io/setupeDNAbaseline/reference/index.html>
