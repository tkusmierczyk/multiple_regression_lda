
print("Exports topics from RData samples file.")


source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)

if (length(args)<3) {
  stop("Three args expected: input .RData file with samples, input .RData file with words, output tsv file") 
}

input = "../../data/jagsMcluster_5_500_100/samples_20160510_002011_21850.RData"
words.path = "../../data/allrecipes_words.RData"
output = "../../data/jagsMcluster_5_500_100/samples_20160510_002011_21850_topics.tsv"

input = ifelse (length(args)>=1, args[[1]], "???")
words.path = ifelse (length(args)>=2, args[[2]], "???")
output = ifelse (length(args)>=2, args[[3]], "???")

######################################################################################

load(input)
load(words.path)

print(head(words))
print(names(samples))
print(dim(samples$worddist))

######################################################################################

library(rjags)

sampleTW = samples$worddist
colnames(sampleTW) = words
freq = summary(sampleTW, FUN = mean)$stat


######################################################################################

cat("Writing to", output,"\n")
write.table(freq, output, sep="\t", row.names = F, col.names = T)



