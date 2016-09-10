#!/bin/sh


echo "RUNS THE BASELINE: MEAN FROM TRAINING"
echo "ARGS: INPUT DATA, OUTPUT PREDICTIONS PATH, NUMBER OF FOLDS (K)"

. ./../models_common/run_params.sh


PREDICTOR="Rscript predict_mean.R"
if [ ! -z "$4" ]; then
    PREDICTOR=$4
fi
echo "PREDICTOR = '$PREDICTOR'"

PREDICTOR_PARAMS=""
if [ ! -z "$5" ]; then
    PREDICTOR_PARAMS=$5
fi
echo "PREDICTOR_PARAMS = '$PREDICTOR_PARAMS'"

set -e #exit if any failure

###############################################################################

TRAIN=/tmp/train_$$.tsv 
TEST=/tmp/test_$$.tsv
PREDICT=/tmp/predictions_$$.tsv

rm -f $OUTPUT #remove output if already exists
NITER=$(($K>1?$K:1))
for fold in `seq 1 $NITER`
do
    echo "#########FOLD $fold/$NITER################"

    echo ">>> TRAIN/TEST SPLIT:"
    python ../evaluation/kfold_csv_split.py $INPUT $fold $K $TRAIN $TEST

    echo ">>> PREDICTING:"
    $PREDICTOR $TRAIN $TEST $PREDICT $PREDICTOR_PARAMS 2>&1

    echo ">>> APPENDING PREDICTIONS:"
    sh ../base/append_predictions.sh $TEST $PREDICT $OUTPUT

    echo "###############################"
done;
#rm $TRAIN $TEST $PREDICT

echo ">>> EVALUATING:"
Rscript ../evaluation/evaluate.R $INPUT $OUTPUT

