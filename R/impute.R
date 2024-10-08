#'
#' Imputation by the global minimum
#'
#' @description
#' Apply imputation to the data by the minimum measured value from any compound found
#' within the entire data.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @import dplyr
#'
#' @return The imputed data.
#'
#' @export

impute.min_global <- function(dataSet) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace all NAs with the global smallest value in the data set
  dataPoints <- replace(dataPoints, is.na(dataPoints), min(dataPoints, na.rm = TRUE))

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by the local minimum
#'
#' @description
#' Apply imputation to the data by the minimum measured value for that compound in that
#' condition.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param reqPercentPresent A scalar (default = 0.51) specifying the required percent of
#' values that must be present in a given compound by condition combination for values to
#' be imputed.
#'
#' @import dplyr
#'
#' @return The imputed data.
#'
#' @autoglobal
#'
#' @export

impute.min_local <- function(dataSet, reqPercentPresent = 0.51) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## create a frequency table for conditions
  frq <- count(dataSet, merged_condition)

  ## loop over compounds
  ## ncol(dataPoints): number of compound in the data
  for (j in 1:ncol(dataPoints)) {

    ## loop over conditions
    ## nrow(frq): number of conditions in the data
    for (i in 1:nrow(frq)) {

      ## condition for subsetting the data
      conditionIndex <- dataSet$condition == frq$condition[i]

      ## select and isolate the data from each compound by condition combination
      localData <- dataPoints[conditionIndex, j]

      ## calculate the percent of samples that are present in that compound by
      ## condition combination
      ## frq$n: number of replicates for each condition in the data
      percentPresent <- sum(!is.na(localData)) / frq$n[i]

      ## impute missing values if the threshold is met
      if (percentPresent >= reqPercentPresent) {

        ## replace missing values with the minimum (non-NA) value of the compound by
        ## condition combination
        dataPoints[conditionIndex, j] <- replace(localData, is.na(localData),
                                                 min(localData, na.rm = TRUE))
      }
    }
  }

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by the k-nearest neighbors algorithm
#'
#' @description
#' Apply imputation to the data by the k-nearest neighbors algorithm
#' \insertCite{troyanskaya2001missing}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param k An integer (default = 10) indicating the number of neighbors to be used in the
#' imputation.
#'
#' @param rowmax A scalar (default = 0.5) specifying the maximum percent missing data
#' allowed in any row. For any rows with more than \code{rowmax}*100% missing are imputed
#' using the overall mean per sample.
#'
#' @param colmax A scalar (default = 0.8) specifying the maximum percent missing data
#' allowed in any column. If any column has more than \code{colmax}*100% missing data, the
#' program halts and reports an error.
#'
#' @param maxp An integer (default = 1500) indicating the largest block of compounds
#' imputed using the k-nearest neighbors algorithm. Larger blocks are divided by two-means
#' clustering (recursively) prior to imputation.
#'
#' @param seed An integer (default = 362436069) specifying the seed used for the
#' random number generator for reproducibility.
#'
#' @import dplyr
#' @importFrom impute impute.knn
#' @importFrom Rdpack reprompt
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.knn <- function(dataSet, k = 10, rowmax = 0.5, colmax = 0.8, maxp = 1500, seed = 362436069) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using knn algorithm
  dataPoints <- t(impute::impute.knn(t(dataPoints), k = k,
                                     rowmax = rowmax, colmax = colmax,
                                     maxp = maxp, rng.seed = seed)$data)

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by the k-nearest neighbors algorithm
#'
#' @description
#' Apply imputation to the data by the sequential k-nearest neighbors algorithm
#' \insertCite{kim2004reuse}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param k An integer (default = 10) indicating the number of neighbors to be used in the
#' imputation.
#'
#' @import dplyr
#' @importFrom multiUS seqKNNimp
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.knn_seq <- function(dataSet, k = 10) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using sequential knn algorithm
  dataPoints <- t(multiUS::seqKNNimp(t(dataPoints), k = k))

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by the truncated k-nearest neighbors algorithm
#'
#' @description
#' Apply imputation to the data by the truncated k-nearest neighbors algorithm
#' \insertCite{shah2017distribution}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param k An integer (default = 10) indicating the number of neighbors to be used in the
#' imputation.
#'
#' @importFrom stats cor integrate na.omit pnorm sd
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.knn_trunc <- function(dataSet, k = 10) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using truncated knn algorithm
  ## source: trunc-knn.R
  dataPoints <- imputeKNN(data = as.matrix(dataPoints), k = k,
                          distance = "truncation", perc = 0)

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by the nuclear-norm regularization
#'
#' @description
#' Apply imputation to the data by the nuclear-norm regularization
#' \insertCite{hastie2015matrix}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param rank.max An integer specifying the restriction on the rank of the solution. The
#' default is set to one less than the minimum dimension of the dataset.
#'
#' @param lambda A scalar specifying the nuclear-norm regularization parameter. If
#' \code{lambda = 0}, the algorithm convergence is typically slower. The default is set to
#' the maximum singular value obtained from the singular value decomposition (SVD) of the
#' dataset.
#'
#' @param thresh A scalar (default = 1e-5) specifying the convergence threshold, measured
#' as the relative change in the Frobenius norm between two successive estimates.
#'
#' @param maxit An integer (default = 100) specifying the maximum number of iterations
#' before the convergence is reached.
#'
#' @param final.svd A boolean (default = TRUE) specifying whether to perform a one-step
#' unregularized iteration at the final iteration, followed by soft-thresholding of the
#' singular values, resulting in hard zeros.
#'
#' @param seed An integer (default = 362436069) specifying the seed used for the
#' random number generator for reproducibility.
#'
#' @import dplyr
#' @importFrom softImpute complete softImpute
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.nuc_norm <- function(dataSet,
                            rank.max = NULL, lambda = NULL, thresh = 1e-05, maxit = 100,
                            final.svd = TRUE, seed = 362436069) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using nuclear-norm regularization
  if(is.null(rank.max)) {
    rank.max <- min(dim(dataPoints) - 1)
  }

  if(is.null(lambda)) {
    lambda <- svd(replace(dataPoints, is.na(dataPoints), 0))$d[1]
  }

  set.seed(seed)

  fit <- softImpute::softImpute(t(dataPoints), type = "als",
                                rank.max = rank.max, lambda = lambda, thresh = thresh,
                                maxit = maxit, final.svd = final.svd)

  dataPoints <- t(softImpute::complete(t(dataPoints), fit))

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by Bayesian linear regression
#'
#' @description
#' Apply imputation to the data by Bayesian linear regression
#' \insertCite{rubin1987multiple,schafer1997analysis,van2011mice}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param m An integer (default = 5) specifying the number of multiple imputations.
#'
#' @param seed An integer (default = 362436069) specifying the seed used for the random
#' number generator for reproducibility.
#'
#' @import dplyr
#' @importFrom mice complete mice
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.mice_norm <- function(dataSet, m = 5, seed = 362436069) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using Bayesian linear regression
  dataPoints <- mice::mice(dataPoints, m = m, seed = seed, method = "norm", printFlag = FALSE)
  dataPoints <- Reduce(`+`, mice::complete(dataPoints, "all")) / m

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by classification and regression trees
#'
#' @description
#' Apply imputation to the data by classification and regression trees
#' \insertCite{breiman1984classification,doove2014recursive,van2018flexible}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param m An integer (default = 5) specifying the number of multiple imputations.
#'
#' @param seed An integer (default = 362436069) specifying the seed used for the random
#' number generator for reproducibility.
#'
#' @import dplyr
#' @importFrom mice complete mice
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.mice_cart <- function(dataSet, m = 5, seed = 362436069) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using classification and regression trees
  dataPoints <- mice::mice(dataPoints, m = m, seed = seed, method = "cart", printFlag = FALSE)
  dataPoints <- Reduce(`+`, mice::complete(dataPoints, "all")) / m

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by Bayesian principal components analysis
#'
#' @description
#' Apply imputation to the data by Bayesian principal components analysis
#' \insertCite{oba2003bayesian}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param nPcs An integer specifying the number of principal components to calculate. The
#' default is set to the minimum between the number of samples and the number of proteins.
#'
#' @param maxSteps An integer (default = 100) specifying the maximum number of estimation
#' steps.
#'
#' @import dplyr
#' @importFrom pcaMethods completeObs pca
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.pca_bayes <- function(dataSet, nPcs = NULL, maxSteps = 100) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using Bayesian principal components analysis
  dataPoints <- pcaMethods::pca(dataPoints, method = "bpca", verbose = FALSE,
                                nPcs = ifelse(is.null(nPcs), min(dim(dataPoints)), nPcs),
                                maxSteps = maxSteps)
  dataPoints <- pcaMethods::completeObs(dataPoints)

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}


