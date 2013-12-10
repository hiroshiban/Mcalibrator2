function a = floor(a)
% b = floor(s) : lower integer round of iFunc object
%
%   @iFunc/floor function to round the elements of 's' to the nearest integers
%   towards minus infinity.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=floor(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/floor, iFunc/ceil, iFunc/round

a = iFunc_private_unary(a, 'floor');

