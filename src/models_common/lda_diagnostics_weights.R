print("Running JAGS diagnostics for multi-outputs weights.")

##############################

n1 = ifelse(exists("d1"), dim(d1)[1], 0)
n2 = ifelse(exists("d2"), dim(d2)[1], 0)   

##############################

pid = paste(format(Sys.time(), "%Y%m%d_%H%M%S"), as.character(Sys.getpid()), sep="_")
path = paste("lda_diagnostics_", pid, "_2.pdf", sep="")
cat("LDA trace diagnotics 2 (",path,")\n")
pdf(path)
for (o in 1:length(outputs)) {
  diagnostics(trace=samples$out[n1+n2,o,,1], label=paste("out[output=",o,", doc=last.test.document]"))
  diagnostics(trace=samples$intercept[o,,1], label=paste("intercept[output=",o,"]"))
  for (i in 1:K) {
    diagnostics(trace=samples$weight[o,i,,1], label=paste("weight[output=",o,", topic=",i,"]", sep=""))
  }
}
dev.off()