function a = log(a)
% b = log(s) : natural logarithm value of iFunc object
%
%   @iFunc/log function to return the natural logarithm value of data sets, ln(s)
%   Use log10 for the base 10 log.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=log(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/exp, iFunc/log, iFunc/log10, iFunc/sqrt

a = iFunc_private_unary(a, 'log');

