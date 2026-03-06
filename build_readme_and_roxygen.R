#### Générer la documentation à partir de roxygen ####

devtools::document() # Cela va créer NAMESPACE

devtools::install()

# Ajout d'une licence
rcompendium::add_license(license = "GPL-2")

# Faire attention à avoir un nom de repo sans majuscule ni underscore

# Dans repo, créer un fichier _pkgdown.yml
# et ajouter : 

# url: https://cyrilhaute.github.io/setupeDNAbaseline/
#   
# output:
#   github_document:
#   toc: false

pkgdown::build_site() # Cela génère un dossier docs/

# Enlever la doc du .gitignore

# push sur github

# Sur GitHub :
#   
# Settings → Pages
# Source → Deploy from branch
# Branch → main
# Folder → /docs

#### Ajouter un beau README ####

# À la racine de ton projet :

usethis::use_readme_rmd() # Cela crée README.Rmd

# En haut du READM.Rmd écrire :
# ---
#   output: github_document
# ---

# Écrire le README

# Générer le README.md : à faire à chaque modification du README

rmarkdown::render("README.Rmd") # Cela crée README.md

pkgdown::build_site()

# push sur github