function a = sinh(a)
% b = sinh(s) : computes the hyperbolic sine of iFunc object
%
%   @iFunc/sinh function to compute the hyperbolic sine of data sets.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=sinh(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/cos, iFunc/acos, iFunc/sin, iFunc/asin, iFunc/tan, iFunc/atan

a = iFunc_private_unary(a, 'sinh');

