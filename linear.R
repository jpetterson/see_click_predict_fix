library(doMC)
registerDoMC()
source('linear_regression.R')
source('common.R')
source('subs.R')

learn.models <- function(lambdas) {
	foreach(lambda = lambdas, .combine=rbind) %dopar% {
		foreach(label = labels, .combine=rbind) %do% {
			cat(sprintf('label %s, lambda %f\n', label, lambda))
			yt <- y.train[, label]
			yv <- y.valid[, label]
			file.name <- sprintf('out/%d/%s_lambda_%f.Rd', expn, label, lambda)
			if (file.exists(file.name)) {
				load(file.name)
			} else {
				r <- linear.regression.no.const(x.train, yt, x.valid, yv, lambda=lambda)
				save(r, file=file.name)
			}

			data.frame(label, lambda, rmse=r$rmse, filename=file.name, stringsAsFactors=F)
		}
	}
}

get.id.column <- function() {
	load('subs/02.Rd')
	ps$id
}

train.final <- function(x.train, x.valid, y.train, r2, expn) {
	foreach (i = 1:nrow(r2), .combine=cbind) %do% {
		label  <- r2$label[i]
		lambda <- r2$lambda[i]
		model  <- linear.regression(x.train, y.train[,label], x.valid, rep(0, nrow(x.valid)), lambda=1.0)
		save(model, file=sprintf('out/%d/%s_lambda_%f_final.Rd', expn, label, lambda))
	}
}

build.sub <- function(r2, expn) {
	ps <- foreach(i = 1:nrow(r2), .combine=cbind) %do% {
		load(sprintf('out/%d/%s_lambda_%f_final.Rd', expn, r2$label[i], r2$lambda[i]))
		model$p
	}
	ps           <- as.data.frame(ps)
	ps           <- expm1(ps)
	names(ps)    <- sprintf('num_%s', gsub('l_', '', r2$label))
	ps$id        <- get.id.column()
	rownames(ps) <- NULL

	ps$num_votes[ps$num_votes<1]       <- 1
	ps$num_comments[ps$num_comments<0] <- 0
	ps$num_views[ps$num_views<0]       <- 0

	ps[, c("id", "num_views", "num_votes", "num_comments")]
}

#----------------------------------------------------------------------------------------------------
load('out/data3.Rd')
source('data_split.R')
source('common.R')

expn    <- 5
cols    <- setdiff(names(d.train), c('month', labels))
lambdas <- 10**(-5:6)
x.train <- as.matrix(d.train[, cols])
x.valid <- as.matrix(d.valid[, cols])
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]
rm(cols, d, d.train, d.valid, d.trainvalid, d.test)
gc()


r <- learn.models(lambdas)
save(r, file=sprintf('out/%d/results1.Rd', expn))

# best result for each label
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }

#      label lambda      rmse
# l_comments  1e+04 0.2086884
#    l_views  1e+03 0.6223436
#    l_votes  1e-05 0.1799212




# build final models
x.train <- as.matrix(d.trainvalid[, cols])
x.valid <- as.matrix(d.test[, cols])
y.train <- d.trainvalid[, labels]
train.final(x.train, x.valid, y.train, r2, expn)
ps <- build.sub(r2, expn)
save.subs(ps, expn)

