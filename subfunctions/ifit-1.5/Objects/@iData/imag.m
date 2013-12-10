function a = imag(a)
% b = imag(s) : imaginary part of iData object
%
%   @iData/imag function to return the imaginary part of data sets.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=imag(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/uminus, iData/abs, iData/real, iData/imag, iData/uplus

a = iData_private_unary(a, 'imag');

