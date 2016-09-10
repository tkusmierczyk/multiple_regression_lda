#!/bin/sh


echo "RUNS ALL MODELS"
echo "ARGS: INPUT DATA, K (NUM FOLDS)"


INPUT=../../data/allrecipes.tsv
if [ ! -z "$1" ]; then
    INPUT=$1
fi
echo "INPUT = $INPUT"


K=10
if [ ! -z "$2" ]; then
    K=$2
fi
echo "K (NUM FOLDS) = $K"

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

#trivial baselines
sh run_baseline_random.sh $INPUT auto $K
code_break
sh run_model.sh $INPUT auto $K "Rscript predict_mean.R"
code_break
sh run_model.sh $INPUT auto $K "python predict_knn.py" "7"
code_break
sh run_model.sh $INPUT auto $K "python predict_knn.py" "21"
code_break

#lm baselines
sh run_feature_model.sh $INPUT auto $K "Rscript family_features.R" "Rscript predict_lm.R"
code_break
sh run_feature_model.sh $INPUT auto $K "Rscript family_features_binary.R" "Rscript predict_lm.R"
code_break
sh run_feature_model.sh $INPUT auto $K "sh metadoc_word_counts.sh" "Rscript predict_lm.R"
code_break
sh run_feature_model.sh $INPUT auto $K "sh metadoc_features.sh" "Rscript predict_lm.R"
code_break

#gbm baselines
sh run_feature_model.sh $INPUT auto $K "sh metadoc_word_counts.sh" "Rscript predict_gbm.R" 
code_break
sh run_feature_model.sh $INPUT auto $K "sh metadoc_features.sh" "Rscript predict_gbm.R"
code_break

#rf baselines
sh run_feature_model.sh $INPUT auto $K "sh metadoc_word_counts.sh" "Rscript predict_rf.R"
code_break
sh run_feature_model.sh $INPUT auto $K "sh metadoc_features.sh" "Rscript predict_rf.R" 
code_break

#jags baselines
sh run_feature_model.sh $INPUT auto $K "Rscript lda_jags0.R" "Rscript predict_lm.R" "10 500 100"
code_break

###############################################################

TIME=`date`
echo "DONE @ $TIME."

exit

###############################################################

sh run_feature_model.sh $INPUT auto $K "sh metadoc_word_counts.sh" "Rscript predict_gbm.R" "" "n.trees=1000,shrinkage=0.05,cv.folds=5,interaction.depth=4,n.minobsinnode=5;n.trees=1000"
code_break

sh run_feature_model.sh $INPUT auto $K "sh metadoc_features.sh" "Rscript predict_gbm.R" "" "n.trees=1000,shrinkage=0.05,cv.folds=5,interaction.depth=4,n.minobsinnode=5;n.trees=1000"
code_break






