function a = isnumeric(a)
% b = isnumeric(s) : True for numeric iData object elements
%
%   @iData/isnumeric function to return true for numeric elements
%   of 's', i.e. that are of type double, single, integer.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=isnumeric(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'isnumeric');
a = uint8(a);
