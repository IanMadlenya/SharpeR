# Copyright 2012-2013 Steven E. Pav. All Rights Reserved.
# Author: Steven E. Pav

# This file is part of SharpeR.
#
# SharpeR is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SharpeR is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with SharpeR.  If not, see <http://www.gnu.org/licenses/>.

# env var:
# nb: 
# see also:
# todo:
# changelog: 
#
# Created: 2012.05.19
# Copyright: Steven E. Pav, 2012-2013
# Author: Steven E. Pav
# Comments: Steven E. Pav

#' @include utils.r
#' @include distributions.r
#' @include sr.r

# note: on citations, use the Chicago style from google scholar. tks.

########################################################################
# Estimation 

# inference on the t-stat#FOLDUP

# standard error on the non-centrality parameter of a t-stat

# See Walck, section 33.3
.t_se_weird <- function(tstat,df) {
	cn <- .tbias(df)
	dn <- tstat / cn
	se <- sqrt(((1+dn**2) * (df/df-2)) - tstat**2)
	return(se)
}
# See Walck, section 33.5
.t_se_normal <- function(tstat,df) {
	se <- sqrt(1 + (tstat**2) / (2*df))
	return(se)
}
.t_se <- function(t,df,type=c("t","Lo","exact")) {
	# 2FIX: add opdyke corrections for skew and kurtosis?
	# 2FIX: add autocorrelation correction?
	type <- match.arg(type)
	se <- switch(type,
							 t = .t_se_normal(t,df),
							 Lo = .t_se_normal(t,df),
							 exact = .t_se_weird(t,df))
	return(se)
}
# confidence intervals on the non-centrality parameter of a t-stat
.t_confint <- function(tstat,df,level=0.95,type=c("exact","t","Z","F"),
					 level.lo=(1-level)/2,level.hi=1-level.lo) {
	type <- match.arg(type)
	if  (type == "exact") {
		ci.lo <- qlambdap(level.lo,df-1,tstat,lower.tail=TRUE)
		ci.hi <- qlambdap(level.hi,df-1,tstat,lower.tail=TRUE)
		ci <- c(ci.lo,ci.hi)
	} else if (type == "t") {
		se <- .t_se(tstat,df,type=type)
		midp <- tstat
		zalp <- qnorm(c(level.lo,level.hi))
		ci <- midp + zalp * se
	} else if (type == "Z") {
		se <- .t_se(tstat,df,type="t")
		midp <- tstat * (1 - 1 / (4 * df))
		zalp <- qnorm(c(level.lo,level.hi))
		ci <- midp + zalp * se
	} else if (type == "F") {
		# this is silly.
		se <- .t_se(tstat,df,type="exact")
		cn <- .tbias(df)
		midp <- z / cn
		zalp <- qnorm(c(level.lo,level.hi))
		ci <- midp + zalp * se
	} else stop("internal error")

	retval <- matrix(ci,nrow=1)
	colnames(retval) <- sapply(c(level.lo,level.hi),function(x) { sprintf("%g %%",100*x) })
	return(retval)
}
#UNFOLD

# confidence intervals on the Sharpe ratio#FOLDUP

