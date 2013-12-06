# using KMM ("Correcting Sample Selection Bias by Unlabeled Data", NIPS 2006)
# to correct the sample selection bias
library(kernlab)
library(doMC)
registerDoMC()

load('out/data3.Rd')
source('common.R')

d.train      <- d[d$month<='2013-03',]
d.valid      <- d[d$month=='2013-04',]
d.trainvalid <- rbind(d.train, d.valid)


expn    <- 20
cols    <- setdiff(names(d.train), c('month', labels))
x.train <- as.matrix(d.train[, cols])
x.valid <- as.matrix(d.valid[, cols])
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]
rm(cols, d, d.train, d.valid, d.trainvalid, d.test)
gc()

system(sprintf('mkdir -p out/%s/final', expn))

kmm <- function(sigma, part.size, x.train, x.valid, final=F, B=10, epsilon=0.1) {
	set.seed(1)
	nparts  <- nrow(x.train) %/% part.size
	idxs    <- rep(1:nparts, (nrow(x.train)+nparts-1)/nparts)
	idxs    <- idxs[1:nrow(x.train)]
	idxs    <- sample(idxs)

	rbf     <- rbfdot(sigma=sigma)
	w       <- rep(0, nrow(x.train)) # weights for the training instance (the output of this)
	key     <- sprintf('partsize_%d_sigma_%f', part.size, sigma)

	a <- foreach(part=1:nparts, .packages='kernlab', .combine=rbind) %dopar% {
		sink(sprintf('%s/%slog_%s_part_%d.txt', out.dir(expn), ifelse(final, 'final/', ''), key, part))
		timestamp()

		# get split of data
		x.s  <- data.matrix(x.train[idxs==part,])
		ms   <- nrow(x.s)

		# build kernels
		K    <- kernelMatrix(rbf, x.s)@.Data
		kapa <- rowMeans(kernelMatrix(rbf, x.s, x.valid)@.Data)*ms

		# solve QP problem
		lvec    <- rep(0, ms)
		uvec    <- rep(B, ms)
		Amat    <- matrix(data=rep(1/ms, ms), nrow=1, ncol=ms)
		bvec    <- c(1-epsilon)
		rvec    <- c(2*epsilon)

		sol <- ipop(-kapa, K, Amat, bvec, lvec, uvec, rvec, verb=1)
		sink()
		data.frame(idx=which(idxs==part), w=sol@primal)
	}
	w[a$idx] <- a$w
	save(w, file=sprintf('%s/%sw_%s.Rd', out.dir(expn), ifelse(final, 'final/', ''), key))
}

sigmas     <- 0.01 * (2^(0:7))
part.sizes <- c(1000, 2000)

for (part.size in part.sizes) {
	for (sigma in sigmas) {
		kmm(sigma, part.size, x.train, x.valid)
	}
}

params <- expand.grid(part.size = part.sizes[1], sigma = sigmas)
ws     <- foreach (i = 1:nrow(params), .combine=rbind) %do% {
	key <- sprintf('partsize_%d_sigma_%f', params$part.size[i], params$sigma[i])
	load(sprintf('%s/w_%s.Rd', out.dir(expn), key))
	w
}
rownames(ws) <- sprintf('partsize_%d_sigma_%f', params$part.size, params$sigma)


# repeat everything with the final test set
cols    <- setdiff(names(d.train), c('month', labels))
x.train <- as.matrix(d.trainvalid[, cols])
x.valid <- as.matrix(d.test[, cols])
rm(cols, d, d.train, d.valid, d.trainvalid, d.test)
gc()

kmm(0.01, 1000, x.train, x.valid, T)
kmm(1.28, 1000, x.train, x.valid, T)


