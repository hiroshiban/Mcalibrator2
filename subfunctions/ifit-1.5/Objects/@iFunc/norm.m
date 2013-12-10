function a = norm(a)
% b = norm(s) : norm-2 of iFunc object
%
%   @iFunc/norm function to return the norm-2 of data sets
%   This function computes the norm of the object 's'.
%
% input:  s: object or array (iFunc)
% output: b: norm (double)
% ex:     b=norm(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/sum, iFunc/trapz, norm

a = iFunc_private_unary(a, 'norm');

