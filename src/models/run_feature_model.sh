#!/bin/sh


echo "RUNS FEATURES BASELINE"
echo "ARGS: INPUT DATA, [OUTPUT PREDICTIONS PATH], [NUMBER OF FOLDS (K)], ['FEATURESGENERATOR'], ['PREDICTOR'], ['FGEN_PARAMS'], ['PREDICTOR_PARAMS']"

. ./../models_common/run_params.sh

FEATURESGENERATOR="sh metadoc_features.sh"
if [ ! -z "$4" ]; then
    FEATURESGENERATOR=$4
fi
echo "FEATURESGENERATOR = '$FEATURESGENERATOR'"


PREDICTOR="Rscript predict_lm.R"
if [ ! -z "$5" ]; then
    PREDICTOR=$5
fi
echo "PREDICTOR = '$PREDICTOR'"


FGEN_PARAMS=""
if [ ! -z "$6" ]; then
    FGEN_PARAMS=$6
fi
echo "FGEN_PARAMS = '$FGEN_PARAMS'"


PREDICTOR_PARAMS=""
if [ ! -z "$7" ]; then
    PREDICTOR_PARAMS=$7
fi
echo "PREDICTOR_PARAMS = '$PREDICTOR_PARAMS'"

set -e #exit if any failure

###############################################################################


TRAIN=/tmp/train_$$.tsv 
TRAINFEATURES=/tmp/train_features_$$.tsv 
TEST=/tmp/test_$$.tsv
TESTFEATURES=/tmp/test_features_$$.tsv
PREDICT=/tmp/predictions_$$.tsv

rm -f $OUTPUT #remove output if already exists
NITER=$(($K>1?$K:1))
for fold in `seq 1 $NITER`
do
    echo "#########FOLD $fold/$NITER################"

    echo ">>> TRAIN/TEST SPLIT:"
    python ../evaluation/kfold_csv_split.py $INPUT $fold $K $TRAIN $TEST

    echo ">>> GENERATING FEATURES:"
    $FEATURESGENERATOR $TRAIN $TEST $TRAINFEATURES $TESTFEATURES $FGEN_PARAMS 2>&1 

    echo ">>> PREDICTING:"
    $PREDICTOR $TRAIN  $TRAINFEATURES $TEST $TESTFEATURES $PREDICT $PREDICTOR_PARAMS 2>&1

    echo ">>> APPENDING PREDICTIONS:"
    sh ../base/append_predictions.sh $TEST $PREDICT $OUTPUT

    echo "###############################"
done;
#rm $TRAIN $TEST $PREDICT

echo ">>> EVALUATING:"
Rscript ../evaluation/evaluate.R $INPUT $OUTPUT


