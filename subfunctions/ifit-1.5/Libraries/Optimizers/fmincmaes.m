function [pars, fval, exitflag, output] = fmincmaes(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = FMINCMAES(FUN,PARS,[OPTIONS],[CONSTRAINTS], ...) Evolution Strategy with Covariance Matrix Adaption
%
% CMAES implements an Evolution Strategy with Covariance Matrix
% Adaptation (CMA-ES) for nonlinear function minimization.
% The CMA-ES (Evolution Strategy with Covariance
% Matrix Adaptation) is a robust search method which should be
% applied, if derivative based methods, e.g. quasi-Newton BFGS or
% conjucate gradient, (supposably) fail due to a rugged search
% landscape (e.g. noise, local optima, outlier, etc.). On smooth
% landscapes CMA-ES is roughly ten times slower than BFGS. For up to
% N=10 variables even the simplex direct search method (Nelder & Mead)
% is often faster, but far less robust than CMA-ES.
%
% Calling:
%   fmincmaes(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fmincmaes(fun, pars, options) same as above, with customized options (optimset)
%   fmincmaes(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fmincmaes(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fmincmaes(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fmincmaes(problem) where problem is a structure with fields
%     problem.objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fmincmaes(..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fmincmaes(banana,[-1.2, 1])
%
% Input:
%  FUN is the function to minimize (handle or string): criteria = FUN(PARS)
%  It needs to return a single value or vector.
%
%  PARS is a vector with initial guess parameters. You must input an
%  initial guess. PARS can also be given as a single-level structure.
%
%  OPTIONS is a structure with settings for the optimizer, 
%  compliant with optimset. Default options may be obtained with
%      o=fmincmaes('defaults');
%   options.PopulationSize sets the population size (20-40).
%  An empty OPTIONS sets the default configuration.
%
%  CONSTRAINTS may be specified as a structure
%   constraints.min=   vector of minimal values for parameters
%   constraints.max=   vector of maximal values for parameters
%   constraints.fixed= vector having 0 where parameters are free, 1 otherwise
%   constraints.step=  vector of maximal parameter changes per iteration
%   constraints.eval=  expression making use of 'p', 'constraints', and 'options' 
%                        and returning modified 'p'
%                      or function handle p=@constraints.eval(p)
%  An empty CONSTRAINTS sets no constraints.
%
%  Additional arguments are sent to the objective function.
%
% Output:
%          MINIMUM is the solution which generated the smallest encountered
%            value when input into FUN.
%          FVAL is the value of the FUN function evaluated at MINIMUM.
%          EXITFLAG return state of the optimizer
%          OUTPUT additional information returned as a structure.
%
% References
% Hansen, N. and S. Kern (2004). Evaluating the CMA Evolution Strategy on 
%   Multimodal Test Functions.  Eighth International Conference on Parallel 
%   Problem Solving from Nature PPSN VIII, Proceedings, pp. 282-291, Springer. 
% Hansen, N. and A. Ostermeier (2001). Completely Derandomized Self-Adaptation 
%   in Evolution Strategies. Evolutionary Computation, 9(2), pp. 159-195.
% Hansen, N., S.D. Mueller and P. Koumoutsakos (2003). Reducing the Time 
%   Complexity of the Derandomized Evolution Strategy with Covariance Matrix 
%   Adaptation (CMA-ES). Evolutionary Computation, 11(1). 
%
% Contrib:
% Nikolaus Hansen, 2001-2007. e-mail: hansen@bionik.tu-berlin.de [cmaes]
%
% Version: $Revision: 1035 $
% See also: fminsearch, optimset

% STANDARD part ================================================================

% nargin stuff (number of parameters)
% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin{1},'defaults'))
  opt=cmaes('defaults'); 
  options=optimset; % default structure
  options.TolFun =1e-3; % will also set StopFitness
  options.MaxIter=1000;
  options.Display='';
  options.TolX   =1e-8;
  options.MaxFunEvals   =Inf;
  options.PopulationSize=opt.PopSize;
  options.SaveVariables ='off';
  options.Science       ='off';
  options.algorithm = [ 'Evolution Strategy with Covariance Matrix Adaptation (CMA-ES by Hansen) [' mfilename ']' ];
  options.optimizer = mfilename;
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

