
print("Exports intercepts from samples *.RData file.")


source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)

if (length(args)<2) {
  stop("Two args expected: input .RData file with samples, output tsv file") 
}


input = ifelse (length(args)>=1, args[[1]], "???")
output = ifelse (length(args)>=2, args[[2]], "???")

######################################################################################

load(input)

print(names(samples))
print(dim(samples$intercept))

intercepts  = t(as.matrix(apply(samples$intercept, c(1), median)))
colnames(intercepts) = outputs


######################################################################################

cat("Writing to", output,"\n")
print(intercepts)
write.table(intercepts, output, sep="\t", row.names = F, col.names = T)



