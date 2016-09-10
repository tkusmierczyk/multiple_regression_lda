#!/usr/bin/python
# -*- coding: utf-8 -*-
""" Predicts outputs using knn.
"""

import sys
import pandas as pd
import codecs
from collections import Counter
import numpy
import math

import sys

sys.path.append("../")

from base.config import outputs

###################################################################################################


def build_texts_index(texts):
    print "Putting %i texts into index" % len(texts)
    print " sample texts: %s" % str(list(texts)[:10])
    word2ixs = dict()
    for i, text in enumerate(texts):
        for word in text.strip().split(" "):
            word2ixs.setdefault(word, set()).add(i)
    return word2ixs


def cos(obj2count1, obj2count2):
    a = math.sqrt( sum( map(lambda v: v*v, obj2count1.values()) ) )
    b = math.sqrt( sum( map(lambda v: v*v, obj2count2.values()) ) )
    ab = sum( map(lambda k: obj2count1.get(k, 0)*obj2count2.get(k, 0), obj2count1.keys()) )
    if ab==0.0: return 0.0
    return float(ab) / (a * b)
    
    
def cos2(objs1, objs2):
    obj2count1 = Counter(objs1)
    obj2count2 = Counter(objs2)
    return cos(obj2count1, obj2count2)


def cos_words(txt1, txt2):
    words1 = txt1.split(" ")
    words2 = txt2.split(" ")
    #words1 = map(lambda w: w.strip(), txt1.split(" "))
    #words2 = map(lambda w: w.strip(), txt2.split(" "))
    return cos2(words1, words2)


def extract_neighbors(train_texts, test_texts, k=5, sim=cos_words):
    word2ixs = build_texts_index(map(str, train_texts))
    test_neighbors = []
    for progress, test_text in enumerate(test_texts):
        if progress%1000==0: print "%i/%i..." % (progress, len(test_texts))
        candidates = set(i for word in test_text.strip().split(" ") 
                                for i in word2ixs.get(word, []))        
        #print test_text, "=>", ", ".join(train_texts[candidate_ix] for candidate_ix in candidates)
        neighbors = sorted(((sim(test_text, train_texts[ix]), ix) for ix in candidates), reverse=True)[:k]
        #print test_text, "=>", ", ".join(map(str, neighbors))
        test_neighbors.append(neighbors)
    return test_neighbors


def predict(train_y, test_neighbors):
    mean_y = float(sum(train_y)) / len(train_y)

    predictions = []
    for neighbors in test_neighbors:
        denom = sum(sim for sim, ix in neighbors)
        nom = sum(sim*train_y[ix] for sim, ix in neighbors)
        if denom==0:
            predictions.append(mean_y)
        else:
            predictions.append(float(nom) / denom)

    return predictions


if __name__=="__main__":
    
    print ">>> Predicts nutrient facts using knn."
    print "Args: input tsv file (must have column 'title'), [output path], [recipe title occurrence threshold]"
    
    train_path = "~/tmp/train_lm_8009.tsv"
    try:
        train_path = sys.argv[1]
    except:
        print "Arg expected: train input tsv file path (with a column 'title')"
        sys.exit(-1)

    test_path = "~/tmp/test_lm_8009.tsv"
    try:
        test_path = sys.argv[2]
    except:
        print "Arg expected: test input tsv file path (with a column 'title')"
        sys.exit(-1)
 
    predict_path = "/tmp/predict_path"
    try:
        predict_path = sys.argv[3]
    except:
        print "Arg expected: output tsv file path"
        sys.exit(-1)
 
    try:
        threshold = int(sys.argv[4])
    except:
        threshold = 5
        print "Argument k (number of neighbors) set to default: %i" % threshold

    try:
        outputs = sys.argv[5].split(",")
    except: 
        print "Argument outputs set to default: %s" % outputs
            
    #####################################################################################
    
    print "Reading from %s" % train_path
    train = pd.read_csv(train_path, sep="\t")
    print "shape =", train.shape
    train.head()

    print "Reading from %s" % test_path
    test = pd.read_csv(test_path, sep="\t")
    print "shape =", test.shape
    test.head()

    #####################################################################################
    
    test_neighbors = extract_neighbors(list(map(str,train["title"])), list(map(str,test["title"])), threshold)
    
    df = pd.DataFrame()
    for output in outputs:
        predictions = predict(list(train[output]), test_neighbors)
        s = pd.Series(predictions)
        df[output] = s
    
    #####################################################################################

    print "Writing %i to %s" % (df.shape[1], predict_path)
    df.to_csv(predict_path, sep='\t', header=True, index=False)


