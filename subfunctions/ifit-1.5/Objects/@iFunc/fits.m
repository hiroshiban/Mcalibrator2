function [pars_out,criteria,message,output] = fits(model, a, pars, options, constraints, varargin)
% [pars,criteria,message,output] = fits(model, data, pars, options, constraints, ...) : fit a model on a data set
%
%   @iFunc/fits find best parameter estimates in order to minimize the 
%     fitting criteria using model 'fun', by mean of an optimization method
%     described with the 'options' structure argument.
%     Additional constraints may be set by fixing some parameters, or define
%     more advanced constraints (min, max, steps). The last arguments controls the 
%     fitting options with the optimset mechanism, and the constraints to apply
%     during optimization.
%  [pars,...] = fits(model, data, pars, options, lb, ub)
%     uses lower and upper bounds as parameter constraints (double arrays)
%  [pars,...] = fits(model, data, pars, options, fixed)
%     indicates which parameters are fixed (non zero elements of array).
%  [pars,...] = fits(model, data, pars, 'optimizer', ...)
%     uses a specific optimizer and its default options options=feval(optimizer,'defaults')
%  [pars,...] = fits(model, data, pars, options, constraints, args...)
%     send additional arguments to the fit model(pars, axes, args...).
%  [optimizers,functions] = fits(iFunc)
%     returns the list of all available optimizers and fit functions.
%  fits(iFunc)
%     displays the list of all available optimizers and fit functions.
%  You may create new fit models with the 'ifitmakefunc' tool.
%
%  When the data is entered as a structure or iData object with a Monitor value, 
%    the fit is performed on Signal/Monitor.
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
% input:  model: model function (iFunc). When entered as an empty object, the
%           list of optimizers and fit models is shown.
%         data: array or structure/object (numeric or structure or cell)
%               Can be entered as a single numeric array (the Signal), or as a 
%                 structure/object with possible members 
%                   Signal, Error, Monitor, Axes={x,y,...}
%               or as a cell { x,y, ... , Signal }
%               or as an iData object
%               or as a file name
%           The 1st axis 'x' is row wise, the 2nd 'y' is column wise.
%         pars: initial model parameters (double array, string or structure). 
%           when set to empty or 'guess', the starting parameters are guessed.
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
%             Optimization method. Default is 'fminpowell' (char/function handle)
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
%           OR use a string 'min=...; max=...'
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
%           modelValue:        Final best model evaluation
%           parsHistoryUncertainty: Uncertainty on the parameters obtained from 
%                              the optimization trajectory (double)
%
% ex:     p=fits(gauss, data,[1 2 3 4]);
%         o=fminpowell('defaults'); o.OutputFcn='fminplot'; 
%         [p,c,m,o]=fits(gauss,data,[1 2 3 4],o); 
%         plot(a); hold on; plot(o.modelAxes, o.modelValue,'r');
%
% Version: $Revision: 1158 $
% See also fminsearch, optimset, optimget, iFunc, iData/fits, iData, ifitmakefunc

% first get the axes and signal from 'data'

% a.Signal (numeric)
% a.Error (numeric)
% a.Monitor (numeric)
% a.Axes (cell of numeric)

