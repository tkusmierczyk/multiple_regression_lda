
###########################

start = Sys.time()
print("Building model")
jags = genLDA(lda.data=lda.data, K=K, n.adapt=n.adapt) ##
cat("building time:", as.numeric(Sys.time()-start,units="secs"),"s\n")

###########################

start.burning = Sys.time()
print(paste("Burning in the MCMC chain with",burn.in,"iterations"))

eval.iter = max(min(100, burn.in), 10)

update(jags, n.iter=10, progress.bar="text")
cat("estimated speed after 10 samples:",  round(10/as.numeric(Sys.time()-start,units="secs"), 4), " samples/second\n")
eval.iter = eval.iter-10

if (eval.iter>0) {
  update(jags, n.iter=eval.iter, progress.bar="text")
  cat("estimated speed after",eval.iter,"+ 10:",  round((eval.iter+10)/as.numeric(Sys.time()-start,units="secs"), 4), " samples/second\n")
}

burn.in = burn.in-eval.iter
if (burn.in>0) {
  update(jags, n.iter=burn.in, progress.bar="text")
} 

cat("burning time:", as.numeric(Sys.time()-start.burning,units="secs"),"s\n")

###########################

start.sampling = Sys.time()
print(paste("Sampling MCMC chain with",n.iter,"iterations" ))

samples = jags.samples(jags, lda.observe, n.iter, progress.bar="text")

summary(samples)
print(paste("dim(samples$topicdist) =", paste(dim(samples$topicdist), collapse=", ")))
print(paste("dim(samples$worddist) =", paste(dim(samples$worddist), collapse=", ")))
cat("sampling time:", as.numeric(Sys.time()-start.sampling,units="secs"),"s\n")

###########################

cat("Total building & sampling time:", as.numeric(Sys.time()-start,units="secs"),"s\n")
