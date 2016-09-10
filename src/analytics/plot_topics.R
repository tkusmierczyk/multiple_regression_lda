
print("Visualizing topics as word clouds.")

args = commandArgs(trailingOnly = TRUE)

if (length(args)<1) {
  stop("Arg expected: input tsv file (topics x words)") 
}

input = "../../data/metadoc5/topics.tsv"
input = "../../data/jagsMcluster_5_1500_300/lda_topics_20160511_082028_24815.tsv"

input = ifelse (length(args)>=1, args[[1]], "?")
min.freq = as.numeric(ifelse (length(args)>=2, args[[2]], "0.01"))


#######################################################################

w2c = as.matrix(read.delim(input))
k = dim(w2c)[1]
head(w2c)

#######################################################################

if(length(args)>=3) {
  order = as.numeric(strsplit(args[[3]], ",")[[1]])  
} else {
  order = 1:k
}
w2c = w2c[order,]

#######################################################################


library(wordcloud)

gen.word.cloud = function(freq, words, ...) {
  wordcloud(words[order(freq)], freq[order(freq)], ...)
}

path = paste(dirname(input),"topic_words.pdf", sep="/")
cat("Plotting to", path, "\n")
pdf(path, width=6, height=1.25, pointsize=1/72)
par(mfrow=c(1,k))
for(i in 1:k) {
  freq = w2c[i, ]
  words = names(freq)
  gen.word.cloud(freq, words, min.freq = min.freq, max.words=100)
}
dev.off()
