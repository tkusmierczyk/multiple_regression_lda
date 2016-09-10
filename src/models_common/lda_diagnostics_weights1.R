print("Running JAGS diagnostics for single-output weights.")

##############################

n1 = ifelse(exists("d1"), dim(d1)[1], 0)
n2 = ifelse(exists("d2"), dim(d2)[1], 0)   

##############################

path = paste("lda_diagnostics_", pid, "_2.pdf", sep="")
cat("Lda trace diagnotics 2 (",path,")\n")
pdf(path)
diagnostics(trace=samples$out[n1+n2,,1], label=paste("out[doc=last.test.document]"))

diagnostics(trace=samples$intercept[1,,1], label="intercept")
for (i in 1:K) {
  diagnostics(trace=samples$weight[i,,1], label=paste("weight[topic=",i,"]", sep=""))
}
dev.off()