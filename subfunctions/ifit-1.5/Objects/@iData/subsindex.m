function y = subsindex(s)
% d = subsindex(s) : subscript index for iData objects
%
%   @iData/subsindex: subscript index for iData objects
%   I = subsindex(S) is called for the syntax 'X(S)' to use S as an index.
%   The returned index is the convertion of S to integer.
%
% Version: $Revision: 1057 $
% See also iData, iData/subsasgn, iData/subsref

% EF 23/09/07 iData implementation

if numel(s) > 1
   s = s(1);
end

y = int32(get(s,'Signal'));
u = unique(y);
if length(u) <= 2 && all(u == 0 | u == 1)
  % signal is logical already
  y = find(y);
end
y=y-1;