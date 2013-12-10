function c = corrcoef(a, b)
% c = corrcoef(a,b) : correlation coefficient with an iData object
%
%   @iData/corrcoef function to compute the correlation of an object with other data
%     http://en.wikipedia.org/wiki/Correlation_coefficient
%
% input:  a: iData or iFunc object, or numerical vector
%         b: iData or iFunc object, or numerical vector
% output: c: correlation coefficient between -1 and 1
% ex:     b=corrcoef(a); c=corrcoef(a, gauss);
%
% Version: $Revision: 1168 $
% See also corrcoef, iData, iData/mean, iData/fits

% either 'a' or 'b' is an iData
if nargin > 1 && isa(b, 'iData')
  tmp = a; a = b; b= tmp;
end

% handle input iData arrays
if numel(a) > 1
  c = cell(numel(a),1);
  parfor index=1:numel(a)
    c{index} = feval(mfilename, a(index), b);
  end
  c = reshape(s, size(a));
  return
end

% handle one input case: use axis and signal
if nargin == 1
  if ndims(a) > 1
    a = meshgrid(a);
  end
  b = getaxis(a, 0);
  a = getaxis(a, 0);
end

% handle input iFunc arrays
if isa(b, 'iFunc')
  b = feval(b, NaN, a);
end

% find intersection
if isa(a, 'iData') && isa(b, 'iData')
  [a,b] = intersect(a,b); % perform operation on intersection
end
% get the Signal of the two objects
if isa(b, 'iData')
  b = getaxis(b, 0);
end
if isa(a, 'iData')
  a = getaxis(a, 0);
end

if ~isnumeric(a) || ~isnumeric(b) || numel(a) ~= numel(b)
  c = [];
  return
end

index = find(isfinite(a) & isfinite(b));
c = corrcoef(a(index), b(index));

