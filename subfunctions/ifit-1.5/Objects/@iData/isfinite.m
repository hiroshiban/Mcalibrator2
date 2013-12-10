function a = isfinite(a)
% b = isfinite(s) : True for finite iData object elements
%
%   @iData/isfinite function to return true for finite elements
%   of 's', i.e. that are not NaN, Inf or -Inf.
%
% input:  s: object or array (iData)
% output: b: array (int)
% ex:     b=isfinite(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'isfinite');

