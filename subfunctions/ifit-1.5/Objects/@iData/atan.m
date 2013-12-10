function a = atan(a)
% b = atan(s) : computes the arc tangent of iData object
%
%   @iData/atan function to compute the inverse tangent of data sets (in radians).
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=atan(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'atan');

