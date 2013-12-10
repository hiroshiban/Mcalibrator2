function a = real(a)
% b = real(s) : real value of iData object
%
%   @iData/real function to return the real value of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=real(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/uminus, iData/abs, iData/real, iData/imag, iData/uplus

a = iData_private_unary(a, 'real');

