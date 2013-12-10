function c = plus(a,b)
% c = plus(a,b) : computes the sum of iData objects
%
%   @iData/plus (+) function to compute the sum of data sets 
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: object or array (iData)
% ex:     c=a+1;
%
% Version: $Revision: 1035 $
% See also iData, iData/minus, iData/plus, iData/times, iData/rdivide, iData/combine

if nargin ==1
	b=[];
end
c = iData_private_binary(a, b, 'plus');

