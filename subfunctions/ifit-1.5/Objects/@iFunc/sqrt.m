function a = sqrt(a)
% b = sqrt(s) : square root value of iFunc object
%
%   @iFunc/sqrt function to return the square root value of data sets
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=sqrt(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/sqrt, iFunc/power

a = iFunc_private_unary(a, 'sqrt');

