function a = abs(a)
% b = abs(s) : absolute value of iData object
%
%   @iData/abs function to return the absolute value of data sets
%   This function computes the absolute value/modulus of the object 's'.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=abs(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/uminus, iData/abs, iData/real, iData/imag, iData/uplus

a = iData_private_unary(a, 'abs');

