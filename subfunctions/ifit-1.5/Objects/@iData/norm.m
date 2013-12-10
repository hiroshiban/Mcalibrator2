function a = norm(a)
% b = norm(s) : norm-2 of iData object
%
%   @iData/norm function to return the norm-2 of data sets
%   This function computes the norm of the object 's'.
%
% input:  s: object or array (iData)
% output: b: norm (double)
% ex:     b=norm(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sum, iData/trapz, norm

a = iData_private_unary(a, 'norm');