#' @title Standard error computation
#' @rdname se
#' @export
se <- function(z, ...) {
	UseMethod("se", z)
}
#'
#' @rdname se
#' @method se default
#' @S3method se default
se.default <- function(z, ...) {
	stop("no generic standard error computation available")
}
#' @title Standard error of Sharpe ratio
#'
#' @description 
#'
#' Estimates the standard error of the Sharpe ratio statistic. 
#'
#' @details 
#'
#' For an observed Sharpe ratio, estimate the standard error.
#' There are two methods:
#'
#' \itemize{
#' \item The default, \code{t}, based on Johnson & Welch, with a correction
#' for small sample size, also known as \code{Lo}.
#' \item A method based on the exact variance of the non-central t-distribution,
#' \code{exact}.
#' }
#' There should be very little difference between these except for very small
#' sample sizes.
#'
#' @usage
#'
#' se(z, ...)
#'
#' se(z, type=c("t","Lo","exact"))
#'
#' @param z an observed Sharpe ratio statistic, of class \code{sr}.
#' @param type estimator type. one of \code{"t", "Lo", "exact"}
#' @param ... further arguments to be passed to or from methods.
#' @keywords htest
#' @return an estimate of standard error.
#' @seealso sr-distribution functions, \code{\link{dsr}}
#' @export 
#' @template etc
#' @template sr
#' @rdname se
#' @note
#' Eventually this should include corrections for autocorrelation, skew,
#' kurtosis.
#' @references 
#'
#' Walck, C. "Hand-book on STATISTICAL DISTRIBUTIONS for experimentalists."
#' 1996. \url{http://www.stat.rice.edu/~dobelman/textfiles/DistributionsHandbook.pdf}
#'
#' Johnson, N. L., and Welch, B. L. "Applications of the non-central t-distribution."
#' Biometrika 31, no. 3-4 (1940): 362-389. \url{http://dx.doi.org/10.1093/biomet/31.3-4.362}
#'
#' Lo, Andrew W. "The statistics of Sharpe ratios." Financial Analysts Journal 58, no. 4 
#' (2002): 36-52. \url{http://ssrn.com/paper=377260}
#'
#' Opdyke, J. D. "Comparing Sharpe Ratios: So Where are the p-values?" Journal of Asset
#' Management 8, no. 5 (2006): 308-336. \url{http://ssrn.com/paper=886728}
#'
#' @examples 
#' asr <- as.sr(rnorm(1000,0.2))
#' anse <- se(asr,type="t")
#' anse2 <- se(asr,type="exact")
#'
#' @export
#'
#' @method se sr
#' @S3method se sr
se.sr <- function(z, type=c("t","Lo","exact")) {
	tstat <- .sr2t(z)
	retval <- .t_se(tstat,df=z$df,type=type)
	retval <- .t2sr(z,retval)
	return(retval)
}

#' @title Confidence Interval on Signal-Noise Ratio
#'
#' @description 
#'
#' Computes approximate confidence intervals on the Signal-Noise ratio given the Sharpe ratio.
#'
#' @details 
#'
#' Constructs confidence intervals on the Signal-Noise ratio given observed
#' Sharpe ratio statistic. The available methods are:
#'
#' \itemize{
#' \item The default, \code{exact}, which is only exact when returns are
#' normal, based on inverting the non-central t
#' distribution.
#' \item A method based on the standard error of a non-central t distribution.
#' \item A method based on a normal approximation.
#' \item A method based on an F statistic.
#' }
#'
#' @usage
#'
#' confint(object,parm,level=0.95,...)
#'
#' @param object an observed Sharpe ratio statistic, of class \code{sr}.
#' @param parm ignored here
#' @param level the confidence level required.
#' @param ... the following parameters are relevant:
#' \itemize{
#' \item \code{type} is oe of \code{c("exact","t","Z","F")}
#' \item \code{level.lo}, and \code{level.hi} allow one to compute
#' non-symmetric CI.
#' }
#' @keywords htest
#' @return A matrix (or vector) with columns giving lower and upper
#' confidence limits for the SNR. These will be labelled as
#' level.lo and level.hi in \%, \emph{e.g.} \code{"2.5 \%"}
#' @seealso \code{\link{confint}}, \code{\link{se}}
#' @export 
#' @template etc
#' @template sr
#' @examples 
#' # using "sr" class:
#' ope <- 253
#' df <- ope * 6
#' xv <- rnorm(df, 1 / sqrt(ope))
#' mysr <- as.sr(xv,ope=ope)
#' confint(mysr,level=0.90)
#' # using "lm" class
#' yv <- xv + rnorm(length(xv))
#' amod <- lm(yv ~ xv)
#' mysr <- as.sr(amod,ope=ope)
#' confint(mysr,level.lo=0.05,level.hi=1.0)
#'
#' @rdname confint
#' @method confint sr 
#' @S3method confint sr 
confint.sr <- function(object,parm,level=0.95,...) {
	tstat <- .sr2t(object)
	retval <- .t_confint(tstat,df=object$df,level=level,...)
	retval <- .t2sr(object,retval)
	return(retval)
}
											 
