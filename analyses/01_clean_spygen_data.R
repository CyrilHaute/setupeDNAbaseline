############################################################
#
# 01_clean_spygen_data.R: clean spygen eDNA raw data
#
############################################################

# Load required functions
source("R/01_clean_eDNA_functions.R")

# Set directory of raw eDNA data
dir.create("data")
dir.create("data/eDNA_raw_data")

# Set directory to save cleaned eDNA data
dir.create("outputs")
dir.create("outputs/01_clean_eDNA")
dir_save <- "outputs/01_clean_eDNA/"

# This function convert spygen raw data to a site X species matrix

spygen_matrix <- convert_to_matrix_function(raw_spygen_path = "data/eDNA_raw_data/1.Results_Med_2018-Oct2025.xlsx")

# This function remove misidentified species and check their names from FishBase

spygen_matrix_clean <- species_clean_function(spygen_matrix = spygen_matrix)
write.csv(spygen_matrix_clean$spygen_matrix_clean, file = paste0(dir_save, "1.spygen_2018_2025.csv"), row.names = FALSE)

# Check for changed species names 

which_diff <- which(!colnames(spygen_matrix_clean$spygen_matrix_clean) %in% colnames(spygen_matrix_clean$spygen_matrix_old))
colnames(spygen_matrix_clean$spygen_matrix_clean)[which_diff]
colnames(spygen_matrix_clean$spygen_matrix_old)[which_diff]


# This function allows adding new eDNA data to previous ones

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/1.spygen_2018_2025.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/2.Teleo_SC21076_DPH_15_08-12-2025.xlsx",
                         path_save = paste0(dir_save, "spygen1_2/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen1_2/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/3.Teleo_SC21076_DPH_15_12012026_V2.xlsx",
                         path_save = paste0(dir_save, "spygen2_3/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen2_3/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/4.Teleo_SC23148_AMS_Corse_25-10_12122025_complet.xlsx",
                         path_save = paste0(dir_save, "spygen3_4/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen3_4/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/5.Teleo_SC23148_AMS_Occ_25_14_021225.xlsx",
                         path_save = paste0(dir_save, "spygen4_5/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen4_5/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/6.Teleo_SC23148_AMS_Occ_25_14_130126-V2.xlsx",
                         path_save = paste0(dir_save, "spygen5_6/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen5_6/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/7.Teleo_SC23148_AMS_PACA_25_4_021225.xlsx",
                         path_save = paste0(dir_save, "spygen6_7/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen6_7/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/8.Teleo_SC23148_AMS_PACA_25_4_130126-V2.xlsx",
                         path_save = paste0(dir_save, "spygen7_8/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen7_8/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/9.Teleo_SC23148_Corse_25-11_09122025.xlsx",
                         path_save = paste0(dir_save, "spygen8_9/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen8_9/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/10.Teleo_SC23148_Corse_25-12_12012026_V1.xlsx",
                         path_save = paste0(dir_save, "spygen9_10/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen9_10/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/11.Teleo_SC23148_Occ_25-13_09122025.xlsx",
                         path_save = paste0(dir_save, "spygen10_11/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen10_11/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/12.Teleo_SC23161_VAMAHEAT_25_18_09122025.xlsx",
                         path_save = paste0(dir_save, "spygen11_12/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen11_12/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/13.Teleo_SC23161_Wamaheat_Lot 19_13012026.xlsx",
                         path_save = paste0(dir_save, "spygen12_13/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen12_13/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/14.Teleo_SC24359_SEA_25_5_10122025.xlsx",
                         path_save = paste0(dir_save, "spygen13_14/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen13_14/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/15.Teleo_SC24359_SEA_25_05_20012026_V2.xlsx",
                         path_save = paste0(dir_save, "spygen14_15/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen14_15/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/16.Teleo_SC25411_FishEdge-1_13012026_V1.xlsx",
                         path_save = paste0(dir_save, "spygen15_16/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen15_16/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/17.Teleo_SC25411_FED_25_1_30012026_V2.xlsx",
                         path_save = paste0(dir_save, "spygen16_17/"))

spygen_new_data_function(old_spygen_data_path = "outputs/01_clean_eDNA/spygen16_17/all.csv",
                         new_spygen_data_path = "data/eDNA_raw_data/18.Teleo_SC25317_DDF_25_1_11-12-2025.xlsx",
                         path_save = paste0(dir_save, "spygen17_18/"))


# This function create a subset of eDNA data (by spygen_code) and return only species present in the subset area

test <- read.csv("data/eDNA_raw_data/Med_metadonnees_ADNe - v1.2_2018-2025.csv", header = TRUE)
spain_test <- test[test$country == "Spain",]

subset_test <- spygen_subset_function(eDNA_species_data_path = "outputs/01_clean_eDNA/spygen17_18/occ.csv",
                                      spygen_code_subset = spain_test) # If spygen_code_subset is a dataframe
subset_test2 <- spygen_subset_function(eDNA_species_data_path = "outputs/01_clean_eDNA/spygen17_18/occ.csv",
                                       spygen_code_subset = spain_test$spygen_code) # If spygen_code_subset is a vector of character
