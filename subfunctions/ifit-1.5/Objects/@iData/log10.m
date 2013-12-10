function a = log10(a)
% b = log10(s) : base 10 logarithm value of iData object
%
%   @iData/log10 function to return the base 10 logarithm value of data sets
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=log10(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/exp, iData/log, iData/log10, iData/sqrt

a = iData_private_unary(a, 'log10');

