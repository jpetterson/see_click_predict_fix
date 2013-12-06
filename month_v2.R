library(randomForest)
library(doMC)
registerDoMC()
source('common.R')

expn <- 16
load('out/data1e.Rd')
system(sprintf('mkdir -p %s', out.dir(expn)))


# split data in train and valid, both from the same period
set.seed(1)
idxs    <- sample(nrow(d), 0.8*nrow(d))
y       <- as.factor(d$month)
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary2', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')
y.train <- y[idxs]
y.valid <- y[-idxs]
x.train <- d[idxs, cols]
x.valid <- d[-idxs, cols]
x.test  <- d.test[, cols]



# sample to have the same number of instances in each class
set.seed(1)
min.train  <- min(table(y.train))
idxs.train <- foreach(m = unique(y.train), .combine=c) %dopar% {
	idxs <- which(y.train==m)
	sample(idxs, min.train)
}

min.valid  <- min(table(y.valid))
idxs.valid <- foreach(m = unique(y.valid), .combine=c) %dopar% {
	idxs <- which(y.valid==m)
	sample(idxs, min.valid)
}

y.train <- y.train[idxs.train]
y.valid <- y.valid[idxs.valid]
x.train <- x.train[idxs.train,]
x.valid <- x.valid[idxs.valid,]



# build trees
n.trees <- 10
n.execs <- 20

foreach(i = 1:n.execs) %dopar% {
	set.seed(i)
	m <- randomForest(x.train, y.train, ntree=n.trees, do.trace=T, keep.forest=T)
	save(m, file=sprintf('%s/model_execn_%d.Rd', out.dir(expn), i))

	p.valid <- predict(m, x.valid, type='prob')
	p.test  <- predict(m, x.test,  type='prob')
	save(p.valid, p.test, file=sprintf('%s/p_execn_%d.Rd', out.dir(expn), i))
}


# combine predictions
foreach(i = 1:n.execs, .combine=rbind) %do% {
	load(sprintf('%s/p_execn_%d.Rd', out.dir(expn), i))
	if (i==1) {
		p.valid.all <- p.valid
		p.test.all  <- p.test
	} else {
		p.valid.all <- p.valid.all + p.valid
		p.test.all  <- p.test.all  + p.test
	}

	# test predictiveness
	p <- colnames(p.valid)[apply(p.valid, 1, which.max)]
	data.frame(i, acc=mean(p==y.valid))
}

p.valid <- p.valid.all/n.execs
p.test  <- p.test.all/n.execs


w.per.month.valid <- colMeans(p.valid[y.valid=='2013-04',]) # 2013-04 is the month we use for validation
w.per.month.test  <- colMeans(p.test)
save(w.per.month.valid, w.per.month.test, file = 'out/w_per_month_v2.Rd')

