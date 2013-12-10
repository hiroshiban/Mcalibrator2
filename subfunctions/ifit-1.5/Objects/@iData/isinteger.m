function a = isinterger(a)
% b = isinterger(s) : True for integer iData object elements
%
%   @iData/isinterger function to return true for integer elements
%   of 's', i.e. that are of type 'uint' and 'int'.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=isinterger(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'isinteger');
a = uint8(a);
