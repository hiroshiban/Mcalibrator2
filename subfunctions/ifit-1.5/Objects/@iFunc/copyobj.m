function a = copyobj(a)
% b = copyobj(s) : makes a copy of iFunc object
%
%   @iFunc/copyobj function to return a duplicate of data sets.
%   creates a new iFunc object with same content as 'a', but different Tag/ID and Date.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=copyobj(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/uplus, iFunc/findobj

% handle input iFunc arrays
if numel(a) > 1
  b = [];
  for index=1:numel(a)
    b = [ b copyobj(a(index)) ];
  end
  a = reshape(b, size(a));
  return
end

t     = iFunc;
a.Tag = t.Tag;

