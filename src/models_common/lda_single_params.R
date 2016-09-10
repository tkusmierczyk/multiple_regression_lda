
args = commandArgs(trailingOnly = TRUE)

train.path      = ifelse (length(args)>=1, args[[1]], "../../data/allrecipes.tsv")
test.path       = ifelse (length(args)>=2, args[[2]], train.path)
prediction.file = ifelse (length(args)>=3, args[[3]], "../../data/prediction.tsv")

selected.output = ifelse (length(args)>=4, args[[4]], "fat")

K         = ifelse(length(args)>=5, as.numeric(args[[5]]), 10)
n.iter    = ifelse(length(args)>=6, as.numeric(args[[6]]), 1000)
burn.in   = ifelse(length(args)>=7, as.numeric(args[[7]]), round(n.iter/3))
n.adapt   = ifelse(length(args)>=8, as.numeric(args[[8]]), burn.in)

aggregator   = match.fun(ifelse(length(args)>=9, args[[9]], aggregator))
model.file   = ifelse(length(args)>=10, args[[10]], model.file)


###############################################################################

print("Parameters:")
print(paste("[01] train.path =", train.path))
print(paste("[02] test.path =", test.path))
print(paste("[03] prediction.file =", prediction.file))

print(paste("[04] selected.output =", selected.output))
print(paste("[05] K =", K))
print(paste("[06] n.iter =", n.iter))
print(paste("[07] burn.in =", burn.in))
print(paste("[08] n.adapt =", n.adapt))

#print(paste("outputs =", outputs))
print("[09] aggregator ="); print(aggregator)
print(paste("[10] model.file =", model.file)); 


print("-----------------------------------------------------------------------")

