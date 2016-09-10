#!/bin/sh


echo "EXPORTS TOPICS AND LM-WEIGHTS FROM JAGS SAMPLES (*.RData)"
echo "ARGS: INPUT DIRECTORY, WORDS FILE, MAX NUM PROCESSES"

######################################################################

if [ ! -z "$1" ]; then
    INPUT=$1
else
    echo "ARG REQUIRED: DIRECTORY WITH *samples*RData FILES"
    exit 1
fi
echo "INPUT = $INPUT"

if [ ! -z "$2" ]; then
    WORDS=$2
else
    echo "ARG REQUIRED: *words*.RData FILE"
    exit 1
fi
echo "WORDS = $WORDS"

K=2
if [ ! -z "$3" ]; then
K=$3
fi
echo "NUM PROCESSES = $K"

set -x 

######################################################################

for INF in `ls $INPUT/samples*.RData`
do
    FNAME=`basename $INF`
    echo "PROCESSING $FNAME"

    OUTLM="$INPUT/$FNAME-lmweights.tsv"
    echo " $INF => $OUTLM"
    Rscript ../postprocessing/samples2lmweights.R $INF $OUTLM &
    sh ../base/numproc.sh $K R

    OUTI="$INPUT/$FNAME-intercepts.tsv"
    echo " $INF => $OUTI"
    Rscript ../postprocessing/samples2intercepts.R $INF $OUTI &
    sh ../base/numproc.sh $K R

    OUTTOPICS="$INPUT/$FNAME-topics.tsv"
    echo " $INF => $OUTTOPICS"
    Rscript ../postprocessing/samples2topics.R $INF $WORDS $OUTTOPICS &
    sh ../base/numproc.sh $K R
done

wait


