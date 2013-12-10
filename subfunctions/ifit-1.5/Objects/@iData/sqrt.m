function a = sqrt(a)
% b = sqrt(s) : square root value of iData object
%
%   @iData/sqrt function to return the square root value of data sets
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=sqrt(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/sqrt, iData/power

a = iData_private_unary(a, 'sqrt');

