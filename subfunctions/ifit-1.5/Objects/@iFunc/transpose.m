function a = transpose(a)
% b = transpose(s) : non-conjugate transpose of iFunc object
%
%   @iFunc/transpose function to return the non-conjugate transpose of data sets
%   which corresponds to syntax: b = s.'
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=transpose(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/transpose, iFunc/ctranspose, iFunc/setaxis, iFunc/getaxis

if numel(a) > 1
  a = builtin('transpose', a);
elseif ndims(a) <=2
  a = iFunc_private_unary(a, 'transpose');
else
  a = permute(a, [2 1]);
end

