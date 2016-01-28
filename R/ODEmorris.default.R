#' @title Morris SA for ODEs for All Output Variables and All Timepoints
#' Simultaneously
#'
#' @description
#' \code{ODEmorris.default} is the default method of \code{\link{ODEmorris}}. It
#' performs a sensitivity analysis for general ODE models using Morris's 
#' elementary effects screening method. 
#'
#' @param mod [\code{function(Time, State, Pars)}]\cr
#'   model to examine, cf. example below.
#' @param pars [\code{character(k)}]\cr
#'   vector of \code{k} input variable names.
#' @param state_init [\code{numeric(z)}]\cr
#'   vector of \code{z} initial values. Must be named (with unique names).
#' @param times [\code{numeric}]\cr
#'   points of time at which the SA should be executed
#'   (vector of arbitrary length). Also the
#'   first point of time must be positive.
#' @param seed [\code{numeric(1)}]\cr
#'   seed.
#' @param binf [\code{numeric(k)}]\cr
#'   vector of lower borders of possible input parameter values.
#'   If they are all equal, a single value can be set.
#' @param bsup [\code{numeric(k)}]\cr
#'   vector of upper borders of possible input parameter values.
#'   If they are all equal, a single value can be set.
#' @param r [\code{integer(1)}]\cr
#'   number of repetitions of the \code{design},
#'   cf. \code{\link[sensitivity]{morris}}.
#' @param design [\code{list}]\cr
#'   a list specifying the design type and its parameters,
#'   cf. \code{\link[sensitivity]{morris}}.
#' @param scale [\code{logical(1)}]\cr
#'   if \code{TRUE}, scaling is done for the input design of experiments after 
#'   building the design and before calculating the elementary effects,
#'   cf. \code{\link[sensitivity]{morris}}. Defaults to \code{TRUE}, which is
#'   highly recommended if the factors have different orders of magnitude, see
#'   \code{\link[sensitivity]{morris}}.
#' @param ode_method [\code{character(1)}]\cr
#'   method to be used for solving the differential equations, see 
#'   \code{\link[deSolve]{ode}}. Defaults to \code{"lsoda"}.
#' @param ode_parallel [\code{logical(1)}]\cr
#'   logical indicating if a parallelization shall be done for computing the
#'   \code{\link[deSolve]{ode}}-results for the different parameter combinations
#'   generated for Monte Carlo estimation of the sensitivity indices.
#' @param ode_parallel_ncores [\code{integer(1)}]\cr
#'   number of processor cores to be used for parallelization. Only applies if
#'   \code{ode_parallel = TRUE}. If set to \code{NA} (as per default) and 
#'   \code{ode_parallel = TRUE}, 1 processor core is used.
#' @param ... further arguments passed to or from other methods.
#'
#' @return 
#'   List of class \code{morrisRes} of length \code{length(state_init)} 
#'   containing in each element a matrix for one \code{state_init}-variable. The
#'   matrices itself contain in their rows the Morris SA results 
#'   (i.e. \code{mu, mu.star} and \code{sigma} for every parameter) 
#'   for all timepoints (columns).
#'
#' @details 
#'   The analysis is done for all output variables and all
#'   timepoints simultaneously using \code{\link[sensitivity]{morris_list}} from 
#'   the package \code{sensitivity}. \code{\link[sensitivity]{morris_list}} can
#'   handle lists as output for its model function. Thus, each element of the 
#'   list can be used to contain the results for one output variable. This saves
#'   time since \code{\link[deSolve]{ode}} from the package \code{deSolve} 
#'   resolves the ODE system for all output variables anyway, so 
#'   \code{\link[deSolve]{ode}} only needs to be executed once.
#' 
#' @note 
#'   \code{\link[deSolve]{ode}} sometimes cannot solve an ODE system if 
#'   unrealistic parameter combinations are sampled by 
#'   \code{\link[sensitivity]{morris_list}}. Hence \code{NA}s might occur in the 
#'   Morris sensitivity results, such that \code{\link{ODEmorris.default}} fails 
#'   for one or many points of time! For this reason, if \code{NA}s occur, 
#'   please make use of \code{\link{ODEsobol.default}} instead or
#'   restrict the input parameter value intervals usefully using
#'   \code{binf}, \code{bsup} and \code{scale = TRUE}. It is also helpful to try
#'   another ODE-solver (argument \code{ode_method}). Problems are known for the
#'   \code{ode_method}s \code{"euler"}, \code{"rk4"} and \code{"ode45"}. 
#'   In contrast, the \code{ode_method}s \code{"vode"}, \code{"bdf"}, 
#'   \code{"bdf_d"}, \code{"adams"}, \code{"impAdams"} and \code{"impAdams_d"} 
#'   might be even faster than the standard \code{ode_method} \code{"lsoda"}.
#'   
#'   If \code{\link[sensitivity]{morris_list}} throws a warning message saying
#'   "In ... keeping ... repetitions out of ...", try using a bigger number of 
#'   \code{levels} in the \code{design} argument.
#'
#' @author Frank Weber
#' @references J. O. Ramsay, G. Hooker, D. Campbell and J. Cao, 2007,
#'   \emph{Parameter estimation for differential equations: a generalized 
#'   smoothing approach}, Journal of the Royal Statistical Society, Series B, 
#'   69, Part 5, 741--796.
#' @seealso \code{\link[sensitivity]{morris}},
#'   \code{\link[sensitivity]{morris_list}},
#'   \code{\link{plot.morrisRes}}
#' 
#' @examples
#' ##### FitzHugh-Nagumo equations (Ramsay et al., 2007) #####
#' # Definition of the model itself, parameters, initial state values
#' # and the times vector:
#' FHNmod <- function(Time, State, Pars) {
#'   with(as.list(c(State, Pars)), {
#'     
#'     dVoltage <- s * (Voltage - Voltage^3 / 3 + Current)
#'     dCurrent <- - 1 / s *(Voltage - a + b * Current)
#'     
#'     return(list(c(dVoltage, dCurrent)))
#'   })
#' }
#' FHNstate  <- c(Voltage = -1, Current = 1)
#' FHNtimes <- seq(0.1, 50, by = 5)
#' 
#' FHNres <- ODEmorris(mod = FHNmod,
#'                     pars = c("a", "b", "s"),
#'                     state_init = FHNstate,
#'                     times = FHNtimes,
#'                     seed = 2015,
#'                     binf = c(0.18, 0.18, 2.8),
#'                     bsup = c(0.22, 0.22, 3.2),
#'                     r = 50,
#'                     design = list(type = "oat", levels = 100, grid.jump = 1),
#'                     scale = TRUE,
#'                     ode_method = "adams",
#'                     ode_parallel = TRUE,
#'                     ode_parallel_ncores = 2)
#'
#' @import checkmate
#' @importFrom deSolve ode
#' @importFrom sensitivity morris_list
#' @export
#'

