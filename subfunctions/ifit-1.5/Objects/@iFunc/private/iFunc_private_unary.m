function b = iFunc_private_unary(a, op)
% iFunc_private_unary: handles unary operations
%
% Supported operations:
% abs acosh acos asinh asin atanh atan ceil conj cosh cos ctranspose del2 exp 
% find fliplr flipud floor full imag isfinite isfloat isinf isinteger islogical 
% isnan isnumeric isreal isscalar issparse log10 logical log norm not 
% real round sign single sinh sin sparse sqrt tanh tan transpose uminus uplus 
% single double find logical

% just modify the Name and the Expression

% handle input iFunc arrays
if numel(a) > 1
  b = [];
  for index=1:numel(a)
    this = iFunc_private_unary(a(index), op);
    b = [ b  this ];
  end
  b = reshape(b, size(a));
  return
end

ax = 'x,y,z,t,u,'; ax = ax(1:(a.Dimension*2));
if isa(a.Expression, 'function_handle')
  a.Expression = sprintf('signal = feval(%s, p, %s);', func2str(a.Expression), ax(1:(end-1)));
end

if ~isempty(a.Name)
   a.Name       = [ op '(' a.Name ')' ];
else
  u = a.Expression; u=strtrim(u); u(~isstrprop(u,'print'))='';
  u = strrep(u, ';', '');
  % remove any 'signal='
  [s,e] = regexp(u, '\<signal\>\s*=');
  for index=1:length(s)
   u = strrep(u, u(s(index):e(index)),'');
  end
  if length(u) > 20, u = [ u(1:17) '...' ]; end
  a.Name       = [ op '(' u ')' ];
end
a.Expression = [ a.Expression sprintf('\nsignal=%s(signal);', op) ];

b = copyobj(a);
