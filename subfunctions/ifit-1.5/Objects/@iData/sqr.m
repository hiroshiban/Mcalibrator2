function c = sqr(a)
% c = sqr(a) : computes the square of iData objects
%
%   @iData/sqr function to compute the square of data sets
%
% input:  a: object or array (iData)
% output: c: object or array (iData)
% ex:     c=sqr(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/times, iData/power

c = iData_private_binary(a, 2, 'power');

