function a = not(a)
% b = not(s) : computes the logical 'not' of iFunc object
%
%   @iFunc/not function to compute the logical 'not' of data sets, 
%     i.e. returns 0 where iFunc Signal is not zero, and 1 otherwise.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=not(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/or, iFunc/and

a = iFunc_private_unary(a, 'not');

