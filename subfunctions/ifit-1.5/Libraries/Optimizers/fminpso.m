function [pars,fval,exitflag,output] = fminpso(varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = fminpso(FUN,PARS,[OPTIONS],[CONSTRAINTS], ...) particle swarm optimization
%
% fminpso finds a minimum of a function of several variables using the particle swarm 
% optimization (PSO) algorithm originally introduced in 1995 by Kennedy and 
% Eberhart. This algorithm was extended by Shi and Eberhart in 1998 through the
% introduction of inertia factors to dampen the velocities of the particles.
% In 2002, Clerc and Kennedy introduced a constriction factor in PSO, which was
% later on shown to be superior to the inertia factors. Therefore, the algorithm
% using a constriction factor was implemented here.
% The objective function has syntax: criteria = objective(p)
% 
% Calling:
%   fminpso(fun, pars) asks to minimize the 'fun' objective function with starting
%     parameters 'pars' (vector)
%   fminpso(fun, pars, options) same as above, with customized options (optimset)
%   fminpso(fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fminpso(fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fminpso(fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fminpso(problem) where problem is a structure with fields
%     problem.objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fminpso(..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fminpso(banana,[-1.2, 1])
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
%     o=fminpso('defaults')
%   option.PopulationSize sets the number of particules in the swarm (20-40).
%   option.SwarmC1 sets the local attractors strength (1-3)
%   option.SwarmC2 sets the global attractor strength (1-3).
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
% Contrib: 2006 Brecht Donckels, BIOMATH, brecht.donckels@ugent.be [PSO]

% default options for optimset
if nargin == 0 || (nargin == 1 && strcmp(varargin{1},'defaults'))
  options=optimset; % empty structure
  options.Display='';
  options.TolFun =1e-3;
  options.TolX   =1e-8;
  options.MaxIter=1000;
  options.MaxFunEvals=5000;
  options.SwarmC1=2.8;
  options.SwarmC2=1.3;
  options.PopulationSize=25;
  options.algorithm  = [ 'Particle Swarm Optimization (by Donckels) [' mfilename ']' ];
  options.optimizer = mfilename;
  pars = options;
  return
end

[pars,fval,exitflag,output] = fmin_private_wrapper(mfilename, varargin{:});

