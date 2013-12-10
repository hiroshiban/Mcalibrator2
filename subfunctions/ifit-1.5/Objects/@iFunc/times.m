function c = times(a,b)
% c = times(a,b) : computes the multiplication of iFunc objects
%
%   @iFunc/times (.*) function to compute the product of functions
%     when one of the argument is a character string, it is used as-is in the 
%     operator expression. 
%
% input:  a: object or array (iFunc or numeric)
%         b: object or array (iFunc or numeric)
% output: c: object or array (iFunc)
% ex:     c=lorz.*gauss;
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/minus, iFunc/plus, iFunc/times, iFunc/rdivide

if nargin ==1
	b=[];
end
c = iFunc_private_binary(a, b, 'times');

