
print("Exports lm weights from samples *.RData file.")


source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)

if (length(args)<2) {
  stop("Two args expected: input .RData file with samples, output tsv file") 
}

input = "../../data/jagsMcluster_5_500_100/samples_20160510_002011_21850.RData"
output = "../../data/jagsMcluster_5_500_100/samples_20160510_002011_21850_lmweights.tsv"

input = ifelse (length(args)>=1, args[[1]], "???")
output = ifelse (length(args)>=2, args[[2]], "???")

######################################################################################

load(input)

print(names(samples))
print(dim(samples$weight))

#intercepts  = apply(samples$intercept, c(1), median)
weights     = apply(samples$weight, c(2,1), median)
colnames(weights) = outputs

######################################################################################

cat("Writing to", output,"\n")
print(weights)
write.table(weights, output, sep="\t", row.names = F, col.names = T)



