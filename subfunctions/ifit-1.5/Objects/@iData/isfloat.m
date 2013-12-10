function a = isfloat(a)
% b = isfloat(s) : True for float iData object elements
%
%   @iData/isfloat function to return true for float elements
%   of 's', i.e. that are of type double or single (complex or real).
%
% input:  s: object or array (iData)
% output: b: array (int)
% ex:     b=isfloat(a);
%
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'isfloat');

