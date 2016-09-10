
print(paste("Starting at", Sys.time()))

drop.features.columns = c("href")

###############################################################################

train = read.table(train, header=1)
cat(dim(train)[1], "rows loaded from training file\n")
#print(head(train))

train.features = read.table(train.features, header=1)
train.features = train.features[ , !(names(train.features) %in% drop.features.columns)]
cat(dim(train.features)[1], "rows (", dim(train.features)[2]," features) loaded from training features file\n")
#print(head(train.features))

###############################################################################

test = read.table(test, header=1)
cat(dim(test)[1], "rows loaded from testing file\n")
#print(head(test))

test.features = read.table(test.features, header=1)
test.features = test.features[ , !(names(test.features) %in% drop.features.columns)]
cat(dim(test.features)[1], "rows (", dim(test.features)[2]," features) loaded from testing features file\n")
#print(head(test.features))

###############################################################################