#' @title Confidence Interval on Maximal Signal-Noise Ratio
#'
#' @description 
#'
#' Computes approximate confidence intervals on the Signal-Noise ratio given the Sharpe ratio.
#'
#' @details 
#'
#' Suppose \eqn{x_i}{xi} are \eqn{n}{n} independent draws of a \eqn{q}{q}-variate
#' normal random variable with mean \eqn{\mu}{mu} and covariance matrix
#' \eqn{\Sigma}{Sigma}. Let \eqn{\bar{x}}{xbar} be the (vector) sample mean, and 
#' \eqn{S}{S} be the sample covariance matrix (using Bessel's correction). 
#' Let 
#' \deqn{z_* = \sqrt{\bar{x}^{\top} S^{-1} \bar{x}}}{z* = sqrt(xbar' S^-1 xbar)}
#' Given observations of \eqn{z_*}{z*}, compute confidence intervals on the
#' population analogue, defined as
#' \deqn{\zeta_* = \sqrt{\mu^{\top} \Sigma^{-1} \mu}}{zeta* = sqrt(mu' Sigma^-1 mu)}
#'
#' @usage
#'
#' sropt_confint(z.s,df1,df2,level=0.95,
#'                ope=1,level.lo=(1-level)/2,level.hi=1-level.lo)
#'
#' @param z.s an observed Sharpe ratio statistic, annualized.
#' @inheritParams dsropt
#' @param level the confidence level required.
#' @template param-ope
#' @param level.lo the lower bound for the confidence interval.
#' @param level.hi the upper bound for the confidence interval.
#' @keywords htest
#' @return A matrix (or vector) with columns giving lower and upper
#' confidence limits for the SNR. These will be labelled as
#' level.lo and level.hi in \%, \emph{e.g.} \code{"2.5 \%"}
#' @seealso \code{\link{confint}}, \code{\link{sropt.test}}
#' @export 
#' @template etc
#' @template sropt
#' @rdname sropt_confint
#' @examples 
#' # fix these!
#' ope <- 253
#' df1 <- 6
#' df2 <- ope * 6
#' rvs <- as.matrix(rnorm(df1*df2),ncol=df1)
#' sro <- as.sropt(rvs)
#' aci <- confint(sro)
#'
#'@export
sropt_confint <- function(z.s,df1,df2,level=0.95,
											     ope=1,level.lo=(1-level)/2,level.hi=1-level.lo) {
	#2FIX: the order of arguments is really wonky. where does ope go?
	#if (!missing(ope)) {
		#z.s <- .deannualize(z.s,ope)
	#}

	ci.hi <- qco_sropt(level.hi,df1=df1,df2=df2,z.s=z.s,ope=ope,lower.tail=TRUE)
	ci.lo <- qco_sropt(level.lo,df1=df1,df2=df2,z.s=z.s,ope=ope,lower.tail=TRUE,ub=ci.hi)
	ci <- c(ci.lo,ci.hi)

	retval <- matrix(ci,nrow=1)
	colnames(retval) <- sapply(c(level.lo,level.hi),function(x) { sprintf("%g %%",100*x) })
	return(retval)
}
#2FIX: this is orphaned. is not described anywhere. bleah.
#' @export
#' @param parm ignored here
#' @rdname sropt_confint
#' @method confint sropt
#' @S3method confint sropt
confint.sropt <- function(z.s,parm,level=0.95,...) {
	retval <- sropt_confint(z.s$sropt,z.s$df1,z.s$df2,level=level,ope=z.s$ope,...)
	return(retval)
}

#UNFOLD

# point inference on sropt/ncp of F#FOLDUP

# compute an unbiased estimator of the non-centrality parameter
.F_ncp_unbiased <- function(Fs,df1,df2) {
	ncp.unb <- (Fs * (df2 - 2) * df1 / df2) - df1
	return(ncp.unb)
}

