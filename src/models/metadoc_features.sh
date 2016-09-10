#!/bin/sh

echo ">>> Calculates MetaDoc Features: semantic embeddings"
echo "Args: INPUT1 DATA1, INPUT1 DATA2, OUTPUT1 FEATURES PATH1, OUTPUT1 FEATURES PATH2, METADOC DIRECTORY"


if [ ! -z "$1" ]; then
    INPUT1=$1
else
    echo "ARG EXPECTED: TRAIN"
    exit 1
fi

if [ ! -z "$2" ]; then
    INPUT2=$2
else
    echo "ARG EXPECTED: TEST"
    exit 1
fi


DIR1=`dirname $INPUT1`
OUTPUT1=$DIR1/train_features.tsv
if [ ! -z "$3" ]; then
    OUTPUT1=$3
fi

DIR2=`dirname $INPUT2`
OUTPUT2=$DIR2/test_features.tsv
if [ ! -z "$4" ]; then
    OUTPUT2=$4
fi

METHOD="gl"
if [ ! -z "$5" ]; then
    METHOD=$5
fi

NUMTOPICS="10"
if [ ! -z "$6" ]; then
    NUMTOPICS=$6
fi

. ../base/config.sh
if [ ! -z "$7" ]; then
    METADOCDIR=$7
fi


echo "INPUT1 = $INPUT1"
echo "INPUT2 = $INPUT2"
echo "OUTPUT1 = $OUTPUT1"
echo "OUTPUT2 = $OUTPUT2"

echo "SEMANTIC METHOD = $METHOD"
echo "NUMTOPICS = $NUMTOPICS"
echo "METADOCDIR = $METADOCDIR"

MD="python $METADOCDIR/metadoc.py"

set -e #exit if any failure
set +o xtrace -e

if [ ! -d "$METADOCDIR" ]; then
    echo ">>> metadoc dir  $METADOCDIR not found. cloning."
    git clone https://github.com/tkusmierczyk/metadocument-processor $METADOCDIR
fi


echo "--------------------------------------------------------------------"
# temporary files management

DST1="/tmp/dst1_$$"
SRC1="/tmp/src1_$$"
DST2="/tmp/dst2_$$"
SRC2="/tmp/src2_$$"

echo "TMP FILES: DST1=$DST1 SRC1=$SRC1 DST2=$DST2 SRC2=$SRC2"

replace_in_out () { 
    echo "moving src <-> dst"
    mv $DST1 $SRC1
    mv $DST2 $SRC2
}

echo "--------------------------------------------------------------------"
# source files prerparation

echo "[*] conversion"
python $METADOCDIR/csv2zbl.py < $INPUT1 > $SRC1
python $METADOCDIR/csv2zbl.py < $INPUT2 > $SRC2

$MD cf title ti < $SRC1 > $DST1
$MD cf title ti < $SRC2 > $DST2
replace_in_out

echo "--------------------------------------------------------------------"
# features calculation

#echo "[*] filtering, stop words removal, stemming"
#$MD fta ti < $SRC1 | $MD ft ti | $MD s standard ti | $MD s2 porter ti > $DST1
#$MD fta ti < $SRC2 | $MD ft ti | $MD s standard ti | $MD s2 porter ti > $DST2
#replace_in_out

echo "[*] counting words"
DICT=/tmp/gensim_dict_$$.pickle
$MD gd ti an $DICT 0 < $SRC1 
$MD gm ti an $DICT < $SRC1 > $DST1
$MD gm ti an $DICT < $SRC2 > $DST2
replace_in_out

#echo "[*] tfidf mapping"
#$MD gt < $SRC1 
#$MD gt2 < $SRC1 > $DST1
#$MD gt2 < $SRC2 > $DST2
$MD mf g0 g1 < $SRC1 > $DST1
$MD mf g0 g1 < $SRC2 > $DST2
replace_in_out

echo "[*] semantic mapping"
SEMDICT=/tmp/gensim_semantic_model_$$.pickle
$MD $METHOD $NUMTOPICS g1 $DICT $SEMDICT < $SRC1 
$MD gsm g1 g2 $SEMDICT < $SRC1 > $DST1
$MD gsm g1 g2 $SEMDICT < $SRC2 > $DST2
head -n10 /tmp/gensim_semantic_model_topics.txt 
replace_in_out

echo "--------------------------------------------------------------------"
# features export

echo "[*] exporting to $OUTPUT1 and $OUTPUT2"
head -n 20 $SRC1
python $METADOCDIR/zblfield2csv.py g2 < $SRC1 > $OUTPUT1
python $METADOCDIR/zblfield2csv.py g2 < $SRC2 > $OUTPUT2

echo "--------------------------------------------------------------------"
# cleaning

#rm $SRC1 $SRC2 

