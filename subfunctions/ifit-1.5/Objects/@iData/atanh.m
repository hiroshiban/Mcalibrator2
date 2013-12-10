function a = atanh(a)
% b = atanh(s) : computes the inverse hyperbolic tangent of iData object
%
%   @iData/atanh function to compute the inverse hyperbolic tangent of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=atanh(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'atanh');

