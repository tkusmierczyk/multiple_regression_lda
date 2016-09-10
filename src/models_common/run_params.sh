#!/bin/sh

set -e #exit if any failure

INPUT=../../data/allrecipes.tsv
if [ ! -z "$1" ]; then
    INPUT=$1
fi

DIR=`dirname $INPUT`
FILENAME=`basename $INPUT`
OUTPUT=$DIR/predictions_random_$FILENAME
if [ ! -z "$2" ]; then
    OUTPUT=$2
fi

if [ $OUTPUT = "auto" ]; then
    DATE=`date +%Y%m%d_%H%M%S`
    OUTPUT="predictions_${DATE}_$$.tsv"
    echo "Automatic output selection: $OUTPUT"
fi


K=10
if [ ! -z "$3" ]; then
    K=$3
fi



echo "INPUT = $INPUT"
echo "DIR = $DIR"
echo "OUTPUT = $OUTPUT"
echo "NUM FOLDS (K) = $K"

set -e #exit if any failure
