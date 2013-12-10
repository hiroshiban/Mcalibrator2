function a = asin(a)
% b = asin(s) : computes the arc sine of iData object
%
%   @iData/acos function to compute the inverse sine of data sets (in radians).
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=asin(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'asin');

