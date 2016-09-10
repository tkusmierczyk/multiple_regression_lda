#!/usr/bin/env python
# -*- coding: utf-8 -*-


import os
import sys
import random
from math import floor


def export_train_test(lines, header, test_path, train_path, indexes, test_fold, k=10):
    n = len(lines)
    ftest = open(test_path, "w")
    ftest.write(header)
    ftest.write("\n")
    print "writing test to %s" % ftest
    ftrain = open(train_path, "w")
    ftrain.write(header)
    ftrain.write("\n")
    print "writing train to %s" % ftrain
    perfold = int(floor(n / k)) + 1
    train, test = [], []
    for i in xrange(0, n):
        ix = indexes[i]
        line = lines[ix]
        fold = int(floor(i / perfold))
        if fold == test_fold - 1:
            ftest.write(line)
            ftest.write("\n")
            test.append(ix)
        else:
            ftrain.write(line)
            ftrain.write("\n")
            train.append(ix)
    
    print "test", len(test), ":", test[:10], "...", test[-10:]
    print "train", len(train), ":", train[:10], "...", train[-10:]
    print "covered:", len(set(range(0, n)).intersection(test + train))


def load(infile1):
    f = open(infile1)
    header = f.readline().strip("\n")
    lines = map(lambda l:l.strip("\n"), f.readlines())
    n = len(lines)
    f.close()
    print "%i rows [excluding header] loaded from %s" % (n, infile1)
    return lines, header


if __name__=="__main__":
    print ">>> Extracts 1-test-fold (k-1)-train-folds from training CSV file."
    print "Args: input file1, test fold number [1,2,...,k], k [opt, default=10], train path [opt], test path [opt]."
    print "Use k to split into two files: test one of size 1/|k| and train composed of the rest."
  
    try: 
        k = int(sys.argv[3])     
    except: 
        k = 10
    k = abs(k)
    k = max(k, 2)

    try:
        infile1 = sys.argv[1]
        test_fold = int(sys.argv[2])
    except:
        print "Args required: input file1, test fold number"
        sys.exit(-1)

    print "k = %i" % k
    if test_fold<1 or test_fold>k:
        print "Fold number must be within the range [1, k]."
        sys.exit(-2)
    print "test_fold number = %i" % test_fold

    try:
        train_path = sys.argv[4]
        test_path = sys.argv[5]
    except:
        base_dir = os.path.dirname(os.path.abspath(infile1))
        test_path = "%s/test.tsv" % base_dir
        train_path = "%s/train.tsv" % base_dir
    print "test_path = %s" % test_path
    print "train_path = %s" % train_path
        
    
    ###########################################################################
    
    print "loading from %s" % infile1
    lines, header = load(infile1)

    print "shuffling"
    random.seed(123)
    indexes = range(0, len(lines))
    random.shuffle(indexes)
    
    print "storing"
    export_train_test(lines, header, test_path, train_path, indexes, test_fold, k)


    
