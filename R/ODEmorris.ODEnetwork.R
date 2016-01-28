#' @title Morris SA for Objects of Class \code{ODEnetwork}
#'
#' @description
#' \code{ODEmorris.ODEnetwork} is the method for objects of class 
#' \code{ODEnetwork}. It performs a sensitivity analysis using Morris's 
#' elementary effects screening method. Package \code{ODEnetwork} is required 
#' for this function to work.
#'
#' @param mod [\code{ODEnetwork}]\cr
#'   list of class \code{ODEnetwork}.
#' @param pars [\code{character(k)}]\cr
#'   vector of \code{k} input variable names. All parameters must be 
#'   contained in \code{names(ODEnetwork::createParamVec(mod))} and must not
#'   be derivable from other parameters supplied (e.g., \code{"k.2.1"} can be 
#'   derived from \code{"k.1.2"}, so supplying \code{"k.1.2"} suffices).
#' @param times [\code{numeric}]\cr
#'   points of time at which the SA should be executed (vector of arbitrary 
#'   length). The first point of time must be greater than zero.
#' @param seed [\code{numeric(1)}]\cr
#'   seed.
#' @param binf [\code{numeric(k)}]\cr
#'   vector of lower borders of possible values for the \code{k} input 
#'   parameters. If they are all equal, a single value can be set.
#' @param bsup [\code{numeric(k)}]\cr
#'   vector of upper borders of possible values for the \code{k} input 
#'   parameters. If they are all equal, a single value can be set.
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
#'   List of class \code{morrisRes} of length \code{2 * nrow(mod$state)} 
#'   containing in each element a matrix for one state variable (all components 
#'   of the 2 state variables are analyzed independently). The matrices 
#'   themselves contain in their rows the Morris SA results (i.e. 
#'   \code{mu, mu.star} and \code{sigma} for every parameter) for all 
#'   timepoints (columns).
#'
#' @details 
#'   The sensitivity analysis is done for all state variables.
#' 
#' @note \code{\link[deSolve]{ode}} sometimes cannot solve an ODE system if 
#'   unrealistic parameter combinations are sampled by 
#'   \code{\link[sensitivity]{morris_list}}. Hence \code{NA}s might occur in the 
#'   Morris sensitivity results, such that \code{\link{ODEmorris}} fails for 
#'   one or many points of time! For this reason, if \code{NA}s occur, please 
#'   make use of \code{\link{ODEsobol}} instead or
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
#' @seealso \code{\link[sensitivity]{morris}},
#'   \code{\link[sensitivity]{morris_list}},
#'   \code{\link{plot.morrisRes}}
#' 
#' @examples 
#' ##### A network of ordinary differential equations #####
#' # Definition of the network using the package "ODEnetwork":
#' library(ODEnetwork)
#' masses <- c(1, 1)
#' dampers <- diag(c(1, 1))
#' springs <- diag(c(1, 1))
#' springs[1, 2] <- 1
#' distances <- diag(c(0, 2))
#' distances[1, 2] <- 1
#' lfonet <- ODEnetwork(masses, dampers, springs, 
#'                      cartesian = TRUE, distances = distances)
#' lfonet <- setState(lfonet, c(0.5, 1), c(0, 0))
#' LFOpars <- c("m.1", "d.1", "k.1", "k.1.2", "m.2", "d.2", "k.2")
#' LFOtimes <- seq(0.01, 20, by = 0.1)
#' LFObinf <- rep(0.001, length(LFOpars))
#' LFObsup <- c(2, 1.5, 6, 6, 2, 1.5, 6)
#' 
#' LFOres <- ODEmorris(lfonet, LFOpars, LFOtimes, 
#'                     seed = 2015, binf = LFObinf, bsup = LFObsup, r = 50, 
#'                     design = list(type = "oat", levels = 100, grid.jump = 1),
#'                     scale = TRUE, ode_method = "adams", 
#'                     ode_parallel = TRUE, ode_parallel_ncores = 2)
#'
#' @import checkmate
#' @importFrom deSolve ode
#' @importFrom sensitivity morris_list
#' @method ODEmorris ODEnetwork
#' @export
#' 

