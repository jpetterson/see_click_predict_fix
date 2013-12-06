library(randomForest)
library(doMC)
registerDoMC()
source('common.R')

expn <- 11
load('out/data1d.Rd')
system(sprintf('mkdir -p %s', out.dir(expn)))



# random forest cannot deal with more then 32 levels in a categorical var
tmp <- c(as.character(d$clean.summary), as.character(d.test$clean.summary))
ns  <- sort(table(tmp))
tmp[tmp %in% names(ns)[ns<200]] <- 'Other'
tmp <- as.factor(tmp)
n1  <- nrow(d)
n2  <- nrow(d.test)
d$clean.summary2      <- tmp[1:n1]
d.test$clean.summary2 <- tmp[(n1+1):(n1+n2)]
rm(tmp, ns, n1, n2)



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


# build trees
n.trees <- 100
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
for(i in 1:n.execs) {
	load(sprintf('%s/p_execn_%d.Rd', out.dir(expn), i))
	if (i==1) {
		p.valid.all <- p.valid
		p.test.all  <- p.test
	} else {
		p.valid.all <- p.valid.all + p.valid
		p.test.all  <- p.test.all  + p.test
	}
}
p.valid <- p.valid.all/n.execs
p.test  <- p.test.all/n.execs

w.per.month.valid <- colMeans(p.valid[y.valid=='2013-04',]) # 2013-04 is the month we use for validation
w.per.month.test  <- colMeans(p.test)
save(w.per.month.valid, w.per.month.test, file = 'out/w_per_month.Rd')

