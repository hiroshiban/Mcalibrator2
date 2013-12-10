function a = abs(a)
% b = abs(s) : absolute value of iFunc object
%
%   @iFunc/abs function to return the absolute value of data sets
%   This function computes the absolute value/modulus of the object 's'.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=abs(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/uminus, iFunc/abs, iFunc/real, iFunc/imag, iFunc/uplus

a = iFunc_private_unary(a, 'abs');

