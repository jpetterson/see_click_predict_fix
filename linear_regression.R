linear.regression.no.const <- function(x.train, y.train, x.valid, y.valid, lambda=1.0)
{
	w          <- solve(lambda*diag(ncol(x.train))+(t(x.train) %*% x.train)) %*% (t(x.train) %*% y.train)
	p          <- data.matrix(x.valid) %*% w
	list(p=p, w=w, rmse=sqrt(mean((y.valid-p)^2)))
}

linear.regression <- function(x.train, y.train, x.valid, y.valid, lambda=1.0)
{
	x.train    <- cbind(x.train, const=1)
	x.valid    <- cbind(x.valid, const=1)
	w          <- solve(lambda*diag(ncol(x.train))+(t(x.train) %*% x.train)) %*% (t(x.train) %*% y.train)
	p          <- data.matrix(x.valid) %*% w
	list(p=p, w=w, rmse=sqrt(mean((y.valid-p)^2)))
}

