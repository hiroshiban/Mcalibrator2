function a = sign(a)
% b = sign(s) : sign of iData object
%
%   @iData/sign function to return the sign of data sets
%   This function computes the sign of the object 's', i.e
%   -1 for negative values, 0 for null, and +1 for positive values.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=sign(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'sign');

