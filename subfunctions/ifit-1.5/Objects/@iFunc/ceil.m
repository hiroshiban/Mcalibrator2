function a = ceil(a)
% b = ceil(s) : upper integer round of iFunc object
%
%   @iFunc/ceil function to round the elements of 's' to the nearest integers
%   towards plus infinity.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=ceil(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/floor, iFunc/ceil, iFunc/round

a = iFunc_private_unary(a, 'ceil');

