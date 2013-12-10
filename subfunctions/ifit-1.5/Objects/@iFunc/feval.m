function [signal, ax, name] = feval(model, p, varargin)
% [signal, axes] = feval(model, parameters, x,y, ...) evaluate a function
%
%   @iFunc/feval applies the function 'model' using the specified parameters and axes
%     and function parameters 'pars' with optional additional parameters.
%
%   parameters = feval(model, 'guess', x,y, ..., signal...)
%     makes a quick parameter guess. This usually requires to specify the signal
%     to guess from to be passed after the axes.
%   signal = feval(model, NaN, x,y, ..., signal...)
%     same as above, but force to get the evaluated function value with
%     guessed parameters.
%   signal = feval(model, [ ... Nan ... ], x,y, ..., signal...)
%     requires some of the initial parameters to be given, others as NaN's. These
%     values are then replaced by guessed ones, and the model value is returned.
%   signal = feval(model, parameters, x,y, ...)
%     evaluates the model with given parameters and axes
%
% input:  model: model function (iFunc, single or array)
%         parameters: model parameters (vector, cell or vectors, structure, iData) or 'guess'
%         x,y,..:  axes values to be used for the computation (vector,matrix)
%         ...: additional parameters may be passed, which are then forwarded to the model
% output: signal: result of the evaluation (vector/matrix/cell) or guessed parameters (vector)
%         axes:   returns the axes used for evaluation (cell of vector/matrix)
%
% ex:     b=feval(gauss,[1 2 3 4]); feval(gauss*lorz, [1 2 3 4, 5 6 7 8]);
%           feval(gauss,'guess', -5:5, -abs(-5:5))
%
% Version: $Revision: 1164 $
% See also iFunc, iFunc/fit, iFunc/plot

% handle input iFunc arrays

if isa(model, 'iFunc') && numel(model) > 1
  signal = {}; ax={}; name={};
  for index=1:numel(model)
    [signal{end+1}, ax{end+1}, name{end+1}] = feval(model(index), p, varargin{:});
  end
  if numel(signal) == 1, 
    signal=signal{1}; ax=ax{1};
  end
  signal = reshape(signal, size(model));
  ax     = reshape(ax,     size(model));
  name   = reshape(name,   size(model));
  return
end

% handle input parameter 'p' ===================================================

if nargin < 2
  p = [];
end

if ischar(model) && isa(p, 'iFunc')
  % call to an iFunc method
  signal = builtin('feval', model, p, varargin{:});
  return
end

if isa(p, 'iData')
  varargin = { p varargin{:} }; % will evaluate on iData axes with guesses pars
  p = NaN;
end

if iscell(p) && ~isempty(p) % as model cell (iterative function evaluation)
  signal = {}; ax={}; name={};
  for index=1:numel(model)
    [signal{end+1}, ax{end+1}, name{end+1}] = feval(model, p{index}, varargin{:});
  end
  if numel(signal) == 1, 
    signal=signal{1}; ax=ax{1}; name=name{1};
  end
  return
end

% convert a structure of parameters into an array matching model parameter
% names.
if isstruct(p)
  new = [];
  for index=1:length(model.Parameters)
    if isfield(p, model.Parameters{index})
      new = [ new p.(model.Parameters{index}) ];
    end
  end
  if length(new) == length(model.Parameters)
    p = new;
  else
    error([ 'iFunc:' mfilename ], 'Fields of the parameters "p" given as a structure do not match the model Parameters.');
  end
end

% some usual commands 
if ~isempty(p) && ischar(p)
  if strcmp(p, 'plot')
    signal=plot(model);
    return
  elseif strcmp(p, 'identify')
    signal=model;
    return
  elseif ~strcmp(p, 'guess')
    disp([ mfilename ': Unknown parameter value ' p '. Using "guess" instead.'])
    p=[];
  end
elseif ~isvector(p) && ~isempty(p)
  error([ 'iFunc:' mfilename ], [ 'Starting parameters "p" should be given as a vector, structure, character or empty, not ' class(p) ]);
end

% handle varargin ==============================================================
% handle case where varargin contains itself model cell as 1st arg for axes and
% Signal

