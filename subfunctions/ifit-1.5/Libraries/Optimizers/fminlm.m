function [pars,fval,exitflag,output] = fminlm(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = fminlm(FUN,PARS,[OPTIONS],[CONSTRAINTS], ...) Levenberg-Maquardt search
%
% This minimization method uses the Levenberg-Maquardt steepest descent 
% in Least-Squares Sense. It finds parameters in order to bring the objective
% to zero (and not to its lowest value). 
% The objective function has syntax: criteria = objective(p)
% 
% Calling:
%   fminlm(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fminlm(fun, pars, options) same as above, with customized options (optimset)
%   fminlm(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fminlm(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fminlm(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fminlm(problem) where problem is a structure with fields
%     problem.objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fminlm(..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fminlm(banana,[-1.2, 1])
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
%     o=fminlm('defaults')
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
%   Fletcher, R., (1971) Rpt. AERE-R 6799, Harwell
%   Fletcher, R., Computer Journal 1970, 13, 317-322
% Contrib: Miroslav Balda, balda AT cdm DOT cas DOT cz 2009 [LMFsolve]
%
% Version: $Revision: 1035 $
% See also: fminsearch, optimset

% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin{1},'defaults'))
  options=optimset; % empty structure
  options.Display  = [];        %   no print of iterations
  options.MaxIter  = 5000;       %   maximum number of iterations allowed
  options.ScaleD   = [];        %   automatic scaling by D = diag(diag(J'*J))
  options.TolFun   = 1e-6;      %   tolerace for final function value
  options.TolX     = 1e-4;      %   tolerance on difference of x-solutions
  options.MaxFunEvals=10000;
  options.algorithm  = [ 'Levenberg-Maquardt (by Balda) [' mfilename ']' ];
  options.optimizer = mfilename;
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

