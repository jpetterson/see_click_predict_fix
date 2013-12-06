library(doMC)
registerDoMC()
library(nnet)
source('subs.R')
source('common.R')

load('out/data3.Rd')
source('data_split.R')

get.id.column <- function() {
	load('subs/02.Rd')
	ps$id
}

train.valid <- function(x.train, y.train, x.valid, y.valid, expn, labels, sizes, decays) {
	foreach(i = 1:nrow(params), .combine=rbind) %dopar% {
		key        <- sprintf('label_%s_size_%d_decay_%f.Rd', params$label[i], params$size[i], params$decay[i])
		model.file <- sprintf('out/%d/model_%s.Rd', expn, key)
		log.file   <- sprintf('out/%d/log_%s.txt', expn, key)

		y.t     <- y.train[, params$label[i]]
		y.v     <- y.valid[, params$label[i]]
		y.scale <- max(y.t) # y should be in the 0-1 range

		if (file.exists(model.file)) {
			load(model.file)
		} else {
			sink(log.file)
			m <- nnet(x=x.train, y=y.t/y.scale, size=params$size[i], decay=params$decay[i], linout=TRUE, maxit=2000)
			p <- predict(m, x.valid, type='raw')
			save(m, p, file=model.file)
			sink()
		}
		data.frame(label=params$label[i], size=params$size[i], decay=params$decay[i], rmse = sqrt(mean(((p*y.scale)-y.v)^2)))
	}
}

train.final <- function(x.train, y.train, x.test, test_ids, expn, r2) {
	system(sprintf('mkdir -p %s/final', out.dir(expn)))

	ps <- foreach (i = 1:nrow(r2)) %dopar% {
		key        <- sprintf('label_%s_size_%d_decay_%f.Rd', r2$label[i], r2$size[i], r2$decay[i])
		model.file <- sprintf('out/%d/final/model_%s.Rd', expn, key)

		y.t     <- y.train[, r2$label[i]]
		y.scale <- max(y.t) # y should be in the 0-1 range
		
		if (file.exists(model.file)) {
			load(model.file)
		} else {
			set.seed(1)
			model <- nnet(x=x.train, y=y.t/y.scale, size=r2$size[i], decay=r2$decay[i], linout=TRUE, maxit=2000)
			p     <- predict(model, x.test, type='raw')
			save(p, model, file=model.file)
		}
		p*y.scale
	}

	ps        <- as.data.frame(ps)
	names(ps) <- r2$label
	ps        <- expm1(ps)
	names(ps) <- gsub('l_', 'num_', names(ps))
	ps$id     <- test_ids
	ps        <- ps[, c('id','num_views','num_votes','num_comments')]
	ps
}


expn    <- 13
cols    <- setdiff(names(d.train), c('month', 'latitude', 'longitude', labels))
x.train <- as.matrix(d.train[, cols])
x.valid <- as.matrix(d.valid[, cols])
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.valid(x.train, y.train, x.valid, y.valid, expn, labels, 1:8, c(0, 0.1, 0.01, 0.001, 0.0001))
save(r, file=sprintf('out/%d/results1.Rd', expn))

r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
#      label size decay      rmse
# l_comments    2  0.10 0.2100016
#    l_views    3  0.01 0.6202113
#    l_votes    3  0.01 0.1666642


y.train  <- d.trainvalid[, labels]
x.train  <- d.trainvalid[, cols]
x.test   <- d.test[, cols]
ps       <- train.final(x.train, y.train, x.test, get.id.column(), expn, r2)
ps[ps<0] <- 0

save.subs(ps, expn)

