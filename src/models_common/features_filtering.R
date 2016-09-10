

#keep only these outputs that are also prestend in the training
outputs = intersect(outputs, colnames(train))
print(paste("kept output cols =", paste(outputs, collapse = ",")))

#####################################################################################

shared.features = intersect(colnames(train.features), colnames(test.features))
if (length(shared.features)!=length(colnames(train.features)) | length(shared.features)!=length(colnames(test.features))  ) {
  print(paste("WARN: only", length(shared.features), "features are shared between train (", 
              length(colnames(train.features)), "features ) and test (", length(colnames(test.features)), "features )"))
}
train.features = train.features[shared.features]
test.features = test.features[shared.features]

