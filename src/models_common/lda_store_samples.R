

pid = paste(format(Sys.time(), "%Y%m%d_%H%M%S"), as.character(Sys.getpid()), sep="_")

##############################


path = paste("samples_", pid, ".RData", sep="")
cat("Saving samples to ",path,"\n")
save(samples, file=path)

path = paste("jags_model_", pid, ".RData", sep="")
cat("Saving JAGS model to ",path,"\n")
save(jags, file=path)

path = paste("words_", pid, ".RData", sep="")
cat("Saving words to ",path,"\n")
save(words, file=path)
