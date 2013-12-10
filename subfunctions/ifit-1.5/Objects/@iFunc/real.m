function a = real(a)
% b = real(s) : real value of iFunc object
%
%   @iFunc/real function to return the real value of data sets.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=real(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/uminus, iFunc/abs, iFunc/real, iFunc/imag, iFunc/uplus

a = iFunc_private_unary(a, 'real');