signal_in_varargin = []; % holds the index of a Signal after Axes in varargin
if ~isempty(varargin) 
  this = varargin{1};
  if iscell(this)
    Axes = this;
    if length(Axes) > model.Dimension
      Signal = Axes{model.Dimension+1};
      Axes   = Axes(1:model.Dimension);
    end
    if ~isempty(Signal), 
      Axes{end+1} = Signal; 
      signal_in_varargin = length(Axes);
    end
    varargin=[ Axes{:} varargin(2:end) ];
  elseif (isstruct(this) && isfield(this, 'Axes')) || isa(this, 'iData')
    Signal = {};
    if isfield(this,'Signal')  
      Signal  = this.Signal;
      if isfield(this,'Monitor') 
        Signal  = bsxfun(@rdivide,Signal, this.Monitor); 
      end
    end

    if isa(this, 'iData')
      Axes=cell(1,ndims(this));
      for index=1:ndims(this)
        Axes{index} = getaxis(this, index);
      end
    elseif isfield(this,'Axes')    Axes    = this.Axes; 
    end
    if ~isempty(Signal), 
      Axes{end+1} = Signal; 
      signal_in_varargin = length(Axes);
    end
    varargin= [ Axes{:} varargin(2:end) ];
  end
  clear this Axes Signal
end

ax=[]; name=model.Name;
guessed = '';
% guess parameters ========================================================

% some ParameterValues have been defined already. Use them.
if isempty(p) && length(model.ParameterValues) == numel(model.Parameters)
  p = model.ParameterValues;
end
% when length(p) < Parameters, we fill NaN's ; when p=[] we guess them all
if strcmp(p, 'guess') || isempty(p)
  p = NaN*ones(1, numel(model.Parameters));
  guessed = 'full';
elseif isnumeric(p) && length(p) < length(model.Parameters) % fill NaN's from p+1 to model.Parameters
  p((length(p)+1):length(model.Parameters)) = NaN;
end