ODEmorris.default <- function(mod,
                              pars,
                              state_init,
                              times,
                              seed = 2015,
                              binf = 0,
                              bsup = 1,
                              r = 25,
                              design =
                                list(type = "oat", levels = 100, grid.jump = 1),
                              scale = TRUE,
                              ode_method = "lsoda",
                              ode_parallel = FALSE,
                              ode_parallel_ncores = NA, ...){
  
  ##### Input checks ###################################################
  
  assertFunction(mod)
  assertCharacter(pars)
  assertNumeric(state_init)
  assertNamed(state_init, type = "unique")
  assertNumeric(times, lower = 0, finite = TRUE, unique = TRUE)
  times <- sort(times)
  stopifnot(!any(times == 0))
  assertNumeric(seed)
  assertNumeric(binf)
  notOk <- length(binf) != length(pars) & length(binf) != 1
  if(notOk)
    stop("binf must be of length 1 or of the same length as pars!")
  assertNumeric(bsup)
  notOk <- length(bsup) != length(pars) & length(bsup) != 1
  if(notOk)
    stop("bsup must be of length 1 or of the same length as pars!")
  assertIntegerish(r, len = 1)
  if(r < 1)
    stop("r must be greater or equal to 1.")
  assertList(design)
  assertLogical(scale, len = 1)
  stopifnot(ode_method %in% c("lsoda", "lsode", "lsodes","lsodar","vode", 
                              "daspk", "euler", "rk4", "ode23", "ode45", 
                              "radau", "bdf", "bdf_d", "adams", "impAdams", 
                              "impAdams_d" ,"iteration"))
  assertLogical(ode_parallel, len = 1)
  assertIntegerish(ode_parallel_ncores, len = 1, lower = 1)
  if(ode_parallel && is.na(ode_parallel_ncores)){
    ode_parallel_ncores <- 1
  }
  
  ##### Preparation ####################################################
  
  set.seed(seed)
  # Number of parameters:
  k <- length(pars)
  # Number of state variables:
  z <- length(state_init)
  # Number of timepoints:
  timesNum <- length(times)
  
  # Adapt the ODE model for argument "model" of morris_list():
  model_fit <- function(X){
    # Input: Matrix X with k columns, containing the random parameter 
    # combinations.
    colnames(X) <- pars
    one_par <- function(i){
      # Resolve the ODE system by using ode() from the package "deSolve":
      ode(state_init, times = c(0, times), mod, parms = X[i, ], 
          method = ode_method)[2:(timesNum + 1), 2:(z + 1)]
    }
    if(ode_parallel){
      # Run one_par() on parallel nodes:
      ode_cl <- parallel::makeCluster(rep("localhost", ode_parallel_ncores), 
                                      type = "SOCK")
      parallel::clusterExport(ode_cl, 
                              varlist = c("ode", "mod", "state_init", "z", "X",
                                          "times", "timesNum", "ode_method"),
                              envir = environment())
      res_per_par <- parallel::parLapply(ode_cl, 1:nrow(X), one_par)
      parallel::stopCluster(ode_cl)
    } else{
      # Just use lapply():
      res_per_par <- lapply(1:nrow(X), one_par)
    }
    if(timesNum == 1){
      # Correction needed if timesNum == 1:
      res_vec <- unlist(res_per_par)
      res_matrix <- matrix(res_vec, ncol = 1)
    } else{
      # Transpose the matrix of the results, so that each column represents
      # one timepoint:
      res_matrix <- t(do.call(cbind, res_per_par))
    }
    rownames(res_matrix) <- NULL
    # Convert the results matrix to a list (one element for each state
    # variable):
    nrow_res_matrix <- nrow(res_matrix)
    res_per_state <- lapply(1:z, function(i){
      res_matrix[seq(i, nrow_res_matrix, z), , drop = FALSE]
    })
    names(res_per_state) <- names(state_init)
    return(res_per_state)
  }
  
  ##### Sensitivity analysis ###########################################
  
  # Sensitivity analysis with function morris_list() from package "sensitivity":
  x <- morris_list(model = model_fit, factors = pars, r = r, 
                   design = design, binf = binf, bsup = bsup, scale = scale)
  
  # Process the results:
  one_state <- function(L){
    mu <- lapply(L, colMeans)
    mu.star <- lapply(L, abs)
    mu.star <- lapply(mu.star, colMeans)
    sigma <- lapply(L, function(M){
      apply(M, 2, sd)
    })
    out_state <- mapply(c, mu, mu.star, sigma, SIMPLIFY = TRUE)
    out_state <- rbind(times, out_state)
    rownames(out_state) <- c("time", paste0("mu_", pars), 
                         paste0("mu.star_", pars),
                         paste0("sigma_", pars))
    return(out_state)
  }
  
  out_all_states <- lapply(x$ee_by_y, one_state)
  
  # Throw a warning if NAs occur:
  NA_check_mu <- function(M){
    any(is.na(M[1:(1 + k*2), ]))
  }
  NA_check_sigma <- function(M){
    all(is.na(M[(2 + k*2):(1 + k*3), ]))
  }
  if(any(unlist(lapply(out_all_states, NA_check_mu)))){
    warning(paste("The ODE system can't be solved. This might be due to", 
      "arising unrealistic parameters by means of Morris Screening. Use",
      "ODEsobol() instead or set binf and bsup differently together with",
      "scale = TRUE. It might also be helpful to try another ODE-solver by",
      "using the \"ode_method\"-argument."))
  } else if(all(unlist(lapply(out_all_states, NA_check_sigma))) && r == 1){
    warning("Calculation of sigma requires r >= 2.")
  } else{
    NA_check_sigma_any <- function(M){
      any(is.na(M[(2 + k*2):(1 + k*3), ]))
    }
    if(any(unlist(lapply(out_all_states, NA_check_sigma_any)))){
      warning("NAs for sigma. This might be due to r being too small.")
    }
  }
  
  # Return:
  class(out_all_states) <- "morrisRes"
  return(out_all_states)
}