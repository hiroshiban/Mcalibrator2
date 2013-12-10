function [pars,fval,exitflag,output] = fmin_private_wrapper(optimizer, fun, pars, options, constraints, varargin)
% [MINIMUM,FVAL,EXITFLAG,OUTPUT] = fmin_private_wrapper(OPTIMIZER, FUN,PARS,[OPTIONS],[constraints], ...) wrapper to optimizers
%
%  Checks for input arguments and options. Then calls the optimizer with a wrapped 
%  inline_objective function, which applies constraints and makes stop condition checks.
%  the main optimizer call is within a try/catch block which exits when an early 
%  stop is met.
% 
% Calling:
%   fmin_private_wrapper(optimizer, fun, pars) asks to minimize the 'fun' inline_objective function with starting
%     parameters 'pars' (vector)
%   fmin_private_wrapper(optimizer, fun, pars, options) same as above, with customized options (optimset)
%   fmin_private_wrapper(optimizer, fun, pars, options, fixed) 
%     is used to fix some of the parameters. The 'fixed' vector is then 0 for
%     free parameters, and 1 otherwise.
%   fmin_private_wrapper(optimizer, fun, pars, options, lb, ub) 
%     is used to set the minimal and maximal parameter bounds, as vectors.
%   fmin_private_wrapper(optimizer, fun, pars, options, constraints) 
%     where constraints is a structure (see below).
%   fmin_private_wrapper(optimizer, problem) where problem is a structure with fields
%     problem.inline_objective:   function to minimize
%     problem.x0:          starting parameter values
%     problem.options:     optimizer options (see below)
%     problem.constraints: optimization constraints
%   fmin_private_wrapper(optimizer, ..., args, ...)
%     sends additional arguments to the objective function
%       criteria = FUN(pars, args, ...)
%
% Example:
%   banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
%   [x,fval] = fmin_private_wrapper('fminimfil',banana,[-1.2, 1])
%
% Input:
%  OPTIMIZER is the name/handle to an optimizer function, or '' for default
%
%  FUN is the function to minimize (handle or string): criteria = FUN(PARS)
%  It needs to return a single value or vector.
%
%  PARS is a vector with initial guess parameters. You must input an
%  initial guess. PARS can also be given as a single-level structure.
%
%  OPTIONS is a structure with settings for the simulated annealing, 
%  compliant with optimset. Default options may be obtained with
%     o=fmin_private_wrapper(optimizer,'defaults')
%  An empty OPTIONS sets the default configuration.
%
%  constraints may be specified as a structure
%   constraints.min=   vector of minimal values for parameters
%   constraints.max=   vector of maximal values for parameters
%   constraints.fixed= vector having 0 where parameters are free, 1 otherwise
%   constraints.step=  vector of maximal parameter changes per iteration
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
% Version: $Revision: 1035 $
% See also: fminsearch, optimset

% NOTE: all optimizers have been gathered here so that maintenance is minimized
% each user call function only defines the options... The optimizer by itself is
% in the 'private'.
%
% private: 'inline_objective', 
%          'inline_apply_constraints', 
%          'inline_constraints_minmax', 
%          'inline_private_check'
%          'inline_localChar', 
%          'inline_disp'
%          'inline_estimate_uncertainty'
%          'inline_auto_optimizer'

% return code     message
%  0                Algorithm terminated normally
% -1                Termination function tolerance criteria reached
% -2                Maximum number of iterations reached
% -3                Maximum number of function evaluations reached
% -4                Function value is Inf or Nan
% -5                Termination parameter tolerance criteria reached
% -6                Algorithm was terminated by the output function
% -7                Maximum consecutive rejections exceeded (anneal)
% -8                Minimum temperature reached (anneal)
% -9                Global Simplex convergence reached (simplex)
% -10               Optimization terminated: Stall Flights Limit reached (swarm)
% -11               Other termination status (cmaes/Ralg)
% -12               Termination function change tolerance criteria reached

% parameter handling ===========================================================

% nargin stuff (number of parameters)
% default options for optimset

if nargin < 1,         optimizer =''; end
if nargin < 2,         fun       = ''; end
if isempty(optimizer), optimizer = 'fmin'; end
if isempty(fun),       fun       = 'defaults'; end

if nargin < 4
  options=[];
end
if nargin < 5
  constraints = [];
end
if nargin < 6
  varargin = {};
end

if strcmp(fun,'defaults')
  pars = feval(optimizer, 'defaults');
  return
elseif nargin < 2
  error([ 'syntax is: ' optimizer '(optimizer, objective, parameters, ...)' ] );
elseif nargin == 2 && isstruct(fun)
  if     isfield(fun, 'x0'),          pars=fun.x0;
  elseif isfield(fun, 'guess'),       pars=fun.guess;
  elseif isfield(fun, 'Guess'),       pars=fun.Guess; end
  if     isfield(fun, 'options'),     options=fun.options; end
  if     isfield(fun, 'constraints'), constraints=fun.constraints; end 
  if     isfield(fun, 'objective'),   tmp=fun.objective; fun=[]; fun=tmp; 
  elseif isfield(fun, 'model'),       tmp=fun.model; fun=[]; fun=tmp;
  elseif isfield(fun, 'f'),           tmp=fun.f; fun=[]; fun=tmp;
  elseif isfield(fun, 'function'),    tmp=fun.function; fun=[]; fun=tmp; end
elseif nargin < 3
  error([ 'syntax is: ' inline_localChar(optimizer) '(objective, parameters, ...)' ] );
end
if isempty(pars)
  error([ inline_localChar(optimizer) ': starting parameters (3rd argument) must not be empty.' ] );
end

if ~ischar(fun) && ~isa(fun, 'function_handle')
  error([ inline_localChar(optimizer) ': objective function (2nd argument) must be a char or function_handle, but is a ' class(fun) '.' ] );
end

% default arguments when missing
if isempty(options)
  options=optimizer;
end

if (ischar(options) && exist(options) == 2) | isa(options, 'function_handle')
  options=feval(optimizer, 'defaults');
elseif ischar(options), options=str2struct(options); end
if ischar(pars),
  pars   =str2struct(pars); 
end
% handle case when parameters are given as structures
if isstruct(pars)
  pars_isstruct=fieldnames(pars);
  pars=cell2mat(struct2cell(pars));
  % check if constraints are also structures, but with same fields
  check = {'min','max','fixed','step'};
  for index=1:length(check)
    if isfield(constraints,check{index}) && isstruct(constraints.(check{index}))
      new = [];
      for f=1:length(pars_isstruct)
        if isfield(constraints.(check{index}), pars_isstruct{f})
          new = [ new constraints.(check{index}).(pars_isstruct{f}) ];
        end
      end
      if length(new) == length(pars)
        constraints.(check{index}) = new;
      else
        error([ inline_localChar(optimizer) ': parameters and constraint %s are given as structures, but not with same length/fields (%i and %i resp.).' ],  ...
          check{index}, length(pars_isstruct), length(fieldnames(constraints.(check{index}))) );
      end
    end
  end
else
  pars_isstruct=[];
end
if length(constraints)==length(pars) & (isnumeric(constraints) | islogical(constraints))
  if nargin < 6,               % given as fixed index vector
    fixed             = constraints; 
    constraints       = [];
    constraints.fixed = fixed;  % avoid warning for variable redefinition.
  elseif isnumeric(varargin{1}) && ~isempty(varargin{1}) ...
      && length(constraints) == length(varargin{1})
    % given as lb,ub parameters (nargin==6)
    lb = constraints; 
    ub = varargin{1};
    varargin(1) = []; % remove the 'ub' from the additional arguments list
    constraints     = [];
    constraints.min = lb;
    constraints.max = ub;
  end
end
if ~isempty(constraints) && ischar(constraints)
  constraints = str2struct(constraints);
end
if ~isempty(constraints) && ~isstruct(constraints)
  error([ inline_localChar(optimizer) ': The constraints argument is of class ' class(constraints) '. Should be a vector or a struct' ]);