% when there are NaN values in parameter values, we replace them by guessed values
if (any(isnan(p)) && length(p) == length(model.Parameters)) || ~isempty(guessed)
  % call private method to guess parameters from axes, signal and parameter names
  if isempty(guessed), guessed = 'partial'; end
  
  % args={x,y,z, ... signal}
  args=cell(1,model.Dimension+1); args(1:end) = { [] };
  args(1:min(length(varargin),model.Dimension+1)) = varargin(1:min(length(varargin),model.Dimension+1));
  args_opt = varargin((model.Dimension+2):end);
  
  p0 = p; % save initial 'p' values
  
  % all args are empty, we generate model fake 1D/2D axes/signal
  if model.Dimension <= 2 && all(cellfun('isempty',args))
    if model.Dimension == 1
      args{1} = linspace(-5,5,50); 
      x=args{1}; p2 = [1 mean(x) std(x)/2 .1]; 
      args{2} = p2(1)*exp(-0.5*((x-p2(2))/p2(3)).^2)+((p2(2)-x)*p2(1)/p2(3)/100) + p2(4);
      clear p2
      signal = args{2};
      signal_in_varargin = 2;
    else
      [args{1},args{2}] = ndgrid(linspace(-5,5,50), linspace(-3,7,60));
      x=args{1}; y=args{2}; p2 = [ 1 mean(x(:)) mean(y(:)) std(x(:)) std(y(:)) 30 0 ];
      x0=p2(2); y0=p2(3); sx=p2(4); sy=p2(5);
      theta = p2(6)*pi/180;  % deg -> rad
      aa = cos(theta)^2/2/sx/sx + sin(theta)^2/2/sy/sy;
      bb =-sin(2*theta)/4/sx/sx + sin(2*theta)/4/sy/sy;
      cc = sin(theta)^2/2/sx/sx + cos(theta)^2/2/sy/sy;
      args{3} = p2(1)*exp(-(aa*(x-x0).^2+2*bb*(x-x0).*(y-y0)+cc*(y-y0).^2)) + p2(7);
      clear aa bb cc theta x0 y0 sx sy p2
      signal = args{3};
      signal_in_varargin = 3;
    end
  end
  
  varargin = [ args args_opt ];
  clear args
  
  % convert axes to nD arrays for operations to take place
  % check the axes and possibly use ndgrid to allow nD operations in the
  % Expression/Constraint
  if model.Dimension > 1 && all(cellfun(@isvector, varargin(1:model.Dimension)))
    [varargin{1:model.Dimension}] = ndgrid(varargin{1:model.Dimension});
  end

  % automatic guessed parameter values -> signal
  p1 = iFunc_private_guess(varargin(1:(model.Dimension+1)), model.Parameters); % call private here -> auto guess

  % check for NaN guessed values and null amplitude
  n=find(isnan(p1) | p1 == 0); n=transpose(n(:));
  for j=n
    if any([strfind(lower(model.Parameters{j}), 'width') ...
       strfind(lower(model.Parameters{j}), 'amplitude') ...
       strfind(lower(model.Parameters{j}), 'intensity')])
      p1(j) = abs(randn)/10;
    else
      p1(j) = 0;
    end
  end
  % specific guessed values (if any) -> p2 override p1
  if ~isempty(model.Guess) && ~all(cellfun('isempty',varargin))
    if isa(model.Guess, 'function_handle')
      n = nargin(model.Guess);                % number of required arguments
      try
        % moments of distributions
        m1 = @(x,s) sum(s(:).*x(:))/sum(s(:));
        m2 = @(x,s) sqrt(abs( sum(x(:).*x(:).*s(:))/sum(s(:)) - m1(x,s).^2 ));
        
        if n > 0 && length(varargin) >= n
          p2 = feval(model.Guess, varargin{1:n}); % returns model vector
        else
          p2 = feval(model.Guess, varargin{:}); % returns model vector
        end
      catch
        p2 = [];
      end
      clear n
    elseif isnumeric(model.Guess)
      p2 = model.Guess;
    else
      % request char eval guess in sandbox
      p2 = iFunc_feval_guess(model, varargin{:});
      p  = p0;             % restore initial value
    end
    if isempty(p2)
      disp([ mfilename ': Warning: Could not evaluate Guess in model ' model.Name ' ' model.Tag ]);
      disp(model.Guess);
      disp('Axes and signal:');
      disp(varargin);
      warning('Using auto-guess values.');
    else
      % merge auto and possibly manually set values
      index     = ~isnan(p2);
      p1(index) = p2(index);
      clear p2
    end
  end
  if all(p1 == 0) && ~isempty(model.ParameterValues) ...
   && ~all(model.ParameterValues == 0)
    p1 = model.ParameterValues;
  end
  signal = p1;  % auto-guess overridden by 'Guess' definition
  % transfer the guessed values from 'signal' to the NaN ones in 'p'
  if any(isnan(p)) && ~isempty(signal)
    index = find(isnan(p)); p(index) = signal(index);
  end
  model.ParameterValues = p; % the guessed values
  
  if ~strcmp(guessed,'full')
    % return the signal and axes
    if ~isempty(signal_in_varargin) && length(varargin) >= signal_in_varargin
      varargin(signal_in_varargin) = []; % remove Signal from arguments for evaluation (used in Guess)
      signal_in_varargin = [];
    end

    [signal, ax, name] = feval(model, p, varargin{:});
  else
    ax=0; name=model.Name;
  end
  % Parameters are stored in the updated model (see assignin below)

end % 'guess'

% format parameters as columns
p = p(:);
model.Constraint.min  =model.Constraint.min(:);
model.Constraint.max  =model.Constraint.max(:);
model.Constraint.fixed=model.Constraint.fixed(:);
model.Constraint.set  =model.Constraint.set(:);

% apply constraints (fixed are handled in 'fits' -> forwarded to the optimizer)
i = find(isfinite(model.Constraint.min));
if ~isempty(i)
  p(i) = max(p(i), model.Constraint.min(i));
end
i = find(isfinite(model.Constraint.max));
if ~isempty(i)
  p(i) = min(p(i), model.Constraint.max(i));
end

% apply 'set' Constraints (with char)
p = iFunc_feval_set(model, p, varargin);

model.ParameterValues = p;

if ~isempty(inputname(1))
  assignin('caller',inputname(1),model); % update in original object
end

% return here with syntax:
% feval(model) when model.ParameterValues is empty
% feval(model, 'guess')
if ~isempty(guessed)
  return
end

