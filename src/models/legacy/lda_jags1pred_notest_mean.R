#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))

library(rjags)
library(plyr)
library(tm)

source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)

#DBG
#train.path = "../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv"

train.path = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
test.path = ifelse (length(args)>=2, args[[2]], train.path)
prediction.file = ifelse (length(args)>=3, args[[3]], "../../data/prediction.tsv")

selected.output = ifelse (length(args)>=4, args[[4]], "fat")

K         = ifelse(length(args)>=5, as.numeric(args[[5]]), 10)
n.iter    = ifelse(length(args)>=6, as.numeric(args[[6]]), 1000)
burn.in   = ifelse(length(args)>=7, as.numeric(args[[7]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=8, as.numeric(args[[8]]), burn.in)


###############################################################################

print("Parameters:")
print(paste("train.path =", train.path))
print(paste("test.path =", test.path))

print(paste("prediction.file =", prediction.file))

print("Settings:")
print(paste("K =", K))
print(paste("n.iter =", n.iter))
print(paste("burn.in =", burn.in))
print(paste("n.adapt =", n.adapt))

#print(paste("outputs =", outputs))
print(paste("selected.output =", selected.output))

print("-----------------------------------------------------------------------")
###############################################################################

d1 = read.csv(train.path, sep="\t")
print(paste("train dims=", dim(d1)))
head(d1, 3)

if (test.path==train.path) {
  d2 = data.frame()  
} else {
  d2 = read.csv(test.path, sep="\t")
}
print(paste("test dims=", dim(d2)))
head(d2, 3)

###############################################################################

d = rbind(d1, d2)
documents = d$title
#documents = documents[1:100]

n1 = dim(d1)[1]
n2 = dim(d2)[1]


###############################################################################

source("../models_common/lda_tdm.R")


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
#lda.data = list(mtdm=mtdm, words=words, out=out)
#lda.observe = c('worddist', 'topicdist', 'intercept', 'weight', "out")
lda.data = list(model.path='lda_reg1.bugs', mtdm=train.mtdm, words=words, out=out)
lda.observe = c('worddist', 'topicdist', 'intercept', 'weight', 'sd')
source("../models_common/lda_sampling.R")

source("../models_common/lda_diagnostics.R")
path = paste("lda_diagnostics_", pid, "_2.pdf", sep="")
cat("Lda trace diagnotics 2 (",path,")\n")
pdf(path)
diagnostics(trace=samples$intercept[1,,1], label="intercept")
for (i in 1:K) {
  diagnostics(trace=samples$weight[i,,1], label=paste("weight[topic=",i,"]", sep=""))
}
dev.off()

###############################################################################



cat("Infering topics for test...\n")
worddist  = apply(samples$worddist[1:K, 1:length(train.words), , 1], c(1,2), mean)
weight    = apply(samples$weight[1:K, , 1], c(1), mean)
intercept = mean(samples$intercept)
sd        = mean(samples$sd)

lda.data = list(model.path="lda_reg1_test.bugs", mtdm=test.mtdm, words=words, 
                worddist=worddist, intercept=intercept, weight=weight, sd=sd)
lda.observe = c('topicdist', 'out')
source("../models_common/lda_sampling.R")

###############################################################################

pid = paste(format(Sys.time(), "%Y%m%d_%H%M%S"), as.character(Sys.getpid()), sep="_")
path = paste("samples_test_", pid, ".RData", sep="")
cat("Saving test samples to ",path,"\n")
save(samples, file=path)

###############################################################################

predicted.out = as.data.frame(apply(samples$out[,  , 1], c(1), mean))
predicted.out[predicted.out<0] = 0
colnames(predicted.out) = c(selected.output)
predicted.out$href = d2$href

###############################################################################


write.table(predicted.out, prediction.file, sep="\t", row.names = F, col.names = T)


print("JAGS Done.")