end
if ~isstruct(options)
  error([ inline_localChar(optimizer) ': The options argument is of class ' class(options) '. Should be a string or a struct' ]);
end

constraints.parsStart       = pars;  % used when applying constraints
constraints.parsPrevious    = pars;
constraints.parsBest        = pars;
constraints.parsHistory     = [];
constraints.criteriaHistory = [];
constraints.criteriaStart   = [];
constraints.criteriaPrevious= Inf;
constraints.criteriaBest    = Inf;
constraints.funcCount       = 0;
constraints.message         = '';
constraints.fevalDuration   = 0;

if isfield(constraints, 'Expression') && ~isfield(constraints, 'eval')
  constraints.eval = constraints.Expression;
end

options.optimizer = optimizer;
if ~isfield(options,'Display') options.Display=''; end

options=inline_private_check(options, feval(options.optimizer,'defaults'));
t0=clock;

n = prod(size(pars)); N=n; % these are for the following 'eval's
numberOfVariables = n;
numberofvariables = n;
if ischar(options.MaxFunEvals), 
  options.MaxFunEvals = eval(options.MaxFunEvals); 
end
if ischar(options.MaxIter), 
  options.MaxIter = eval(options.MaxIter); 
end

if ischar(options.TolFun)
  options.TolFunChar = options.TolFun;
  if options.TolFun(end)=='%'
    options.TolFun(end)='';
    fval = inline_objective(fun, pars, varargin{:});
    options.TolFun = abs(str2num(options.TolFun)*fval/100);
  else
    options.TolFun = str2num(options.TolFun);
  end
else
  fval = NaN;
end

if ischar(options.TolX)
  options.TolXChar=options.TolX;
  if options.TolX(end)=='%'
    options.TolX(end)='';
    options.TolX = abs(str2num(options.TolX)*pars(:)/100);
  else
    options.TolX = str2num(options.TolX);
  end
end

if strncmp(options.Display,'iter',4)
  disp([ '** Starting minimization of ' inline_localChar(fun) ' using algorithm ' inline_localChar(options.algorithm) ]);
  disp('Func_count  min[f(x)]    Parameters');
  inline_disp(options, constraints.funcCount , fun, pars, fval)
end

message    = constraints.message;
exitflag   = 0;
iterations = 0;
fval       = Inf;       % in case this is a vector, it should be a row
pars       = pars(:);   % should be a column
output     = [];  

% Optimizer call ===============================================================

try

% calls the optimizer with a wrapped 'inline_objective' function
%    which applies constraints and makes stop condition checks.
% the main optimizer call is within a try/catch block which exits when an early 
%  stop is met. See private 'inline_objective' and 'inline_apply_constraints' below.

switch options.optimizer
case 'fmin' % automatic guess
  [optimizer, algorithm] = inline_auto_optimizer(fun, pars, varargin{:});
  options.optimizer = optimizer;
  options.algorithm = algorithm;
  [pars,fval,exitflag,output] = feval(optimizer, fun, pars, options, constraints, varargin{:});
  return
case {'cmaes','fmincmaes'}    
% Evolution Strategy with Covariance Matrix Adaption ---------------------------
  hoptions.MaxIter    = options.MaxIter;
  hoptions.TolFun     = options.TolFun;
  hoptions.MaxFunEvals= options.MaxFunEvals;
  hoptions.PopSize    = options.PopulationSize;
  hoptions.DispFinal  = 'off';
  hoptions.DispModulo = 0;
  hoptions.SaveVariables  = 'off';
  hoptions.LogModulo      = 0;
  hoptions.LogPlot        = 'off';
  if isfield(constraints,'step'), hoptions.DiffMaxChange = constraints.step(:); end
  if isfield(constraints,'min'),  hoptions.LBounds=constraints.min(:); end
  if isfield(constraints,'max'),  hoptions.UBounds=constraints.max(:); end
  if isfield(constraints,'min') & isfield(constraints,'max')
    sigma = abs(constraints.max(:) - constraints.min(:))/4;
  elseif isfield(constraints,'step')
    sigma = constraints.step*10;
  else
    sigma = 0.3;
  end

  [pars, fval, iterations, exitflag, output] = cmaes(@(pars) inline_objective(fun, pars, varargin{:}), pars, ...
    sigma, hoptions);

  if     strmatch(exitflag, 'tolx')
    exitflag=-5;
    message = [ 'Converged: Termination parameter tolerance criteria reached (options.TolX=' ...
              num2str(options.TolX) ')' ];
  elseif strmatch(exitflag, 'tolfun')
    exitflag=-1;
    message = [ 'Converged: Termination function tolerance criteria reached (options.TolFun=' ...
              num2str(options.TolFun) ')' ];
  elseif strmatch(exitflag, 'maxiter')
    exitflag=-2;
    message = [ 'Maximum number of iterations reached (options.MaxIter=' ...
              num2str(options.MaxIter) ')' ];
  elseif strmatch(exitflag, 'maxfunevals')
    exitflag=-3;
    message = [ 'Maximum number of function evaluations reached (options.MaxFunEvals=' ...
              num2str(options.MaxFunEvals) ')' ];
  elseif strmatch(exitflag, 'outputfcn')
    exitflag=-6;
    message = 'Algorithm was terminated by the output function (options.OutputFcn)';
  elseif strmatch(exitflag, 'funvalcheck')
    exitflag=-4;
    message = 'Function value is Inf or Nan (options.FunValCheck)';  
  else   
    message=char(exitflag);
    exitflag=-11;
  end
case {'ga','fminga','GA'}          
% genetic algorithm ------------------------------------------------------------
  constraints = inline_constraints_minmax(pars, constraints);
  [pars,fval,iretations,output] = GA(@(pars) inline_objective(fun, pars, varargin{:}), pars, options,constraints);
case {'gradrand','ossrs','fmingradrand'}
% random gradient --------------------------------------------------------------
  [pars,fval,iterations] = ossrs(pars, @(pars) inline_objective(fun, pars, varargin{:}), options);
case {'hooke','fminhooke'}
% Hooke-Jeeves direct search ---------------------------------------------------
  [pars,histout] = hooke(pars, @(pars) inline_objective(fun, pars, varargin{:}), ...
                       options.MaxFunEvals, 2.^(-(0:options.MaxIter)), options.TolFun);
  iterations      = size(histout,1);
case {'imfil','fminimfil'}
% Unconstrained Implicit filtering (version 1998) ------------------------------
  [pars,fval,iterations,output] = imfil(pars, @(pars) inline_objective(fun, pars, varargin{:}), options); 
case {'fminlm','LMFsolve'}
% Levenberg-Maquardt steepest descent ------------------------------------------
  % LMFsolve minimizes the sum of the squares of the inline_objective: sum(inline_objective.^2)
  [pars, fval, iterations, exitflag] = LMFsolve(@(pars) inline_objective(fun, pars, varargin{:}), pars, ...
           'Display',0, 'FunTol', options.TolFun, 'XTol', options.TolX, ...
           'MaxIter', options.MaxIter, 'Evals',options.MaxFunEvals);
  switch exitflag
  case -5, message='Converged: Termination function tolerance criteria reached';
  case -2, message='Maximum number of iterations reached';
  case -3, message='Maximum number of function evaluations reached';
  case -1, message='Converged: Termination parameter tolerance criteria reached';
  end
case {'powell','fminpowell'}
% Powell minimization ----------------------------------------------------------
  if isempty(options.Hybrid), options.Hybrid='Coggins'; end
  if strcmp(lower(options.Hybrid), 'coggins') 
    t = 'Coggins';
  else 
    t = 'Golden rule';
  end
  options.algorithm  = [ 'Powell Search (by Secchi) [' options.optimizer '/' t ']' ];
  constraints = inline_constraints_minmax(pars, constraints);
  [pars,fval,exitflag,output] = powell(@(pars) inline_objective(fun, pars, varargin{:}), pars, options);