% guess axes ==============================================================
% complement axes if too few are given
if length(varargin) < model.Dimension
  % not enough axes, but some may be given: we set them to 'empty' so that default axes are used further
  for index=(length(varargin)+1):model.Dimension
    varargin{index} = [];
  end
end

% default return value...
signal          = [];
parameter_names = lower(model.Parameters);
AxisOrientation = ''; ParallelAxes=1;
% check axes and define missing ones
for index=1:model.Dimension
  % check for default axes to represent the model when parameters are given
  % test parameter names
  
  width    = NaN;
  position = NaN;
  for index_p=1:length(parameter_names)
    if  ~isempty(strfind(parameter_names{index_p}, 'width')) ...
      | ~isempty(strfind(parameter_names{index_p}, 'tau')) ...
      | ~isempty(strfind(parameter_names{index_p}, 'damping'))
      if isnan(width)
        width = abs(p(index_p)); 
        % this parameter name is removed from the search for the further axes
        parameter_names{index_p} = ''; 
      end
    elseif ~isempty(strfind(parameter_names{index_p}, 'centre')) ...
      |    ~isempty(strfind(parameter_names{index_p}, 'center')) ...
      |    ~isempty(strfind(parameter_names{index_p}, 'position'))
      if isnan(position), 
        position = p(index_p);
        % this parameter name is removed from the search for the further axes
        parameter_names{index_p} = '';
      end
    end
    if ~isnan(width) && ~isnan(position)
      if isempty(varargin{index}) || all(all(isnan(varargin{index})))
		    % axis is not set: use default axis from parameter names and values given
		    varargin{index} = linspace(position-3*width,position+3*width, 50+index);
		    % orient the axis along the right dimension to indicate this is not an event type
        d = ones(1,max(2,model.Dimension)); d(index) = numel(varargin{index});
        varargin{index} = reshape(varargin{index}, d);
		width = NaN; position = NaN;
		break; % go to next axis (exit index_p loop)
      end
    end
  end % for index in parameter names
  if isempty(varargin{index})
    varargin{index} = linspace(-5,5,50+index);
    % orient the axis along the right dimension to indicate this is not an event type
    d = ones(1,max(2,model.Dimension)); d(index) = numel(varargin{index});
    varargin{index} = reshape(varargin{index}, d);
  end
  % check if axes are vectors of same length and orientation (event type model)
  if isempty(AxisOrientation), AxisOrientation=size(varargin{index});
  elseif length(AxisOrientation) == length(size(varargin{index})) ...
          && any(AxisOrientation ~= size(varargin{index})), ParallelAxes=0; end
end % for index in model dim

% convert axes to nD arrays for operations to take place
% check the axes and possibly use ndgrid to allow nD operations in the
% Expression/Constraint. Only for non event style axes.
if model.Dimension > 1 && all(cellfun(@isvector, varargin(1:model.Dimension))) && ~ParallelAxes
  [varargin{1:model.Dimension}] = ndgrid(varargin{1:model.Dimension});
end

% evaluate expression ==========================================================

% Eval contains both the Constraint and the Expression
% in case the evaluation is empty, we compute it (this should better have been done before)
if isempty(model.Eval) 
  model.Eval=cellstr(model);
  if ~isempty(inputname(1))
    assignin('caller',inputname(1),model);
  end
end

% make sure we have enough parameter values wrt parameter names, else
% append 0's
if length(p) < length(model.Parameters)
  p = transpose([ p(:) ; zeros(length(model.Parameters) - length(p), 1) ]);
end

model.ParameterValues = p; % store current set of parameters

% request evaluation in sandbox, but should remove Signal after axes
if ~isempty(signal_in_varargin) && length(varargin) >= signal_in_varargin
  varargin(signal_in_varargin) = []; % remove Signal from arguments for evaluation (used in Guess)
  signal_in_varargin = [];
end
[signal,ax,p] = iFunc_feval_expr(model, varargin{:});

% model.ParameterValues = p; % store current set of parameters (updated)

