function [pars,fval,exitflag,output] = fminsimpsa(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = fminsimpsa(FUN,PARS,[OPTIONS],[CONSTRAINTS]) simplex/simulated annealing
%
% fminsimpsa finds a minimum of a function of several variables using an algorithm 
% that is based on the combination of the non-linear simplex and the simulated 
% annealing algorithm (the SIMPSA algorithm, Cardoso et al., 1996). 
% In this paper, the algorithm is shown to be adequate for the global optimi-
% zation of an example set of unconstrained and constrained NLP functions.
% 
% Calling:
%   fminsimpsa(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fminsimpsa(fun, pars, options) same as above, with customized options (optimset)
%   fminsimpsa(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fminsimpsa(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fminsimpsa(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fminsimpsa(problem) where problem is a structure with fields
%     problem.objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fminsimpsa(..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fminsimpsa(banana,[-1.2, 1])
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
%     o=fminsimpsa('defaults')
%  An empty OPTIONS sets the default configuration.
%
%  CONSTRAINTS may be specified as a structure
%   constraints.min= vector of minimal values for parameters
%   constraints.max= vector of maximal values for parameters
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
% Reference: Section 10.4 and 10.9 in "Numerical Recipes in C", ISBN 0-521-43108-5
%   Cardoso, Salcedo, Feyo de Azevedo and Bardosa, Comp. Chem Engng, 21 (1997) 1349
%   Kirkpatrick, J. Stat. Phys. 34 (1984) 975.
% Contrib:   2006 Brecht Donckels, BIOMATH, brecht.donckels@ugent.be
% Systems Biology Toolbox for MATLAB, 2005 Henning Schmidt, FCC, henning@fcc.chalmers.se [SIMPSA]

% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin,'defaults'))
  options=optimset; % empty structure
  options.Display='';
  options.TolFun =1e-3;
  options.TolX   =1e-8;
  options.MaxIter=1000;
  options.MaxFunEvals=5000;
  options.PopulationSize=50;
  options.nITER_INNER_LOOP=30;
  options.algorithm  = [ 'simplex/simulated annealing (by Donckels) [' mfilename ']' ];
  options.optimizer = mfilename;
  options.TEMP_START=[];  % starting temperature (if none provided, an optimal one will be estimated)
  options.TEMP_END=1;     % end temperature
  options.COOL_RATE=10;   % small values (<1) means slow convergence,large values (>1) means fast convergence
  options.INITIAL_ACCEPTANCE_RATIO=0.95; % when initial temperature is estimated, this will be the initial acceptance ratio in the first round
  options.MIN_COOLING_FACTOR=0.9;       % minimum cooling factor (<1)
  options.MAX_ITER_TEMP_FIRST=50;       % number of iterations in the preliminary temperature loop
  options.MAX_ITER_TEMP_LAST=50;        % number of iterations in the last temperature loop (pure simplex)
  options.MAX_ITER_TEMP=10;             % number of iterations in the remaining temperature loops
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

