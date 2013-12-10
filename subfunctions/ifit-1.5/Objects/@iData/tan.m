function a = tan(a)
% b = tan(s) : computes the tangent of iData object
%
%   @iData/atan function to compute the tangent of data sets (using radians).
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=tan(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'tan');