% singlme empty argument: show funcs/optim list ================================
% handle default parameters, if missing
if nargin == 1 && isempty(model)
    % return the list of all available optimizers and fit functions
    output     = {};
    pars_out   = {};
    warn       = warning('off','MATLAB:dispatcher:InexactCaseMatch');
    if nargout == 0
      fprintf(1, '\n%s\n', version(iData));
      
      fprintf(1, '      OPTIMIZER DESCRIPTION [%s]\n', 'iFit/Optimizers');
      fprintf(1, '-----------------------------------------------------------------\n'); 
    end
    d = dir([ fileparts(which('fminpso')) ]);
    for index=1:length(d)
      this = d(index);
      try
        [dummy, method] = fileparts(this.name);
        options = feval(method,'defaults');
        if isstruct(options)
          output{end+1} = options;
          pars_out{end+1}   = method;
          if nargout == 0
            fprintf(1, '%15s %s\n', options.optimizer, options.algorithm);
          end
        end
      end
    end % for
    if nargout == 0
      fprintf(1, '\n');
      fprintf(1, '       FUNCTION DESCRIPTION [%s]\n', 'iFit/Models');
      fprintf(1, '-----------------------------------------------------------------\n'); 
    end
    d = dir([ fileparts(which('gauss')) ]);
    criteria = []; 
    for index=1:length(d)
      this = d(index);
      try
        [dummy, method, ext] = fileparts(this.name);
        if strcmp(ext, '.m')
          options = feval(method,'identify');
        else
          options = [];
        end
        if isa(options, 'iFunc')
          criteria   = [ criteria options ];
          if nargout == 0
            fprintf(1, '%15s %s\n', method, options.Name);
          end
        end
      end
    end % for
    
    % local (pwd) functions
    message = '';
    d = dir(fullfile(pwd,'*.m'));
    for index=1:length(d)
      this = d(index);
      try
        [dummy, method] = fileparts(this.name);
        options = feval(method,'identify');
        if isa(options, 'iFunc')
          criteria   = [ criteria options ];
          if isempty(message)
            fprintf(1, '\nLocal functions in: %s\n', pwd);
            message = ' ';
          end
          if nargout == 0
            fprintf(1, '%15s %s\n', method, options.Name);
          end
        end
      end
    end % for

    if nargout == 0 && length(criteria)
      fprintf(1, '\n');
      % plot all functions
      subplot(criteria);
    end
    message = 'Optimizers and fit functions list'; 
    warning(warn);
    return
end


% check of input arguments =====================================================

if isempty(model)
  disp([ 'iFunc:' mfilename ': Using default gaussian model as fit function.' ]);
  model = gauss;
end

if nargin < 2
	a = [];
	inname = '';
else
	inname = inputname(2);
end

if nargin < 3, pars = [];        end % will use guessed values
if nargin < 4, options=[];       end
if nargin < 5, constraints = []; end

% check for vectorized input of data sets
% handle array of model functions
if numel(model) > 1
  pars_out={} ; criteria={}; message={}; output={};
  for index=1:numel(model)
    [pars_out{end+1},criteria{end+1},message{end+1},output{end+1}]= ...
      fits(model(index), a, pars, options, constraints, varargin{:});
  end
  return
end
% handle array of data sets
if (iscellstr(a) || isstruct(a) || isa(a,'iData')) && numel(a) > 1
  pars_out={} ; criteria={}; message={}; output={};
  for index=1:numel(model)
    [pars_out{end+1},criteria{end+1},message{end+1},output{end+1}]= ...
      fits(model, a(1), pars, options, constraints, varargin{:});
  end
  return
end

% extract Signal from input argument, as well as a Data identifier
% default values
Monitor=1; Error=1; Axes={}; Signal=[]; Name = ''; is_idata=[];
if iscellstr(a) || ischar(a)
  a = iData(a);
end
if iscell(a)
  Signal = a{end};
  a(end) = [];
  Axes = a;
end
if isstruct(a) || isa(a, 'iData')
  if isfield(a,'Signal')  Signal  = a.Signal; end
  if isfield(a,'Error')   Error   = a.Error; end
  if isfield(a,'Monitor') Monitor = a.Monitor; end
  if isa(a, 'iData')
    is_idata = a;
    Axes=cell(1,ndims(a));
    for index=1:ndims(a)
      Axes{index} = getaxis(a, index);
    end
    Name = strtrim([ inname ' ' char(a) ]);
  elseif isfield(a,'Axes')    Axes    = a.Axes; 
  end
elseif isnumeric(a)
  Signal = a; 
  % create index axes
  for index=1:ndims(a)
    if size(a, index) > 1
      Axes{end+1} = 1:size(a, index);
    end
  end
end
if isempty(Name)
  Name   = strtrim([ class(a) ' ' mat2str(size(Signal)) ' ' inname ]);
end

if ~iscell(Axes) && isvector(Axes), Axes = { Axes }; end

% create the new Data structure to pass to the criteria
a = [];
a.Signal = iFunc_private_cleannaninf(Signal);
a.Error  = iFunc_private_cleannaninf(Error);
a.Monitor= iFunc_private_cleannaninf(Monitor);
a.Name   = Name;
a.Axes   = Axes;
clear Signal Error Monitor Axes

% handle Monitor normalisation
a.Monitor =real(a.Monitor);
if not(all(a.Monitor == 1 | a.Monitor == 0 | isnan(a.Monitor))), % fit(signal/monitor) 
  a.Signal = bsxfun(@rdivide,a.Signal,a.Monitor); 
  if not(all(a.Error == 1 | a.Error == 0 | isnan(a.Error)))
    a.Error  = bsxfun(@rdivide,a.Error, a.Monitor); % per monitor
  end
