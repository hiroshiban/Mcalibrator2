function a = sign(a)
% b = sign(s) : sign of iFunc object
%
%   @iFunc/sign function to return the sign of data sets
%   This function computes the sign of the object 's', i.e
%   -1 for negative values, 0 for null, and +1 for positive values.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=sign(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/sign, iFunc/isreal, iFunc/isfinite, iFunc/isnan,
%          iFunc/isinf, iFunc/isfloat, iFunc/isinterger,
%          iFunc/isnumeric, iFunc/islogical, iFunc/isscalar, 
%          iFunc/isvector, iFunc/issparse

a = iFunc_private_unary(a, 'sign');

