function a = conj(a)
% b = conj(s) : conjugate of iData object
%
%   @iData/conj function to return conjugate of data sets
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=conj(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/transpose, iData/ctranspose, iData?imag, iData/real

a = iData_private_unary(a, 'conj');