#MLE of the ncp based on a single F-stat
.F_ncp_MLE_single <- function(Fs,df1,df2,ub=NULL,lb=0) {
	if (Fs <= 1) { return(0.0) }  # Spruill's Thm 3.1, eqn 8
	max.func <- function(z) { df(Fs,df1,df2,ncp=z,log=TRUE) }

	if (is.null(ub)) {
		prevdpf <- -Inf
		ub <- 1
		dpf <- max.func(ub)
		while (prevdpf < dpf) {
			prevdpf <- dpf
			ub <- 2 * ub
			dpf <- max.func(ub)
		}
		lb <- ifelse(ub > 2,ub/4,lb)
	}
	ncp.MLE <- optimize(max.func,c(lb,ub),maximum=TRUE)$maximum;
	return(ncp.MLE)
}
.F_ncp_MLE <- Vectorize(.F_ncp_MLE_single,
											vectorize.args = c("Fs","df1","df2"),
											SIMPLIFY = TRUE)

# KRS estimator of the ncp based on a single F-stat
.F_ncp_KRS <- function(Fs,df1,df2) {
	xbs <- Fs * (df1/df2)
	delta0 <- (df2 - 2) * xbs - df1
	phi2 <- 2 * xbs * (df2 - 2) / (df1 + 2)
	delta2 <- pmax(delta0,phi2)
	return(delta2)
}
# ' @usage
# '
# ' F.inference(Fs,df1,df2,...)
# '
# ' @export
# ' @param Fs a (non-central) F statistic.
# ' @examples 
# ' rvs <- rf(1024, 4, 1000, 5)
# ' unbs <- F.inference(rvs, 4, 1000, type="unbiased")
F.inference <- function(Fs,df1,df2,type=c("KRS","MLE","unbiased")) {
	# type defaults to "KRS":
	type <- match.arg(type)
	Fncp <- switch(type,
								 MLE = .F_ncp_MLE(Fs,df1,df2),
								 KRS = .F_ncp_KRS(Fs,df1,df2),
								 unbiased = .F_ncp_unbiased(Fs,df1,df2))
	return(Fncp)
}
# ' @usage
# '
# ' T2.inference(T2,df1,df2,...)
# '
# ' @export
# ' @param T2 a (non-central) Hotelling \eqn{T^2} statistic.
T2.inference <- function(T2,df1,df2,...) {
	Fs <- .T2_to_F(T2, df1, df2)
	Fdf1 <- df1
	Fdf2 <- df2 - df1
	retv <- F.inference(Fs,Fdf1,Fdf2,...)
	# the NCP is legit
	retv <- retv
	return(retv)
}
#' @title Inference on noncentrality parameter of F or F-like statistic 
#'
#' @description 
#'
#' Estimates the non-centrality parameter associated with an observed
#' statistic following a (non-central) F, \eqn{T^2}, or sropt distribution. 
#'
#' @details 
#'
#' Let \eqn{F}{F} be an observed statistic distributed as a non-central F with 
#' \eqn{\nu_1}{df1}, \eqn{\nu_2}{df2} degrees of freedom and non-centrality 
#' parameter \eqn{\delta^2}{delta^2}. Three methods are presented to
#' estimate the non-centrality parameter from the statistic:
#'
#' \itemize{
#' \item an unbiased estimator, which, unfortunately, may be negative.
#' \item the Maximum Likelihood Estimator, which may be zero, but not
#' negative.
#' \item the estimator of Kubokawa, Roberts, and Shaleh (KRS), which
#' is a shrinkage estimator.
#' }
#'
#' The sropt distribution is equivalent to an F distribution up to a 
#' square root and some rescalings. 
#' 
#' The non-centrality parameter of the sropt distribution is 
#' the square root of that of the Hotelling, \emph{i.e.} has
#' units 'per square root time'. As such, the \code{'unbiased'}
#' type can be problematic!
#'
#' @usage
#'
#' inference(z.s,type=c("KRS","MLE","unbiased"))
#'
#' @param z.s an object of type \code{sropt}.
#' @inheritParams dsropt
#' @param type the estimator type. one of \code{c("KRS", "MLE", "unbiased")}
#' @keywords htest
#' @return an estimate of the non-centrality parameter.
#' @seealso F-distribution functions, \code{\link{df}}
#' @export 
#' @template etc
#' @family sropt Hotelling
#' @references 
#'
#' Kubokawa, T., C. P. Robert, and A. K. Saleh. "Estimation of noncentrality parameters." 
#' Canadian Journal of Statistics 21, no. 1 (1993): 45-57. \url{http://www.jstor.org/stable/3315657}
#'
#' Spruill, M. C. "Computation of the maximum likelihood estimate of a noncentrality parameter." 
#' Journal of multivariate analysis 18, no. 2 (1986): 216-224.
#' \url{http://www.sciencedirect.com/science/article/pii/0047259X86900709}
#'
#' @examples 
#' # generate some sropts
#' nfac <- 5
#' nyr <- 10
#' ope <- 253
#' # simulations with no covariance structure.
#' # under the null:
#' set.seed(as.integer(charToRaw("determinstic")))
#' Returns <- matrix(rnorm(ope*nyr*nfac,mean=0,sd=0.0125),ncol=nfac)
#' asro <- as.sropt(Returns,drag=0,ope=ope)
#' est1 <- inference(asro,type='unbiased')  
#' est2 <- inference(asro,type='KRS')  
#' est3 <- inference(asro,type='MLE')
#' 
#' # under the alternative:
#' Returns <- matrix(rnorm(ope*nyr*nfac,mean=0.0005,sd=0.0125),ncol=nfac)
#' asro <- as.sropt(Returns,drag=0,ope=ope)
#' est1 <- inference(asro,type='unbiased')  
#' est2 <- inference(asro,type='KRS')  
#' est3 <- inference(asro,type='MLE')
#'
#' # sample many under the alternative, look at the estimator.
#' df1 <- 6
#' df2 <- 2000
#' ope <- 253
#' zeta.s <- 1.25
#' rvs <- rsropt(500, df1, df2, zeta.s, ope)
#' roll.own <- sropt(z.s=rvs,df1,df2,drag=0,ope=ope)
#' est1 <- inference(roll.own,type='unbiased')  
#' est2 <- inference(roll.own,type='KRS')  
#' est3 <- inference(roll.own,type='MLE')
#'
inference <- function(z.s,type=c("KRS","MLE","unbiased")) {
	# type defaults to "KRS":
	type <- match.arg(type)
	T2 <- .sropt2T(z.s)
	retval <- T2.inference(T2,z.s$df1,z.s$df2,type)
	# convert back
	retval <- .T2sropt(z.s,retval)
	return(retval)
}
#UNFOLD