end

% starting configuration

if isempty(a.Signal)
  error([ 'iFunc:' mfilename ],[ 'Undefined/empty Signal ' inname ' to fit. Syntax is fits(model, Signal, parameters, ...).' ]);
end

if isvector(a.Signal) 
  ndimS = 1;
  % check if we have an event-type nD data set
  if all(cellfun(@isvector, a.Axes)) && all(cellfun(@numel, a.Axes) == numel(a.Signal))
    ndimS = length(a.Axes);
  end
else                  ndimS = ndims(a.Signal);
end

% handle case when model dimensionality is larger than actual Signal
if model.Dimension > ndimS
  error([ 'iFunc:' mfilename ], 'Signal %s with dimensionality %d has lower dimension than model %s dimensionality %d.\n', a.Name, ndimS, model.Name, model.Dimension);
% handle case when model dimensionality is smaller than actual Signal
elseif model.Dimension < ndimS && rem(ndimS, model.Dimension) == 0
  % extend model to match Signal dimensions
  disp(sprintf('iFunc:%s: Extending model %s dimensionality %d to data %s dimensionality %d.\n', ...
    mfilename, model.Name, model.Dimension, a.Name, ndimS));
  new_model=model;
  for index=2:(ndimS/model.Dimension)
    new_model = new_model * model;
  end
  model = new_model;
  clear new_model
elseif model.Dimension ~= ndimS
  error([ 'iFunc:' mfilename ], 'Signal %s with dimensionality %d has higher dimension than model %s dimensionality %d.\n', a.Name, ndimS, model.Name, model.Dimension);
end

% handle parameters: from char, structure or vector

pars_isstruct=[];
if ischar(pars) && ~strcmp(pars,'guess')
  pars = str2struct(pars);
end
if isempty(pars), pars=[]; end
if isstruct(pars)
  % search 'pars' names in the model parameters, and reorder the parameter vector
  p = []; f=fieldnames(pars);
  for index=1:length(f)
    match = strcmp(f{index}, model.Parameters);
    if any(match) && isscalar(pars.(f{index})) ...
      && isnumeric(pars.(f{index}))
      p(index) = pars.(f{index});
    else
      pars_isstruct.(f{index}) = pars.(f{index});
    end
  end
  % we try to simply build a parameter vector
  if length(p) ~= length(model.Parameters)
    p = [];
    for index=1:length(f)
      if isnumeric(pars.(f{index}))
        p = [ p pars.(f{index}) ];
      end
    end
  end
  if length(p) ~= length(model.Parameters)
    disp('Actual parameters')
    disp(pars)
    disp([ 'Required model ' model.Name ' ' model.Tag ' parameters' ])
    disp(model.Parameters)
    error([ 'iFunc:' mfilename], [ 'The parameters entered as a structure do not define all required model parameters.\n\tUse a vector or a structure with same fields or number of numerical values.' ]);
  else
    if isempty(pars_isstruct), pars_isstruct=1; end
    pars = p;
  end
elseif strcmp(pars,'guess') || (isnumeric(pars) && length(pars) < length(model.Parameters))
  pars = feval(model, pars, a.Axes{:}, a.Signal); % guess missing starting parameters
  pars = model.ParameterValues;
end
pars = reshape(pars, [ 1 numel(pars)]); % a single row

% handle options
if isempty(options)
  options = 'fmin';% default optimizer
end
if (ischar(options) && length(strtok(options,' =:;'))==length(options)) | isa(options, 'function_handle')
  algo = options;
  options           = feval(algo,'defaults');
  if isa(algo, 'function_handle'), algo = func2str(algo); end
  options.optimizer = algo;
elseif ischar(options), options=str2struct(options);
end
if ~isfield(options, 'optimizer')
  options.optimizer = 'fmin';
end
if ~isfield(options, 'criteria')
  options.criteria  = @least_square;
end
if ~isfield(options,'Display')   options.Display  =''; end
if  isempty(options.Display)     options.Display  ='notify'; end
% update name of optimizer
options_defaults = feval(options.optimizer,'defaults');
if isfield(options_defaults,'algorithm')
  options.algorithm = options_defaults.algorithm;
