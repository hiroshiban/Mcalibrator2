function a = floor(a)
% b = floor(s) : lower integer round of iData object
%
%   @iData/floor function to round the elements of 's' to the nearest integers
%   towards minus infinity.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=floor(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/floor, iData/ceil, iData/round

a = iData_private_unary(a, 'floor');

