#!/bin/sh

echo "The script prepares data sets"

set -e -x #exit if any failure

echo "###############################################################################"

echo "[allrecipes.com]"
gunzip ../../data/raw/list_of_recipesprofiles.txt.gz

Rscript extract_allrecipes.R ../../data/raw/list_of_recipesprofiles.txt ../../data/allrecipes.tsv

Rscript filtering_nutrients.R ../../data/allrecipes.tsv ../../data/allrecipes.tsv
#Rscript text_preprocessing.R ../../data/allrecipes.tsv ../../data/allrecipes.tsv english
sh text_preprocessing.sh ../../data/allrecipes.tsv ../../data/allrecipes.tsv

cut -f 9 ../../data/allrecipes.tsv > ../../data/allrecipes_titles.tsv
python extract_families.py ../../data/allrecipes.tsv ../../data/allrecipes_family_features.tsv 2
Rscript family_subset.R ../../data/allrecipes.tsv ../../data/allrecipes_family_features.tsv cake,muffin,cheesecak,sweet_potato,salsa,caramel,burger ../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv

gzip ../../data/raw/list_of_recipesprofiles.txt

echo "###############################################################################"

#echo "[kochbar.de]"
#gunzip ../../data/raw/kochbar.tsv.gz
#Rscript filtering_nutrients.R ../../data/raw/kochbar.tsv ../../data/kochbar.tsv
#Rscript text_preprocessing.R ../../data/kochbar.tsv ../../data/kochbar.tsv german
#echo "TODO: text_preprocessing.sh for kochbar.de"
#gzip ../../data/raw/kochbar.tsv
 

