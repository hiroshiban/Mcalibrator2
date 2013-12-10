function a = issparse(a)
% b = issparse(s) : True for sparse matrix iData object
%
%   @iData/issparse function to return true if data set is a vector
%   of 's', i.e. that size is 1xN or Nx1
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=issparse(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sign, iData/isreal, iData/isfinite, iData/isnan,
%          iData/isinf, iData/isfloat, iData/isinterger,
%          iData/isnumeric, iData/islogical, iData/isscalar, 
%          iData/isvector, iData/issparse

a = iData_private_unary(a, 'issparse');
a = uint8(a);
