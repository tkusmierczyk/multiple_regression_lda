
print("Visualisation of topic weights.")


args = commandArgs(trailingOnly = TRUE)

if (length(args)<1) {
  stop("Arg expected: input tsv file (clusters x outputs)") 
}

input = "../../data/jagsMcluster_5_500_100/samples_20160510_002011_21850_lmweights.tsv"
input = "../../data/jagsMcluster_5_1500_300/samples_20160511_082028_24815_lmweights.tsv"
input = "../../data/metadoc5/allrecipes_metadoc_gl_5_lm_weights.tsv"

input = ifelse (length(args)>=1, args[[1]], "?")

#######################################################################

weights = as.matrix(read.delim(input))
k = dim(weights)[1]
outputs =  colnames(weights)
print(outputs)
print(weights)

#######################################################################

if(length(args)>=2) {
  order = as.numeric(strsplit(args[[2]], ",")[[1]])  
} else {
  order = 1:k
}
weights = weights[order,]

#######################################################################

max.weights = t(as.matrix(apply(weights, c(2), function(v) max(abs(v)))))
max.weights  = max.weights[rep(1,k),]
weights = weights/max.weights #normalize to relative importance

###############################################################################################

library(ggplot2)
library(grid)
library(gridExtra)


df = as.data.frame( c(weights))
colnames(df) = "weights"
df$cluster = as.factor(rep(1:k,length(outputs)))
df$nutrient = rep(outputs,times=1,each=k)
df$nutrient.order = rep(1:length(outputs),times=1,each=k)

ggplot(df) + 
  geom_polygon(aes(y = weights, x =  reorder(nutrient, nutrient.order), 
                   group = cluster, fill = cluster, color=cluster), alpha=0.3) + 
  coord_polar() + 
  facet_wrap(~cluster) +
  labs(x = NULL, y = "relative weight")


###############################################################################################

df0 = data.frame()
for (cluster in 1:dim(weights)[1]) {
  weights1 = weights[cluster,]
  
  df = as.data.frame( c(weights1))
  colnames(df) = "weights"
  df$cluster = as.factor(rep(cluster, length(outputs)))
  df$nutrient = rownames(df)
  df$nutrient.order = rep(1:length(outputs),times=1,each=1)
  df$sign = "+"
  df2 = df
  df2$sign = "-"
  df2$weights = -df2$weights
  df$weights[df$weights<0] = 0.0001
  df2$weights[df2$weights<0] = 0.0001
  df = rbind(df, df2)
  df$cluster = cluster
  df0 = rbind(df0, df)
}
df0$cluster = as.factor(paste("topic", df0$cluster))
df = df0

df$nutrient[df$nutrient=="carbohydrates"] = "carbo" 
#df$nutrient[df$nutrient=="sodium"] = "_______sod." 
df$nutrient[df$nutrient=="sugars"] = "sugar" 
df$nutrient[df$nutrient=="kcal"] = "  kcal" 



path = paste(dirname(input),"cluster_weights.pdf", sep="/")
cat("Plotting to", path, "\n")
pdf(path, width=12, height=2.5, pointsize=1/72)
library(ggplot2)
ggplot(df) + 
  geom_polygon(aes(y = weights, x =  reorder(nutrient, nutrient.order), 
                   group = sign, fill = sign, color=sign), alpha=0.3) + 
  coord_polar() + 
  facet_wrap(~cluster, ncol=5) + theme_bw() + 
  theme(text = element_text(size=20), axis.ticks=element_blank())+
  labs(x = NULL, y = "relative weight") 
dev.off()









