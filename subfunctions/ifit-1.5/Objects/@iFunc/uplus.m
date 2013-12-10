function a = uplus(a)
% b = uplus(s) : makes a copy of iFunc object
%
%   @iFunc/uplus function to return a duplicate of data sets.
%   b=+a creates a new iFunc object with same content as 'a', but different Tag/ID and Date.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=uplus(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/uminus, iFunc/abs, iFunc/real, iFunc/imag, iFunc/uplus

a = iFunc_private_unary(a, 'uplus');

