
# raw_spygen_path <- "data/raw-data/Results_Med_2018-Oct2025.xlsx"

convert_to_matrix_function <- function(raw_spygen_path){
  
  # Load raw spygen data
  raw_data <- readxl::read_xlsx(raw_spygen_path, col_names = FALSE)
  
  # trouver la ligne qui contient "SPY" 

  row_spy <- which(sapply(1:nrow(raw_data), function(i) { any(grepl("SPY", raw_data[i,])) }))

  col_spy <- which(grepl("SPY", raw_data[row_spy,]))
  
  data_fliped <- data.frame(t(raw_data))
  
  data_spygen <- data_fliped[,row_spy:ncol(data_fliped)]
  
  # trouver la ligne qui contient "scientific_name" 
  
  col_sn <- which(sapply(1:ncol(data_spygen), function(i) { any(grepl("scientific_name", data_spygen[,i])) }))
  
  row_sn <- which(grepl("scientific_name", data_spygen[,col_sn]))
  
  colnames(data_spygen) <- data_spygen[row_sn,]
  
  data_clean1 <- data_spygen[col_spy,]
  
  data_clean1 <- data_clean1[-which(colnames(data_clean1) == "scientific_name")]
  
  colnames(data_clean1)[1] <- "spygen_code"

  data_clean1[,colnames(data_clean1) !=  "spygen_code"] <- sapply(data_clean1[,colnames(data_clean1) !=  "spygen_code"], as.numeric)
  
  data_clean1[is.na(data_clean1)] <- 0
  
  data_clean1 <- data_clean1[-which(grepl("NA", colnames(data_clean1)))]
  
  
  
  
  ## sommer tous els doublons avec .1, .2, .3 etc
  # identifier les colonnes numériques
  num_cols <- sapply(data_clean1, is.numeric)
  
  # pour les séparer des character et ainsi faire nos calculs sur les numeriques
  data_clean1_num  <- data_clean1[, num_cols]
  data_clean1_meta <-  data_clean1[!num_cols]

  # récupérer les noms de base des espèces (sans .1, .2, .3, etc.)
  base_names <- sub("\\.[0-9]+$", "", names(data_clean1_num))

  # sommer les colonnes ayant le même nom
  data_num_sum <- lapply(1:length(unique(base_names)), function(i) {
      
      sp_sp <- data.frame(species = rowSums(data_clean1_num[ base_names == unique(base_names)[i]], na.rm = TRUE))
      
      colnames(sp_sp) <- unique(base_names)[i]
      
      return(sp_sp)

    })
  data_num_sum_bind <- do.call(cbind, data_num_sum)

  # résultat final 
  data_all_sum <- cbind(data_clean1_meta, data_num_sum)

}


species_clean_function <- function(spygen_matrix) {
  
  species_names <- colnames(spygen_matrix)
  species_names <- species_names[! species_names %in% "spygen_code"]
  
  # ─────────────────────────────────────────────
  # ─── Identify and Remove Problematic Taxa ────
  # ─────────────────────────────────────────────
  
  # Define cleaning mask:
  # Remove:
  #  - Entries with only ONE word (e.g. "Mugilidae" or "Raja")
  #  - NA or empty entries
  #  - Complex detections with underscores (e.g. "C. heterurus_H. speculiger")
  # Keep:
  #  - Normal binomials (e.g. "Scomber scombrus")

  bad_mask <- species_names[unique(c(
    which(is.na(species_names)), # Missing
      which(species_names == ""), # Empty
      which(grepl("dae", species_names, ignore.case = TRUE)),  # Families
      which(grepl("_", species_names)),
      which(sapply(strsplit(species_names, "[ _]"), length) < 2) # Only one token (no space or underscore)
  ))]

  # Remove problematic taxon rows from raw data
  spygen_clean <- spygen_matrix[!colnames(spygen_matrix) %in% bad_mask]
}
