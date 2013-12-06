library(randomForest)
library(doMC)
registerDoMC()
source('subs.R')
source('common.R')


key2filename <- function(what, mtry, label, n.trees, expn, seed, final=F, suffix='Rd') {
	sprintf('%s/%s%s_mtry_%d_label_%s_seed_%d_expn_%d_ntrees_%d.%s', out.dir(expn), ifelse(final, 'final/', ''), what, mtry, label, seed, expn, n.trees, suffix)
}

train.rfs <- function(n.trees, n.seeds, mtrys, labels, y.train, x.train, expn) {
	system(sprintf('mkdir -p %s', out.dir(expn)))

	params <- expand.grid(label=labels, mtrys=mtrys, seed=1:n.seeds, stringsAsFactors=F)

	foreach (i = 1:nrow(params)) %dopar% {
		mtry   <- params$mtry[i]
		label  <- params$label[i]
		seed   <- params$seed[i]
		y      <- y.train[, label]

		sink(key2filename('log', mtry, label, n.trees, expn, seed, F, 'txt'))
		set.seed(seed)
		model <- randomForest(x.train, y, ntree=n.trees, mtry=mtry, do.trace=T, keep.forest=T)
		sink()

		save(model, file=key2filename('model', mtry, label, n.trees, expn, seed))
		
		p.valid <- predict(model, x.valid)
		save(p.valid, file=key2filename('predictions', mtry, label, n.trees, expn, seed))
	}
}

test.rfs <- function(expn, y.valid) {
	# get metadata about experiments
	models <- list.files(out.dir(expn), 'predictions')
	r      <- foreach (m = models, .combine=rbind) %dopar% {
		mtry    <- as.integer(gsub('.*mtry_([0-9]*)_.*', '\\1', m))
		seed    <- as.integer(gsub('.*seed_([0-9]*)_.*', '\\1', m))
		label   <- gsub('.*label_(l_[^_]*)_.*', '\\1', m)
		ntrees  <- as.integer(gsub('.*ntrees_([0-9]*).Rd', '\\1', m))
		p.file  <- sprintf('%s/%s', out.dir(expn), m)
		data.frame(expn, label, ntrees, mtry, seed, p.file, stringsAsFactors=F)
	}

	# for each combination of parameters (except seed)
	foreach(r2 = split(r, list(r$label, r$ntrees, r$mtry)), .combine=rbind) %dopar% {
		if (nrow(r2)>0) {
			y <- y.valid[, r2$label[1]]

			# get all predictions (one for each seed)
			ps <- foreach(f = r2$p.file, .combine=rbind) %do% {
				load(f)
				p.valid
			}

			# compute the rmse for the first prediction, the average of the first two, the average of the first three, etc
			rmses <- if (nrow(r2)==1) {
				sqrt(mean((ps-y)^2))
			} else {
				foreach(i = 1:nrow(ps), .combine=c) %do% {
					p <- if (i==1) {
						ps[1,]
					} else {
						colMeans(ps[1:i,])
					}
					sqrt(mean((p-y)^2))
				}
			}
			r2$rmse <- rmses
			r2
		} else { NULL }
	}
}

test.rfs.1seed <- function(expn, x.valid, y.valid) {
	# get metadata about experiments
	models <- list.files(out.dir(expn), 'predictions')
	r      <- foreach (m = models, .combine=rbind) %dopar% {
		mtry    <- as.integer(gsub('.*mtry_([0-9]*)_.*', '\\1', m))
		seed    <- as.integer(gsub('.*seed_([0-9]*)_.*', '\\1', m))
		label   <- gsub('.*label_(l_[^_]*)_.*', '\\1', m)
		ntrees  <- as.integer(gsub('.*ntrees_([0-9]*).Rd', '\\1', m))
		p.file  <- sprintf('%s/%s', out.dir(expn), m)
		m.file  <- gsub('predictions', 'model', p.file)
		data.frame(expn, label, ntrees, mtry, seed, m.file, stringsAsFactors=F)
	}
	r <- r[r$seed==1,]

	foreach(i = 1:nrow(r), .combine=rbind) %dopar% {
		y <- y.valid[, r$label[i]]

		load(r$m.file[i])
		ps    <- t(predict(model, x.valid, predict.all=T)$individual)
		rmses <- foreach(j = 1:nrow(ps), .combine=c) %do% {
			p <- if (j==1) {
				ps[1,]
			} else {
				colMeans(ps[1:j,])
			}
			sqrt(mean((p-y)^2))
		}
		data.frame(expn=r$expn[i], label=r$label[i], mtry=r$mtry[i], n.trees=1:nrow(ps), rmse=rmses)
	}
}


train.rfs.final <- function(y.train, x.train, x.test, test_ids, expn, r2, w.train=NULL) {
	system(sprintf('mkdir -p %s/final', out.dir(expn)))
	ps <- foreach (j = 1:nrow(r2)) %dopar% {
		mtry    <- r2$mtry[j]
		label   <- r2$label[j]
		n.trees <- r2$n.trees[j]
		y       <- y.train[, label]

		model.file <- key2filename('model', mtry, label, n.trees, expn, 1, T)
		if (file.exists(model.file)) {
			load(model.file)
		} else {
			set.seed(1)
			model <- randomForest(x.train, y, ntree=n.trees, mtry=mtry, do.trace=T, keep.forest=T)
			save(model, file=model.file)
		}

		p.file <- key2filename('predictions', mtry, label, n.trees, expn, 1, T)
		if (file.exists(p.file)) {
			load(p.file)
		} else {
			p <- predict(model, x.test)
			save(p, file=p.file)
		}
		p
	}

	ps        <- as.data.frame(ps)
	names(ps) <- r2$label
	ps        <- expm1(ps)
	names(ps) <- gsub('l_', 'num_', names(ps))
	ps$id     <- test_ids
	ps        <- ps[, c('id','num_views','num_votes','num_comments')]
	ps
}




#   14
# ----

load('out/data1e.Rd')
source('data_split.R')

expn    <- 14
cols    <- c('latitude', 'longitude', 'source', 'has.descr', 'clean.summary2', 'clean.tag_type', 'city', 'wday', 'hour', 'summary.nchar', 'description.nchar', 'summary.nword', 'description.nword', 'summary.ncaps', 'summary.nexcl', 'description.ncaps', 'description.nexcl')
x.train <- d.train[, cols]
x.valid <- d.valid[, cols]
y.train <- d.train[, labels]
y.valid <- d.valid[, labels]

train.rfs(100, 100, 3:8, labels, y.train, x.train, expn)
r <- test.rfs.1seed(expn, x.valid, y.valid)
r2 <- foreach(rs = split(r, r$label), .combine=rbind) %do% { rs[which.min(rs$rmse),] }
save(r, r2, file=sprintf('%s/results1.Rd', out.dir(expn)))

# expn      label mtry n.trees      rmse
#   14 l_comments    3     100 0.2093755
#   14    l_views    3      52 0.6224450
#   14    l_votes    4     100 0.1591173


y.train <- d.trainvalid[, labels]
x.train <- d.trainvalid[, cols]
x.test  <- d.test[, cols]
ps      <- train.rfs.final(y.train, x.train, x.test, d.test$id, expn, r2)
save.subs(ps, expn)

