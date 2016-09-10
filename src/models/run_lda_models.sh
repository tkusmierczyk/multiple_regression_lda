#!/bin/sh


echo "RUNS LDA MODELS (FOR DEBUG PURPOSES)"
echo "ARGS: INPUT DATA, K (NUM FOLDS)"


INPUT="../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv"
if [ ! -z "$1" ]; then
INPUT=$1
fi
echo "INPUT = $INPUT"


K=-5
if [ ! -z "$2" ]; then
K=$2
fi
echo "K (NUM FOLDS) = $K"


OUTPUTS="kcal,fat,carbohydrates,proteins,sugars,sodium,cholesterol"
if [ ! -z "$3" ]; then
OUTPUTS=$3
fi
echo "OUTPUTS = $OUTPUTS"

set -e -x #exit if any failure

###################################################################################################

code_break () { 
  set +x -e
  echo "******************************************************************************"
  echo "******************************************************************************"
  echo "******************************************************************************"
  echo "******************************************************************************"
  set -x -e
}

TIME=`date`
echo "START @ $TIME"

code_break


sh run_model.sh $INPUT auto $K "Rscript lda_jags1pred_notest.R" "fat 3 50 10 10 median" 


Rscript lda_jagsMcluster.R $INPUT $OUTPUTS 3 50 10 10 median "lda_regg.bugs"
code_break

Rscript lda_jagsMcluster.R $INPUT $OUTPUTS 3 50 10 10 median 
code_break


sh run_model.sh $INPUT auto $K "Rscript lda_jagsMpred.R" "3 50 10 10 median" 
code_break

sh run_model.sh $INPUT auto $K "Rscript lda_jagsMpred.R" "3 50 10 10 median $OUTPUTS lda_regg.bugs" 
code_break


sh run_model.sh $INPUT auto $K "Rscript lda_jagsM1pred.R" "fat 3 50 10 10 median" 
code_break

sh run_model.sh $INPUT auto $K "Rscript lda_jagsM1pred.R" "fat 3 50 10 10 median lda_regg.bugs" 
code_break


sh run_model.sh $INPUT auto $K "Rscript lda_jagsMx1pred.R" "fat 3 50 10 10 median" 
code_break

sh run_model.sh $INPUT auto $K "Rscript lda_jagsMx1pred.R" "fat 3 50 10 10 median lda_regg.bugs" 
code_break


sh run_model.sh $INPUT auto $K "Rscript lda_jags1pred.R" "fat 3 50 10 10 median" 
code_break

sh run_model.sh $INPUT auto $K "Rscript lda_jags1pred.R" "fat 3 50 10 10 median lda_reg1g.bugs" 
code_break



###############################################################

TIME=`date`
echo "DONE @ $TIME."

exit

###############################################################





