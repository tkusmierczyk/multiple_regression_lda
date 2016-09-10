
paste(">>> Extracts family features for given train and test data sets.")
args = commandArgs(TRUE)

train = ifelse (length(args)>=1, args[[1]], "../../data/train.tsv")
test = ifelse (length(args)>=2, args[[2]], "../../data/test.tsv")

train.features.path = ifelse (length(args)>=3, args[[3]], "../../data/train_features.tsv")
test.features.path = ifelse (length(args)>=4, args[[4]], "../../data/test_features.tsv")

family.features   = ifelse(length(args)>=5, args[[5]],  "../../data/allrecipes_family_features.tsv")


print("Parameters:")
print(paste("train =", train))
print(paste("test =", test))

print(paste("train.features =", train.features.path))
print(paste("test.features =", test.features.path))

print(paste("family.features =", family.features))


###############################################################################

train = read.table(train, header=1)
cat(dim(train)[1], "rows loaded from training file\n")
#print(head(train))

test = read.table(test, header=1)
cat(dim(test)[1], "rows loaded from testing file\n")
#print(head(test))

family.features = read.table(family.features, header=1)
cat(dim(family.features)[1], "rows loaded from family features file\n")
#print(head(family.features))

###############################################################################

train.features = family.features[match(train$href, family.features$href), ]

if (dim(train.features)[1] != dim(train)[1]) {
  stop("dim(train.features)[1] != dim(train)[1]")
}


cat("Storing to train features file", train.features.path,"\n")
write.table(train.features, train.features.path, sep="\t", row.names = F, col.names = T)

###############################################################################

test.features = family.features[match(test$href, family.features$href), ]

if (dim(test.features)[1] != dim(test)[1]) {
  stop("dim(test.features)[1] != dim(test)[1]")
}

cat("Storing to test features file", test.features.path,"\n")
write.table(test.features, test.features.path, sep="\t", row.names = F, col.names = T)

###############################################################################







