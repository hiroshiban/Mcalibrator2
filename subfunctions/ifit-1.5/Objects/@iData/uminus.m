function a = uminus(a)
% b = uminus(s) : opposite value of iData object
%
%   @iData/uminus function to return the opposite value of data sets, i.e. b=-s.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=uminus(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/uminus, iData/abs, iData/real, iData/imag, iData/uplus

a = iData_private_unary(a, 'uminus');

