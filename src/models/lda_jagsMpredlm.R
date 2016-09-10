#!/usr/bin/Rscript
print(paste("Starting at", Sys.time()))


library(rjags)
library(plyr)
library(tm)

source(file="../base/config.R")

args = commandArgs(trailingOnly = TRUE)

#DBG
#train.path = "../../data/allrecipes_cake_muffin_cheesecak_sweet_potato_salsa_caramel_burger.tsv"
#test.path = train.path


train.path = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
test.path = ifelse (length(args)>=2, args[[2]], train.path)
prediction.file = ifelse (length(args)>=3, args[[3]], "../../data/prediction.tsv")


K         = ifelse(length(args)>=4, as.numeric(args[[4]]), 10)
n.iter    = ifelse(length(args)>=5, as.numeric(args[[5]]), 1000)
burn.in   = ifelse(length(args)>=6, as.numeric(args[[6]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=7, as.numeric(args[[7]]), burn.in)

aggregator   = match.fun(ifelse(length(args)>=8, args[[8]], aggregator))
print("aggregator ="); print(aggregator)

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

print(paste("outputs =", outputs))

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

###############################################################################


genLDA = function(lda.data, K = 10, n.adapt = 1000, alpha.Words = 0.1, alpha.Topics = 0.1) {
  mtdm  = lda.data$mtdm
  words = lda.data$words  
  out   = lda.data$out
  
  word = do.call(rbind.fill.matrix,
                 lapply(1:ncol(mtdm), function(i) t(rep(1:length(mtdm[,i]), mtdm[,i]))))
  
  N = ncol(mtdm)                 #Number of documents
  Nwords = length(words)         #Number of terms
  Nouts = dim(out)[2]             #Number of outputs
  alphaTopics = rep(alpha.Topics, K)      #Hyperprior on topics
  alphaWords = rep(alpha.Words, Nwords)  #Hyperprior on words
  
  wordtopic = matrix(NA, nrow(word), ncol(word))
  doclengths = rowSums(!is.na(word))
  topicdist = matrix(NA, N, K)
  topicwords = matrix(NA, K, Nwords)
  
  ## All the parameters to be passed to JAGS
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
                  Nouts = Nouts)
  
  jags = jags.model('lda_reg.bugs',
                    data = dataList, n.adapt=n.adapt)
  return (jags)
}


print("extracts output")
out = d[,outputs]

print("NA for tests")
if (n2>0) {
  for (output in outputs) {
    out[(n1+1):(n1+n2), output] = NA
    cat(output," NAs:",sum(is.na(out[,output])), "\n")
  }
}

#print("znorm")
#for (output in outputs) {
#  col = out[,output] 
#  out[,output] = (col-mean(col[!is.na(col)])) / sd(col[!is.na(col)]) 
#}


lda.data = list(mtdm=mtdm, words=words, out=out)
lda.observe = c('worddist', 'topicdist', "intercept", "weight", "sd")
source("../models_common/lda_sampling.R")


###############################################################################

topicdist = apply(samples$topicdist, c(1,2), aggregator)
intercepts = apply(samples$intercept, c(1), aggregator)
weights = apply(samples$weight, c(1,2), aggregator)

predictions = c()
for (i in 1:length(outputs)) {
  predictions = cbind(predictions, topicdist[(n1+1):(n1+n2),] %*% weights[i,] + intercepts[i])
}
colnames(predictions) = outputs
predictions[predictions<0] = 0 #force positive outputs

predictions = as.data.frame(predictions)
predictions$href = d2$href

###############################################################################

cat("Storing predictions to",prediction.file,"\n")
write.table(predictions, prediction.file, sep="\t", row.names = F, col.names = T)

###############################################################################

source("../models_common/lda_diagnostics.R")

path = paste("lda_diagnostics_", pid, "_2.pdf", sep="")
cat("LDA trace diagnotics 2 (",path,")\n")
pdf(path)
for (o in 1:length(outputs)) {
  diagnostics(trace=samples$intercept[o,,1], label=paste("intercept[output=",o,"]"))
  for (i in 1:K) {
    diagnostics(trace=samples$weight[o,i,,1], label=paste("weight[output=",o,", topic=",i,"]", sep=""))
  }
}

dev.off()



print("JAGS Done.")


