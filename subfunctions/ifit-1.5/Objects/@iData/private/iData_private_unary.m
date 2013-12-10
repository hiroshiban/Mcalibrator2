function b = iData_private_unary(a, op, varargin)
% iData_private_unary: handles unary operations
%
% Supported operations:
% abs acosh acos asinh asin atanh atan ceil conj cosh cos ctranspose del2 exp 
% fliplr flipud floor full imag isfinite isfloat isinf isinteger islogical 
% isnan isnumeric isreal isscalar issparse log10 log norm not permute 
% real reshape resize round sign sinh sin sparse sqrt tanh tan transpose uminus uplus 
%
% present but not used here: 'double','single','logical','find'

% handle input iData arrays
if numel(a) > 1
  b = [];
  for index=1:numel(a)
    this = iData_private_unary(a(index), op);
    if (isnumeric(this)||islogical(this)) && ~isa(this, 'iData') && ~isscalar(this), 
      if isempty(b), b={}; end 
      this = { this };
    end
    b = [ b this ];
  end
  b = reshape(b, size(a));
  return
end

iData_private_warning('enter',[ mfilename ' ' op ]);

cmd=a.Command;
b = copyobj(a);

% get Signal Error and Monitor
s = subsref(b,struct('type','.','subs','Signal'));
[dummy, sl] = getaxis(b, '0');  % signal definition/label
e = subsref(b,struct('type','.','subs','Error'));
m = subsref(b,struct('type','.','subs','Monitor'));

% make sure sparse is done with 'double' type
if strcmp(op, 'sparse')
  if ndims(a) > 2
    iData_private_error('unary',['Operation ' op ' can only be used on 2d data sets. Object ' a.Tag ' is ' num2str(ndims(a)) 'd.' ]);
  end
  if ~strcmp(class(s), 'double') && ~strcmp(class(s), 'logical')
    s = double(s);
  end
  if ~strcmp(class(e), 'double') && ~strcmp(class(e), 'logical')
    e = double(e);
  end
  if ~strcmp(class(m), 'double') && ~strcmp(class(m), 'logical')
    m = double(m);
  end
end

% non-linear operators should perform on the Signal/Monitor
% and then multiply again by the Monitor

% operate with Signal/Monitor and Error/Monitor
if ~isempty(find(strcmp(op, {'norm','asin', 'acos','atan','cos','sin','exp','log',...
 'log10','sqrt','tan','asinh','atanh','acosh','sinh','cosh','tanh'}))) ...
   && not(all(m(:) == 0 | m(:) == 1))
  s = genop(@rdivide, s, m);
  e = genop(@rdivide, e, m);
end

% new Signal value is set HERE <================================================
if ~isfloat(s), s=double(s); end
if length(varargin)
  new_s = feval(op, s, varargin{:});
else
  new_s = feval(op, s);
end

switch op
case 'acos'
	e = -e./sqrt(1-s.*s);
case 'acosh'
  e = e./sqrt(s.*s-1);
case 'asin'
	e = e./sqrt(1-s.*s);
case 'asinh'
  e = e./sqrt(1+s.*s);
case 'atan'
	e = e./(1+s.*s);
case 'atanh'
  e = e./(1-s.*s);
case 'cos'
	e = -e.*sin(s);
case 'cosh'
  e = e.*sinh(s);
case 'exp'
	e = e.*exp(s);
case 'log'
	e = e./s;
case 'log10'
	e = e./(log(10)*s);
case 'sin'
	e = e.*cos(s);
case 'sinh'
  e = e.*cosh(s);
case 'sqrt'
	e = e./(2*sqrt(s));
  m = m.^0.5;
case 'tan'
	c = cos(s);
	e = e./(c.*c);
case 'tanh'
  c = cosh(s);
  e = e./(c.*c);
case { 'transpose', 'ctranspose'}; % .' and ' respectively
	e = feval(op, e);
	m = feval(op, m);
	if ndims(b) > 1
  	x1 = getaxis(b, '1'); % axis names
  	x2 = getaxis(b, '2');
  	v1 = getaxis(b, 1);   % axis values
  	v2 = getaxis(b, 2);
  	if ~isempty(x2), b= setaxis(b, 1, x2, transpose(v2)); end
  	if ~isempty(x1), b= setaxis(b, 2, x1, transpose(v1)); end
  end
case {'sparse','full','flipud','fliplr'}
  % apply same operator on error and Monitor
	e = feval(op, e);
	m = feval(op, m);
case {'floor','ceil','round'}	
	% apply same operator on error
	e = feval(op, e);
case 'del2'
  new_s = new_s*2*ndims(a);
  e = 2*ndims(a)*del2(e);
case {'sign','isfinite','isnan','isinf'}
	b = new_s;
	iData_private_warning('exit',mfilename);
	return
case {'isscalar','isvector','issparse','isreal','isfloat','isnumeric','isinteger', ...
      'islogical','double','single','logical','find','norm'}
	% result is a single value
	b = new_s;
	iData_private_warning('exit',mfilename);
	return
case {'uminus','abs','real','imag','uplus','not','conj'}
	% retain error, do nothing
case {'permute','reshape','iData_private_resize'}
  if ~isscalar(e) && ~isempty(e),  e = feval(op, e, varargin{:}); end
  if ~isscalar(m) && ~isempty(m),  m = feval(op, m, varargin{:}); end
otherwise
  iData_private_error('unary',['Can not apply operation ' op ' on object ' a.Tag ]);
end

% operate with Signal/Monitor and Error/Monitor (back to Monitor data)
if ~isempty(find(strcmp(op, {'norm','asin', 'acos','atan','cos','sin','exp','log',...
 'log10','sqrt','tan','asinh','atanh','acosh','sinh','cosh','tanh'}))) ...
   && not(all(m(:) == 0 | m(:) == 1))
  new_s = genop(@times, new_s, m);
  e     = genop(@times, e, m);
end

% update object
e = abs(e);
b = set(b, 'Signal', new_s, 'Error', e, 'Monitor', m);
% test if we could update signal as expected, else we store the new value directly in the field
if ~isequal(subsref(b,struct('type','.','subs','Signal')), new_s)
  b = setalias(b, 'Signal', new_s, [  op '(' sl ')' ]);
end
if ~isequal(subsref(b,struct('type','.','subs','Error')), e)
  b = setalias(b, 'Error', e);
end
if ~isequal(subsref(b,struct('type','.','subs','Monitor')), m)
  b = setalias(b, 'Monitor', m);
end
b.Command=cmd;
b = iData_private_history(b, op, a);  

iData_private_warning('exit',mfilename);

