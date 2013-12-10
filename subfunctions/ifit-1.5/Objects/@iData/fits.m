function [pars_out,criteria,message,output] = fits(a, model, varargin)
% [pars,criteria,message,output] = fits(a, model, pars, options, constraints, ...) : fit data set on a model
%
%   @iData/fits find best parameters estimates in order to minimize the 
%     fitting criteria using model 'fun', by mean of an optimization method
%     described with the 'options' structure argument.
%     Additional constraints may be set by fxing some parameters, or define
%     more advanced constraints (min, max, steps). The last arguments controls the fitting
%     options with the optimset mechanism, and the constraints to apply during optimization.
%     The fit can be applied sequentially and independently onto iData object arrays.
%  [pars,...] = fits(a, model, pars, options, lb, ub)
%     uses lower and upper bounds as parameter constraints (double arrays)
%  [pars,...] = fits(a, model, pars, options, fixed)
%     indicates which parameters are fixed (non zero elements of array).
%  [pars,...] = fits(a, model, pars, 'optimizer', ...)
%     uses a specific optimizer and its default options.
%  [pars,...] = fits(a, model, pars, options, constraints, args...)
%     send additional arguments to the fit model(pars, axes, args...)
%  [optimizers,functions] = fits(iData)
%     returns the list of all available optimizers and fit functions.
%  fits(iData)
%     displays the list of all available optimizers and fit functions.
%  You may create new fit models with the 'ifitmakefunc' tool.
%
%  When the iData object contains a Monitor value, the fit is performed on
%    Signal/Monitor.
%  When parameters, options, and constraints are entered as a string with
%    name=value pairs, the string is interpreted as a structure description, so
%    that options='TolX=1e-4; optimizer=fminpso' is a compact form for 
%    options=struct('TolX','1e-4','optimizer','fminpso').
%
%   To set a constraint on a model parameter, define the 'constraint' input argument
%   or set the constraint directly on the model parameters with:
%     model.parameter='fix'     % to lock its value during a fit process
%     model.parameter='clear'   % to unlock value during a fit process
%     model.parameter=[min max] % to bound value
%     model.parameter=[nan nan] % to remove bound constraint
%     model.parameter=''        % to remove all constraints on 'parameter'
%     model.Constraint=''       % to remove all constraints
% 
% The default fit options.criteria is 'least_square', but others are available:
%   least_square          (|Signal-Model|/Error).^2     non-robust 
%   least_absolute         |Signal-Model|/Error         robust
%   least_median    median(|Signal-Model|/Error)        robust, scalar
%   least_max          max(|Signal-Model|/Error)        non-robust, scalar
%
%  Type <a href="matlab:doc(iData,'Fit')">doc(iData,'Fit')</a> to access the iFit/Fit Documentation.
%
% input:  a: object or array (iData)
%           when given as an empty iData, the list of optimizers and fit models
%             is shown.
%         model: model function (char/iFunc/function handle)
%           the model is converted into an iFunc object, with 'p' as parameters
%           and 'x,y,...' as axes (1st axis 'x' refers to rows, 'y' to columns)
%             from a string:       'signal = expression(p, x,y,...);'
%                                  'expression(p, x,y,...)' 
%             from function handle: @(p,x,..)expression or @function(p,x,...)
%           when set to empty, the 'gauss' 1D function is used (and possibly extended to multidimensional).
%         pars: initial model parameters (double array). 
%           when set to empty the starting parameters are guessed.
%           Named parameters can be given as a structure or string 'p1=...; p2=...'
%         options: structure as defined by optimset/optimget (char/struct)
%           if given as a char, it defines the algorithm to use and its default %             options (single optimizer name or string describing a structure).
%           when set to empty, it sets the default algorithm options (fmin).
%           options.TolX
%             The termination tolerance for x. Its default value is 1.e-4.
%           options.TolFun
%             The termination tolerance for the function value. The default value is 1.e-4. 
%             This parameter is used by fminsearch, but not fminbnd.
%           options.MaxIter
%             Maximum number of iterations allowed.
%           options.MaxFunEvals
%             The maximum number of function evaluations allowed. 
%           options.optimizer
%             Optimization method. Default is 'fminsearch' (char/function handle)
%             the syntax for calling the optimizer is e.g. optimizer(criteria,pars,options,constraints)
%           options.criteria
%             Minimization criteria. Default is 'least_square' (char/function handle)
%             the syntax for evaluating the criteria is criteria(Signal, Error, Model)
%           options.OutputFcn
%             Function called at each iteration as outfun(pars, optimValues, state)
%             The 'fminplot' function may be used.
%           options.Display
%             Display additional information during fit: 'iter','off','final'. Default is 'iter'.
%           options.Diagnostics
%             When set to 'on' or 1, returns the correlation coefficient and Hessian matrix
%         constraints: fixed parameter array. Use 1 for fixed parameters, 0 otherwise (double array)
%           OR use empty to not set constraints
%           OR use a structure with some of the following fields:
%           constraints.min:   minimum parameter values (double array)
%           constraints.max:   maximum parameter values (double array)
%           constraints.step:  maximum parameter step/change allowed.
%           constraints.fixed: fixed parameter flag. Use 1 for fixed parameters, 0 otherwise (double array)
%           constraints.eval:  expression making use of 'p', 'constraints', and 'options' 
%                              and returning modified 'p'
%                              or function handle p=@constraints.eval(p)
%           OR use a string 'min=...; max=...' to define the structure
%
% output: 
%         pars:              best parameter estimates (double array)
%         criteria:          minimal criteria value achieved (double)
%         message:           return message/exitcode from the optimizer (char/integer)
%         output:            additional information about the optimization (structure)
%           algorithm:         Algorithm used (char)
%           funcCount:         Number of function evaluations (double)
%           iterations:        Number of iterations (double)
%           parsHistory:       Parameter set history during optimization (double array)
%           criteriaHistory:   Criteria history during optimization (double array)
%           modelValue:        Last model evaluation (iData)
%           parsHistoryUncertainty: Uncertainty on the parameters obtained from 
%                              the optimization trajectory (double)
%
% ex:     p=fits(a,gauss,[1 2 3 4]);
%         o=fminpowell('defaults'); o.OutputFcn='fminplot'; 
%         [p,c,m,o]=fits(a,'gauss',[1 2 3 4],o); b=o.modelValue; plot(a,b)
%
% Version: $Revision: 1158 $
% See also iData, fminsearch, optimset, optimget, ifitmakefunc, Models, iFunc/fits

