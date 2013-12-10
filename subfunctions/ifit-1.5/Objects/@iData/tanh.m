function a = tanh(a)
% b = tanh(s) : computes the hyperbolic tangent of iData object
%
%   @iData/tanh function to compute the hyperbolic tangent of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=tanh(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'tanh');

