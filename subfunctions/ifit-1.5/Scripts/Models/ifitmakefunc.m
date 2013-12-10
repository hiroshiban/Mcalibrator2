function f = ifitmakefunc(varargin)
% f = ifitmakefunc(fun, descr, pars, expr, guess, constraint) : build a fit function/model
%
%   iFit/ifitmakefunc fit function/model builder.
%     when only the first argument is specified as an expression (using p and x,y,z,t)
%       a model is built from the expression analysis.
%         ifitmakefunc(EXPR)
%     when only the first argument is specified as a structure, it should define fields
%       fun.Name:        the function name
%       fun.Description: the description of the function
%       fun.Parameters:  the parameter names as words separated with spaces
%       fun.Guess:       the default parameters, or 'automatic'
%       fun.Expression:  the expression of the function value
%       fun.Constraint:  the expression executed before the function evaluation
%     when input parameters are missing, a dialog pops-up to request the information
%       all arguments are optional (can be left empty), except the expression
%     when exactly 5 arguments are given, the dialogue does not show up, and a the 
%       model is retunred directly.
%     The list of all available function can be obtained with the 'fits(iFunc)' 
%
% WARNING: the 1D and 2D cases work fine, but higher dimensions (using z,t...) are NOT validated.
%
% input:  FUN:     function name or expression (single word or expression or structure or iFunc model)
%         DESCR:   description of the function (string)
%         PARS:    name of parameters, as a single string of words 'a b c ...'
%         EXPR:    expression of the function value, using 'p' vector as parameter values
%         GUESS:   default parameter values (guess, optional, leave empty for automatic guess)
%         CONSTRAINT: expression to execute before the function evaluation
%           which may contain any parameter constraints such as 'p(1)=p(5)'
%
% output: f: new model object
% 
% Version: $Revision: 1163 $
% See also iData, gauss, iFunc

f       = [];
NL      = sprintf('\n');

if nargin == 0
  constraint=''; 
  guess     = 'automatic'; 
  expr      = '@(p,x)p(1)*exp(- 0.5*((x-p(2))/p(3)).^2) + p(4)'; 
  pars      = 'Amplitude Centre HalfWidth Background'; 
  descr     = 'Gaussian function'; 
  name      = 'gauss'; 
else
  expr      = '';
  name      = '';
  descr     = '';
  pars      = '';
  guess     = '';
  constraint= '';
end 

% single input argument
if nargin == 1
  fun = varargin{1};
  if strcmp(fun, 'identify')
    return
  elseif ischar(fun)
    % special case when only the expression is given
    expr      = fun;
  elseif isa(fun,'function_handle')
    expr      = fun;
  elseif isa(fun, 'iFunc')
    fun       = struct(fun);
  end
  
  if isstruct(fun)
    if isfield(fun, 'Expression'),      expr =fun.Expression; end
    if isfield(fun, 'guess'),           guess=fun.guess;
    elseif isfield(fun, 'x0'),          guess=fun.x0;
    elseif isfield(fun, 'Guess'),       guess=fun.Guess; end
    if isfield(fun, 'pars'),            pars =fun.pars;
    elseif isfield(fun, 'Parameters'),  pars =fun.Parameters; end
    if isfield(fun, 'Name'),            name =fun.Name; end
    if isfield(fun, 'Description'),     descr=fun.Description; end
    if isfield(fun, 'Constraint'),      constraint=fun.Constraint; end
    if isfield(fun, 'function'),        name=fun.function; end
  end
else
  % multiple input argument
  if nargin >= 6,  constraint= varargin{6}; end
  if nargin >= 5,  guess     = varargin{5}; end
  if nargin >= 4,  expr      = varargin{4}; end
  if nargin >= 3   pars      = varargin{3}; end
  if nargin >= 2,  descr     = varargin{2}; end
  if nargin >= 1   fun       = varargin{1}; end
end

% test arguments
expr = char(expr); 
while ~isempty(strfind(expr,'  '))
  expr = strrep(expr,'  ',' ');
end
if isnumeric(guess), guess = mat2str(guess);
else                 guess = char(guess); end

constraint_org = [];
if ~isstruct(constraint)
  constraint=char(constraint);
elseif isfield(constraint, 'eval')
  constraint_org = constraint; constraint=[];
  constraint=constraint_org.eval;
end
if iscellstr(pars)
  p = '';
  for index=1:length(pars)
    p = [ p ' ' strtok(pars{index}) ];
  end
  pars = p;
end

if nargin < 5
  % request input dialog
  prompt    = { [ '{\bf Function name}' NL '(a single word, optional)' ], ...
                [ '{\bf Description of the fit model}' NL '(a character string, optional)' ], ...
                [ '{\bf Model parameter names}' NL '(single names separated by spaces, optional)' ], ...
                [ '{\bf Value of the function {\color{red} required}}' NL '(expression using parameters from vector {\color{blue} p(1), p(2)}, ... and axes {\color{blue} x, y, z, t}, ...), returning a "signal". It may be a function handle {\color{blue} @(p,x,y...)expression}.' ], ...
                [ '{\bf Default parameter values}' NL '(vector, expression, function handle {\color{blue} @(x,..signal)guess},  e.g [1 2 ...], leave empty for automatic guess)' ], ...
                [ '{\bf Constraint}' NL '(any expresion or function handle {\color{blue} @(p,x,...) constraint} executed before the function Value, returning a new set of parameters "p", optional)' ]};
  dlg_title = 'iFit: Make fit function';
  num_lines = [ 1 1 1 3 1 3]';
  defAns    = {name, descr, pars, expr, guess, constraint};
  options.Resize      = 'on';
  options.WindowStyle = 'normal';   
  options.Interpreter = 'tex';
  answer = inputdlg(prompt, dlg_title, num_lines, defAns, options);
  if isempty(answer), 
    return; 
  end
  % extract results
  name  = answer{1};
  descr = answer{2};
  pars  = answer{3};
  expr  = answer{4};
  guess = answer{5};
  constraint=answer{6};
end

% default function name
if isempty(name)
  name = clock;
  name = sprintf('fun_%i', fix(fun(6)*1e4));
end

% check expression, guess and constraint for function_handle
try
  if isa(eval(expr), 'function_handle')
    expr = eval(expr);
  end
end
try
  if isa(eval(constraint), 'function_handle')
    constraint = eval(constraint);
  end
end
try
  if isa(eval(guess), 'function_handle')
    guess = eval(guess);
  end
end
% default parameter names
if strncmp(guess, 'auto',4), guess = ''; end

% create a structure before we build the object
f.Name        = name;
f.Guess       = guess;
f.Expression  = expr;
f.Parameters  = pars;
if ~isempty(constraint_org)
  f.Constraint      = constraint_org;
  f.Constraint.eval = constraint;
else
  f.Constraint      = constraint;
end
f.Description = descr;

f = iFunc(f);