end
if ~isfield(options,'algorithm') options.algorithm=options.optimizer; end

% handle constraints

% handle constraints given as vectors
if (length(constraints)==length(pars) | isempty(pars)) & (isnumeric(constraints) | islogical(constraints))
  if nargin<6
    fixed            = constraints;
    constraints      =[];
    constraints.fixed=fixed;
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
elseif ischar(constraints), constraints=str2struct(constraints);
end
if ~isstruct(constraints) && ~isempty(constraints)
  error([ 'iFunc:' mfilename],[ 'The constraints argument is of class ' class(constraints) '. Should be a single array or a struct' ]);
end
% update Constraints with those from the model (if any not set yet)
for index=1:length(model.Parameters)
  if length(model.Constraint.min) >=index && isfinite(model.Constraint.min(index))
    this_min = model.Constraint.min(index);
  else
    this_min = NaN;
  end
  if length(model.Constraint.max) >=index && isfinite(model.Constraint.max(index))
    this_max = model.Constraint.max(index);
  else
    this_max = NaN;
  end
  if length(model.Constraint.fixed) >=index && model.Constraint.fixed(index)
    if ~isfield(constraints,'fixed'), 
      constraints.fixed = zeros(1, length(model.Parameters));
    end
    constraints.fixed(index) = 1;
  elseif any(isfinite([this_min this_max]))
    if ~isfield(constraints,'min'), 
      constraints.min = NaN*ones(1, length(model.Parameters));
    end
    if ~isfield(constraints,'max'), 
      constraints.max =  NaN*ones(1, length(model.Parameters));
    end
    constraints.min(index) = this_min;
    constraints.max(index) = this_max;
  end
end

% set other constraints fields used during optimization monitoring
constraints.parsStart      = pars;
constraints.parsHistory    = [];
constraints.criteriaHistory= [];
constraints.algorithm      = options.algorithm;
constraints.optimizer      = options.optimizer;
constraints.funcCount      = 0;

% update the 'model' with starting parameter values
model.ParameterValues = pars;
% feval(model, pars, a.Axes{:}, a.Signal); 

if strcmp(options.Display, 'iter') | strcmp(options.Display, 'final')
  fprintf(1, '** Starting fit of %s\n   using model    %s\n   with optimizer %s\n', ...
    a.Name,  model.Name, options.algorithm);
  disp(  '** Minimization performed on parameters:');
  for index=1:length(model.Parameters); 
    fprintf(1,'  p(%3d)=%20s=%g', index,strtok(model.Parameters{index}), pars(index)); 
    if isfield(constraints, 'fixed') && length(constraints.fixed) >= index && constraints.fixed(index)
      fprintf(1, ' (fixed)'); end
    fprintf('\n');
  end;
end

% we need to call the optimization method with the eval_criteria as FUN
% call minimizer ===============================================================
if abs(nargin(options.optimizer)) == 1 || abs(nargin(options.optimizer)) >= 6
  [pars_out,criteria,message,output] = feval(options.optimizer, ...
    @(pars) eval_criteria(model, pars, options.criteria, a, varargin{:}), pars, options, constraints);
else
  % Constraints not supported by optimizer
  [pars_out,criteria,message,output] = feval(options.optimizer, ...
    @(pars) eval_criteria(model, pars, options.criteria, a, varargin{:}), pars, options);
end

% format output arguments ======================================================
pars_out = reshape(pars_out, [ 1 numel(pars_out) ]); % row vector
model.ParameterValues = pars_out;
if ~isempty(inputname(1))  
    try
  assignin('caller',inputname(1),model); % update in original object
    end
end

