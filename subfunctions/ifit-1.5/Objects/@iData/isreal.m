function a = isreal(a)
% b = isreal(s) : True for real iData object elements
%
%   @iData/isreal function to return true for real elements
%   of 's', i.e. that are not complex.
%
% input:  s: object or array (iData)
% output: b: array (int)
% ex:     b=isreal(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'isreal');
a = uint8(a);
