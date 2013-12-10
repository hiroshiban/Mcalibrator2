function a = islogical(a)
% b = islogical(s) : True for logical iData object elements
%
%   @iData/islogical function to return true for logical elements
%   of 's', i.e. that are of type 'true (1) or false(0)'.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=islogical(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'islogical');
a = uint8(a);
