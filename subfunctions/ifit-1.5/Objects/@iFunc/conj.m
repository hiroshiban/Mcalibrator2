function a = conj(a)
% b = conj(s) : conjugate of iFunc object
%
%   @iFunc/conj function to return conjugate of data sets
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=conj(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/transpose, iFunc/ctranspose, iFunc?imag, iFunc/real

a = iFunc_private_unary(a, 'conj');


