function a = uminus(a)
% b = uminus(s) : opposite value of iFunc object
%
%   @iFunc/uminus function to return the opposite value of data sets, i.e. b=-s.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=uminus(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/uminus, iFunc/abs, iFunc/real, iFunc/imag, iFunc/uplus

a = iFunc_private_unary(a, 'uminus');

