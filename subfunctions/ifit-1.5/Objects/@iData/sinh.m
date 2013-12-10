function a = sinh(a)
% b = sinh(s) : computes the hyperbolic sine of iData object
%
%   @iData/sinh function to compute the hyperbolic sine of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=sinh(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cos, iData/acos, iData/sin, iData/asin, iData/tan, iData/atan

a = iData_private_unary(a, 'sinh');

