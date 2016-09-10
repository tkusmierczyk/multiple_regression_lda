#!/usr/bin/env python
# -*- coding: utf-8 -*-


import sys
import os.path


def validate_headers(header1, header2):
    if header1 is None and header2 is None:
        print "ERROR: none of the files exist!"
        sys.exit(-3)
    if header1 is None:
        header1 = header2
    if header2 is None:
        header2 = header1
    if header1 != header2:
        print "ERROR: Headers are not equal!"
        sys.exit(-2)
    return header1


def load(infile1):
    if not os.path.isfile(infile1):
        return [], None
    f = open(infile1)
    header = f.readline().strip("\n")
    lines = map(lambda l: l.strip("\n"), f.readlines())
    n = len(lines)
    f.close()
    print "%i rows [excluding header] loaded from %s" % (n, infile1)
    return lines, header


def store(lines, header, outfile):
    print "writing %i rows (+1 of header) to %s" % (len(lines), outfile)
    f = open(outfile, "w")
    f.write(header)
    f.write("\n")
    for line in lines:
        f.write(line)
        f.write("\n")
    f.close()


if __name__=="__main__":
    print ">>> Takes two CSV files with the same header and appends second to the first."
    print "Args: input file1, input file2."
    
    try:
        infile1 = sys.argv[1]
        infile2 = sys.argv[2]
    except:
        print "Args required: input file1, input file2"
        sys.exit(-1)
    
    
    lines1, header1 = load(infile1)
    lines2, header2 = load(infile2)
    
    header1 = validate_headers(header1, header2)

    store(lines1+lines2, header1, infile1)
    
    
    