#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import itertools


def merge_csv_files(infile1, infile2, outfile, separator="\t"):
    fin1 = open(infile1)
    fin2 = open(infile2)
    fout = open(outfile, "w")
    for i, (line1, line2) in enumerate(itertools.izip(fin1.xreadlines(), fin2.xreadlines())):
        if i % 10000 == 0:
            print "%i ..." % i
        line1 = line1.strip("\n")
        line2 = line2.strip("\n")
        fout.write(line1)
        fout.write(separator)
        fout.write(line2)
        fout.write("\n")
    
    print "%i lines merged" % (i + 1)
    fout.close()


if __name__=="__main__":
    print ">>> Merges two csv files line by line"
    print "Args: input file1, input file2, output file3, separator [opt]."

    try:
        infile1 = sys.argv[1]
        infile2 = sys.argv[2]
        outfile = sys.argv[3]
    except:
        print "Args required: input file1, input file2, output file3"
        sys.exit(-1)

    try: 
        separator = sys.argv[4]        
    except: 
        separator = "\t"
        
    ###########################################################################


    merge_csv_files(infile1, infile2, outfile, separator)
    
 
