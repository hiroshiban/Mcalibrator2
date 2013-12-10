function a = round(a)
% b = round(s) : upper integer round of iData object
%
%   @iData/round function to round the elements of 's' to the nearest integers.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=round(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/floor, iData/ceil, iData/round

a = iData_private_unary(a, 'round');

