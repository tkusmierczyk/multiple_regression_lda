#!/bin/sh


echo "RUNS THE BASELINE: LM"
echo "ARGS: INPUT DATA, OUTPUT PREDICTIONS PATH, NUMBER OF FOLDS (K)"

. ./../models_common/run_params.sh

set -e #exit if any failure

###############################################################################


TRAIN=/tmp/train_random_$$.tsv 
TEST=/tmp/test_random_$$.tsv
PREDICT=/tmp/predict_random_$$.tsv

rm -f $OUTPUT #remove output if already exists
NITER=$(($K>1?$K:1))
for fold in `seq 1 $NITER`
do
    echo "#########FOLD $fold/$NITER################"
    python ../evaluation/kfold_csv_split.py $INPUT $fold $K $TRAIN $TEST
    Rscript predict_random.R  $TRAIN  $TEST  $PREDICT
    sh ../base/append_predictions.sh $TEST $PREDICT $OUTPUT
    echo "###############################"
done;
#rm $TRAIN $TEST $PREDICT

echo "#########################################"
Rscript ../evaluation/evaluate.R $INPUT $OUTPUT




