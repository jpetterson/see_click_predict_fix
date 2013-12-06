library(gbm)

key2filename <- function(out.dir, what, depth, label, n.trees, expn, final=F, suffix='Rd') {
	sprintf('%s/%s%s_depth_%d_label_%s_expn_%d_%d.%s', out.dir, ifelse(final, 'final/', ''), what, depth, label, expn, n.trees, suffix)
}

train.gbms <- function(max.n.trees, step.n.trees, depths, labels, d.train, x.train, out.dir, expn) {
	system(sprintf('mkdir -p %s', out.dir))
	params <- expand.grid(label=labels, depth=depths, stringsAsFactors=F)

	foreach (j = 1:nrow(params)) %dopar% {
		depth   <- params$depth[j]
		label   <- params$label[j]
		model   <- NULL
		n.i     <- max.n.trees/step.n.trees
		y.train <- d.train[, label]

		for(i in 1:n.i) 
		{
			cat(sprintf("%s: depth %d, label %s, %d/%d\n", date(), depth, label, i, n.i))
			n.trees <- i*step.n.trees

			sink(key2filename(out.dir, 'log', depth, label, n.trees, expn, F, 'txt'))
			if (is.null(model))
			{
				model <- gbm.fit(x.train, y.train, distribution="gaussian", n.trees=step.n.trees, interaction.depth=depth, verbose=T)
			}
			else
			{
				model <- gbm.more(model, n.new.trees <- step.n.trees)
			}
			sink()

			save(model, file=key2filename(out.dir, 'model', depth, label, n.trees, expn))

			# delete previous model (to save space)
			if (i>1)
			{
				unlink(key2filename(out.dir, 'model', depth, label, n.trees-step.n.trees, expn))
			}
		}
	}
}

test.gbms <- function(out.dir, eval.step=200) {
	models <- list.files(out.dir, 'model')
	r      <- foreach (m = models, .combine=rbind) %dopar% {
		depth   <- as.integer(gsub('.*depth_([0-9]*)_.*', '\\1', m))
		label   <- gsub('.*label_(l_[^_]*)_.*', '\\1', m)
		expn    <- as.integer(gsub('.*expn_([0-9]*)_.*', '\\1', m))
		ntrees  <- as.integer(gsub('.*_([0-9]*).Rd', '\\1', m))
		model.f <- sprintf('%s/%s', out.dir, m)
		y.valid <- d.valid[, label]

		cat(sprintf("depth %d, label %s, ntrees %d\n", depth, label, ntrees))
		load(model.f)

		foreach(n.trees = seq(eval.step, ntrees, eval.step), .combine=rbind) %do% {
			cat(sprintf("depth %d, n.trees %d\n", depth, n.trees))

			p.file <- key2filename(out.dir, 'predictions', depth, label, n.trees, expn)
			if (file.exists(p.file)) {
				load(p.file)
			} else {
				p <- predict(model, x.valid, n.trees=n.trees)
				save(p, file=p.file)
			}
			rmse <- sqrt(mean((y.valid-p)^2))
			data.frame(expn, label, n.trees, depth, rmse)
		}
	}
}


train.final <- function(out.dir, d.trainvalid, x.train, x.test, expn, r2) {
	system(sprintf('mkdir -p %s/final', out.dir))
	foreach (j = 1:nrow(r2)) %dopar% {
		depth   <- r2$depth[j]
		label   <- r2$label[j]
		n.trees <- r2$n.trees[j]
		y.train <- d.trainvalid[, label]

		model.file <- key2filename(out.dir, 'model', depth, label, n.trees, expn, T)
		if (file.exists(model.file)) {
			load(model.file)
		} else {
			set.seed(1)
			model <- gbm.fit(x.train, y.train, distribution="gaussian", n.trees=n.trees, interaction.depth=depth, verbose=T)
			save(model, file=model.file)
		}

		p <- predict(model, x.test, n.trees=n.trees)
		save(p, file=key2filename(out.dir, 'predictions', depth, label, n.trees, expn, T))
	}
}

build.sub <- function(out.dir, expn, r2) {
	# build submission file
	ps <- foreach (j = 1:nrow(r2), .combine=cbind) %dopar% {
		depth   <- r2$depth[j]
		label   <- r2$label[j]
		n.trees <- r2$n.trees[j]
		load(key2filename(out.dir, 'predictions', depth, label, n.trees, expn, T))
		p
	}
	ps        <- as.data.frame(ps)
	names(ps) <- r2$label
	ps        <- expm1(ps)
	names(ps) <- gsub('l_', 'num_', names(ps))
	ps$id     <- d.test$id
	ps        <- ps[, c('id','num_views','num_votes','num_comments')]
	ps
}

