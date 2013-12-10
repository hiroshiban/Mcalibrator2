function a = cosh(a)
% b = cosh(s) : computes the hyperbolic cosine of iData object
%
%   @iData/cosh function to compute the hyperbolic cosine of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=cosh(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'cosh');