##----------------------------------------------------------------------------------------
#'
#' Imputation by probabilistic principal components analysis
#'
#' @description
#' Apply imputation to the data by probabilistic principal components analysis
#' \insertCite{stacklies2007pcamethods}{metastat}.
#'
#' @param dataSet A data frame containing the data signals.
#'
#' @param nPcs An integer specifying the number of principal components to calculate. The
#' default is set to the minimum between the number of samples and the number of proteins.
#'
#' @param maxIterations An integer (default = 1000) specifying the maximum number of
#' allowed iterations.
#'
#' @param seed An integer (default = 362436069) specifying the seed used for the random
#' number generator for reproducibility.
#'
#' @import dplyr
#' @importFrom pcaMethods completeObs pca
#'
#' @return The imputed data.
#'
#' @references
#' \insertAllCited{}
#'
#' @export

impute.pca_prob <- function(dataSet, nPcs = NULL, maxIterations = 1000, seed = 362436069) {

  attrnames <- attributes(dataSet)$attrnames

  ## select the numerical data
  dataPoints <- select(dataSet, -any_of(attrnames))

  ## replace NAs using Bayesian principal components analysis
  dataPoints <- pcaMethods::pca(dataPoints, method = "ppca", verbose = FALSE,
                                nPcs = ifelse(is.null(nPcs), min(dim(dataPoints)), nPcs),
                                maxIterations = maxIterations, seed = seed)
  dataPoints <- pcaMethods::completeObs(dataPoints)

  ## recombine the labels and imputed data
  imputedData <- cbind(dataSet[,attrnames], dataPoints)
  attributes(imputedData)$attrnames <- attrnames

  ## return the imputed data
  return(imputedData)
}
