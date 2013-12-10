function c = plus(a,b)
% c = plus(a,b) : computes the sum of iFunc objects
%
%   @iFunc/plus (+) function to compute the sum of functions
%     when one of the argument is a character string, it is used as-is in the 
%     operator expression. When this string also contains an equal or ';'
%     character, the argument is prepended/appended to the Expression:
%       model = gauss + 'b'
%     adds a Gaussian with 'b' (you then need to define 'b' somewhere else, for 
%     instance as a global variable in Constraint: model.Constraint = 'global b'
%       model = gauss + 'disp(''This was the Gaussian !'');'
%     adds some code after the Expression.
%       model = 'disp(''There comes the Gaussian !'');' + gauss
%     adds some code before the Expression.
%
% input:  a: object or array (iFunc or numeric or char)
%         b: object or array (iFunc or numeric or char)
% output: c: object or array (iFunc)
% ex:     c=a+1;
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/minus, iFunc/plus, iFunc/times, iFunc/rdivide

if nargin ==1
	b=[];
end
c = iFunc_private_binary(a, b, 'plus');

