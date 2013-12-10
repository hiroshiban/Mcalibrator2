function a = not(a)
% b = not(s) : computes the logical 'not' of iData object
%
%   @iData/not function to compute the logical 'not' of data sets, 
%     i.e. returns 0 where iData Signal is not zero, and 1 otherwise.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=not(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/or, iData/and

a = iData_private_unary(a, 'not');

