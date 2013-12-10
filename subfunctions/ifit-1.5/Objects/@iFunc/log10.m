function a = log10(a)
% b = log10(s) : base 10 logarithm value of iFunc object
%
%   @iFunc/log10 function to return the base 10 logarithm value of data sets
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=log10(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/exp, iFunc/log, iFunc/log10, iFunc/sqrt

a = iFunc_private_unary(a, 'log10');

