
print("Calculates lm weights when topic and outputs are given.")

source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)


if (length(args)<3) {
  stop("Args expected: input data (must contain outputs), features (topics) for lm model, output path") 
}

train = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
train.features = ifelse (length(args)>=2, args[[2]], "../../data/metadoc5/allrecipes_metadoc_gl_5.tsv")
output.path = ifelse (length(args)>=3, args[[3]], "../../data/metadoc5/allrecipes_metadoc_gl_5_lmweights.tsv")

train.params = list()

###############################################################################

train = read.table(train, header=1)
cat(dim(train)[1], "rows loaded from training file\n")

drop.features.columns = c("href")
train.features = read.table(train.features, header=1)
train.features = train.features[ , !(names(train.features) %in% drop.features.columns)]
cat(dim(train.features)[1], "rows (", dim(train.features)[2]," features) loaded from training features file\n")

###############################################################################

weights = c()
for (col.name in outputs) {
  print(paste("predicting for", col.name))
  
  ###########################################################
  
  start = Sys.time()
  formula = as.formula(paste(col.name, "~."))  
  l1 = do.call(lm, c(list(formula=formula, 
                          data=cbind(train[col.name], train.features)), train.params))
  cat("Building time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
  summary(l1)
  weights = cbind(weights, l1$coefficients)
  
  ###########################################################
}
colnames(weights) = outputs
weights = weights[2:dim(weights)[1],]

###############################################################################

cat("writing weights to ", output.path, "\n")
print(weights)
write.table(weights, output.path, sep="\t", row.names = F, col.names = T)


