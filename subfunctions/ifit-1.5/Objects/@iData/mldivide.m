function c = mldivide(a,b)
% c = mldivide(a,b) : a\b is fast notation for combine(a,b)
%
%   @iData/mldivide (\) function to combine data sets
%     the 'matrix left division' notation is used to ease
%     combination data sets, so that:
%       a\b = combine(a,b)
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: object or array (iData)
% ex:     c=a\b;
%
% Version: $Revision: 1035 $
% See also iData, iData/combine
if nargin ==1
	b=[];
end
c = combine(a,b);

