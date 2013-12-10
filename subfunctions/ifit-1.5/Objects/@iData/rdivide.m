function c = rdivide(a,b)
% c = rdivide(a,b) : computes the ratio of iData objects
%
%   @iData/rdivide (./) function to compute the ratio of data sets
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: object or array (iData)
% ex:     c=a./2; c=a./b;
%
% Version: $Revision: 1035 $
% See also iData, iData/minus, iData/plus, iData/times, iData/rdivide
if nargin ==1
	b=[];
end
c = iData_private_binary(a, b, 'rdivide');

