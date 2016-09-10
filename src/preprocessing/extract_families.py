#!/usr/bin/python
# -*- coding: utf-8 -*-
"""A manipulation of recipe titles to identify title_families. 
A family of recipes is a set of recipes describing the same meal e.g., pizza, muffins. 
"""

import sys
import pandas as pd
import codecs
from collections import Counter
import numpy
from itertools import izip

def log_info(txt):
    print txt
    
def log_dbg(txt):
    print txt
    

def preview_obj(val, size=100):
    size = max(size, 10)
    if val is None: return "None"
    val = unicode(val)
    if len(val)>size:
        val = val[:size-3]+"..."
    return val.replace("u'","").replace("'","").replace('"','')


def preview_dict(key2val, size=10, val_size=100):
    if key2val is None: return "None"
    key2val = preview_obj( map(lambda kv: (kv[0],preview_obj(kv[1], val_size)), key2val.iteritems())[:size], 1000)
    return key2val.replace("u'","").replace("'","").replace('"','').strip("[").strip("]")


###################################################################################################


def calc_title2count(title):
    log_info("Counting title titles")
    title2count = dict()
    for title in title:
        title2count[title] = title2count.get(title, 0) + 1
    return title2count


def build_family_titles_index(family_titles):
    log_info("Putting %i family titles into index" % len(family_titles))
    log_dbg(" sample titles: %s" % str(list(family_titles)[:10]))
    word2families = dict()
    for family_title in family_titles:
        for title_word in family_title.strip().split(" "):
            word2families.setdefault(title_word, set()).add(family_title)
    return word2families


def identify_recipe_families(titles, min_recipe_titles_count=5):
    """Returns dictionary {single word recipe name: list of assigned recipes}.    """
    title2count = calc_title2count(titles) 
    log_dbg("title2count(%i) = %s" % (len(title2count), 
            preview_obj(sorted(title2count.iteritems(), key=lambda (t,c): -c))))
        
    family_titles = set(title for title, count  in title2count.iteritems() if count>=min_recipe_titles_count)
    log_dbg("family_titles(%i) = %s" % (len(family_titles), preview_obj(family_titles)))
    
    word2families = build_family_titles_index(family_titles)
    log_dbg("word2families = %s" % preview_dict(word2families))

    log_info("Matching longer titles to shorter ones (family titles)")
    family2recipes, matched = dict(), 0
    families_assignment = list()
    for no, title in enumerate(titles): 
        if no%50000 == 0: log_dbg("%i/%i (%i matched)..." % (no, len(titles), matched))
        
        title_families = set()    
        for title_word in title.split(" "):
            for family_title in word2families.get(title_word, list()):                     
                if family_title in title: #recipe title is more concrete than family title
                    family2recipes.setdefault(family_title, set()).add( (no, title) )
                    title_families.add(family_title)
                    matched += 1
                    if matched<30: log_dbg(" matching: %s -> %s" % (title, family_title))
        families_assignment.append(title_families)

    #print "Matching longer titles to shorter ones:"
    #family2recipes = dict()
    #for href, title in recipes:
    #    for word in title_text_clean(title).split():
    #        word = word.lower()
    #        if is_stopword(word):   continue
    #        if word not in family_titles:  continue
    #        family2recipes.setdefault(word, list()).append( (href, title) )

    return families_assignment, family2recipes


###################################################################################################


def store_key2list(key2list_list, col_names, 
                   value_formatter=lambda e: e, 
                   key_formatter=lambda e: e, valsep=", "):
    for key,lst in key2list_list:
        col_names.write("%s: %s\n" % (key_formatter(key), (valsep.join(value_formatter(e) for e in lst)) ) )
        
        
def jaccard_on_words(family_name, title):
    words1 = set(family_name.split())
    words2 = set(title.split())
    return len(words1.intersection(words2)) / float(len(words1.union(words2)))
    
        
def build_features_matrix(family2recipes, families_assignment, titles, sim=jaccard_on_words):
    family2col = dict((family, i) for i, family in enumerate(family2recipes.keys()))

    m = numpy.empty( (len(families_assignment), len(family2col)) )
    for r, (assigned_families, title) in enumerate(zip(families_assignment, titles)):
        #print title,"->",assigned_families
        for family in assigned_families:
            c = family2col[family]
            m[r, c] = sim(family, title)
    return m, family2col
    
    
def header_formatter(column, family_name):
    return family_name.replace("\t", "_").replace(" ", "_")


def export_family_features(out, features_matrix, family2col, hrefs, header_formatter=header_formatter):
    col2family = sorted( (c, f) for f, c in family2col.iteritems() )
    header = "\t".join( map(lambda (c,f): header_formatter(c, f), col2family) )
    #out.write(header)
    #out.write("\n")
    #for r in xrange(features_matrix.shape[0]):
    #    row = "\t".join(map(str, (features_matrix[r,c] for c in xrange(features_matrix.shape[1]))))
    #    out.write(row)
    #    out.write("\n")
    numpy.savetxt(out, features_matrix, fmt="%g", delimiter="\t", header=header, comments="")

    f = codecs.open(out, "r", "utf-8")
    lines = f.readlines()
    f.close()    
        
    lines = [l.strip() for l in lines if l.strip()!=""]
    hrefs = ["href"]+hrefs
    f = codecs.open(out, "w", "utf-8")
    for href, line in izip(hrefs, lines):
        f.write("%s\t%s\n" % (href, line))
    f.close()
    

###################################################################################################


        
if __name__=="__main__":
    
    print "Extracts food families from recipe titles."
    print "Args: input tsv file (must have columns 'title' & 'href'), [output path], [recipe title occurrence threshold]"
    
    try:
        ipath = sys.argv[1]
    except:
        print "Arg expected: input tsv file path (with a column 'title')"
        sys.exit(-1)
 
    try:
        opath = sys.argv[2]
    except:
        print "Second argument (output tsv file path) set to default"
        opath = ipath.replace(".tsv", "")+"_family_features.tsv"
 
    try:
        threshold = int(sys.argv[3])
    except:
        threshold = 2
        print "Third argument (recipe title occurrence threshold) set to default."
            
    #####################################################################################
    
    print "Reading from %s" % ipath
    d = pd.read_csv(ipath, sep="\t")
    titles = d["title"]
    titles = map(lambda t: str(t).lower(), titles)
    #print Counter(titles)["nan"]
    
    print "Identifying families (recipe title occurrence threshold set to %i)" % threshold
    families_assignment, family2recipes = identify_recipe_families(titles, min_recipe_titles_count=threshold)
    print "family2recipes(%i) = %s" % (len(family2recipes), preview_dict(family2recipes))
    of = codecs.open(opath.replace(".tsv", "")+"_family2recipes.txt", "w")
    store_key2list(family2recipes.items(), of, value_formatter=str)
    
    
    print "Building features matrix"
    features_matrix, family2col = build_features_matrix(family2recipes, families_assignment, titles)
    print features_matrix
    
    print "Exporting matrix %i x %i to %s" % (features_matrix.shape[0], features_matrix.shape[1], opath)
    export_family_features(opath, features_matrix, family2col, list(d["href"]))
    
    
    