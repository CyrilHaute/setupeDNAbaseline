
convert_to_matrix_function <- function(raw_spygen_path){
  
  # Load raw spygen data
  raw_data <- readxl::read_xlsx(raw_spygen_path, col_names = FALSE)
  
  
  # Find row and column containing "SPY" 

  row_spy <- which(sapply(1:nrow(raw_data), function(i) { any(grepl("SPY", raw_data[i,])) }))

  col_spy <- which(grepl("SPY", raw_data[row_spy,]))
  
  
  # Flip the dataframe and select select spygen_code column
  
  data_fliped <- data.frame(t(raw_data))
  
  data_spygen <- data_fliped[,row_spy:ncol(data_fliped)]
  
  
  # Find row and column containing "scientific_name" 
  
  col_sn <- which(sapply(1:ncol(data_spygen), function(i) { any(grepl("scientific_name", data_spygen[,i])) }))
  
  row_sn <- which(grepl("scientific_name", data_spygen[,col_sn]))
  
  # Rename column by species (first column is spygen code)
  colnames(data_spygen) <- data_spygen[row_sn,]
  
  # Remove unnecessary rows
  data_clean1 <- data_spygen[col_spy,]
  
  colnames(data_clean1)[which(colnames(data_clean1) == "scientific_name")] <- "nb"

  colnames(data_clean1)[1] <- "spygen_code"

  data_clean1[,!colnames(data_clean1) %in% c("spygen_code", "nb")] <- sapply(data_clean1[,!colnames(data_clean1) %in% c("spygen_code", "nb")], as.numeric)
  
  data_clean1[is.na(data_clean1)] <- 0
  
  if(any(is.na(colnames(data_clean1))) == TRUE) {
    
    data_clean1 <- data_clean1[-which(is.na(colnames(data_clean1)))]
    
  }else{
    
    data_clean1 <- data_clean1
    
  }

  
  # Make the sum of species identified multiple times

  # Select numeric columns
  num_cols <- sapply(data_clean1, is.numeric)
  
  data_clean1_num  <- data_clean1[, num_cols]
  data_clean1_meta <-  data_clean1[!num_cols]

  # Species names without .1, .2, .3, etc.
  base_names <- sub("\\.[0-9]+$", "", names(data_clean1_num))

  # Sum columns with the same names
  data_num_sum <- lapply(1:length(unique(base_names)), function(i) {
      
      sp_sp <- data.frame(species = rowSums(data_clean1_num[ base_names == unique(base_names)[i]], na.rm = TRUE))
      
      colnames(sp_sp) <- unique(base_names)[i]
      
      return(sp_sp)

    })
  data_num_sum_bind <- do.call(cbind, data_num_sum)

  # Bind metadata and species
  data_all_sum <- cbind(data_clean1_meta, data_num_sum)
  
  # END

}


species_clean_function <- function(spygen_matrix) {
  
  species_names <- colnames(spygen_matrix)
  species_names <- species_names[! species_names %in% c("spygen_code", "nb")]
  
  # Filter misidentification

  bad_mask <- species_names[unique(c(which(is.na(species_names)), # Missing
                                     which(species_names == ""), # Empty
                                     which(grepl("dae", species_names, ignore.case = TRUE)), # Families
                                     which(grepl("_", species_names)), # _
                                     which(sapply(strsplit(species_names, "[ _]"), length) != 2), # Only one token (no space or underscore)
                                     which(grepl("spp.", species_names)), # spp.
                                     which(grepl("sp\\.", species_names)), # sp
                                     which(grepl("\\(cf\\)", species_names)), # (cf)
                                     which(grepl("hybrid", species_names)), # hybrid
                                     which(grepl("Unidentified", species_names)), # Unidentified
                                     which(grepl("\\?", species_names)), # ?
                                     which(grepl("\\!", species_names)), # !
                                     which(grepl("\\/", species_names)), # /
                                     which(grepl("New", species_names)) # New
  ))]

  # Remove problematic taxon rows from raw data
  spygen_clean <- spygen_matrix[!colnames(spygen_matrix) %in% bad_mask]
  
  # Check names from fishbase
  spygen_clean_species <- colnames(spygen_clean)
  spygen_clean_species_names <- spygen_clean_species[! spygen_clean_species %in% c("spygen_code", "nb")]
  
  validname <- rfishbase::validate_names(spygen_clean_species_names)
  
  remove_genus <- grep("Genus Species", validname)
  
  if(length(remove_genus) == 0) {
    
    validname_clean <- validname
    
  }else{
    
    validname_clean <- validname[-remove_genus]
    
  }
  
  old_spygen_name <- spygen_clean
  
  colnames(spygen_clean)[! colnames(spygen_clean) %in% c("spygen_code", "nb")] <- validname_clean
  
  
  # Sort species name by alphabethic order
  
  # old_spygen_name <- old_spygen_name[, c("spygen_code", sort(setdiff(names(old_spygen_name), "spygen_code")))]
  # 
  # spygen_clean <- spygen_clean[, c("spygen_code", sort(setdiff(names(spygen_clean), "spygen_code")))]

  to_return <- list(spygen_clean, old_spygen_name, bad_mask)
  names(to_return) <- c("spygen_matrix_clean", "spygen_matrix_old", "removed_species")
  
  return(to_return)
  
  # END
  
}
