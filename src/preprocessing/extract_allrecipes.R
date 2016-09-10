

paste(">>> Extracts allrecipes.com data to TSV file.")
args = commandArgs(TRUE)

input.path  = ifelse (length(args)>=1, args[[1]],  "../../data/raw/list_of_recipesprofiles.txt")
output.path  = ifelse (length(args)>=2, args[[2]], "../../data/allrecipes.tsv")

print(paste("input.path =", input.path))
print(paste("output.path =", output.path))

#######################################################################

d2 = read.table(input.path, sep=";", header=F)

library(stringr)


#extracts numeric column values
extract.column = function (col) {
  missing = col=="" | col=="N/A"
  values <- str_extract_all(col,"\\(?[0-9,.]+\\)?")
  values[missing] = NA
  values = as.numeric(unlist(values))
  return (values)
}


#column mapping:
src2dst = rbind(c("V18", "kcal"), c("V38", "fat"), c("V43", "cholesterol"), 
                c("V52", "carbohydrates"), c("V58", "proteins"), 
                c("V61", "sugars"), c("V46", "sodium"))
outputs = src2dst[,2]

d = data.frame(d2$V1); colnames(d)=c("href")
d$href = d2$V1
d$title = d2$V6
for (r in 1:dim(src2dst)[1]) {
  src = src2dst[r, 1]
  dst = src2dst[r, 2]
  d[[dst]] = extract.column(d2[[src]])
}



#################################################


write.table(d, output.path, row.names = F, col.names = T, sep="\t")

#######################################################################

