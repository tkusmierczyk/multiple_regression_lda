
source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)



if (length(args)<3) {
  print("Args expected: input training data (including outputs), family features, output path") 
}

train = ifelse (length(args)>=1, args[[1]],  "../../data/allrecipes.tsv")
train.features = ifelse (length(args)>=2, args[[2]], "../../data/allrecipes_family_features.tsv")
output.path = ifelse (length(args)>=3, args[[3]], "../../data/allrecipes_nofamily.tsv")


###############################################################################

train = read.table(train, header=1)
cat(dim(train)[1], "rows loaded from training file\n")
head(train)

train.features = read.table(train.features, header=1)
cat(dim(train.features)[1], "rows (", dim(train.features)[2]," features) loaded from training features file\n")
head(train.features[,1:5])

###############################################################################

drop.features.columns = c("href")
train.features = train.features[ , !(names(train.features) %in% drop.features.columns)]

###############################################################################

rs = rowSums(train.features)
train = train[rs==0, ]
cat(dim(train)[1], "rows left in the training set\n")
head(train)

###############################################################################

cat("writing no-family subset to ", output.path, "\n")
write.table(train, output.path, sep="\t", row.names = F, col.names = T)