ODEmorris.ODEnetwork <- function(mod,
                                 pars,
                                 times,
                                 seed = 2015,
                                 binf = 0,
                                 bsup = 1,
                                 r = 25,
                                 design = list(type = "oat", levels = 100, 
                                               grid.jump = 1),
                                 scale = TRUE, 
                                 ode_method = "lsoda",
                                 ode_parallel = FALSE,
                                 ode_parallel_ncores = NA, ...){
  
  ##### Package checks #################################################
  
  if(!requireNamespace("ODEnetwork", quietly = TRUE)){
    stop(paste("Package \"ODEnetwork\" needed for this function to work.",
               "Please install it."),
         call. = FALSE)
  }
  
  ##### Input checks ###################################################
  
  assertClass(mod, "ODEnetwork")
  assertCharacter(pars)
  stopifnot(all(pars %in% names(ODEnetwork::createParamVec(mod))))
  # Check if there are duplicated parameters:
  if(any(duplicated(pars))){
    rfuncs <- rfuncs[!duplicated(pars)]
    rargs <- rargs[!duplicated(pars)]
    pars <- unique(pars)
    warning("Duplicated parameter names in \"pars\". Only taking unique names.")
  }
  # Check if there are parameters which can be derived from others (like 
  # "k.2.1" from "k.1.2"):
  pars_offdiag <- pars[nchar(pars) == 5]
  pars_offdiag_exchanged <- pars_offdiag
  # Exchange third and fifth position:
  substr(pars_offdiag_exchanged, 3, 3) <- substr(pars_offdiag, 5, 5)
  substr(pars_offdiag_exchanged, 5, 5) <- substr(pars_offdiag, 3, 3)
  if(any(pars_offdiag_exchanged %in% pars)){
    pars_deriv <- pars_offdiag[pars_offdiag %in% pars_offdiag_exchanged]
    pars_deriv_exchanged <- 
      pars_offdiag_exchanged[pars_offdiag_exchanged %in% pars_offdiag]
    pars_keep <- character(length(pars_deriv))
    for(i in seq_along(pars_deriv)){
      if(!pars_deriv_exchanged[i] %in% pars_keep){
        pars_keep[i] <- pars_deriv[i]
      } else{
        pars_keep[i] <- "drop"
      }
    }
    pars_keep <- c(pars[nchar(pars) != 5], 
                   pars_offdiag[!pars_offdiag %in% pars_deriv], 
                   pars_keep[pars_keep != "drop"])
    rfuncs <- rfuncs[pars %in% pars_keep]
    rargs <- rargs[pars %in% pars_keep]
    pars <- pars[pars %in% pars_keep]
    warning(paste("Derivable parameters in \"pars\". Keeping only one", 
                  "parameter of each derivable pair."))
  }
  assertNumeric(times, lower = 0, finite = TRUE, unique = TRUE)
  times <- sort(times)
  stopifnot(!any(times == 0))
  assertNumeric(seed)
  assertNumeric(binf)
  if(length(binf) != length(pars) && length(binf) != 1)
    stop("binf must be of length 1 or of the same length as pars!")
  assertNumeric(bsup)
  if(length(bsup) != length(pars) & length(bsup) != 1)
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
  # Initial state:
  state_init <- ODEnetwork::createState(mod)
  # Number of parameters:
  k <- length(pars)
  # Number of output variables (state variables):
  z <- length(state_init)
  # Number of timepoints:
  timesNum <- length(times)
  
  # Adapt the ODE-model for argument "model" of morris_list():
  model_fit <- function(X){
    # Input: matrix X with k columns
    colnames(X) <- pars
    one_par <- function(i){
      # Get the parameter values:
      pars_upd <- X[i, ]
      names(pars_upd) <- pars
      # Update the model function in the ODEnetwork-object "mod":
      mod_parmod <- ODEnetwork::updateOscillators(mod,
                                                  ParamVec = pars_upd)
      # Simulate the network (the results correspond to those by ode() in the 
      # package "deSolve"):
      simnet_res <- ODEnetwork::simuNetwork(mod_parmod, 
                                            c(0, times), 
                                            method = ode_method)
      return(simnet_res$simulation$results[2:(timesNum + 1), 2:(z + 1)])
    }
    if(ode_parallel){
      # Run one_par() on parallel nodes:
      ode_cl <- parallel::makeCluster(rep("localhost", ode_parallel_ncores), 
                                      type = "PSOCK")
      parallel::clusterExport(ode_cl, 
                              varlist = c("X", "pars", "mod", "z",
                                          "times", "ode_method", "timesNum"),
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
  
  ##### Sensitivity analysis #########################################
  
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
  
  # Throw a warning if NAs occur (probably not suitable parameters, so ODE
  # system can't be solved):
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