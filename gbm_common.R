library(gbm)
library(doMC)
registerDoMC()

key2filename <- function(what, depth, label, n.trees, expn, final=F, suffix='Rd') {
	sprintf('%s/%s%s_depth_%d_label_%s_expn_%d_%d.%s', out.dir(expn), ifelse(final, 'final/', ''), what, depth, label, expn, n.trees, suffix)
}

train.gbms <- function(max.n.trees, step.n.trees, depths, labels, y.train, x.train, expn, w.train=NULL, distribution='gaussian') {
	system(sprintf('mkdir -p %s', out.dir(expn)))
	params <- expand.grid(label=labels, depth=depths, stringsAsFactors=F)

	foreach (j = 1:nrow(params)) %dopar% {
		depth   <- params$depth[j]
		label   <- params$label[j]
		model   <- NULL
		n.i     <- max.n.trees/step.n.trees
		y       <- y.train[, label]

		for(i in 1:n.i) 
		{
			cat(sprintf("%s: depth %d, label %s, %d/%d\n", date(), depth, label, i, n.i))
			n.trees <- i*step.n.trees

			sink(key2filename('log', depth, label, n.trees, expn, F, 'txt'))
			if (is.null(model))
			{
				model <- gbm.fit(x.train, y, distribution=distribution, n.trees=step.n.trees, interaction.depth=depth, verbose=T, w = w.train)
			}
			else
			{
				model <- gbm.more(model, n.new.trees = step.n.trees, weights = w.train)
			}
			sink()

			save(model, file=key2filename('model', depth, label, n.trees, expn))

			# delete previous model (to save space)
			if (i>1)
			{
				unlink(key2filename('model', depth, label, n.trees-step.n.trees, expn))
			}
		}
	}
}

test.gbms <- function(expn, y.valid, eval.step=200, eval.step.beginning=0) {
	models <- list.files(out.dir(expn), 'model')
	r      <- foreach (m = models, .combine=rbind) %dopar% {
		depth   <- as.integer(gsub('.*depth_([0-9]*)_.*', '\\1', m))
		label   <- gsub('.*label_(l_[^_]*)_.*', '\\1', m)
		ntrees  <- as.integer(gsub('.*_([0-9]*).Rd', '\\1', m))
		model.f <- sprintf('%s/%s', out.dir(expn), m)
		y       <- y.valid[, label]

		cat(sprintf("depth %d, label %s, ntrees %d\n", depth, label, ntrees))
		load(model.f)

		seq.eval <- seq(eval.step, ntrees, eval.step)
		if (eval.step.beginning>0) {
			seq.eval <- c(seq(0, seq.eval[1]-1, eval.step.beginning), seq.eval)
		}

		foreach(n.trees = seq.eval, .combine=rbind) %do% {
			cat(sprintf("depth %d, n.trees %d\n", depth, n.trees))

			p.file <- key2filename('predictions', depth, label, n.trees, expn)
			if (file.exists(p.file)) {
				load(p.file)
			} else {
				p <- predict(model, x.valid, n.trees=n.trees)
				save(p, file=p.file)
			}
			rmse <- sqrt(mean((y-p)^2))
			data.frame(expn, label, n.trees, depth, rmse, stringsAsFactors=F)
		}
	}
}


train.final <- function(y.train, x.train, x.test, test_ids, expn, r2, w.train=NULL, distribution='gaussian') {
	system(sprintf('mkdir -p %s/final', out.dir(expn)))
	ps <- foreach (j = 1:nrow(r2)) %dopar% {
		depth   <- r2$depth[j]
		label   <- r2$label[j]
		n.trees <- r2$n.trees[j]
		y       <- y.train[, label]

		model.file <- key2filename('model', depth, label, n.trees, expn, T)
		if (file.exists(model.file)) {
			load(model.file)
		} else {
			set.seed(1)
			model <- gbm.fit(x.train, y, distribution=distribution, n.trees=n.trees, interaction.depth=depth, verbose=T, w = w.train)
			save(model, file=model.file)
		}

		p.file <- key2filename('predictions', depth, label, n.trees, expn, T)
		if (file.exists(p.file)) {
			load(p.file)
		} else {
			p <- predict(model, x.test, n.trees=n.trees)
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


