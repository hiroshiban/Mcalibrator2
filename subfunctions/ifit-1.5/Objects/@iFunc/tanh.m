function a = tanh(a)
% b = tanh(s) : computes the hyperbolic tangent of iFunc object
%
%   @iFunc/tanh function to compute the hyperbolic tangent of data sets.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=tanh(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/cos, iFunc/acos, iFunc/sin, iFunc/asin, iFunc/tan, iFunc/atan

a = iFunc_private_unary(a, 'tanh');

