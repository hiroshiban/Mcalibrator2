function a = asin(a)
% b = asin(s) : computes the arc sine of iFunc object
%
%   @iFunc/acos function to compute the inverse sine of data sets (in radians).
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=asin(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/cos, iFunc/acos, iFunc/sin, iFunc/asin, iFunc/tan, iFunc/atan

a = iFunc_private_unary(a, 'asin');