case {'pso','fminpso'}
% particle swarm ---------------------------------------------------------------
  constraints = inline_constraints_minmax(pars, constraints);
  [pars,fval,exitflag,output] = PSO(@(pars) inline_objective(fun, pars, varargin{:}),pars, ...
     constraints.min(:),constraints.max(:),options);
  message = output.message;
case {'ralg','fminralg','solvopt'}
% Shor's r-algorithm -----------------------------------------------------------
  opt(1) = -1;
  opt(2) = options.TolX;
  opt(3) = options.TolFun;
  opt(4) = options.MaxIter;
  opt(5) = -1;
  opt(6) = 1e-8; 
  opt(7) = 2.5; 
  opt(8) = 1e-11;

  % call the optimizer
  [pars,fval,out,iterations, message] = ralg(pars, @(pars) inline_objective(fun, pars, varargin{:}), ...
    [], opt,[],[], [], options.MaxFunEvals, options.FunValCheck);
  if out(9) < 0, exitflag = out(9); 
  else exitflag=0; end
case {'fminsearch','fminsearchbnd'}
% Nelder-Mead simplex, with constraints ----------------------------------------
  [pars,fval,exitflag,output] = fminsearch(@(pars) inline_objective(fun, pars, varargin{:}), pars, options);
%     1  Maximum coordinate difference between current best point and other
%        points in simplex is less than or equal to TolX, and corresponding 
%        difference in function values is less than or equal to TolFun.
%     0  Maximum number of function evaluations or iterations reached.
%    -1  Algorithm terminated by the output function.
  if     exitflag == 1, exitflag=-5;
  elseif exitflag == 0, exitflag=-3;
  elseif exitflag ==-1, exitflag=-6;
  end
case {'simpsa','fminsimpsa','SIMPSA'}
% simplex/simulated annealing --------------------------------------------------
  constraints = inline_constraints_minmax(pars, constraints);
  [pars,fval,exitflag,output] = SIMPSA(@(pars) inline_objective(fun, pars, varargin{:}), pars, ...
    constraints.min(:),constraints.max(:),options);
case {'SCE','fminsce'}
% shuffled complex evolution ---------------------------------------------------
  constraints = inline_constraints_minmax(pars, constraints);
  [pars,fval,exitflag,output] = SCE(@(pars) inline_objective(fun, pars, varargin{:}), pars, ...
    constraints.min(:),constraints.max(:),options);
case {'hPSO','fminswarmhybrid','fminswarm'}
  constraints = inline_constraints_minmax(pars, constraints);
  if isa(options.Hybrid, 'function_handle') | exist(options.Hybrid) == 2
    hoptions.algorithm = [ 'hybrid Particle Swarm Optimizer (by Leontitsis) [' options.optimizer '/' inline_localChar(options.Hybrid) ']' ];
  else
    hoptions.algorithm = [ 'Particle Swarm Optimizer (by Leontitsis) [fminswarm]' ];
  end

  % transfer optimset options and constraints
  hoptions.space     = [ constraints.min(:) constraints.max(:) ];
  hoptions.MaxIter   = options.MaxIter;
  hoptions.TolFun    = options.TolFun;
  hoptions.TolX      = options.TolX;
  hoptions.Display   = options.Display;
  hoptions.MaxFunEvals=options.MaxFunEvals;
  hoptions.FunValCheck=options.FunValCheck;
  hoptions.OutputFcn  =options.OutputFcn;

  hoptions.Hybrid     =options.Hybrid;
  hoptions.c1         =options.SwarmC1;
  hoptions.c2         =options.SwarmC2;
  hoptions.w          =options.SwarmW;
  hoptions.bees       =options.PopulationSize;
  if isa(options.Hybrid, 'function_handle') | exist(options.Hybrid) == 2
    hoptions.StallFliLimit = 50;
  else
    hoptions.StallFliLimit = Inf;
  end
  if isfield(constraints,'step')
    hoptions.maxv = constraints.step;
  else
    hoptions.maxv = abs(constraints.max(:)-constraints.min(:))/2;
  end
  [pars,fval,iterations,output] = hPSO(@(pars) inline_objective(fun, pars, varargin{:}), pars, hoptions);
case {'Simplex','fminsimplex'}
% Nelder-Mead simplex state machine --------------------------------------------
  constraints = inline_constraints_minmax(pars, constraints);
  [pars, out]=Simplex('init', pars, abs(constraints.max(:)-constraints.min(:))/10);  % Initialization
  for iterations=1:options.MaxIter
    fval = feval(@(pars) inline_objective(fun, pars, varargin{:}), pars);

    [pars,out]=Simplex( fval );
    if isfield(options,'TolFunChar')
      options.TolFun = options.TolFunChar;
      if options.TolFun(end)=='%'
        options.TolFun(end)='';
        options.TolFun = abs(str2num(options.TolFun)*fval/100);
      else
        options.TolFun = str2num(options.TolFun);
      end
    end
    if Simplex('converged', options.TolFun)             % Test for convergence
      exitflag=-1;
      message= [ 'Converged: Termination function tolerance criteria reached (options.TolFun=' ...
                num2str(options.TolFun) ')' ];
      break
    end
    if iterations >= options.MaxIter
      exitflag=-2;
      message = [ 'Maximum number of iterations reached (options.MaxIter=' ...
                num2str(options.MaxIter) ')' ];;
      break
    end
  end
  pars=Simplex('centroid'); % obtain the final value.
case {'cgtrust','fmincgtrust'}
% Steihaug Newton-CG-Trust region algorithm ------------------------------------
  [pars,histout] = cgtrust(pars, @(pars) inline_objective(fun, pars, varargin{:}), ...
    [ options.TolFun .1 options.MaxIter options.MaxIter], options.TolX*options.TolX);
% [pars,histout] = levmar(pars, @(pars) inline_objective(fun, pars, varargin{:}), options.TolFun, options.MaxIter);
  iterations      = size(histout,1);
