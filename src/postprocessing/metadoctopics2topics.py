

import sys

if __name__=="__main__":
    
    f = sys.stdin
    out = sys.stdout
    
    lines = f.readlines()
    lines = map(lambda l: l.strip(), lines)
    lines = filter(lambda l: len(l)>0, lines)
    
    words = set()
    
    topicword2weight = {}
    for t, line in enumerate(lines):
        line = line.split("=")[1].strip()
        for entry in line.split("+"):
            pp = entry.split("*")
            weight = str(float(pp[0]))
            word = pp[1].strip()
            words.add(word)
            topicword2weight[(t, word)] = weight
    numtopics = t+1     
    
    words = sorted(words)   
    
    header = "\t".join(words)
    out.write(header)
    out.write("\n")
    for t in xrange(numtopics):
        line = map(lambda w: topicword2weight.get((t,w), "0"), words)
        line = "\t".join(line)
        out.write(line)
        out.write("\n")