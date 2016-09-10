
## Take our documents and turn it into a Term Document Matrix
## Rows are terms, and columns are documents. Cells are counts of terms in documents.
## Check it out using inspect(tdm)
## We strip out numbers and punctuation here to make it a bit easier on ourselves
docsToTDM = function(documents) {
  docs.tm = Corpus(VectorSource(documents))
  #docs.tm = tm_map(docs.tm, tolower)
  #docs.tm = tm_map(docs.tm, removeNumbers)
  ## docs.tm = tm_map(docs.tm, removePunctuation)
  #docs.tm = tm_map(docs.tm, function(x) gsub("[[:punct:]]", " ", x))
  #docs.tm = tm_map(docs.tm, stripWhitespace)
  #docs.tm = tm_map(docs.tm, removeWords, stopwords('english'))
  ## We could also filter out non-frequent terms to keep the graph size small:
  ## tdm = TermDocumentMatrix(docs.tm)
  ## findFreqTerms(tdm, 5)
  ## tdm.sparse = removeSparseTerms(tdm, 0.99)
  ## tdm.sparse
  TermDocumentMatrix(docs.tm)
}


mtdm = as.matrix(docsToTDM(documents))
print(paste("dim(mtdm) =", paste(dim(mtdm), collapse=", ")))

## List of all the terms
words = rownames(mtdm)
print(paste("length(words)=",length(words)))