# notes:
# extract statistics (t-stat) from lm object:
# https://stat.ethz.ch/pipermail/r-help/2009-February/190021.html

# to get a hotelling statistic from n x k matrix x:
# myt <- summary(manova(lm(x ~ 1)),test="Hotelling-Lawley",intercept=TRUE)
#              Df Hotelling-Lawley approx F num Df den Df Pr(>F)
#(Intercept)   1          0.00606     1.21      5    995    0.3
#
# HLT <- myt$stats[1,"Hotelling-Lawley"]
#
# myt <- summary(manova(lm(x ~ 1)),intercept=TRUE)
# HLT <- sum(myt$Eigenvalues) #?
# ...

## junkyard#FOLDUP

##compute the asymptotic mean and variance of the sqrt of a
##non-central F distribution

#f_sqrt_ncf_asym_mu <- function(df1,df2,ncp = 0) {
	#return(sqrt((df2 / (df2 - 2)) * (df1 + ncp) / df1))
#}
#f_sqrt_ncf_asym_var <- function(df1,df2,ncp = 0) {
	#return((1 / (2 * df1)) * 
				 #(((df1 + ncp) / (df2 - 2)) + (2 * ncp + df1) / (df1 + ncp)))
#}
#f_sqrt_ncf_apx_pow <- function(df1,df2,ncp,alpha = 0.05) {
	#zalp <- qnorm(1 - alpha)
	#numr <- 1 - f_sqrt_ncf_asym_mu(df1,df2,ncp = ncp) + zalp / sqrt(2 * df1)
	#deno <- sqrt(f_sqrt_ncf_asym_var(df1,df2,ncp = ncp))
	#return(1 - pnorm(numr / deno))
#}
##UNFOLD

#for vim modeline: (do not edit)
# vim:fdm=marker:fmr=FOLDUP,UNFOLD:cms=#%s:syn=r:ft=r
