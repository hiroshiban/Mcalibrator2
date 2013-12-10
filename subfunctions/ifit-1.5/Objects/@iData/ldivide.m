function c = ldivide(a,b)
% c = ldivide(a,b) : fast notation for combine iData objects
%
%   @iData/ldivide (.\) is fast notation for combine(a,b)
%     the 'left division' notation is used to ease
%     combination data sets, so that:
%       a.\b = combine(a,b)
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: object or array (iData)
% ex:     c=a.\2; c=a.\b;
%
% Version: $Revision: 1035 $
% See also iData, iData/minus, iData/plus, iData/times, iData/mldivide
if nargin ==1
	b=[];
end
c = combine(a,b);
