function a = log(a)
% b = log(s) : natural logarithm value of iData object
%
%   @iData/log function to return the natural logarithm value of data sets, ln(s)
%   Use log10 for the base 10 log.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=log(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/exp, iData/log, iData/log10, iData/sqrt

a = iData_private_unary(a, 'log');