% handle input parameters
% ======================================================

pars_out=[]; criteria=[]; message=[]; output=[];

if nargin == 1 && all(isempty(a))
  if nargout == 0
    fits(iFunc);
  else
    [pars_out,criteria,message,output] = fits(iFunc);
  end
  return
end

% handle model given as a char
if nargin < 2
  model = '';
end
if isempty(model)
  model = gauss;
end

% test the model: is this an iFunc, a function handle or a char ?
if ~isa(model, 'function_handle') && ~ischar(model) && ~iscell(model) && ~isa(model, 'iFunc')
  iData_private_error(mfilename,[ 'The model argument is of class ' class(model) '. Should be a function name, expression, iFunc or function handle.' ]);
end

if ~isa(model, 'iFunc')
  model = iFunc(model);
end

if isempty(model)
  iData_private_error(mfilename,[ 'The model argument is empty. Should be a function name, expression, iFunc object or function handle.' ...
    sprintf('\n') 'Type "fits(iData)" to get a list of available predefined models.' ...
    sprintf('\n') 'or use "ifitmakefunc" to create one.' ]);
end

% handle input iData arrays
if numel(a) > 1
  pars_out=cell(1,numel(a)) ; criteria=zeros(1,numel(a)); 
  message =pars_out; output=pars_out;
  parfor index=1:numel(a)
    [pars_out{index}, criteria(index), message{index}, output{index}] = ...
      fits(model, a(index), varargin{:});
  end
  pars = pars_out;
  return
end

% calls iFunc/fits =============================================================
[pars_out, criteria, message, output] = fits(model, a, varargin{:});

% format output arguments (to iData) ===========================================
if nargin > 1 && ~isempty(inputname(2))  
  assignin('caller',inputname(2),model); % update in original object
end


