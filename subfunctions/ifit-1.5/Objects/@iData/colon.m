function c = colon(a,d,b)
% b = colon(s) : vector of arrays
%
%   @iData/colon create a vector of objects by varying their mean value,
%     using linspace with a number of steps corresponding to the mean value range.
%
% input:  s: object (iData)
% output: b: object (iData)
% ex:     c=a:b; c=a:2:b;
%
% Version: $Revision: 1035 $
% See also iData, iData/floor, iData/ceil, iData/round, iData/combine

if nargin == 1
  b = []; d=0;
elseif nargin == 2
  b = d;
  d = 0;
end
if isempty(b)
  b=a;
end
if numel(a) > 1, a=a(1); end
if numel(b) > 1, b=b(end); end
if isempty(d), d=0; end

if isa(a, 'iData'), as = getaxis(a(1),0); as = as(:); else as = a; end
if isa(b, 'iData'), bs = getaxis(b(1),0); bs = bs(:); else bs = b; end

as = floor(mean(as));
bs = ceil(mean(bs));
if d    , n = abs((bs-as)/d);
else      n = abs(bs-as); end

if n <= 1, c = a; return; end
if n < 0,  c = a; return; end

c = linspace(a,b,n);

