#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

model.file = "lda_reg1.bugs"
source(file="../base/config.R")
source(file="../models_common/lda_single_params.R")
source(file="../models_common/lda_load_train_test.R")
source(file="../models_common/lda_tdm.R")

###############################################################################

train.mtdm = mtdm[, 1:n1]
train.words = rowSums(train.mtdm)
train.words = names(train.words[train.words>0])
train.mtdm = train.mtdm[train.words, ]
cat(length(train.words),"/",length(words)," words in the training set (", dim(train.mtdm)[2], "docs )\n")

test.mtdm = mtdm[, (n1+1):(n1+n2)] 
test.mtdm = test.mtdm[train.words,] #only train words available in test
cat(sum(rowSums(test.mtdm)>0),"/",length(train.words)," ( all =", length(words),") words in the test set (",dim(test.mtdm)[2],"docs )\n")

words = train.words


###############################################################################


genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  mtdm  = lda.data$mtdm
  words = lda.data$words  
  out  = lda.data$out
  
  word = do.call(rbind.fill.matrix,
                 lapply(1:ncol(mtdm), function(i) t(rep(1:length(mtdm[,i]), mtdm[,i]))))
  
  N = ncol(mtdm)                 #Number of documents
  Nwords = length(words)         #Number of terms
  alphaTopics = rep(alpha.Topics, K)      #Hyperprior on topics
  alphaWords = rep(alpha.Words, Nwords)  #Hyperprior on words
  
  wordtopic = matrix(NA, nrow(word), ncol(word))
  doclengths = rowSums(!is.na(word))
  topicdist = matrix(NA, N, K)
  if ("worddist" %in% names(lda.data)) {
    cat("Using infered previously topicwords (worddist)\n")
    topicwords = lda.data$worddist
  } else {
    topicwords = matrix(NA, K, Nwords)
  }
  
  ## All the parameters to be passed to JAGS
  
  if ("intercept" %in% names(lda.data)) {
    cat("Using infered previously intercept & weights\n")
    dataList = list(alphaTopics = alphaTopics,
                    alphaWords = alphaWords,
                    topicdist = topicdist,
                    wordtopic = wordtopic,
                    word = word,
                    Ndocs = N,
                    Ktopics = K,
                    length = doclengths,
                    Nwords = Nwords,
                    worddist = topicwords,
                    out = out,
                    intercept = intercept,
                    weight = weight,
                    sd = sd)    
  } else {
    dataList = list(alphaTopics = alphaTopics,
                    alphaWords = alphaWords,
                    topicdist = topicdist,
                    wordtopic = wordtopic,
                    word = word,
                    Ndocs = N,
                    Ktopics = K,
                    length = doclengths,
                    Nwords = Nwords,
                    worddist = topicwords,
                    out = out)
  }
  
  jags = jags.model(lda.data$model.path,
                    data = dataList, n.adapt=n.adapt)
  return (jags)
}

###########################


print("extracts output from training only")
out = d1[,selected.output] # 

#print("znorm over output")
#m = mean(out[!is.na(out)])
#s = sd(out[!is.na(out)])
#out = (out-m)/s #znorm


###########################

cat("Model training...\n")
lda.data = list(model.path='lda_reg1.bugs', mtdm=train.mtdm, words=words, out=out)
lda.observe = c('worddist', 'topicdist', 'intercept', 'weight', 'sd')
source("../models_common/lda_sampling.R")
source("../models_common/lda_diagnostics.R")

###############################################################################

cat("Infering topics for test...\n")
worddist  = apply(samples$worddist[1:K, 1:length(train.words), , 1], c(1,2), aggregator)
weight    = apply(samples$weight[1:K, , 1], c(1), aggregator)
intercept = aggregator(samples$intercept)
sd        = aggregator(samples$sd)

lda.data = list(model.path="lda_reg1_test.bugs", mtdm=test.mtdm, words=words, 
                worddist=worddist, intercept=intercept, weight=weight, sd=sd)
lda.observe = c('topicdist', 'out')
source("../models_common/lda_sampling.R")
source("../models_common/lda_store_test_samples.R")

###############################################################################

predicted.out = as.data.frame(apply(samples$out[,  , 1], c(1), aggregator))
predicted.out[predicted.out<0] = 0
colnames(predicted.out) = c(selected.output)
predicted.out$href = d2$href

###############################################################################

cat("Writing to",prediction.file,"\n")
write.table(predicted.out, prediction.file, sep="\t", row.names = F, col.names = T)

###############################################################################

print("JAGS Done.")