if nargout > 3 || (isfield(options,'Diagnostics') && (strcmp(options.Diagnostics, 'on') || any(options.Diagnostics == 1)))
  output.modelValue = feval(model, pars_out, a.Axes{:});
  index=find(~isnan(a.Signal) & ~isnan(output.modelValue));
  if ~isscalar(a.Error), e = a.Error(index); else e=a.Error; end
  output.corrcoef   = eval_corrcoef(a.Signal(index), e, output.modelValue(index));
  output.residuals  = a.Signal - output.modelValue;
  output.Rfactor    = sum(e.*output.residuals(index).^2)/sum(e.*a.Signal(index));
  if strcmp(options.Display, 'iter') | strcmp(options.Display, 'final') | ...
    (isfield(options,'Diagnostics') && (strcmp(options.Diagnostics, 'on') || any(options.Diagnostics == 1)))
    fprintf(1, ' Correlation coefficient=%g (closer to 1 is better)\n',  output.corrcoef);
    fprintf(1, ' Weighted R-factor      =%g (smaller that 1 is better)\n', output.Rfactor);
  end
  if abs(output.corrcoef) < 0.6 && ~isscalar(a.Error)
    name = inputname(2);
    if isempty(name)
      name = 'a';
    end
    fprintf(1, ' WARNING: The fit result is BAD. You may improve it by setting %s.Error=1\n',...
      name);
  end
  
  if ~isempty(is_idata)
    % make it an iData
    b = is_idata;
    % fit(signal/monitor) but object has already Monitor -> we compensate Monitor^2
    if not(all(a.Monitor == 1 | a.Monitor == 0)) 
      output.modelValue    = bsxfun(@times,output.modelValue, a.Monitor); 
    end
    setalias(b,'Signal', output.modelValue, model.Name);
    b.Title = [ model.Name '(' char(b) ')' ];
    b.Label = b.Title;
    b.DisplayName = b.Title;
    setalias(b,'Error', 0);
    setalias(b,'Parameters', pars_out, [ model.Name ' model parameters for ' a.Name ]);
    setalias(b,'Model', model, model.Name);
    output.modelValue = b;
  else
    if length(a.Axes) == 1
      output.modelAxes  = a.Axes{1};
    else
      output.modelAxes  = a.Axes(:);
    end
  end
  output.model      = model;
  
  % set output/results
  if ischar(message) | ~isfield(output, 'message')
    output.message = message;
  else
    output.message = [ '(' num2str(message) ') ' output.message ];
  end
  output.parsNames  = model.Parameters;
  % final plot when in OutputFcn mode
  eval_criteria(model, pars_out, options.criteria, a, varargin{:});
end
if ~isempty(pars_isstruct)
  % first rebuild the model parameter structure
  pars_out = cell2struct(num2cell(pars_out), strtok(model.Parameters), 2);
  % then add initial additional fields
  if isstruct(pars_isstruct)
    f = fieldnames(pars_isstruct);
    for index=1:length(f)
      pars_out.(f{index}) = pars_isstruct.(f{index});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EMBEDDED FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%
% this way 'options' is available in here...

  function c = eval_criteria(model, p, criteria, a, varargin)

  % criteria to minimize
    if nargin<5, varargin={}; end
    % then get model value
    Model  = feval(model, p, a.Axes{:}, varargin{:}); % return model values

    % get actual parameters used during eval (in case of Constraints)
    p = model.ParameterValues;
    % send it back to input call
    Model  = iFunc_private_cleannaninf(Model);
    if isempty(Model)
      error([ 'iFunc:' mfilename ],[ 'The model ' model ' could not be evaluated (returned empty).' ]);
    end
    
    % compute criteria
    c = feval(criteria, a.Signal(:), a.Error(:), Model(:));
    % divide by the number of degrees of freedom
    % <http://en.wikipedia.org/wiki/Goodness_of_fit>
    if numel(a.Signal) > length(p)-1
      c = c/(numel(a.Signal) - length(p) - 1); % reduced 'Chi^2'
    end
    
    % overlay data and Model when in 'OutputFcn' mode
    if (isfield(options, 'OutputFcn') && ~isempty(options.OutputFcn) && ~isscalar(a.Signal) && ndims(a.Signal) <= 2)
      if ~isfield(options, 'updated')
        options.updated   = -clock;
        options.funcCount = 0;
      end
      
      options.funcCount = options.funcCount+1;
      
      if (options.funcCount < 50 && abs(etime(options.updated, clock)) > 0.5) ...
       || abs(etime(options.updated, clock)) > 2
        iFunc_private_fminplot(a,model,p,Model,options,c)
      end
    end
    
  end % eval_criteria (embedded)

end % fits

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRIVATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r=eval_corrcoef(Signal, Error, Model)
% correlation coefficient between the data and the model
  
  % compute the correlation coefficient
  if isempty(Error) || isscalar(Error) || all(Error(:) == Error(end))
    wt = 1;
  else
    wt = 1./Error;
    wt(find(~isfinite(wt))) = 0;
  end
  r = corrcoef(Signal.*wt,Model.*wt);
  r = r(1,2);                                     % correlation coefficient
  if isnan(r)
    r = corrcoef(Signal,Model);
    r = r(1,2);
  end
