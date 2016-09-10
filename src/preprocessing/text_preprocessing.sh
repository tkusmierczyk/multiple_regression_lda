#!/bin/sh

#!/bin/sh

echo ">>> Clean up text (title column)"
echo "Args: INPUT DATA, [OUTPUT], [METADOC DIRECTORY]"


if [ ! -z "$1" ]; then
    INPUT1=$1
else
    echo "ARG EXPECTED: TRAIN"
    exit 1
fi

DIR1=`dirname $INPUT1`
FILENAME=`basename $INPUT1`
OUTPUT1=$DIR1/clean_$FILENAME
if [ ! -z "$2" ]; then
    OUTPUT1=$2
fi


. ../base/config.sh
if [ ! -z "$3" ]; then
    METADOCDIR=$3
fi


echo "INPUT = $INPUT1"
echo "OUTPUT  = $OUTPUT1"
echo "METADOCDIR = $METADOCDIR"

MD="python $METADOCDIR/metadoc.py"

set -e #exit if any failure

echo "###############################################################################"
echo " temporary files management"

DST1="/tmp/tp_dst1_$$"
SRC1="/tmp/tp_src1_$$"

replace_in_out () { 
    echo "moving src <-> dst"
    mv $DST1 $SRC1
}

echo "##############################################################################"
echo " source files prerparation"

echo ">>> conversion"
python $METADOCDIR/csv2zbl.py < $INPUT1 > $SRC1

echo "###############################################################################"
echo " features calculation"

echo ">>> filtering, stop words removal, stemming, min occurrence filtering"
$MD cf title ti < $SRC1 | $MD cf title title.bak | $MD fta ti | $MD ft ti | $MD s standard ti | $MD s2 porter ti | $MD fmwc ti 2 ti | $MD mf ti title > $DST1
replace_in_out

echo "###############################################################################"
echo " features export"

echo ">>> exporting to $OUTPUT1"
python $METADOCDIR/zbl2csv.py -s TAB -sr " " -k href < $SRC1 > $OUTPUT1


echo "###############################################################################"
echo " cleaning"

rm $SRC1 



