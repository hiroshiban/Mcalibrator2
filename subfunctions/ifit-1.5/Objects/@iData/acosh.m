function a = acosh(a)
% b = acosh(s) : computes the inverse hyperbolic cosine of iData object
%
%   @iData/acosh function to compute the inverse hyperbolic cosine of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=acosh(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'acosh');

