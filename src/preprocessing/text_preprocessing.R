

paste(">>> Cleans recipe titles.")
args = commandArgs(TRUE)

src.path = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
out.path = ifelse (length(args)>=2, args[[2]], src.path)
language = ifelse (length(args)>=3, args[[3]], "english")

cat("src.path =", src.path,"\n")
cat("out.path =", out.path,"\n")
cat("language =", language,"\n")

#####################################################################################

d = read.table(src.path, header=1)
cat("read", dim(d)[1], "rows from", src.path,"\n")
head(d)
d$title.bak = d$title

#####################################################################################

#install.packages("SnowballC")
#install.packages("tm")
#In case of problems you may also need the following:
#Needed = c("tm", "SnowballCC", "RColorBrewer", "ggplot2", "wordcloud", "biclust", "cluster", "igraph", "fpc")   
#install.packages(Needed, dependencies=TRUE)   
#install.packages("Rcampdf", repos = "http://datacube.wu.ac.at/", type = "source")   

library(SnowballC)
library(tm)

print("preprocessing:")

print("punctuation filtering")
d$title = gsub("[[:punct:]]", " ", d$title)
print("corpus buidling")
corp = Corpus(VectorSource(d$title))
print("whitespace stripping")
corp = tm_map(corp, stripWhitespace)
print("lowering")
corp = tm_map(corp, content_transformer(tolower))
print("stopwords removal")
corp = tm_map(corp, removeWords, stopwords(language))
print("stemming")
wordStem2 = function(x) {
  wordStem(x, language)
}
corp2 = tm_map(corp, wordStem2);
print("whitespace stripping")
corp = tm_map(corp, stripWhitespace)

print("result preview:")
unlist(lapply(corp[1:5], as.character))

#save
d$title = unlist(lapply(corp, as.character))

#####################################################################################

cat("writing", dim(d)[1], "rows to", out.path, "\n")
head(d)
write.table(d, out.path, sep="\t", row.names = F, col.names = T)

