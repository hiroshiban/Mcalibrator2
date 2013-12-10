function c = power(a,b)
% c = power(a,b) : computes the power of iData objects
%
%   @iData/power function to compute the power of data sets
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: object or array (iData)
% ex:     c=a.^2;
%
% Version: $Revision: 1035 $
% See also iData, iData/times, iData/rdivide, iData/power

if nargin == 1,
  b = a;
end
c = iData_private_binary(a, b, 'power');

