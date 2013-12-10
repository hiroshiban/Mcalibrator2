function a = del2(a)
% b = del2(s) : computes the Discrete Laplacian of iFunc object
%
%   @iFunc/del2 function to compute the Discrete Laplacian of models.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=del2(a);
%
% Version: $Revision: 1077 $
% See also iFunc, iFunc/gradient, del2, gradient, iFunc/jacobian

% make sure axes are regularly binned

a = iFunc_private_unary(a, 'del2');

