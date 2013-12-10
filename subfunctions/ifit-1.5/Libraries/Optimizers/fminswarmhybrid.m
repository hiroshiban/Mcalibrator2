function [pars,fval,exitflag,output] = fminswarmhybrid(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = FMINSWARMHYBRID(FUN,PARS,[OPTIONS],[CONSTRAINTS]) hybrid Particle Swarm Optimization
%
% This minimization method uses a hybrid Particle Swarm Optimization algorithm for 
% finding the minimum of the function 'FUN' in the real space. At each iteration 
% step, a local optimization is performed.
% Default local optimizer is the Nelder-Mead simplex (fminsearch). You may change
% it by defining the options.Hybrid function to any minimizer.
%
% Calling:
%   fminswarmhybrid(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fminswarmhybrid(fun, pars, options) same as above, with customized options (optimset)
%   fminswarmhybrid(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fminswarmhybrid(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fminswarmhybrid(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fminswarmhybrid(problem) where problem is a structure with fields
%     problem.objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fminswarmhybrid(..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fminswarmhybrid(banana,[-1.2, 1])
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
%      o=fminswarmhybrid('defaults');
%   options.Hybrid specifies the algorithm to use for local hybrid optimizations.
%      It may be set to any optimization method using the @fminsearch syntax.
%   option.PopulationSize sets the number of particules in the swarm (20-40).
%   option.SwarmC1 sets the local attractors strength (1-3)
%   option.SwarmC2 sets the global attractor strength (1-3).
%   option.SwarmW  sets inertia weight (0-1).
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
% Reference:
% Kennedy J., Eberhart R.C. (1995): Particle swarm optimization. In: Proc.
%   IEEE Conf. on Neural Networks, IV, Piscataway, NJ, pp. 1942-1948
% Shi, Y. and Eberhart, R. C. A modified particle swarm optimizer. Proc. 
%   IEEE Int Conf. on Evol Comput pp. 69-73. IEEE Press, Piscataway, NJ, 1998
%
% Contrib:
% Alexandros Leontitsis leoaleq@yahoo.com Ioannina, Greece 2004 [hPSO]
% and more informations on http://www.particleswarm.net, http://www.swarmintelligence.org
%
% Version: $Revision: 1035 $
% See also: fminsearch, optimset

% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin{1},'defaults'))
  options=optimset; % empty structure
  options.Display='';
  options.TolFun =1e-4;
  options.TolX   =1e-8;
  options.MaxIter=1000;
  options.MaxFunEvals=10000;
  options.Hybrid = @fminpowell;
  options.SwarmC1=2;
  options.SwarmC2=2;
  options.SwarmW =0;
  options.PopulationSize=5;
  options.algorithm = [ 'Hybrid Particle Swarm Optimizer (by Leontitsis) [fminswarmhybrid]' ];
  options.optimizer = mfilename;
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

