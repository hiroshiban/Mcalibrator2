function a = imag(a)
% b = imag(s) : imaginary part of iFunc object
%
%   @iFunc/imag function to return the imaginary part of data sets.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=imag(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/uminus, iFunc/abs, iFunc/real, iFunc/imag, iFunc/uplus

a = iFunc_private_unary(a, 'imag');

