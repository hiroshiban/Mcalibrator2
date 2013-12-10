function a = isscalar(a)
% b = isscalar(s) : True for scalar iData objects
%
%   @iData/isscalar function to return true if data set is a single scalar element
%   of 's', i.e. that size is 1x1
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=isscalar(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'isscalar');