p    = sprintf('%g ', p(:)'); if length(p) > 20, p=[ p(1:20) '...' ]; end
name = [ model.Name '(' p ') ' ];

% ==============================================================================
function [signal,iFunc_ax,p] = iFunc_feval_expr(model, varargin)
% private function to evaluate an expression in a reduced environment so that 
% internal function variables do not affect the result.

signal = [];
% assign parameters and axes for the evaluation of the expression, in case this is model char
% p already exists, we assign axes, re-assign varargin if needed
iFunc_ax = 'x y z t u ';
if model.Dimension
  eval([ '[' iFunc_ax(1:(2*model.Dimension)) ']=deal(varargin{' mat2str(1:model.Dimension) '});' ]);
end

if nargout > 1
  iFunc_ax = varargin(1:model.Dimension);
else
  iFunc_ax = [];
end
clear index

% remove axes from varargin -> leaves additional optional arguments to the function
varargin(1:model.Dimension) = []; 

% EVALUATE now ...
% in the evaluation:
% * x,y,z,...        hold the axes
% * p                holds the numerical values of the parameters (row)
% * struct_p         holds the parameters as a structure (inactivated for now)
% * model.Parameters holds the names of these parameters
% 

p       = reshape(model.ParameterValues,1,numel(model.ParameterValues));
% if we wish to have parameters usable as a structure
%struct_p= cell2struct(num2cell(p),model.Parameters,2);

try
  model.Eval = cellstr(model.Eval);
  model.Eval = model.Eval(~strncmp('%', model.Eval, 1)); % remove comment lines
  eval(sprintf('%s\n', model.Eval{:}));
catch
  disp([ 'Error: Could not evaluate Expression in model ' model.Name ' ' model.Tag ]);
  disp(model)
  model.Eval
  lasterr
  error([ 'iFunc:' mfilename ], 'Failed model evaluation.');
end

% ==============================================================================
function p = iFunc_feval_guess(model, varargin)
% private function to evaluate a guess in a reduced environment so that 
% internal function variables do not affect the result. 
% Guess=char as fhandle are handled directly in the core function
  ax = 'x y z t u ';
  p  = [];
  if model.Dimension
    eval([ '[' ax(1:(2*model.Dimension)) ']=deal(varargin{' mat2str(1:model.Dimension) '});' ]);
  end
  if length(varargin) > model.Dimension && ~isempty(varargin{model.Dimension+1}) && isnumeric(varargin{model.Dimension+1})
    signal = varargin{model.Dimension+1};
  else
    signal = 1;
  end
  clear ax
  % moments of distributions (used in some Guesses, e.g. gauss, lorz, ...)
  m1 = @(x,s) sum(s(:).*x(:))/sum(s(:));
  m2 = @(x,s) sqrt(abs( sum(x(:).*x(:).*s(:))/sum(s(:)) - m1(x,s).^2 ));
  try
    p = eval(model.Guess);     % returns model vector
  end
  if isempty(p)
    try
      eval(model.Guess);       % returns model vector and redefines 'p'
    catch
      p = [];
    end
  end

% ==============================================================================
function p = iFunc_feval_set(model, p, varargin)
% private function to evaluate a parameter set expression in a reduced environment so that 
% internal function variables do not affect the result.

  i = find(~cellfun('isempty', model.Constraint.set)); i=i(:)';
  if ~isempty(i)

    ax = 'x y z t u ';
    if model.Dimension
      eval([ '[' ax(1:(2*model.Dimension)) ']=deal(varargin{' mat2str(1:model.Dimension) '});' ]);
    end
    if length(varargin) > model.Dimension && ~isempty(varargin{model.Dimension+1}) && isnumeric(varargin{model.Dimension+1})
      signal = varargin{model.Dimension+1};
    else
      signal = 1;
    end
    clear ax

    for index=i
      try
        if isa(model.Constraint.set{index}, 'function_handle') && ...
           nargout(model.Constraint.set{index}) == 1
          n = nargin(model.Constraint.set{index});
          if n > 0 && length(varargin) >= n
            p(index) = feval(model.Constraint.set{index}, p, varargin{1:n});
          else
            p(index) = feval(model.Constraint.set{index}, p, varargin);
          end
        elseif ischar(model.Constraint.set{index})
          p(index) = eval(model.Constraint.set{index});
        end
      catch
        warning([ 'iFunc:' mfilename ], 'Could not evaluate model.Constraint.set on p(%i):', index);
        disp(model.Constraint.set{index})
      end % try
      
    end
  end

