function [pars,fval,exitflag,output] = fminanneal(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = FMINANNEAL(FUN,PARS,[OPTIONS],[CONSTRAINTS], ...) simulated annealing optimizer
%
% Simulated annealing minimization. Parameters are scanned randomly with a decreasing
%  noise.
% The objective function has syntax: criteria = objective(p)
% 
% Calling:
%   fminanneal(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fminanneal(fun, pars, options) same as above, with customized options (optimset)
%   fminanneal(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fminanneal(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fminanneal(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fminanneal(problem) where problem is a structure with fields
%     problem.objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fminanneal(..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fminanneal(banana,[-1.2, 1])
%
% Input:
%  FUN is the function to minimize (handle or string): criteria = FUN(PARS)
%  It needs to return a single value or vector.
%
%  PARS is a vector with initial guess parameters. You must input an
%  initial guess. PARS can also be given as a single-level structure.
%
%  OPTIONS is a structure with settings for the simulated annealing, 
%  compliant with optimset. Default options may be obtained with
%     o=fminanneal('defaults')
%  options.TEMP_START sets the starting temperature
%  options.TEMP_END   sets the end temperature
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
% Reference:
%    Kirkpatrick, S., Gelatt, C.D., & Vecchi, M.P. (1983). Optimization by
%    Simulated Annealing. _Science, 220_, 671-680.
% Contrib:
%   joachim.vandekerckhove@psy.kuleuven.be 2006/04/26 12:54:04 [anneal]
%
% Version: $Revision: 1035 $
% See also: fminsearch, optimset

% STANDARD part ================================================================

% nargin stuff (number of parameters)
% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin{1},'defaults'))
  options=optimset; % empty structure
  options.Display='';
  options.TolFun =1e-3;
  options.TolX   =1e-8;
  options.MaxIter=1000;
  options.MaxFunEvals= 5000;
  options.algorithm  = [ 'Simulated Annealing (by Vandekerckhove) [' mfilename ']' ];
  options.TEMP_START = 1;  
  options.TEMP_END   = 1e-8;     
  options.optimizer  = mfilename;
  options.efficiency = 'low';
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

