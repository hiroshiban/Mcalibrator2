function a = acos(a)
% b = cos(s) : computes the cosine of iData object
%
%   @iData/cos function to compute the cosine of data sets (using radians).
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=cos(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'cos');

