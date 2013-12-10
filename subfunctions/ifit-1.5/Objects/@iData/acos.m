function a = acos(a)
% b = acos(s) : computes the arc cosine of iData object
%
%   @iData/acos function to compute the inverse cosine of data sets (in radians).
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=acos(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'acos');

