function a = tan(a)
% b = tan(s) : computes the tangent of iFunc object
%
%   @iFunc/atan function to compute the tangent of data sets (using radians).
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=tan(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/cos, iFunc/acos, iFunc/sin, iFunc/asin, iFunc/tan, iFunc/atan

a = iFunc_private_unary(a, 'tan');