end % eval_corrcoef

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s=iFunc_private_cleannaninf(s)
% iFunc_private_cleannaninf: clean NaNs and Infs from a numerical field
%
  
  if isnumeric(s)
    S = s(:);
    if all(isfinite(S)), return; end
    index_ok     = find(isfinite(S));

    maxs = max(S(index_ok));
    mins = min(S(index_ok));

    S(isnan(S)) = 0;
    if ~isempty(mins)
      if mins<0, S(find(S == -Inf)) = mins*100;
      else       S(find(S == -Inf)) = mins/100; end
    end
    if ~isempty(maxs)
      if maxs>0, S(find(S == +Inf)) = maxs*100;
      else       S(find(S == +Inf)) = maxs/100; end
    end

    s = double(reshape(S, size(s)));
  end
end % iFunc_private_cleannaninf

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iFunc_private_fminplot(a,model,p,ModelValue,options,criteria)
% plot/update OutputFcn fitting monitoring window (used in eval_criteria)
  old_gcf = get(0, 'CurrentFigure');
  
  % is this window already opened ?
  h = findall(0, 'Tag', 'iFunc:fits');
  if isempty(h) % create it
    h = figure('Tag','iFunc:fits', 'Unit','pixels');
    tmp = get(h, 'Position'); tmp(3:4) = [500 400];
    set(h, 'Position', tmp);
    % add a Parameters button to display the current parameter values
    d = uicontrol(h, 'String','Param','Callback','helpdlg(get(gcbo, ''UserData''),''Current Parameters'');', ...
      'Tag','fits:param','ToolTip','Click here to show current parameters');
  end
  % raise existing figure (or keep it hidden)
  
  if old_gcf ~= h, set(0, 'CurrentFigure', h); end
  n1 = strtrim(a.Name);     if length(n1) > 40, n1 = [ n1(1:37) '...' ]; end
  n2 = strtrim(model.Name); if length(n2) > 40, n2 = [ n2(1:37) '...' ]; end

  if isvector(a.Signal)
    set(plot(a.Signal,'r-'),'DisplayName',n1);   hold on
    set(plot(ModelValue,'b--'),'DisplayName',n2); hold off
  else
    set(surf(a.Signal),'DisplayName',n1);  hold on; 
    set(surf(ModelValue),'DisplayName',n2); hold off
  end
  options.updated = clock;
  if length(p) > 20, p= p(1:20); end
  p = mat2str(p);
  if length(p) > 50, p = [ p(1:47) ' ...' ']' ]; end
  set(h, 'Name', [ mfilename ': ' options.algorithm ': ' n2 ' f=' sprintf('%g',sum(criteria(:))) ]);
  title({ [ mfilename ': ' options.algorithm ': ' n2 ' #' sprintf('%g',options.funcCount) ], ...
          a.Name, p });
  legend show
  set(h,'MenuBar','figure', 'ToolBar', 'figure');
  
  % store information for the 'Param' button
  d = findall(h, 'Tag', 'fits:param');
  if ~isempty(d)
    % store the list of non fixed parameters
    if ~isempty(model.Parameters)
      ud = { ...
        sprintf('Data:      %s', a.Name),...
        sprintf('Model:     %s', model.Name), ...
        sprintf('Algorithm: %s', options.algorithm), ...
        sprintf('Iteration: %i', options.funcCount), ...
        sprintf('Criteria:  %g', sum(criteria(:))) };
      for i=1:length(model.Parameters)
        if length(model.Constraint.fixed) >=i && ~model.Constraint.fixed(i)
          [name, R] = strtok(model.Parameters{i}); % make sure we only get the first word (not following comments)
          val  = [];
          if ~isempty(model.ParameterValues)
            try
              val = model.ParameterValues(i);
            end
          end
          if ~isempty(val) && isfinite(val)
            ud{end+1} = sprintf('%s = %g', name, val);
          end
        end
      end % for
      set(d, 'UserData', ud);
      set(d, 'ToolTip',  sprintf('%s\n', ud{:}));
    end
  end
  
  set(0, 'CurrentFigure', old_gcf);
  
end % iFunc_private_fminplot
