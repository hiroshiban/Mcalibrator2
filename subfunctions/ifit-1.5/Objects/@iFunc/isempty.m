function y = isempty(s)
% isempty(s) : true for empty iFunc object
%
%   @iFunc/isempty true for empty iFunc object
%
% input:  s: object or array (iFunc)
% output: false(0) or true(1) whether Signal is empty in the objects
% ex :    isempty(iFunc)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/disp, iFunc/get

if numel(s) > 1
  y = zeros(size(s));
elseif ~numel(s), y=1; return;
end
for index = 1:numel(s)
  t = s(index);
  if t.Dimension == 0 && isempty(t.Parameters), empty = 1;
  else                                          empty = 0; end
  y(index) = empty;
end

y=uint8(y);



