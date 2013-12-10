function c = times(a,b)
% c = times(a,b) : computes the product of iData objects
%
%   @iData/times (*) function to compute the product of data sets=a.*b
%     the square of a single iData object should rather be computed 
%     using the power law.
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: object or array (iData)
% ex:     c=a.*2;
%
% Version: $Revision: 1035 $
% See also iData, iData/minus, iData/plus, iData/times, iData/rdivide, iData/power
if nargin ==1
	b=[];
end

c = iData_private_binary(a, b, 'times');

