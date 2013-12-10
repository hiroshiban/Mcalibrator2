function a = round(a)
% b = round(s) : upper integer round of iFunc object
%
%   @iFunc/round function to round the elements of 's' to the nearest integers.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=round(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/floor, iFunc/ceil, iFunc/round

a = iFunc_private_unary(a, 'round');