% not so efficient optimizers ==================================================
case {'fminanneal','anneal'}  
% simulated annealing ----------------------------------------------------------
  options.MaxTries   = options.MaxIter/10;
  options.StopVal    = options.TolFun;
  options.Verbosity=0;
  [pars,fval,iterations,exitflag] = anneal(@(pars) inline_objective(fun, pars, varargin{:}), pars(:)', options);
  if exitflag==-7,message='Maximum consecutive rejections exceeded (anneal)'; end
case {'fminbfgs','bfgs'}      
% Broyden-Fletcher-Goldfarb-Shanno ---------------------------------------------
  [pars, histout, costdata,iterations] = bfgswopt(pars(:), @(pars) inline_objective(fun, pars, varargin{:}), options.TolFun, options.MaxIter);
  iterations = size(histout,1);
case {'fminkalman','kalmann','ukfopt'}
% unscented Kalman filter ------------------------------------------------------
  [pars,iterations] = ukfopt(@(pars) inline_objective(fun, pars(:)), pars(:), ...
              options.TolFun, norm(pars)*eye(length(pars)), 1e-6*eye(length(pars)), 1e-6);
case {'ntrust','fminnewton'}
% Dogleg trust region, Newton model --------------------------------------------
  [pars,histout,costdata] = ntrust(pars(:),@(pars) inline_objective(fun, pars, varargin{:}), ...
       options.TolFun,options.MaxIter);
  iterations      = size(histout,1);
case {'buscarnd','fminrand'}
% adaptive random search -------------------------------------------------------
  [pars,fval]=buscarnd(@(pars) inline_objective(fun, pars, varargin{:}), pars, options);
otherwise
  % unknown optimizer. 
  error([ inline_localChar(optimizer) ': Unknown optimizer.' ]);
  return
end % switch
catch
  % we may get here when the inline_objective issue an error after a stop condition.
  output.lasterror = lasterror;
end % try

if isstruct(output) && isfield(output,'lasterror') && isempty(strfind(output.lasterror.message, 'stop condition:'))
  disp('Code error when launching the optimizer. Please fix it...')
  disp(output.lasterror.message);
  for index=1:length(output.lasterror.stack)
    disp(output.lasterror.stack(index))
  end
  % this is a real error (not from a stop condition)
  rethrow(output.lasterror);
end

% post optimization checks =====================================================

fval = constraints.criteriaBest; 
fval=sum(fval(:));
pars = constraints.parsBest;

if iterations, 
  output.iterations    = iterations;
elseif ~isfield(output,'iterations')
  output.iterations    = constraints.funcCount ;
end

% determine message (return status of optimiser)
if isempty(message) && isfield(constraints,'message')
  message = constraints.message;
end

if isempty(message)
  if exitflag==0
    message='Algorithm terminated';
  end
end
if ~isfield(output,'message')
  output.message         = message;
end

% raise fminplot if it exists
if ~isempty(options.OutputFcn) & strcmp(options.OutputFcn, 'fminplot')
  h = findall(0, 'Tag', 'fminplot'); d = findall(0, 'Tag', 'fminplot:stop');
  if ~isempty(h), 
    figure(h(1));
    t = [ '#' num2str(constraints.funcCount) ' f=' num2str(fval,4) ' [End]' sprintf('\n') options.optimizer  ];
    set(h, 'Visible', 'on', 'Name', t);
    title(t); 
    set(d, 'String','END','BackgroundColor','green' );
  end
end
  
output.funcCount       = constraints.funcCount ;
output.algorithm       = options.algorithm;
output.parsHistory     = constraints.parsHistory;
output.criteriaHistory = constraints.criteriaHistory;
output.parsBest        = constraints.parsBest;
output.criteriaBest    = constraints.criteriaBest;
output.options         = options; 
output.constraints     = constraints;
output.optimizer       = options.optimizer;
output.duration        = etime(clock, t0);
output.fevalDuration   = constraints.fevalDuration;

% estimate parameter uncertainty from the search trajectory

index      = find(output.criteriaHistory < min(output.criteriaHistory)*4);   % identify tolerance region around optimum 
if length(index) < 3 % retain 1/4 lower criteria part
  delta_criteria = output.criteriaHistory - min(output.criteriaHistory);
  index      = find(abs(delta_criteria/min(output.criteriaHistory)) < 0.25);
end
if length(index) < 3
  index = 1:length(output.criteriaHistory);
end
try
delta_pars = (output.parsHistory(index,:)-repmat(output.parsBest,[length(index) 1])); % get the corresponding parameter set
weight_pars= exp(-((output.criteriaHistory(index)-min(output.criteriaHistory))/min(output.criteriaHistory)).^2 / 8); % Gaussian weighting for the parameter set
weight_pars= repmat(weight_pars,[1 length(output.parsBest)]);
output.parsHistoryUncertainty = sqrt(sum(delta_pars.*delta_pars.*weight_pars)./sum(weight_pars));
end
if ((strcmp(options.Display,'final') || strcmp(options.Display,'iter') ...
  || (strcmp(options.Display,'notify') && isempty(strfind(message, 'Converged')))) || nargout == 4) ...
  && ((isfield(options,'Diagnostics') && strcmp(options.Diagnostics,'on')) ...
 || (length(pars)^2*output.fevalDuration/2 < 60 ... % should spend less than a minute to compute the Hessian
  && (~isfield(options,'Diagnostics') || ~strcmp(options.Diagnostics,'off')) ...
  && exitflag ~= -6)) % not when user explicitely requested premature end (Abort)
  if length(pars)^2*output.fevalDuration/2 > 5
    disp([ '  Estimating Hessian matrix... (' num2str(length(pars)^2*output.fevalDuration/2) ' [s] remaining, please wait)' ]);
  end
  %try
  [dp, covp, corp,jac,hessian]  = inline_estimate_uncertainty(fun, pars, options, varargin{:});
  if ~isempty(covp)
    output.parsHessianUncertainty = reshape(abs(dp), size(pars));
    output.parsHessianCovariance  = covp;
    output.parsHessianCorrelation = corp;
    output.parsHessian            = hessian;
    output.parsJacobian           = jac;
  end
  %end
else
  output.parsHessianUncertainty = [];
  output.parsHessianCovariance  = [];
  output.parsHessianCorrelation = [];
  output.parsHessian            = [];
  output.parsJacobian           = [];
end

if strcmp(options.Display,'final') || strcmp(options.Display,'iter') ...
  || (strcmp(options.Display,'notify') && isempty(strfind(message, 'Converged'))) ...
  || (isfield(options,'Diagnostics') && strcmp(options.Diagnostics,'on'))
  disp([ sprintf('\n') '** Finishing minimization of ' inline_localChar(fun) ' using algorithm ' inline_localChar(options.algorithm) ]);
  disp( [ ' Status: ' output.message ]);
  disp(' Func_count     min[f(x)]        Parameters');
  inline_disp(struct('Display','iter'), -constraints.funcCount , fun, pars, mean(fval));
  
  if length(index) > 10 % test length of tolerence region
    disp(' Gaussian uncertainty on parameters (half width, from the optimization history)')
    inline_disp(struct('Display','iter'), -1, fun, output.parsHistoryUncertainty, NaN);
  end
  if isfield(output,'parsHessianUncertainty') && ~isempty(output.parsHessianUncertainty)
    disp(' Gaussian uncertainty on parameters (half width, from the Hessian matrix)')
    inline_disp(struct('Display','iter'), -1, fun, output.parsHessianUncertainty, NaN);
  end
end

% restore initial parameters as a structure (when given as such)
if ~isempty(pars_isstruct)
  try
  pars = cell2struct(num2cell(pars(:)), pars_isstruct(:), 1);
  end
end

return  % actual end of optimization

% ==============================================================================
% Use nested functions as the criteria wrapper, to access 'constraints' and 'options'
  
  function c = inline_objective(fun, pars, varargin)
  % criteria to minimize, fun returns a scalar, or vector which is summed
    if nargin < 3, varargin={}; end
    % apply constraints on pars first
    pars                = inline_apply_constraints(pars,constraints,options); % private function
    % compute criteria
    t = clock;
    c = feval(fun, pars, varargin{:});         % function=row vector, pars=column
    c = double(c(:)');
    switch options.optimizer
    case {'fminlm','LMFsolve'}
      % LMFsolve supports criteria as a vector of residuals, which sum is the criteria
      % but gradient is used to guide the optimizer
      if length(c) == 1,
        c = c*ones(1,10)/10;
      end
    otherwise
      c = sum(c);
    end
    
    % check for usual stop conditions MaxFunEvals, TolX, TolFun ..., and call OutputFcn
    [exitflag, message] = inline_private_check(pars, sum(c), ...
       constraints.funcCount , options, constraints);
    constraints.message = message;
    
    % save current optimization state
    if sum(c) < sum(constraints.criteriaBest(:)), 
      constraints.criteriaBest=c;
      constraints.parsBest    =pars;
    end
    constraints.fevalDuration   = etime(clock, t); % time required to estimate the criteria
    constraints.criteriaPrevious= c;
    constraints.criteriaHistory = [ constraints.criteriaHistory ; sum(constraints.criteriaPrevious)
     ];
    constraints.parsPrevious    = pars;
    constraints.parsHistory     = [ constraints.parsHistory ; pars ]; 
    constraints.funcCount       = constraints.funcCount +1; 
    
    if exitflag
      error([ 'stop condition: ' message ]); % will end optimization in try/catch
    end
  end

end % fmin_private_wrapper optimizer core end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function constraints = inline_constraints_minmax(pars, constraints)
% define default min max in constraints, needed by bounded optimizers
  if ~isfield(constraints, 'min')
    constraints.min = NaN*ones(size(pars));
  end
  for i=find(isnan(constraints.min));
    constraints.min(i) = -2*abs(pars(i)); % default min values
    if pars(i) == 0
      constraints.min(i) = -1;
    end
  end
  if ~isfield(constraints, 'max')
    constraints.max = NaN*ones(size(pars));
  end
  for i=find(isnan(constraints.max));
    constraints.max(i) =  2*abs(pars(i)); % default max values
    if pars(i) == 0
      constraints.max(i) = 1;
    end
  end
end % inline_constraints_minmax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pars = inline_apply_constraints(pars, constraints, options)
  % take into account constraints on parameters, and perform stop condition checks
  exitflag=0;
  message='';

  if isfield(constraints, 'step') % restrict parameter change
    parsStep    = pars(:) - constraints.parsPrevious(:);
    index       = find(constraints.steps(:) & abs(parsStep) > abs(constraints.steps(:)) & ~isnan(constraints.steps(:)));
    if ~isempty(index), 
      parsStep    = sign(parsStep).*abs(constraints.steps(:));
      pars(index) = constraints.parsPrevious(index) + parsStep(index);
    end
  end
  if isfield(constraints, 'min')    % lower bound for parameters
    index = find(pars(:) < constraints.min(:) & isfinite(constraints.min(:)));
    if ~isempty(index), pars(index) = constraints.min(index); end
  end
  if isfield(constraints, 'max')    % upper bound for parameters
    index = find(pars(:) > constraints.max(:) & isfinite(constraints.max(:)));
    if ~isempty(index), pars(index) = constraints.max(index); end
  end
  if isfield(constraints, 'fixed')  % fix some parameters
    index = find(constraints.fixed & ~isnan(constraints.fixed));
    if ~isempty(index), pars(index) = constraints.parsStart(index); end
  end
  if isfield(constraints, 'eval')   % evaluate expression with 'p'
    p = pars;
    try
      if isa(constraints.eval, 'function_handle')
        p = feval(constraints.eval, p);
      elseif ischar(constraints.eval)
        eval([ constraints.eval ';' ]);
      end
    end
    pars = p;
  end

  pars=pars(:)'; % parameters is a row
end % inline_apply_constraints

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function strfcn = inline_localChar(fcn)
% Convert the fcn to a string for printing

  if ischar(fcn)
      strfcn = fcn;
  elseif isa(fcn,'inline')
      strfcn = char(fcn);
  elseif isa(fcn,'function_handle')
      strfcn = func2str(fcn);
  else
      try
          strfcn = char(fcn);
      catch
          strfcn = '(name not printable)';
      end
  end

end % inline_localChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function inline_disp(options, funccount, fun, pars, fval)
% function called during minimization procedure
%
% Displays iteration information every 5 steps, then 10 steps, then 100 steps
% or at every step if iteration is negative


  if funccount > 5
    if funccount > 50  & mod(funccount,100) return;
    elseif mod(funccount,10) return; end
  end

  if isfield(options,'Display')
    if strncmp(options.Display, 'iter',4)
      spars=pars(1:min(20,length(pars)));
      spars=mat2str(spars', 4);  % as a row
      if length(spars) > 45, spars=[ spars(1:42) ' ...]' ]; end
      index = isfinite(fval);
      if isfinite(funccount) && ~isempty(index)
        disp(sprintf(' %5.0f    %12.6g          %s', abs(funccount), sum(fval(index)), spars));
      else
        disp(sprintf('                                %s', spars));
      end
    end
  end
  
end % inline_disp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [istop, message] = inline_private_check(pars, fval, funccount, options, constraints)
% standard checks
% inline_private_check(pars, fval, funccount, options, constraints)
% or
% options=inline_private_check(options, default_options);

  istop=0; message='';
  
  % check of option members
  if nargin<=2
    options=pars;
    if nargin ==2, 
      default=fval; 
      checks=fieldnames(default);
    else 
      fval=[]; 
      checks={'TolFun','TolX','Display','MaxIter','MaxFunEvals','FunValCheck','OutputFcn','algorithm'};
    end
    
    for index=1:length(checks)
      if ~isfield(options, checks{index}), 
        if isfield(default, checks{index}), 
          options=setfield(options,checks{index},getfield(default, checks{index}));
        else
          options=setfield(options,checks{index},[]); 
        end
      end
    end
    istop=options;
    return
  end
  
  pars_prev = constraints.parsPrevious;
  fval_prev = constraints.criteriaPrevious;
  fval_best = constraints.criteriaBest;
  fval_mean = mean(constraints.criteriaHistory(max(1, length(constraints.criteriaHistory)-10):end));
  
  % handle relative stop conditions
  if isfield(options,'TolFunChar')
    options.TolFun = options.TolFunChar;
  end
  if ischar(options.TolFun)
    if options.TolFun(end)=='%'
      options.TolFun(end)='';
      options.TolFun = abs(str2num(options.TolFun)*fval/100);
    else
      options.TolFun = str2num(options.TolFun);
    end
  end
  if isfield(options,'TolXChar')
    options.TolX = options.TolXChar;
  end
  if ischar(options.TolX)
    if options.TolX(end)=='%'
      options.TolX(end)='';
      options.TolX = abs(str2num(options.TolX)*pars/100);
    else
      options.TolX = str2num(options.TolX);
    end
  end

  % normal terminations: function tolerance reached
  if ~isempty(options.TolFun) && options.TolFun ~= 0 && funccount >= 5*length(pars)
    if (all(0 < fval) && all(fval <= options.TolFun)) % stop on lower threshold
      istop=-1;
      message = [ 'Converged: Termination function tolerance criteria reached (fval <= options.TolFun=' ...
                num2str(options.TolFun) ')' ];
    end
    if ~istop
      % stop on criteria change
      if  all(abs(fval-fval_prev) < options.TolFun) ...
       && all(abs(fval-fval_prev) > 0) ...
       && all(fval < fval_mean - options.TolFun) 
        istop=-12;
        message = [ 'Converged: Termination function change tolerance criteria reached (delta(fval) < options.TolFun=' ...
                num2str(options.TolFun) ')' ];
      end
    end
  end
  
  % normal terminations: parameter variation tolerance reached, when function termination is also true
  if (istop==-1 || istop==-12) 
    if ~isempty(options.TolX) && isnumeric(options.TolX)
      index=find(isfinite(options.TolX) & options.TolX);
      if all(abs(pars(index)-pars_prev(index)) < abs(options.TolX(index))) ...
      && any(abs(pars(index)-pars_prev(index)) > 0)
        istop=-5;
        message = [ 'Converged: Termination parameter tolerance criteria reached (delta(parameters) <= options.TolX=' ...
              num2str(mean(options.TolX)) ')' ];
      end
    end
  end

  % abnormal terminations
  if ~istop

    if options.MaxFunEvals > 0 & funccount >= options.MaxFunEvals
      istop=-3;
      message = [ 'Maximum number of function evaluations reached (options.MaxFunEvals=' ...
                num2str(options.MaxFunEvals) ')' ];
    end

    % the function value is nan or parameters just went to nan
    if strcmp(options.FunValCheck,'on') && (any(isnan(fval) | isinf(fval)))
      istop=-4;
      message = 'Function value is Inf or Nan (options.FunValCheck)';
    end
    
    if any(isnan(pars))
      index = find(isnan(pars(:)) & ~isnan(pars_prev(:)));
      if ~isempty(index)
        pars(index) = pars_prev(index);
      end
      index = find(isnan(pars(:)) & ~isnan(constraints.parsBest(:)));
      if ~isempty(index)
        pars(index) = constraints.parsBest(index);
      end
      index = find(isnan(pars(:)) & ~isnan(constraints.parsStart(:)));
      if ~isempty(index)
        pars(index) = constraints.parsStart(index);
      end
    end

    if ~isempty(options.OutputFcn)
      optimValues = options;
      if ~isfield(optimValues,'state')
        if istop,               optimValues.state='done';
        elseif funccount  <= 2, optimValues.state='init';
        else                    optimValues.state='iter'; end
      end
      optimValues.funcount   = funccount;
      optimValues.funcCount  = funccount;
      optimValues.funccount  = funccount;
      optimValues.fval       = sum(fval(:));
      if isfield(options,'procedure'),        optimValues.procedure=options.procedure;
      elseif isfield(options, 'algorithm'),   optimValues.procedure=options.algorithm;
      elseif isfield(options, 'optimizer'),   optimValues.procedure=options.optimizer;
      else optimValues.procedure  = 'iteration'; end
      istop2 = feval(options.OutputFcn, pars, optimValues, optimValues.state);
      if istop2 && ~istop
        istop=-6;
        message = 'Algorithm was terminated by the output function (options.OutputFcn)';
      end
    end
    if istop
      funccount = -funccount; % trigger iteration display
    end
    inline_disp(options,  funccount, options.optimizer, pars, fval);
  end

end % inline_private_check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [dp,covp,corp,jac,hessian] = inline_estimate_uncertainty(fun, pars, options, varargin)
% [dp,covp,corp] = inline_estimate_uncertainty(fun, pars, options)
% 
% Estimates the uncertainty around an optimization solution using
% the error matrix from the criteria jacobian inversion.
% 
% Calling:
%   [p,c,e,o]  = fmin(fun, p0, ...);
%   dp = o.parsHessianUncertainty;
%
% Input:
%  FUN is a function handle (anonymous function or inline) with a loss
%  function, which may be of any type, and needn't be continuous. It does,
%  however, need to return a single value.
%
%  PARS is a vector with initial guess parameters. You must input an
%  initial guess.
%
%  OPTIONS is a structure with settings for the simulated annealing, 
%  compliant with optimset. Default options may be obtained with
%     o=fmin_private_wrapper(optimizer,'defaults')
%
% Output:
%  DP is the gaussian uncertainty around PARS
%  COVP is the error matrix 
%  CORP is the correlation matrix
%  JAC  is the Jacobian
%  HESSIAN is the Hessian


  n=length(pars);
  if nargin < 3, options=[]; end
  if nargin < 4, args={}; end
  if isfield(options,'TolX') TolX = options.TolX; 
  else TolX = 0; end

  % initialize the curvature matrix alpha = '1/2 d2 Chi2/dpi/dpj' (half Hessian)
  alpha= zeros(n);
  dp   = zeros(size(pars));
  chisq= sum(feval(fun, pars, varargin{:}));
  
  covp = [];
  corp = [];
  jac  = [];
  hessian = [];
  if TolX <= 0, 
    TolX = 0.01*pars;
  end
  if length(TolX) == 1
    dp   = TolX*ones(size(pars));
  else
    dp   = TolX;
  end
  dp(find(dp == 0)) = 1e-5;

  % we now build the error matrix 'alpha' and the Jacobian
  jac = zeros(n,1);
  for i=1:n
    p    = pars; p(i) = p(i)+dp(i); chi1 = sum(feval(fun, p, varargin{:}));
    p    = pars; p(i) = p(i)-dp(i); chi2 = sum(feval(fun, p, varargin{:}));
    alpha(i,i) = (chi1-2*chisq+chi2)/2/dp(i)/dp(i); % diagonal terms
    jac(i) = (chi1-chisq)/dp(i);
    
    for j=i+1:n
      p=pars; p(i)=p(i)+dp(i); p(j)=p(j)+dp(j); chi1=sum(feval(fun,p, varargin{:}));
      p=pars; p(i)=p(i)+dp(i); p(j)=p(j)-dp(j); chi2=sum(feval(fun,p, varargin{:}));
      p=pars; p(i)=p(i)-dp(i); p(j)=p(j)+dp(j); chi3=sum(feval(fun,p, varargin{:}));
      p=pars; p(i)=p(i)-dp(i); p(j)=p(j)-dp(j); chi4=sum(feval(fun,p, varargin{:}));
      alpha(i,j)=(chi1-chi2-chi3+chi4)/8/dp(i)/dp(j);
      alpha(j,i)=alpha(i,j); % off diagonal terms (symmetric)
    end
  end
  if any(isnan(alpha(:))), return; end 
  hessian=2*alpha;
  alpha = alpha/chisq;      % normalized error matrix
  covp  = pinv(alpha);       % COV MATRIX
  dp    = sqrt(abs(diag(covp))); % uncertainty on parameters
  corp  = covp./(dp*dp');   % correlation matrix
  
end % inline_estimate_uncertainty

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [optimizer, name] = inline_auto_optimizer(fun, pars, varargin)
% optimizer = inline_auto_optimizer(fun, pars, varargin)
%
% Determine the best optimizer to use, depending on:
% * objective function is noisy/continuous
% * number of parameters
% * duration of function evaluation
%
% Input:
%  FUN is a function handle (anonymous function or inline) with a loss
%  function, which may be of any type, and needn't be continuous. It does,
%  however, need to return a single value.
%
%  PARS is a vector with initial guess parameters. You must input an
%  initial guess.
%
% Output:
%  optimizer: name of the best optimizer to use

% list of optimizers
optimizers = { ...
  'fminanneal',  ...
  'fminbfgs',  ...
  'fmincgtrust',  ...
  'fmincmaes',  ...
  'fminga',  ...
  'fmingradrand',  ...
  'fminhooke',  ...
  'fminimfil',  ...
  'fminkalman',  ...
  'fminlm',  ...
  'fminnewton',  ...
  'fminpowell',  ...
  'fminpso',  ...
  'fminralg',  ...
  'fminrand',  ...
  'fminsce',  ...
  'fminsearchbnd',  ...
  'fminsimplex',  ...
  'fminsimpsa',  ...
  'fminswarm',  ...
  'fminswarmhybrid' ...
}; 

if nargin < 3, varargin = {}; end

dimensions = [ 1     2     4     6     8    10    12    16    20    24    28    32    40    48    64 ];

tic
fval1 = feval(fun, pars, varargin{:});
t1 = toc;
if t1 > 5
  disp([ 'Analysing the objective function. Please wait (' num2str(t1) '[s])' ])
end
tic
fval2 = feval(fun, pars, varargin{:});
t2 = toc;

elapsed = mean([t1,t2]);

if sum(fval1(:)) == sum(fval2(:)) % continuous function
  threshold = 0.8;
  success_ratio = [ ...
   85.1923   81.9231   87.5000   85.7692   87.3077   86.1538   87.6923   85.7692   84.6154   78.8462   78.8462   79.4872   77.5641   82.6923   76.2821
   82.3077   80.0000   81.7308   80.5769   78.4615   76.9231   76.5385   75.7692   76.2821   74.3590   69.2308   72.4359   74.3590   71.7949   70.5128
   90.7692   89.4231   89.4231   88.2692   89.2308   87.6923   88.4615   88.4615   89.7436   87.1795   85.8974   87.8205   87.1795   85.8974   83.9744
   88.2692   85.1923   88.4615   87.1154   87.3077   90.0000   90.3846   93.4615   92.9487   92.3077   89.7436   91.0256   90.3846   85.2564   82.0513
   96.7308   92.8846   94.6154   98.2692   98.2692   98.4615   98.4615   98.4615   98.0769   98.0769   98.0769  100.0000   98.0769   96.1538   94.2308
   90.3846   86.9231   80.7692   81.9231   82.8846   80.7692   79.2308   79.2308   75.0000   76.2821   76.2821   70.5128   77.5641   73.7179   63.4615
   98.6538   97.3077   95.9615   97.8846   98.0769  100.0000   99.2308   97.6923   98.0769   97.4359   94.8718   95.5128   96.1538   96.1538   94.2308
   97.5000   95.7692   96.1538   96.1538   94.2308   95.7692   95.0000   95.7692   95.5128   94.8718   90.3846   91.0256   89.1026   89.1026   85.8974
   81.9231   83.6538   76.1538   70.9615   78.4615   74.6154   78.8462   74.2308   78.8462   76.2821   78.8462   80.7692   74.3590   69.2308   61.5385
   78.6538   67.5000   80.9615   84.2308   85.0000   85.0000   85.0000   83.0769   79.4872   81.4103   80.7692   78.8462   79.4872   75.6410   76.9231
   90.1923   70.7692   74.2308   82.8846   75.9615   76.1538   76.1538   74.6154   75.6410   72.4359   69.8718   78.8462   76.2821   79.4872   76.9231
   98.0769   98.8462   99.4231   99.8077   99.6154   99.2308   98.4615   99.2308   99.3590   98.7179   99.3590   98.7179   99.3590  100.0000  100.0000
   99.6154   97.6923   99.8077   99.8077   99.4231   99.2308   99.6154   99.6154   99.3590   98.7179   99.3590   96.7949   94.2308   93.5897   92.3077
       0   88.8462   89.0385   88.6538   86.9231   87.6923   87.3077   88.8462   88.4615   88.4615   88.4615   89.7436   90.3846   91.0256   91.0256
   98.6538   98.0769   98.2692   99.8077  100.0000  100.0000   98.4615   87.6923   62.8205   58.3333   46.1538   48.0769   42.3077   42.3077   37.8205
  100.0000  100.0000  100.0000  100.0000  100.0000  100.0000   99.6154   97.6923   96.1538   94.8718   94.8718   92.3077   87.8205   88.4615   83.9744
   90.5769   93.0769   90.9615   90.9615   91.1538   86.9231   83.4615   70.7692   60.8974   52.5641   39.7436   37.8205   30.1282   35.8974   32.6923
   99.8077   98.0769   99.0385   99.2308   98.6538   96.9231   94.2308   90.7692   83.9744   84.6154   70.5128   57.0513   56.4103   57.0513   50.6410
  100.0000  100.0000   99.8077   99.8077  100.0000  100.0000  100.0000   98.4615   97.4359   98.7179   98.0769   95.5128   91.6667   90.3846   85.8974
  100.0000   99.8077   98.8462   98.6538   98.0769   96.9231   96.9231   96.1538   97.4359   92.9487   92.3077   92.9487   87.8205   87.1795   88.4615
  100.0000   98.8462   99.2308   98.8462   98.4615   96.1538   94.6154   92.3077   90.3846   90.3846   89.7436   89.1026   85.2564   78.8462   71.7949
  ];
  
  calls = 1000*[ ...
    0.2693    0.2415    0.2141    0.2204    0.2857    0.3207    0.3769    0.4299    0.5563    0.4161    0.4575    0.5465    0.5086    0.6054    0.6598
    0.0164    0.0764    0.0331    0.0372    0.0427    0.0523    0.0608    0.0822    0.1045    0.1245    0.1462    0.1651    0.2040    0.2420    0.3233
    0.0605    0.0827    0.0449    0.0551    0.0849    0.0967    0.1135    0.2210    0.3079    0.4992    0.3093    0.3874    0.4400    0.4344    0.5887
    0.0737    0.2219    0.4083    0.6234    0.8914    1.1223    1.2868    1.7643    1.9959    2.4550    2.8529    3.5294    3.6230    3.5442    3.7831
    1.6515    3.4798    3.8199    4.4356    4.9326    5.2903    5.3315    5.7945    6.1345    6.0191    6.4135    6.7933    6.6413    7.3729    7.6670
    0.0712    0.3133    0.7274    0.8223    1.0092    1.1417    1.1660    1.4760    1.6228    1.8562    1.8574    1.5919    2.2417    1.3564    1.7119
    0.0458    0.1527    0.2809    0.4838    0.6963    1.2556    1.1672    1.0838    1.2007    1.3091    1.4621    1.6364    1.8917    2.2753    2.7098
    0.0939    0.2528    0.4473    0.6018    0.8382    1.1089    1.1171    1.4071    1.4821    1.8729    1.8834    1.9261    2.1155    2.6947    3.5206
    0.0446    0.0801    0.4744    0.8817    1.0960    0.8408    1.5597    1.2743    2.2105    1.8744    3.0964    3.2771    3.3436    3.3913    1.8740
    0.0416    0.1256    0.3588    1.0271    0.6324    0.6562    0.5582    0.9899    1.0497    1.0583    1.2038    1.3420    1.6554    2.3724    2.4328
    0.0108    0.0184    0.0350    0.0611    0.0986    0.1417    0.2413    0.4261    0.7417    1.1582    0.7880    0.9736    1.2944    1.7232    2.8102
    0.0529    0.0563    0.1386    0.2230    0.2022    0.3379    0.2362    0.2639    0.3572    0.4499    0.4391    0.3819    0.5193    0.5030    0.7003
    0.5450    1.0566    1.5427    1.8732    2.2197    2.2858    2.5978    2.8713    3.0430    3.4155    3.8864    3.9315    3.7694    4.1024    4.2280
       0    0.0194    0.0291    0.0386    0.0464    0.0670    0.0799    0.1022    0.1227    0.1457    0.1828    0.2432    0.3207    0.4188    0.5071
    0.1174    0.3285    0.9123    1.8045    3.0254    4.3795    5.8132    7.9103    6.6244    6.4910    4.4082    4.7445    5.6173    5.6746    5.7539
    0.1764    0.4695    0.8583    1.2411    1.5666    1.9494    2.3250    2.7945    3.2867    4.0204    4.5006    4.8020    5.7679    6.7163    8.0322
    0.0198    0.0906    0.1955    0.3822    0.5785    0.8160    0.9122    1.1120    1.0581    1.1747    0.9068    0.8358    0.8505    1.1227    1.0455
    0.0152    0.0595    0.1354    0.1996    0.2941    0.3666    0.4568    0.5976    0.6029    0.7326    0.7119    0.6283    0.6854    0.7360    0.7651
    0.1894    0.4376    0.7971    1.0692    1.5103    1.7598    2.1463    2.5770    3.0743    3.6196    4.2443    4.3916    4.4845    5.0825    6.5448
    0.2847    0.5638    0.8843    1.2339    1.5976    2.2045    2.1526    2.7078    3.0478    3.0776    3.3807    3.4760    3.9423    4.4684    4.6633
    0.1475    0.2234    0.4536    0.6490    0.9279    1.0107    1.2060    1.3491    1.3422    2.1512    2.3052    3.1118    3.5412    3.3738    3.2854
  ];
else                            % noisy function
  threshold = 0.4;
  success_ratio = [ ...
   56.7308   25.3846   23.0769   21.5385   21.7308   18.4615   20.0000   16.1538   19.8718   16.0256   16.6667   16.0256   17.3077   12.8205   14.7436
   19.6154    2.5000    1.7308    1.1538    0.1923       0       0       0    0.6410       0       0       0       0    1.2821    0.6410
   31.3462    7.8846    9.2308   11.3462   10.7692   15.0000   11.9231   14.2308   13.4615   13.4615   13.4615   12.8205   14.1026   14.7436   15.3846
   78.4615   69.2308   72.6923   72.8846   75.3846   72.6923   73.4615   73.0769   74.3590   74.3590   68.5897   69.2308   67.3077   66.6667   60.8974
   96.1538   92.1154   83.6538   92.5000   90.5769   85.0000   83.4615   77.6923   74.3590   73.0769   69.8718   67.9487   64.7436   60.2564   53.2051
   67.3077   29.2308   26.7308   31.1538   31.5385   26.9231   22.6923   21.1538   20.5128   21.7949   18.5897   17.9487   17.3077   17.9487   16.0256
   80.9615   68.2692   72.1154   70.7692   69.8077   64.2308   63.4615   53.4615   55.7692   48.0769   46.7949   39.7436   40.3846   35.2564   35.2564
   81.5385   69.4231   71.1538   69.6154   64.4231   57.6923   53.8462   50.3846   50.6410   42.3077   39.1026   41.0256   42.9487   36.5385   35.8974
   55.7692   34.4231   40.3846   41.7308   40.9615   37.3077   37.6923   38.0769   35.8974   35.8974   32.0513   30.7692   30.7692   30.7692   30.7692
    3.2692    2.6923    3.4615    4.2308    4.4231    5.3846    5.7692    6.5385    7.0513    7.0513    3.8462    5.1282    5.1282    3.8462    3.8462
   13.0769    6.3462    9.6154   14.8077   16.3462   18.4615   20.3846   21.9231   25.0000   26.9231   28.8462   29.4872   31.4103   31.4103   26.2821
   95.7692   74.2308   65.9615   65.5769   62.1154   55.7692   50.3846   46.1538   40.3846   42.3077   38.4615   36.5385   37.1795   31.4103   33.3333
   98.0769   97.8846   98.0769   97.8846   97.8846   97.3077   95.3846   90.0000   89.1026   82.6923   71.7949   69.2308   61.5385   61.5385   53.2051
       0    6.7308   11.1538   11.1538   14.4231   14.2308   16.9231   15.0000   18.5897   17.3077   18.5897   21.7949   18.5897   19.2308   23.7179
   83.0769   86.9231   83.8462   84.6154   85.5769   83.4615   76.5385   64.2308   55.7692   48.0769   42.9487   37.8205   33.3333   33.9744   32.6923
   98.2692   98.0769   97.3077   96.9231   94.6154   89.6154   90.0000   86.5385   82.6923   80.7692   75.0000   77.5641   75.0000   71.1538   65.3846
   31.5385   12.6923   11.5385   12.3077   11.7308    9.6154   10.0000   11.1538    8.9744   10.2564   10.2564   10.8974    7.0513    7.0513    8.3333
   97.3077   83.8462   66.9231   57.5000   52.6923   40.7692   38.4615   29.6154   24.3590   23.7179   20.5128   19.8718   17.9487   15.3846   10.2564
   98.0769   97.8846   98.0769   97.5000   96.5385   95.7692   93.0769   90.0000   89.7436   85.8974   80.7692   80.7692   69.2308   55.7692   43.5897
  100.0000   98.6538   97.5000   96.3462   94.4231   91.5385   87.3077   75.7692   67.9487   65.3846   57.6923   53.2051   55.1282   47.4359   42.3077
   97.1154   77.3077   59.0385   55.0000   53.2692   45.0000   46.9231   40.7692   35.8974   38.4615   30.7692   32.0513   33.9744   30.7692   29.4872
  ];
  
  calls = 10000*[ ...
    0.0554    0.0777    0.0680    0.0811    0.0931    0.0720    0.0981    0.0652    0.0852    0.0698    0.0753    0.0825    0.0905    0.0786    0.0874
    0.0030    0.0048    0.0050    0.0034    0.0094       0       0       0    0.0033       0       0       0       0    0.0061    0.0077
    0.0228    0.0222    0.0371    0.0401    0.0442    0.0538    0.0440    0.0854    0.0808    0.0640    0.1655    0.1000    0.1683    0.2337    0.2581
    0.0097    0.0263    0.0477    0.0713    0.0981    0.1230    0.1387    0.1781    0.2220    0.2943    0.2901    0.3270    0.3426    0.3953    0.5349
    0.1329    0.2902    0.3116    0.5021    0.5598    0.5765    0.6370    0.6329    0.6607    0.7030    0.6963    0.6870    0.6873    0.7294    0.7096
    0.0291    0.0551    0.0656    0.0891    0.1166    0.1071    0.1124    0.0859    0.0941    0.1137    0.0906    0.1045    0.1083    0.1070    0.1328
    0.0055    0.0274    0.0883    0.1462    0.2526    0.2791    0.2775    0.3559    0.3857    0.4429    0.4326    0.4138    0.4930    0.4449    0.5561
    0.0170    0.0562    0.1152    0.1993    0.2428    0.2846    0.3085    0.2879    0.3135    0.2890    0.3676    0.4225    0.5008    0.4145    0.3884
    0.0622    0.1438    0.2662    0.4033    0.4638    0.4308    0.4769    0.5193    0.5091    0.5771    0.4303    0.5188    0.5017    0.5117    0.4447
    0.1838    0.2521    0.3755    0.4559    0.5379    0.7025    0.7427    1.1144    1.1745    0.9902    0.8121    0.6603    0.5538    0.4866    0.2722
    0.0074    0.0108    0.0214    0.0358    0.0541    0.0765    0.0741    0.1289    0.2205    0.2601    0.3271    0.4365    0.5529    0.5866    0.4151
    0.0639    0.1574    0.3075    0.3752    0.5129    0.5624    0.5945    0.5261    0.4835    0.5177    0.5260    0.5140    0.6334    0.3981    0.5545
    0.0529    0.1028    0.1468    0.1900    0.2232    0.3169    0.3136    0.3337    0.4231    0.4470    0.3996    0.4227    0.3914    0.4377    0.4182
       0    0.0093    0.0215    0.0282    0.0483    0.0532    0.0521    0.0699    0.0787    0.0963    0.0805    0.1493    0.0975    0.1906    0.2237
    0.0241    0.0631    0.1387    0.2515    0.3580    0.4917    0.5858    0.7183    0.6344    0.5262    0.5578    0.4541    0.4801    0.6533    0.5411
    0.0214    0.0463    0.0862    0.1393    0.1973    0.2351    0.2699    0.3229    0.3295    0.3831    0.4323    0.4891    0.5294    0.5913    0.7043
    0.0064    0.0283    0.1000    0.1456    0.2210    0.2055    0.1986    0.2992    0.2459    0.3029    0.2807    0.2311    0.2995    0.2494    0.2286
    0.0044    0.0075    0.0210    0.0323    0.0448    0.0499    0.0623    0.0646    0.0619    0.0690    0.0734    0.0767    0.0789    0.0712    0.0706
    0.0281    0.0492    0.0987    0.1603    0.2042    0.2564    0.2637    0.3418    0.4575    0.4981    0.6021    0.6129    0.6760    0.6627    0.5968
    0.0268    0.0551    0.1044    0.1717    0.2327    0.2819    0.3872    0.3832    0.3943    0.3834    0.3607    0.3676    0.4264    0.5465    0.5066
    0.0431    0.1283    0.2420    0.3113    0.4613    0.5006    0.5144    0.4573    0.4688    0.3568    0.4419    0.5771    0.4892    0.6035    0.4527
  ];
end

  % interpolates data for the required dimension=length(pars)
  this_success = zeros(length(optimizers), 1);
  this_calls   = this_success;
  for index=1:length(optimizers)
    this_success(index) = interp1(dimensions, success_ratio(index, :), length(pars));
    this_calls(index)   = interp1(dimensions, calls(index, :),         length(pars));
  end

  % sort success ratio
  [this_success, index] = sort(this_success,1,'descend');
  this_calls = this_calls(index);
  optimizers = optimizers(index);

  % apply threshold on success (higher than 80% for continuous, 40% for noisy)
  index=find(this_success >= threshold*100);
  this_success = this_success(index);
  this_calls   = this_calls(index);
  optimizers   = optimizers(index);

  % select randomly among optimizers
  weight = exp(this_success-100)./this_calls; % highest is best: success close to 100, lowest call number
  rand_table=cumsum( weight );
  rand_table = rand_table/max(rand_table);

  % choose optimzer on the probability distribution
  index = find(rand_table >= rand);
  index=index(1);
  optimizer = optimizers{index};
  
  
  fprintf(1,'** Optimizer selected: %s: success=%g cost=%g\n', optimizer, this_success(index), this_calls(index));
  
  pars = feval(optimizer, 'defaults');
  
  if isfield(pars, 'algorithm'), name = pars.algorithm; 
  else                           name = optimizer; end

end % inline_auto_optimizer
