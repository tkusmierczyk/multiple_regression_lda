#!/bin/sh


echo ">>> Appends predictions"

if [ ! -z "$1" ]; then
    TEST=$1
else
    echo "ARG REQUIRED: TEST FILE PATH"
    exit 1
fi

if [ ! -z "$2" ]; then
    PRED=$2
else
    echo "ARG REQUIRED: PREDICTIONS FILE PATH"
    exit 1
fi

if [ ! -z "$3" ]; then
    OUTPUT=$3
else
    echo "ARG REQUIRED: OUTPUT FILE PATH (APPEND TO THIS FILE)"
    exit 1
fi

echo "test=$TEST"
echo "predictions=$PRED"
echo "output=$OUTPUT"

TFILE="/tmp/$(basename $0).$$.tmp"
PFILE="/tmp/$(basename $0).$$.p.tmp"
#echo "TFILE=$TFILE"
#echo "PFILE=$PFILE"

cut -f 1 $TEST > $TFILE
paste $TFILE $PRED > $PFILE
python ../base/append_csv.py $OUTPUT $PFILE

rm $TFILE
rm $PFILE

