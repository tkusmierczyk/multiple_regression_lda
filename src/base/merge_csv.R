
d = read.table("../data/allrecipes.tsv", header=T, sep="\t")
paste("input file1 size:", round(object.size(d)/1024/1024, 2), "MB")

f = read.table("../data/features.tsv", header=T, sep="\t")
paste("input file2 size:", round(object.size(f)/1024/1024, 2), "MB")

f = cbind(d, f)
write.table(f, "../data/data.tsv", sep="\t", row.names = F, col.names = T)
paste("output file size:", round(object.size(f)/1024/1024, 2), "MB")

