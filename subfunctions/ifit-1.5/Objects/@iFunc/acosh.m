function a = acosh(a)
% b = acosh(s) : computes the inverse hyperbolic cosine of iFunc object
%
%   @iFunc/acosh function to compute the inverse hyperbolic cosine of data sets.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=acosh(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/cos, iFunc/acos, iFunc/sin, iFunc/asin, iFunc/tan, iFunc/atan

a = iFunc_private_unary(a, 'acosh');

