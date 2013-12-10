function c = mtimes(a,b)
% c = mtimes(a,b) : computes the multiplication of iFunc objects
%
%   @iFunc/mtimes (*) function to compute the matrix-product of functions (orthogonal axes)
%     when one of the argument is a character string, it is used as-is in the 
%     operator expression. 
%
% input:  a: object or array (iFunc or numeric)
%         b: object or array (iFunc or numeric)
% output: c: object or array (iFunc)
% ex:     c=lorz*gauss;
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/minus, iFunc/plus, iFunc/times, iFunc/rdivide

if nargin ==1
	b=[];
end
c = iFunc_private_binary(a, b, 'mtimes');

