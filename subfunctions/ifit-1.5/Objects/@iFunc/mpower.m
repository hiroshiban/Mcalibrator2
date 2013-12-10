function c = mpower(a,b)
% c = mpower(a,b) : computes the power of iFunc objects
%
%   @iFunc/mpower (^) function to compute the matrix-power of functions (orthogonal axes)
%     when one of the argument is a character string, it is used as-is in the 
%     operator expression. 
%     when the second argument is an integer, the initial model is extended
%     orthogonaly, creating a ndims(a)*b dimension model
%
% input:  a: object or array (iFunc or numeric)
%         b: object or array (iFunc or numeric)
% output: c: object or array (iFunc)
% ex:     c=lorz^gauss; c=gauss^3
%
% Version: $Revision: 1079 $
% See also iFunc, iFunc/minus, iFunc/plus, iFunc/times, iFunc/rdivide

if nargin ==1
	b=[];
end
c = iFunc_private_binary(a, b, 'mpower');

