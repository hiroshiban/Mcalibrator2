function a = asinh(a)
% b = asinh(s) : computes the inverse hyperbolic sine of iData object
%
%   @iData/asinh function to compute the inverse hyperbolic sine of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=asinh(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'asinh');

